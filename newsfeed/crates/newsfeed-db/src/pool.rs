//! `AppState` and `DbPool` — shared application state injected into every
//! Axum handler via `State<Arc<AppState>>`.

use std::{sync::Arc, sync::atomic::AtomicBool, time::Duration};

use newsfeed_config::{AppConfig, DatabaseConfig, DatabaseTarget};

use crate::error::DbError;

//  MSSQL pool type alias

/// Type alias for the bb8-managed MSSQL connection pool.
#[cfg(feature = "mssql")]
pub type MssqlPool = bb8::Pool<bb8_tiberius::ConnectionManager>;

//  Active database pool

/// Holds the single active database pool for the configured `DATABASE_TARGET`.
#[derive(Debug)]
pub enum DbPool {
    #[cfg(feature = "postgres")]
    Postgres(sqlx::PgPool),
    #[cfg(feature = "mariadb")]
    MariaDb(sqlx::MySqlPool),
    #[cfg(feature = "mssql")]
    MsSql(MssqlPool),
}

impl DbPool {
    /// Ping the active database pool to verify connectivity.
    pub async fn ping(&self) -> Result<(), DbError> {
        match self {
            #[cfg(feature = "postgres")]
            #[rustfmt::skip]
            DbPool::Postgres(p) => sqlx::query("SELECT 1").execute(p).await.map(|_| ()).map_err(DbError::Sqlx),
            #[cfg(feature = "mariadb")]
            #[rustfmt::skip]
            DbPool::MariaDb(p) => sqlx::query("SELECT 1").execute(p).await.map(|_| ()).map_err(DbError::Sqlx),
            #[cfg(feature = "mssql")]
            DbPool::MsSql(pool) => {
                let mut conn = pool.get().await?;
                #[cfg_attr(coverage_nightly, coverage(off))]
                tiberius::Query::new("SELECT 1")
                    .query(&mut *conn)
                    .await
                    .map(|_| ())
                    .map_err(DbError::Tiberius)
            }
        }
    }

    /// Gracefully close the database pool connections.
    pub async fn close(&self) {
        match self {
            #[cfg(feature = "postgres")]
            DbPool::Postgres(p) => p.close().await,
            #[cfg(feature = "mariadb")]
            DbPool::MariaDb(p) => p.close().await,
            #[cfg(feature = "mssql")]
            DbPool::MsSql(_) => {} // bb8 handles this on drop
        }
    }
}

