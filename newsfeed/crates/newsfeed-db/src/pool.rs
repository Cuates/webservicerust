//! `AppState` and `DbPool` — shared application state injected into every
//! Axum handler via `State<Arc<AppState>>`.

use std::{collections::HashSet, sync::Arc, time::Duration};

use newsfeed_config::{AppConfig, DatabaseConfig, DatabaseTarget};

use crate::error::DbError;

// ── MSSQL pool type alias ─────────────────────────────────────────────────────

/// Type alias for the bb8-managed MSSQL connection pool.
pub type MssqlPool = bb8::Pool<bb8_tiberius::ConnectionManager>;

// ── Active database pool ──────────────────────────────────────────────────────

/// Holds the single active database pool for the configured `DATABASE_TARGET`.
pub enum DbPool {
    Postgres(sqlx::PgPool),
    MariaDb(sqlx::MySqlPool),
    MsSql(Arc<MssqlPool>),
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
}

// ── Application state ─────────────────────────────────────────────────────────

/// Shared state injected into every Axum handler via `State<Arc<AppState>>`.
pub struct AppState {
    /// Active database pool (only the configured target is initialised).
    pub db: DbPool,

    /// Pre-parsed set of valid API keys loaded from `API_KEYS` env var.
    /// Constant-time comparison is performed at the middleware layer.
    pub api_keys: HashSet<String>,

    /// Concurrency cap for batch CUD operations (`BATCH_CONCURRENCY_LIMIT`).
    pub batch_concurrency_limit: usize,
}

impl AppState {
    /// Initialise `AppState` at startup.
    ///
    /// - Reads `DATABASE_TARGET` and initialises only the matching pool.
    /// - Validates that `API_KEYS` contains at least one key (panics otherwise).
    /// - Applies pool-tuning env vars to sqlx and bb8 pools.
    pub async fn init(app_cfg: &AppConfig, db_cfg: &DatabaseConfig) -> Result<Self, DbError> {
        // Validate that required DB env vars are present for the active target.
        db_cfg.validate();

        // ── Startup guard: refuse to start with zero API keys ─────────────────
        let api_keys = app_cfg.api_keys_set();
        if api_keys.is_empty() {
            return Err(DbError::Config(
                "API_KEYS must contain at least one key. \
                 Run scripts/generate-api-key.sh to generate one."
                    .into(),
            ));
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
                    .idle_timeout(Duration::from_secs(300))
                    .max_lifetime(Duration::from_secs(1800))
                    .test_before_acquire(true)
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
                    .idle_timeout(Duration::from_secs(300))
                    .max_lifetime(Duration::from_secs(1800))
                    .test_before_acquire(true)
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
                    .connection_timeout(acquire_timeout)
                    .build(mgr)
                    .await
                    .map_err(|e| DbError::Config(format!("MSSQL pool build error: {e}")))?;

                tracing::info!(
                    max_connections = db_cfg.db_pool_max,
                    "Connected to MSSQL via bb8-tiberius pool"
                );
                DbPool::MsSql(Arc::new(pool))
            }
        };

        Ok(Self {
            db,
            api_keys,
            batch_concurrency_limit: app_cfg.batch_concurrency_limit,
        })
    }
}
