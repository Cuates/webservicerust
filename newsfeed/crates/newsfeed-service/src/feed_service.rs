//! Feed service: orchestrates database calls via the active `DbPool`.

use std::sync::Arc;

use serde_json::Value;

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
        DbPool::Postgres(pool) => {
            newsfeed_db::postgres::extract_feed(pool, params)
                .await
                .map_err(ServiceError::Database)
        }
        DbPool::MariaDb(pool) => {
            newsfeed_db::mariadb::extract_feed(pool, params)
                .await
                .map_err(ServiceError::Database)
        }
        DbPool::MsSql(cfg) => {
            newsfeed_db::mssql::extract_feed(cfg, params)
                .await
                .map_err(ServiceError::Database)
        }
    }
}

// ── Create / Update / Delete ──────────────────────────────────────────────────

/// Execute a create, update, or delete operation against the configured pool.
///
/// `option_mode` is one of the `OptionMode::*` constants.
pub async fn cud_feed(
    state: &Arc<AppState>,
    option_mode: &str,
    params: &CudParams,
) -> Result<Vec<Value>, ServiceError> {
    match &state.db {
        DbPool::Postgres(pool) => {
            newsfeed_db::postgres::cud_feed(pool, option_mode, params)
                .await
                .map_err(ServiceError::Database)
        }
        DbPool::MariaDb(pool) => {
            newsfeed_db::mariadb::cud_feed(pool, option_mode, params)
                .await
                .map_err(ServiceError::Database)
        }
        DbPool::MsSql(cfg) => {
            newsfeed_db::mssql::cud_feed(cfg, option_mode, params)
                .await
                .map_err(ServiceError::Database)
        }
    }
}