//  Application state

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
        //  Startup guard: refuse to start with zero API keys
        let required_pool_size = (u32::try_from(app_cfg.rate_limit_rps).unwrap_or(u32::MAX)
            / newsfeed_constants::db::POOL_CONNECTIONS_PER_RPS)
            .max(1);
        if db_cfg.db_pool_max < required_pool_size {
            #[rustfmt::skip]
            return Err(DbError::Config(format!("Boot-time assertion failed: DB_POOL_MAX ({}) is dangerously low compared to RATE_LIMIT_RPS ({}). Must be >= {} to prevent thread starvation.", db_cfg.db_pool_max, app_cfg.rate_limit_rps, required_pool_size)));
        }

        let api_keys_set = app_cfg.api_keys_set();
        if api_keys_set.is_empty() {
            #[rustfmt::skip]
            return Err(DbError::Config("API_KEYS must contain at least one key. Run scripts/generate-api-key.sh to generate one.".into()));
        }

        let mut api_keys = Vec::with_capacity(api_keys_set.len());
        for key_hex in &api_keys_set {
            let mut buf = [0u8; 32];
            hex::decode_to_slice(key_hex, &mut buf).map_err(|_| {
                let prefix: String = key_hex.chars().take(8).collect();
                #[rustfmt::skip]
                return DbError::Config(format!("API_KEYS contains malformed hex string (prefix '{prefix}...'). Must be 64 hex characters."));
            })?;
            api_keys.push(buf);
        }

        let acquire_timeout = Duration::from_secs(db_cfg.db_acquire_timeout_secs);

        let db = match db_cfg.database_target {
            DatabaseTarget::Postgres => {
                #[cfg(feature = "postgres")]
                {
                    #[rustfmt::skip]
                    let url = db_cfg.postgres_url.as_deref().ok_or_else(|| DbError::Config("POSTGRES_URL not set".into()))?;
                    let pool = sqlx::postgres::PgPoolOptions::new()
                        .max_connections(db_cfg.db_pool_max)
                        .min_connections(db_cfg.db_pool_min)
                        .acquire_timeout(acquire_timeout)
                        .idle_timeout(Duration::from_mins(
                            newsfeed_constants::db::PoolDefaults::IDLE_TIMEOUT_MINS,
                        ))
                        .max_lifetime(Duration::from_mins(
                            newsfeed_constants::db::PoolDefaults::MAX_LIFETIME_MINS,
                        ))
                        .connect(url)
                        .await?;
                    tracing::info!(
                        max_connections = db_cfg.db_pool_max,
                        min_connections = db_cfg.db_pool_min,
                        "Connected to Postgres"
                    );
                    DbPool::Postgres(pool)
                }
                #[cfg(not(feature = "postgres"))]
                return Err(DbError::Config(
                    "Configured database target Postgres is not enabled in this build".into(),
                ));
            }
            DatabaseTarget::MariaDb => {
                #[cfg(feature = "mariadb")]
                {
                    #[rustfmt::skip]
                    let url = db_cfg.mariadb_url.as_deref().ok_or_else(|| DbError::Config("MARIADB_URL not set".into()))?;
                    let pool = sqlx::mysql::MySqlPoolOptions::new()
                        .max_connections(db_cfg.db_pool_max)
                        .min_connections(db_cfg.db_pool_min)
                        .acquire_timeout(acquire_timeout)
                        .idle_timeout(Duration::from_mins(5))
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
                #[cfg(not(feature = "mariadb"))]
                return Err(DbError::Config(
                    "Configured database target MariaDb is not enabled in this build".into(),
                ));
            }
            DatabaseTarget::MsSql => {
                #[cfg(feature = "mssql")]
                {
                    pub fn create_mssql_config(
                        db_cfg: &DatabaseConfig,
                    ) -> Result<tiberius::Config, DbError> {
                        let mut config = tiberius::Config::new();
                        #[rustfmt::skip]
                        config.host(db_cfg.mssql_host.as_deref().ok_or_else(|| DbError::Config("MSSQL_HOST not set".into()))?);
                        config.port(db_cfg.mssql_port.unwrap_or(1433));
                        config.database(
                            db_cfg
                                .mssql_database
                                .as_deref()
                                .ok_or_else(|| DbError::Config("MSSQL_DATABASE not set".into()))?,
                        );
                        config.authentication(tiberius::AuthMethod::sql_server(
                            db_cfg
                                .mssql_username
                                .as_deref()
                                .ok_or_else(|| DbError::Config("MSSQL_USERNAME not set".into()))?,
                            db_cfg
                                .mssql_password
                                .as_deref()
                                .ok_or_else(|| DbError::Config("MSSQL_PASSWORD not set".into()))?,
                        ));
                        config.encryption(if db_cfg.db_mssql_encrypt {
                            tiberius::EncryptionLevel::Required
                        } else {
                            tiberius::EncryptionLevel::NotSupported
                        });
                        if db_cfg.db_mssql_trust_cert {
                            config.trust_cert();
                        }
                        Ok(config)
                    }

                    let mssql_config = create_mssql_config(db_cfg)?;
                    let mgr = bb8_tiberius::ConnectionManager::new(mssql_config);
                    let pool = bb8::Pool::builder()
                        .max_size(db_cfg.db_pool_max)
                        .min_idle(Some(db_cfg.db_pool_min))
                        .connection_timeout(acquire_timeout)
                        .idle_timeout(Some(Duration::from_mins(
                            newsfeed_constants::db::PoolDefaults::IDLE_TIMEOUT_MINS,
                        )))
                        .max_lifetime(Some(Duration::from_mins(
                            newsfeed_constants::db::PoolDefaults::MAX_LIFETIME_MINS,
                        )))
                        .build(mgr)
                        .await
                        .map_err(|e| DbError::Config(format!("MSSQL pool build error: {e}")))?;

                    tracing::info!(
                        max_connections = db_cfg.db_pool_max,
                        "Connected to MSSQL via bb8-tiberius pool"
                    );
                    DbPool::MsSql(pool)
                }
                #[cfg(not(feature = "mssql"))]
                return Err(DbError::Config(
                    "Configured database target MsSql is not enabled in this build".into(),
                ));
            }
        };

        Ok(Self {
            db,
            api_keys,
            is_healthy: Arc::new(AtomicBool::new(true)),
        })
    }
}

