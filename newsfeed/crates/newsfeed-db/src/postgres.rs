//! PostgreSQL query executors.
//!
//! Calls the `extractnewsfeed` PostgreSQL **function** and the
//! `insertupdatedeletenewsfeed` PostgreSQL **procedure**.

use serde_json::Value;
use sqlx::PgPool;
use tracing::instrument;

use newsfeed_constants::db::OptionMode;
use newsfeed_models::{CudParams, ExtractParams, NewsFeedRow};

use crate::error::DbError;

// ── Extract ───────────────────────────────────────────────────────────────────

/// Call `extractnewsfeed(...)` and return a list of feed rows.
///
/// PostgreSQL exposes this as a **function** (`RETURNS TABLE`), so it is
/// called with `SELECT * FROM extractnewsfeed(...)`.
#[instrument(skip(pool), level = "debug")]
pub async fn extract_feed(
    pool: &PgPool,
    params: &ExtractParams,
) -> Result<Vec<NewsFeedRow>, DbError> {
    let rows = sqlx::query_as::<_, NewsFeedRow>(
        "SELECT titlereturn, imageurlreturn, feedurlreturn, actualurlreturn, publishdatereturn \
         FROM extractnewsfeed($1::text, $2::text, $3::text, $4::text, $5::text, $6::text, $7::text)",
    )
    .bind(OptionMode::ExtractFeed.as_str())
    .bind(params.title.as_deref())
    .bind(params.image_url.as_deref())
    .bind(params.feed_url.as_deref())
    .bind(params.actual_url.as_deref())
    .bind(params.limit.as_deref())
    .bind(params.sort.as_deref())
    .fetch_all(pool)
    .await?;

    tracing::debug!("PostgreSQL extract returned {} row(s)", rows.len());
    Ok(rows)
}

// ── Create / Update / Delete ──────────────────────────────────────────────────

/// Call `insertupdatedeletenewsfeed(...)` and return the parsed status JSON.
#[instrument(skip(pool), level = "debug")]
pub async fn cud_feed(
    pool: &PgPool,
    option_mode: OptionMode,
    params: &CudParams,
) -> Result<Vec<Value>, DbError> {
    // PostgreSQL CALL returns a result set with a single `status` JSON column.
    let rows: Vec<(Option<String>,)> =
        sqlx::query_as("CALL insertupdatedeletenewsfeed($1::text, $2::text, $3::text, $4::text, $5::text, $6::text, $7)")
            .bind(option_mode.as_str())
            .bind(params.title.as_deref())
            .bind(params.image_url.as_deref())
            .bind(params.feed_url.as_deref())
            .bind(params.actual_url.as_deref())
            .bind(params.publish_date.as_deref())
            .bind(None::<String>)
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

        if parsed.get("Status").and_then(Value::as_str) == Some("Error") {
            return Err(DbError::ProcedureFailed(json_str));
        }

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
    #[test]
    fn test_parse_status_rows_procedure_failed() {
        let json_str = r#"{"Status":"Error","Message":"Invalid optionMode"}"#;
        let rows = vec![(Some(json_str.to_string()),)];
        assert!(matches!(
            parse_status_rows(rows),
            Err(DbError::ProcedureFailed(_))
        ));
    }
}
