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
    let raw_rows = sqlx::query("CALL extractnewsfeed(?, ?, ?, ?, ?, ?, ?)")
        .bind(OptionMode::ExtractFeed.as_str())
        .bind(params.title.as_deref())
        .bind(params.image_url.as_deref())
        .bind(params.feed_url.as_deref())
        .bind(params.actual_url.as_deref())
        .bind(params.limit.as_deref())
        .bind(params.sort.as_deref())
        .fetch_all(pool)
        .await?;

    use sqlx::Row;
    let mut feed_rows = Vec::with_capacity(raw_rows.len());
    for row in raw_rows {
        feed_rows.push(NewsFeedRow {
            titlereturn: row.try_get(0).ok().flatten(),
            imageurlreturn: row.try_get(1).ok().flatten(),
            feedurlreturn: row.try_get(2).ok().flatten(),
            actualurlreturn: row.try_get(3).ok().flatten(),
            publishdatereturn: row.try_get(4).ok().flatten(),
        });
    }

    tracing::debug!("MariaDB extract returned {} row(s)", feed_rows.len());
    Ok(feed_rows)
}

// ── Create / Update / Delete ──────────────────────────────────────────────────

/// Call `insertupdatedeletenewsfeed(...)` stored procedure and return parsed status JSON.
#[instrument(skip(pool), level = "debug")]
pub async fn cud_feed(
    pool: &MySqlPool,
    option_mode: OptionMode,
    params: &CudParams,
) -> Result<Vec<Value>, DbError> {
    let rows: Vec<(Option<String>,)> =
        sqlx::query_as("CALL insertupdatedeletenewsfeed(?, ?, ?, ?, ?, ?)")
            .bind(option_mode.as_str())
            .bind(params.title.as_deref())
            .bind(params.image_url.as_deref())
            .bind(params.feed_url.as_deref())
            .bind(params.actual_url.as_deref())
            .bind(params.publish_date.as_deref())
            .fetch_all(pool)
            .await?;

    parse_status_rows(rows)
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Parse the status column rows returned by the stored procedure.
///
/// A `NULL` status column indicates the procedure produced no usable output —
/// propagated as `DbError::EmptyResult` so the handler returns a 5xx rather
/// than a misleading `200 OK` with an error body.
fn parse_status_rows(rows: Vec<(Option<String>,)>) -> Result<Vec<Value>, DbError> {
    let mut results = Vec::with_capacity(rows.len());
    for (status_json,) in rows {
        let json_str = status_json.ok_or(DbError::EmptyResult)?;
        let parsed: Value = serde_json::from_str(&json_str)?;
        results.push(parsed);
    }
    Ok(results)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_status_rows_ok() {
        let rows = vec![(Some(r#"{"Status":"Success"}"#.to_string()),)];
        let res = parse_status_rows(rows).unwrap();
        assert_eq!(res.len(), 1);
        assert_eq!(res[0]["Status"], "Success");
    }

    #[test]
    fn test_parse_status_rows_empty_result() {
        let rows = vec![(None,)];

        assert!(matches!(parse_status_rows(rows), Err(DbError::EmptyResult)));
    }

    #[test]
    fn test_parse_status_rows_invalid_json() {
        let rows = vec![(Some("not json".to_string()),)];
        assert!(matches!(parse_status_rows(rows), Err(DbError::Json(_))));
    }
}