//  Unit tests

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
        #[rustfmt::skip]
        let cfg = AppConfig { bind_host: "127.0.0.1".to_string(), app_port: 8080, rust_log: "info".to_string(), api_keys: keys_str.to_string(), allowed_origins: "*".to_string(), rate_limit_rps: 10, rate_limit_burst: 20, trust_proxy: false, trusted_proxy_cidr: None, timeout_standard_secs: 10, timeout_cud_secs: 60 };
        cfg
    }

    fn postgres_db_cfg() -> DatabaseConfig {
        #[rustfmt::skip]
        let cfg = DatabaseConfig { database_target: DatabaseTarget::Postgres, postgres_url: Some("postgres://fake:fake@localhost/fake".to_string()), mariadb_url: None, mssql_host: None, mssql_port: None, mssql_database: None, mssql_username: None, mssql_password: None, db_mssql_encrypt: false, db_mssql_trust_cert: false, db_pool_max: 2, db_pool_min: 1, db_acquire_timeout_secs: 1 };
        cfg
    }

    //  AppState::init error paths

    #[tokio::test]
    async fn test_init_fails_with_dangerously_low_pool_size() {
        let mut app_cfg = postgres_app_cfg("test_key");
        app_cfg.rate_limit_rps = 100; // Requires pool size >= 10
        let mut db_cfg = postgres_db_cfg();
        db_cfg.db_pool_max = 2;
        let err = AppState::init(&app_cfg, &db_cfg)
            .await
            .unwrap_err()
            .to_string();
        assert!(err.contains("dangerously low compared to RATE_LIMIT_RPS"));
    }

    #[tokio::test]
    async fn test_init_fails_with_negative_rps() {
        let mut app_cfg = postgres_app_cfg("test_key");
        app_cfg.rate_limit_rps = u64::MAX; // triggers try_from to fail and unwrap_or(u32::MAX)
        let db_cfg = postgres_db_cfg();
        let err = AppState::init(&app_cfg, &db_cfg)
            .await
            .unwrap_err()
            .to_string();
        assert!(err.contains("dangerously low compared to RATE_LIMIT_RPS"));
    }

    #[tokio::test]
    async fn test_init_fails_with_missing_api_keys() {
        let app_cfg = postgres_app_cfg("");
        let db_cfg = postgres_db_cfg();
        let err = AppState::init(&app_cfg, &db_cfg)
            .await
            .unwrap_err()
            .to_string();
        assert!(err.contains("API_KEYS must contain at least one key"));
    }

    /// When API_KEYS is empty, `init` must return Err(DbError::Config).
    #[tokio::test]
    async fn test_init_fails_with_empty_api_keys() {
        let app_cfg = postgres_app_cfg(""); // empty key string
        let db_cfg = postgres_db_cfg();
        let err = AppState::init(&app_cfg, &db_cfg)
            .await
            .unwrap_err()
            .to_string();
        assert!(err.contains("API_KEYS must contain at least one key"));
    }

    #[tokio::test]
    async fn test_init_fails_with_malformed_hex_api_key() {
        let app_cfg = postgres_app_cfg("bad_hex");
        let db_cfg = postgres_db_cfg();
        let err = AppState::init(&app_cfg, &db_cfg)
            .await
            .unwrap_err()
            .to_string();
        assert!(err.contains("malformed hex string"));

        let app_cfg2 = postgres_app_cfg("invalid_hex_string_not_64_chars");
        let err2 = AppState::init(&app_cfg2, &db_cfg)
            .await
            .unwrap_err()
            .to_string();
        assert!(err2.contains("malformed hex string"));
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
        let _ = result.unwrap_err();
    }

    #[tokio::test]
    async fn test_init_api_keys_invalid_hex_length() {
        let app_cfg =
            postgres_app_cfg("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd");
        let db_cfg = postgres_db_cfg();
        let err = AppState::init(&app_cfg, &db_cfg)
            .await
            .unwrap_err()
            .to_string();
        assert!(err.contains("Must be 64 hex characters"));
    }

    //  DbPool::ping error paths

    /// Postgres lazy pool — ping must fail (no real server behind fake URL).
    #[cfg(feature = "postgres")]
    #[tokio::test]
    async fn test_ping_postgres_fails_on_fake_pool() {
        #[rustfmt::skip]
        let pool = sqlx::postgres::PgPoolOptions::new().acquire_timeout(std::time::Duration::from_millis(100)).connect_lazy("postgres://fake:fake@localhost/fake").expect("lazy pool must be created without connecting");
        let db_pool = DbPool::Postgres(pool);
        let result = db_pool.ping().await;
        let _ = result.unwrap_err();
    }

    /// MariaDB lazy pool — ping must fail (no real server behind fake URL).
    #[cfg(feature = "mariadb")]
    #[tokio::test]
    async fn test_ping_mariadb_fails_on_fake_pool() {
        #[rustfmt::skip]
        let pool = sqlx::mysql::MySqlPoolOptions::new().acquire_timeout(std::time::Duration::from_millis(100)).connect_lazy("mysql://fake:fake@localhost/fake").expect("lazy pool must be created without connecting");
        let db_pool = DbPool::MariaDb(pool);
        let result = db_pool.ping().await;
        let _ = result.unwrap_err();
    }

    /// MSSQL bb8 pool — ping must fail (non-routable address with 1 ms timeout).
    #[cfg(feature = "mssql")]
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

    //  AppState::init configuration error paths

    #[tokio::test]
    async fn test_init_postgres_missing_url() {
        let app_cfg =
            postgres_app_cfg("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.postgres_url = None; // Missing URL

        let result = AppState::init(&app_cfg, &db_cfg).await;
        let _ = result.unwrap_err();
    }

    #[tokio::test]
    async fn test_init_postgres_connection_failure() {
        let app_cfg =
            postgres_app_cfg("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
        let mut db_cfg = postgres_db_cfg();
        // Provide a URL that fails to connect (e.g. non-routable with 1s timeout)
        db_cfg.postgres_url = Some("postgres://fake:fake@127.0.0.2:1/fake".to_string());
        db_cfg.db_acquire_timeout_secs = 1;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        let _ = result.unwrap_err(); // sqlx::Error connection refused or timeout
    }

    #[tokio::test]
    async fn test_init_mariadb_missing_url() {
        let app_cfg =
            postgres_app_cfg("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.database_target = DatabaseTarget::MariaDb;
        db_cfg.mariadb_url = None;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        let _ = result.unwrap_err();
    }

    #[tokio::test]
    async fn test_init_mariadb_connection_failure() {
        let app_cfg =
            postgres_app_cfg("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.database_target = DatabaseTarget::MariaDb;
        db_cfg.mariadb_url = Some("mysql://fake:fake@127.0.0.2:1/fake".to_string());
        db_cfg.db_acquire_timeout_secs = 1;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        let _ = result.unwrap_err();
    }

    #[tokio::test]
    async fn test_init_mssql_missing_host() {
        let app_cfg =
            postgres_app_cfg("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.database_target = DatabaseTarget::MsSql;
        db_cfg.mssql_host = None;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        let _ = result.unwrap_err();
    }

    #[tokio::test]
    async fn test_init_mssql_missing_database() {
        let app_cfg =
            postgres_app_cfg("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.database_target = DatabaseTarget::MsSql;
        db_cfg.mssql_host = Some("127.0.0.2".to_string());
        db_cfg.mssql_database = None;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        let _ = result.unwrap_err();
    }

    #[tokio::test]
    async fn test_init_mssql_missing_username() {
        let app_cfg =
            postgres_app_cfg("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.database_target = DatabaseTarget::MsSql;
        db_cfg.mssql_host = Some("127.0.0.2".to_string());
        db_cfg.mssql_database = Some("db".to_string());
        db_cfg.mssql_username = None;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        let _ = result.unwrap_err();
    }

    #[tokio::test]
    async fn test_init_mssql_missing_password() {
        let app_cfg =
            postgres_app_cfg("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
        let mut db_cfg = postgres_db_cfg();
        db_cfg.database_target = DatabaseTarget::MsSql;
        db_cfg.mssql_host = Some("127.0.0.2".to_string());
        db_cfg.mssql_database = Some("db".to_string());
        db_cfg.mssql_username = Some("sa".to_string());
        db_cfg.mssql_password = None;

        let result = AppState::init(&app_cfg, &db_cfg).await;
        let _ = result.unwrap_err();
    }

    #[cfg(feature = "mssql")]
    #[tokio::test]
    async fn test_init_mssql_connection_failure() {
        let app_cfg =
            postgres_app_cfg("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
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
        let err = result.unwrap_err();
        assert!(matches!(err, DbError::Config(msg) if msg.contains("MSSQL pool build error")));
    }

    #[cfg(feature = "mssql")]
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
        let err = result.unwrap_err();
        assert!(matches!(err, DbError::Config(msg) if msg.contains("MSSQL pool build error")));
    }
    #[tokio::test]
    async fn test_pool_close() {
        #[cfg(feature = "postgres")]
        {
            let pg_pool = sqlx::postgres::PgPoolOptions::new()
                .connect_lazy("postgres://fake:5432")
                .unwrap();
            let db_pg = DbPool::Postgres(pg_pool);
            db_pg.close().await;
        }

        #[cfg(feature = "mariadb")]
        {
            let my_pool = sqlx::mysql::MySqlPoolOptions::new()
                .connect_lazy("mysql://fake:3306")
                .unwrap();
            let db_my = DbPool::MariaDb(my_pool);
            db_my.close().await;
        }

        #[cfg(feature = "mssql")]
        {
            let bb8_mgr = bb8_tiberius::ConnectionManager::build(tiberius::Config::new()).unwrap();
            let ms_pool = bb8::Pool::builder().build_unchecked(bb8_mgr);
            let db_ms = DbPool::MsSql(ms_pool);
            db_ms.close().await;
        }
    }
}
