//! `AppState` and `DbPool` — shared application state injected into every
//! Axum handler via `State<Arc<AppState>>`.

use std::{collections::HashSet, sync::Arc};

use newsfeed_config::{AppConfig, DatabaseConfig, DatabaseTarget};

use crate::error::DbError;
use crate::mssql::MssqlConfig;

// ── Active database pool ──────────────────────────────────────────────────────

/// Holds the single active database pool for the configured `DATABASE_TARGET`.
pub enum DbPool {
    Postgres(sqlx::PgPool),
    MariaDb(sqlx::MySqlPool),
    MsSql(Arc<MssqlConfig>),
}

// ── Application state ─────────────────────────────────────────────────────────

/// Shared state injected into every Axum handler via `State<Arc<AppState>>`.
pub struct AppState {
    /// Active database pool (only the configured target is initialised).
    pub db: DbPool,

    /// Pre-parsed set of valid API keys loaded from `API_KEYS` env var.
    /// `HashSet` gives O(1) lookup per request.
    pub api_keys: HashSet<String>,
}

impl AppState {
    /// Initialise `AppState` at startup.
    ///
    /// - Reads `DATABASE_TARGET` and initialises only the matching pool.
    /// - Parses `API_KEYS` into a `HashSet`.
    /// - Panics with a descriptive message if required env vars are missing.
    pub async fn init(
        app_cfg: &AppConfig,
        db_cfg: &DatabaseConfig,
    ) -> Result<Self, DbError> {
        // Validate that required DB env vars are present for the active target.
        db_cfg.validate();

        let db = match db_cfg.database_target {
            DatabaseTarget::Postgres => {
                let url = db_cfg.postgres_url.as_deref()
                    .ok_or_else(|| DbError::Config("POSTGRES_URL not set".into()))?;
                let pool = sqlx::postgres::PgPoolOptions::new()
                    .max_connections(10)
                    .test_before_acquire(true)
                    .connect(url)
                    .await?;
                tracing::info!("Connected to PostgreSQL");
                DbPool::Postgres(pool)
            }
            DatabaseTarget::MariaDb => {
                let url = db_cfg.mariadb_url.as_deref()
                    .ok_or_else(|| DbError::Config("MARIADB_URL not set".into()))?;
                let pool = sqlx::mysql::MySqlPoolOptions::new()
                    .max_connections(10)
                    .test_before_acquire(true)
                    .connect(url)
                    .await?;
                tracing::info!("Connected to MariaDB");
                DbPool::MariaDb(pool)
            }
            DatabaseTarget::MsSql => {
                let config = MssqlConfig {
                    host: db_cfg.mssql_host.clone()
                        .ok_or_else(|| DbError::Config("MSSQL_HOST not set".into()))?,
                    port: db_cfg.mssql_port.unwrap_or(1433),
                    database: db_cfg.mssql_database.clone()
                        .ok_or_else(|| DbError::Config("MSSQL_DATABASE not set".into()))?,
                    username: db_cfg.mssql_username.clone()
                        .ok_or_else(|| DbError::Config("MSSQL_USERNAME not set".into()))?,
                    password: db_cfg.mssql_password.clone()
                        .ok_or_else(|| DbError::Config("MSSQL_PASSWORD not set".into()))?,
                };
                tracing::info!("MSSQL configuration loaded (connections created per request)");
                DbPool::MsSql(Arc::new(config))
            }
        };

        Ok(Self {
            db,
            api_keys: app_cfg.api_keys_set(),
        })
    }
}
