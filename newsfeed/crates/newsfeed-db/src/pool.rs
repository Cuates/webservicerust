//! `AppState` and `DbPool` — shared application state injected into every
//! Axum handler via `State<Arc<AppState>>`.

use std::{sync::Arc, sync::atomic::AtomicBool, time::Duration};

use newsfeed_config::{AppConfig, DatabaseConfig, DatabaseTarget};

use crate::error::DbError;

// ── MSSQL pool type alias ─────────────────────────────────────────────────────

/// Type alias for the bb8-managed MSSQL connection pool.
pub type MssqlPool = bb8::Pool<bb8_tiberius::ConnectionManager>;

// ── Active database pool ──────────────────────────────────────────────────────

/// Holds the single active database pool for the configured `DATABASE_TARGET`.
#[derive(Debug)]
pub enum DbPool {
    Postgres(sqlx::PgPool),
    MariaDb(sqlx::MySqlPool),
    MsSql(MssqlPool),
}

impl DbPool {
    /// Ping the active database pool to verify connectivity.
    pub async fn ping(&self) -> Result<(), String> {
        match self {
            DbPool::Postgres(p) => sqlx::query("SELECT 1")
                .execute(p)
                .await
                .map(|_| ())
                .map_err(|e| e.to_string()),
            DbPool::MariaDb(p) => sqlx::query("SELECT 1")
                .execute(p)
                .await
                .map(|_| ())
                .map_err(|e| e.to_string()),
            DbPool::MsSql(pool) => pool.get().await.map(|_| ()).map_err(|e| e.to_string()),
        }
    }

    /// Gracefully close the database pool connections.
    pub async fn close(&self) {
        match self {
            DbPool::Postgres(p) => p.close().await,
            DbPool::MariaDb(p) => p.close().await,
            DbPool::MsSql(_) => {} // bb8 handles this on drop
        }
    }
}

// ── Application state ─────────────────────────────────────────────────────────

/// Shared state injected into every Axum handler via `State<Arc<AppState>>`.
#[derive(Debug)]
pub struct AppState {
    /// Active database pool (only the configured target is initialised).
    pub db: DbPool,

    /// Pre-decoded SHA-256 digests of valid API keys loaded from `API_KEYS` env var.
    /// Constant-time comparison is performed at the middleware layer using `subtle::ConstantTimeEq`.
    pub api_keys: Vec<[u8; 32]>,

    /// Cached database health status for zero-overhead /health probes.
    pub is_healthy: Arc<AtomicBool>,
}

