//! MariaDB query executors.
//!
//! Calls `extractnewsfeed` and `insertupdatedeletenewsfeed` stored procedures
//! using sqlx's MySQL driver (compatible with MariaDB).

use serde_json::Value;
use sqlx::MySqlPool;
use tracing::instrument;

use newsfeed_constants::db::OptionMode;
use newsfeed_models::{CudParams, ExtractParams, NewsFeedRow};

use crate::error::DbError;

// ── Extract ───────────────────────────────────────────────────────────────────

/// Call `extractnewsfeed(...)` stored procedure and return feed rows.
#[instrument(skip(pool), level = "debug")]
pub async fn extract_feed(
    pool: &MySqlPool,
    params: &ExtractParams,
) -> Result<Vec<NewsFeedRow>, DbError> {
    let rows = sqlx::query_as::<_, NewsFeedRow>(
        "CALL extractnewsfeed(?, ?, ?, ?, ?, ?, ?)"
    )
    .bind(OptionMode::EXTRACT_FEED)
    .bind(params.title.as_deref())
    .bind(params.imageurl.as_deref())
    .bind(params.feedurl.as_deref())
    .bind(params.actualurl.as_deref())
    .bind(params.limit.as_deref())
    .bind(params.sort.as_deref())
    .fetch_all(pool)
    .await?;

    tracing::debug!("MariaDB extract returned {} row(s)", rows.len());
    Ok(rows)
}

// ── Create / Update / Delete ──────────────────────────────────────────────────

/// Call `insertupdatedeletenewsfeed(...)` stored procedure and return parsed status JSON.
#[instrument(skip(pool), level = "debug")]
pub async fn cud_feed(
    pool: &MySqlPool,
    option_mode: &str,
    params: &CudParams,
) -> Result<Vec<Value>, DbError> {
    let rows: Vec<(Option<String>,)> = sqlx::query_as(
        "CALL insertupdatedeletenewsfeed(?, ?, ?, ?, ?, ?)"
    )
    .bind(option_mode)
    .bind(params.title.as_deref())
    .bind(params.imageurl.as_deref())
    .bind(params.feedurl.as_deref())
    .bind(params.actualurl.as_deref())
    .bind(params.publishdate.as_deref())
    .fetch_all(pool)
    .await?;

    parse_status_rows(rows)
}

// ── Helpers ───────────────────────────────────────────────────────────────────

fn parse_status_rows(rows: Vec<(Option<String>,)>) -> Result<Vec<Value>, DbError> {
    let mut results = Vec::with_capacity(rows.len());
    for (status_json,) in rows {
        let json_str = status_json.unwrap_or_else(|| {
            r#"{"Status":"Error","Message":"Missing status from procedure"}"#.to_owned()
        });
        let parsed: Value = serde_json::from_str(&json_str)?;
        results.push(parsed);
    }
    Ok(results)
}
