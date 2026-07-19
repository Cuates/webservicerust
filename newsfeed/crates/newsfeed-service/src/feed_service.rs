//! Feed service: orchestrates database calls via the active `DbPool`.

use std::sync::Arc;

use serde_json::Value;

use newsfeed_constants::db::OptionMode;
use newsfeed_db::pool::{AppState, DbPool};
use newsfeed_models::{CudParams, ExtractParams, NewsFeedRow};

use crate::error::ServiceError;

// ── Extract ───────────────────────────────────────────────────────────────────

/// Execute the extract (read) operation against the configured database pool.
pub async fn extract_feed(
    state: &Arc<AppState>,
    params: &ExtractParams,
) -> Result<Vec<NewsFeedRow>, ServiceError> {
    match &state.db {
        DbPool::Postgres(pool) => newsfeed_db::postgres::extract_feed(pool, params)
            .await
            .map_err(ServiceError::Database),
        DbPool::MariaDb(pool) => newsfeed_db::mariadb::extract_feed(pool, params)
            .await
            .map_err(ServiceError::Database),
        DbPool::MsSql(pool) => newsfeed_db::mssql::extract_feed(pool, params)
            .await
            .map_err(ServiceError::Database),
    }
}

// ── Create / Update / Delete ──────────────────────────────────────────────────

/// Execute a create, update, or delete operation against the configured pool.
///
/// `option_mode` is a typed `OptionMode` enum variant — the correct procedure
/// argument string is produced via `OptionMode::as_str()` inside each driver.
pub async fn cud_feed(
    state: &Arc<AppState>,
    option_mode: OptionMode,
    params: &CudParams,
) -> Result<Vec<Value>, ServiceError> {
    match &state.db {
        DbPool::Postgres(pool) => newsfeed_db::postgres::cud_feed(pool, option_mode, params)
            .await
            .map_err(ServiceError::Database),
        DbPool::MariaDb(pool) => newsfeed_db::mariadb::cud_feed(pool, option_mode, params)
            .await
            .map_err(ServiceError::Database),
        DbPool::MsSql(pool) => newsfeed_db::mssql::cud_feed(pool, option_mode, params)
            .await
            .map_err(ServiceError::Database),
    }
}

// ── Unit tests ────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashSet;

    // ── helpers ───────────────────────────────────────────────────────────────

    fn make_postgres_state() -> Arc<AppState> {
        let pool = sqlx::postgres::PgPoolOptions::new()
            .connect_lazy("postgres://fake:fake@localhost/fake")
            .expect("lazy pool creation must not fail");
        Arc::new(AppState {
            db: DbPool::Postgres(pool),
            api_keys: HashSet::new(),
            batch_concurrency_limit: 1,
        })
    }

    fn make_mariadb_state() -> Arc<AppState> {
        let pool = sqlx::mysql::MySqlPoolOptions::new()
            .connect_lazy("mysql://fake:fake@localhost/fake")
            .expect("lazy pool creation must not fail");
        Arc::new(AppState {
            db: DbPool::MariaDb(pool),
            api_keys: HashSet::new(),
            batch_concurrency_limit: 1,
        })
    }

    async fn make_mssql_state() -> Arc<AppState> {
        // bb8 with tiberius validates the config eagerly but doesn't open a TCP
        // connection until the first `pool.get()`.  We configure it to point at
        // a non-existent host so any operation will fail immediately.
        let mut cfg = tiberius::Config::new();
        cfg.host("127.0.0.2"); // non-routable — connection refused instantly
        cfg.port(1);
        cfg.authentication(tiberius::AuthMethod::sql_server("fake", "fake"));
        cfg.encryption(tiberius::EncryptionLevel::NotSupported);

        let mgr = bb8_tiberius::ConnectionManager::new(cfg);
        // connection_timeout = 1ms so the test doesn't hang
        let pool = bb8::Pool::builder()
            .connection_timeout(std::time::Duration::from_millis(1))
            .build_unchecked(mgr);

        Arc::new(AppState {
            db: DbPool::MsSql(Arc::new(pool)),
            api_keys: HashSet::new(),
            batch_concurrency_limit: 1,
        })
    }

    fn default_extract_params() -> ExtractParams {
        ExtractParams {
            title: None,
            image_url: None,
            feed_url: None,
            actual_url: None,
            limit: None,
            sort: None,
        }
    }

    fn default_cud_params() -> CudParams {
        CudParams {
            title: Some("test".to_string()),
            image_url: None,
            feed_url: Some("http://example.com".to_string()),
            actual_url: None,
            publish_date: None,
        }
    }

    // ── extract_feed dispatch arms ─────────────────────────────────────────────

    #[tokio::test]
    async fn test_extract_feed_postgres_dispatches_and_errors() {
        let state = make_postgres_state();
        let result = extract_feed(&state, &default_extract_params()).await;
        assert!(result.is_err(), "expected DB error from fake Postgres pool");
        assert!(matches!(result.unwrap_err(), ServiceError::Database(_)));
    }

    #[tokio::test]
    async fn test_extract_feed_mariadb_dispatches_and_errors() {
        let state = make_mariadb_state();
        let result = extract_feed(&state, &default_extract_params()).await;
        assert!(result.is_err(), "expected DB error from fake MariaDB pool");
        assert!(matches!(result.unwrap_err(), ServiceError::Database(_)));
    }

    #[tokio::test]
    async fn test_extract_feed_mssql_dispatches_and_errors() {
        let state = make_mssql_state().await;
        let result = extract_feed(&state, &default_extract_params()).await;
        assert!(result.is_err(), "expected DB error from fake MSSQL pool");
        assert!(matches!(result.unwrap_err(), ServiceError::Database(_)));
    }

    // ── cud_feed dispatch arms ─────────────────────────────────────────────────

    #[tokio::test]
    async fn test_cud_feed_postgres_dispatches_and_errors() {
        let state = make_postgres_state();
        let result = cud_feed(&state, OptionMode::InsertFeed, &default_cud_params()).await;
        assert!(result.is_err(), "expected DB error from fake Postgres pool");
        assert!(matches!(result.unwrap_err(), ServiceError::Database(_)));
    }

    #[tokio::test]
    async fn test_cud_feed_mariadb_dispatches_and_errors() {
        let state = make_mariadb_state();
        let result = cud_feed(&state, OptionMode::InsertFeed, &default_cud_params()).await;
        assert!(result.is_err(), "expected DB error from fake MariaDB pool");
        assert!(matches!(result.unwrap_err(), ServiceError::Database(_)));
    }

    #[tokio::test]
    async fn test_cud_feed_mssql_dispatches_and_errors() {
        let state = make_mssql_state().await;
        let result = cud_feed(&state, OptionMode::InsertFeed, &default_cud_params()).await;
        assert!(result.is_err(), "expected DB error from fake MSSQL pool");
        assert!(matches!(result.unwrap_err(), ServiceError::Database(_)));
    }
}