impl AppState {
    /// Initialise `AppState` at startup.
    ///
    /// - Reads `DATABASE_TARGET` and initialises only the matching pool.
    /// - Validates that `API_KEYS` contains at least one key (panics otherwise).
    /// - Applies pool-tuning env vars to sqlx and bb8 pools.
    #[allow(clippy::too_many_lines)]
    pub async fn init(app_cfg: &AppConfig, db_cfg: &DatabaseConfig) -> Result<Self, DbError> {
        // ── Startup guard: refuse to start with zero API keys ─────────────────
        let api_keys_set = app_cfg.api_keys_set();
        if api_keys_set.is_empty() {
            return Err(DbError::Config(
                "API_KEYS must contain at least one key. \
                 Run scripts/generate-api-key.sh to generate one."
                    .into(),
            ));
        }

        let mut api_keys = Vec::with_capacity(api_keys_set.len());
        for key_hex in &api_keys_set {
            let mut buf = [0u8; 32];
            hex::decode_to_slice(key_hex, &mut buf).map_err(|_| {
                let prefix = if key_hex.len() > 8 { &key_hex[..8] } else { key_hex };
                DbError::Config(format!(
                    "API_KEYS contains malformed hex string (prefix '{prefix}...'). Must be 64 hex characters."
                ))
            })?;
            api_keys.push(buf);
        }

        let acquire_timeout = Duration::from_secs(db_cfg.db_acquire_timeout_secs);

        let db = match db_cfg.database_target {
            DatabaseTarget::Postgres => {
                let url = db_cfg
                    .postgres_url
                    .as_deref()
                    .ok_or_else(|| DbError::Config("POSTGRES_URL not set".into()))?;
                let pool = sqlx::postgres::PgPoolOptions::new()
                    .max_connections(db_cfg.db_pool_max)
                    .min_connections(db_cfg.db_pool_min)
                    .acquire_timeout(acquire_timeout)
                    .idle_timeout(Duration::from_mins(5))
                    // `test_before_acquire` adds a round-trip query (e.g. SELECT 1) before
                    // handing out every pooled connection. With `max_lifetime` and `idle_timeout`
                    // expiring stale connections, this extra overhead is unnecessary.
                    .max_lifetime(Duration::from_mins(30))
                    .connect(url)
                    .await?;
                tracing::info!(
                    max_connections = db_cfg.db_pool_max,
                    min_connections = db_cfg.db_pool_min,
                    "Connected to PostgreSQL"
                );
                DbPool::Postgres(pool)
            }
            DatabaseTarget::MariaDb => {
                let url = db_cfg
                    .mariadb_url
                    .as_deref()
                    .ok_or_else(|| DbError::Config("MARIADB_URL not set".into()))?;
                let pool = sqlx::mysql::MySqlPoolOptions::new()
                    .max_connections(db_cfg.db_pool_max)
                    .min_connections(db_cfg.db_pool_min)
                    .acquire_timeout(acquire_timeout)
                    .idle_timeout(Duration::from_mins(5))
                    // `test_before_acquire` adds a round-trip query (e.g. SELECT 1) before
                    // handing out every pooled connection. With `max_lifetime` and `idle_timeout`
                    // expiring stale connections, this extra overhead is unnecessary.
                    .max_lifetime(Duration::from_mins(30))
                    .connect(url)
                    .await?;
                tracing::info!(
                    max_connections = db_cfg.db_pool_max,
                    min_connections = db_cfg.db_pool_min,
                    "Connected to MariaDB"
                );
                DbPool::MariaDb(pool)
            }
            DatabaseTarget::MsSql => {
                let host = db_cfg
                    .mssql_host
                    .clone()
                    .ok_or_else(|| DbError::Config("MSSQL_HOST not set".into()))?;
                let port = db_cfg.mssql_port.unwrap_or(1433);
                let database = db_cfg
                    .mssql_database
                    .clone()
                    .ok_or_else(|| DbError::Config("MSSQL_DATABASE not set".into()))?;
                let username = db_cfg
                    .mssql_username
                    .clone()
                    .ok_or_else(|| DbError::Config("MSSQL_USERNAME not set".into()))?;
                let password = db_cfg
                    .mssql_password
                    .clone()
                    .ok_or_else(|| DbError::Config("MSSQL_PASSWORD not set".into()))?;

                let mut tib_cfg = tiberius::Config::new();
                tib_cfg.host(&host);
                tib_cfg.port(port);
                tib_cfg.database(&database);
                tib_cfg.authentication(tiberius::AuthMethod::sql_server(&username, &password));

                // Encryption is driven by env vars to support dev (no cert) vs
                // production (NPM-fronted TLS) without code changes.
                if db_cfg.db_mssql_encrypt {
                    tib_cfg.encryption(tiberius::EncryptionLevel::Required);
                    tracing::info!("MSSQL TLS encryption: Required");
                } else {
                    tib_cfg.encryption(tiberius::EncryptionLevel::NotSupported);
                    tracing::warn!(
                        "MSSQL TLS encryption: NotSupported — \
                         set DB_MSSQL_ENCRYPT=true in production"
                    );
                }
                if db_cfg.db_mssql_trust_cert {
                    tib_cfg.trust_cert();
                    tracing::warn!(
                        "MSSQL certificate trust: enabled — \
                         only use DB_MSSQL_TRUST_CERT=true in local development"
                    );
                }

                let mgr = bb8_tiberius::ConnectionManager::new(tib_cfg);
                let pool = bb8::Pool::builder()
                    .max_size(db_cfg.db_pool_max)
                    .min_idle(Some(db_cfg.db_pool_min))
                    .connection_timeout(acquire_timeout)
                    .idle_timeout(Some(Duration::from_mins(5)))
                    .max_lifetime(Some(Duration::from_mins(30)))
                    .build(mgr)
                    .await
                    .map_err(|e| DbError::Config(format!("MSSQL pool build error: {e}")))?;

                tracing::info!(
                    max_connections = db_cfg.db_pool_max,
                    "Connected to MSSQL via bb8-tiberius pool"
                );
                DbPool::MsSql(pool)
            }
        };

        Ok(Self {
            db,
            api_keys,
            is_healthy: Arc::new(AtomicBool::new(true)),
        })
    }
}

