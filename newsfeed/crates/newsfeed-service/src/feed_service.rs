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