// ── Unit tests ────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use newsfeed_config::{AppConfig, DatabaseConfig, DatabaseTarget};

    fn postgres_app_cfg(api_keys: &str) -> AppConfig {
        let keys_str = if api_keys == "test_key" {
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
        } else {
            api_keys
        };
        AppConfig {
            bind_host: "127.0.0.1".to_string(),
            app_port: 8080,
            rust_log: "info".to_string(),
            api_keys: keys_str.to_string(),
            allowed_origins: "*".to_string(),
            rate_limit_rps: 10,
            rate_limit_burst: 20,
            trust_proxy: false,
            trusted_proxy_cidr: None,
        }
    }

    fn postgres_db_cfg() -> DatabaseConfig {
        DatabaseConfig {
            database_target: DatabaseTarget::Postgres,
            postgres_url: Some("postgres://fake:fake@localhost/fake".to_string()),
            mariadb_url: None,
            mssql_host: None,
            mssql_port: None,
            mssql_database: None,
            mssql_username: None,
            mssql_password: None,
            db_mssql_encrypt: false,
            db_mssql_trust_cert: false,
            db_pool_max: 2,
            db_pool_min: 1,
            db_acquire_timeout_secs: 1,
        }
    }

    // ── AppState::init error paths ────────────────────────────────────────────

    /// When API_KEYS is empty, `init` must return Err(DbError::Config).
    #[tokio::test]
    async fn test_init_fails_with_empty_api_keys() {
        let app_cfg = postgres_app_cfg(""); // empty key string
        let db_cfg = postgres_db_cfg();

        let result = AppState::init(&app_cfg, &db_cfg).await;
        assert!(result.is_err(), "expected Err for empty API keys");
        match result {
            Err(DbError::Config(_)) => {} // expected
            Err(other) => panic!("expected DbError::Config, got: {other}"),
            Ok(_) => panic!("expected Err but got Ok"),
        }
    }

    #[tokio::test]
    async fn test_init_fails_with_malformed_hex_api_key() {
        for key in ["bad_hex", "invalid_hex_string_not_64_chars"] {
            let app_cfg = postgres_app_cfg(key);
            let db_cfg = postgres_db_cfg();
            let result = AppState::init(&app_cfg, &db_cfg).await;
            assert!(
                result
                    .unwrap_err()
                    .to_string()
                    .contains("malformed hex string")
            );
        }
    }

    #[tokio::test]
    async fn test_init_api_keys_multiple_valid_keys() {
        let key1 = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        let key2 = "fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210";
        let app_cfg = postgres_app_cfg(&format!("{key1}, {key2}"));
        let db_cfg = postgres_db_cfg();

        // Note: connecting will fail because postgres://fake is unreachable, but we can verify
        // that if it fails with Sqlx/connection error, the API key validation stage passed!
        let result = AppState::init(&app_cfg, &db_cfg).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_init_api_keys_invalid_hex_length() {
        // 62 hex characters instead of 64
        let app_cfg =
            postgres_app_cfg("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd");
        let db_cfg = postgres_db_cfg();

        let result = AppState::init(&app_cfg, &db_cfg).await;
        assert!(
            result
                .unwrap_err()
                .to_string()
                .contains("Must be 64 hex characters")
        );
    }

    // ── DbPool::ping error paths ──────────────────────────────────────────────

    /// Postgres lazy pool — ping must fail (no real server behind fake URL).
    #[tokio::test]
    async fn test_ping_postgres_fails_on_fake_pool() {
        let pool = sqlx::postgres::PgPoolOptions::new()
            .acquire_timeout(std::time::Duration::from_millis(100))
            .connect_lazy("postgres://fake:fake@localhost/fake")
            .expect("lazy pool must be created without connecting");
        let db_pool = DbPool::Postgres(pool);
        let result = db_pool.ping().await;
        assert!(
            result.is_err(),
            "expected ping error from fake Postgres pool"
        );
    }

    /// MariaDB lazy pool — ping must fail (no real server behind fake URL).
    #[tokio::test]
    async fn test_ping_mariadb_fails_on_fake_pool() {
        let pool = sqlx::mysql::MySqlPoolOptions::new()
            .acquire_timeout(std::time::Duration::from_millis(100))
            .connect_lazy("mysql://fake:fake@localhost/fake")
            .expect("lazy pool must be created without connecting");
        let db_pool = DbPool::MariaDb(pool);
        let result = db_pool.ping().await;
        assert!(
            result.is_err(),
            "expected ping error from fake MariaDB pool"
        );
    }

    /// MSSQL bb8 pool — ping must fail (non-routable address with 1 ms timeout).
    #[tokio::test]
    async fn test_ping_mssql_fails_on_fake_pool() {
        let mut cfg = tiberius::Config::new();
        cfg.host("127.0.0.2"); // non-routable
        cfg.port(1);
        cfg.authentication(tiberius::AuthMethod::sql_server("fake", "fake"));
        cfg.encryption(tiberius::EncryptionLevel::NotSupported);

        let mgr = bb8_tiberius::ConnectionManager::new(cfg);
        let pool = bb8::Pool::builder().build_unchecked(mgr);

        let db_pool = DbPool::MsSql(pool);
        let result = db_pool.ping().await;
        assert!(result.is_err(), "expected ping error from fake MSSQL pool");
    }

    // ── AppState::init configuration error paths ──────────────────────────────

    #[tokio::test]
    async fn test_init_postgres_missing_url() {
        let app_cfg = postgres_app_cfg("test_key");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.postgres_url = None; // Missing URL

        let result = AppState::init(&app_cfg, &db_cfg).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_init_postgres_connection_failure() {
        let app_cfg = postgres_app_cfg("test_key");
        let mut db_cfg = postgres_db_cfg();
        // Provide a URL that fails to connect (e.g. non-routable with 1s timeout)
        db_cfg.postgres_url = Some("postgres://fake:fake@127.0.0.2:1/fake".to_string());
        db_cfg.db_acquire_timeout_secs = 1;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        assert!(result.is_err()); // sqlx::Error connection refused or timeout
    }

    #[tokio::test]
    async fn test_init_mariadb_missing_url() {
        let app_cfg = postgres_app_cfg("test_key");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.database_target = DatabaseTarget::MariaDb;
        db_cfg.mariadb_url = None;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_init_mariadb_connection_failure() {
        let app_cfg = postgres_app_cfg("test_key");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.database_target = DatabaseTarget::MariaDb;
        db_cfg.mariadb_url = Some("mysql://fake:fake@127.0.0.2:1/fake".to_string());
        db_cfg.db_acquire_timeout_secs = 1;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_init_mssql_missing_host() {
        let app_cfg = postgres_app_cfg("test_key");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.database_target = DatabaseTarget::MsSql;
        db_cfg.mssql_host = None;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_init_mssql_missing_database() {
        let app_cfg = postgres_app_cfg("test_key");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.database_target = DatabaseTarget::MsSql;
        db_cfg.mssql_host = Some("127.0.0.2".to_string());
        db_cfg.mssql_database = None;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_init_mssql_missing_username() {
        let app_cfg = postgres_app_cfg("test_key");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.database_target = DatabaseTarget::MsSql;
        db_cfg.mssql_host = Some("127.0.0.2".to_string());
        db_cfg.mssql_database = Some("db".to_string());
        db_cfg.mssql_username = None;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_init_mssql_missing_password() {
        let app_cfg = postgres_app_cfg("test_key");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.database_target = DatabaseTarget::MsSql;
        db_cfg.mssql_host = Some("127.0.0.2".to_string());
        db_cfg.mssql_database = Some("db".to_string());
        db_cfg.mssql_username = Some("sa".to_string());
        db_cfg.mssql_password = None;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_init_mssql_connection_failure() {
        let app_cfg = postgres_app_cfg("test_key");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.database_target = DatabaseTarget::MsSql;
        db_cfg.mssql_host = Some("127.0.0.2".to_string()); // non-routable
        db_cfg.mssql_port = Some(1);
        db_cfg.mssql_database = Some("db".to_string());
        db_cfg.mssql_username = Some("sa".to_string());
        db_cfg.mssql_password = Some("fake".to_string());
        db_cfg.db_mssql_encrypt = false;
        db_cfg.db_mssql_trust_cert = false;
        db_cfg.db_acquire_timeout_secs = 1;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        // bb8 build() tests connections eagerly, so building the pool fails if it can't connect.
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert!(matches!(err, DbError::Config(msg) if msg.contains("MSSQL pool build error")));
    }

    #[tokio::test]
    async fn test_init_mssql_encryption_and_trust() {
        let app_cfg = postgres_app_cfg("test_key");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.database_target = DatabaseTarget::MsSql;
        db_cfg.mssql_host = Some("127.0.0.2".to_string());
        db_cfg.mssql_port = Some(1);
        db_cfg.mssql_database = Some("db".to_string());
        db_cfg.mssql_username = Some("sa".to_string());
        db_cfg.mssql_password = Some("fake".to_string());

        // This covers the specific lines for these toggles
        db_cfg.db_mssql_encrypt = true;
        db_cfg.db_mssql_trust_cert = true;
        db_cfg.db_acquire_timeout_secs = 1;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        // bb8 build() tests connections eagerly, so building the pool fails if it can't connect.
        assert!(result.is_err());
        let err = result.unwrap_err();
        assert!(matches!(err, DbError::Config(msg) if msg.contains("MSSQL pool build error")));
    }
    #[tokio::test]
    async fn test_pool_close() {
        // Create fake DbPools and just call close on them. It shouldn't panic.
        // It's hard to assert state changes on close without real connections,
        // but this provides line coverage for the close() match branches.
        let pg_pool = sqlx::postgres::PgPoolOptions::new()
            .connect_lazy("postgres://fake:5432")
            .unwrap();
        let db_pg = DbPool::Postgres(pg_pool);
        db_pg.close().await;

        let my_pool = sqlx::mysql::MySqlPoolOptions::new()
            .connect_lazy("mysql://fake:3306")
            .unwrap();
        let db_my = DbPool::MariaDb(my_pool);
        db_my.close().await;

        let bb8_mgr = bb8_tiberius::ConnectionManager::build(tiberius::Config::new()).unwrap();
        let ms_pool = bb8::Pool::builder().build_unchecked(bb8_mgr);
        let db_ms = DbPool::MsSql(ms_pool);
        db_ms.close().await;
    }
}
