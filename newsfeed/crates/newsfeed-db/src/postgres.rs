//! `PostgreSQL` query executors.
//!
//! Calls the `extractnewsfeed` `PostgreSQL` **function** and the
//! `insertupdatedeletenewsfeed` `PostgreSQL` **procedure**.

use sqlx::PgPool;
use tracing::instrument;

use newsfeed_constants::db::OptionMode;
use newsfeed_models::{CudParams, ExtractParams, NewsFeedRow, SortOrder};

use crate::{error::DbError, shared::parse_status_rows};

// ── Extract ───────────────────────────────────────────────────────────────────

/// Call `extractnewsfeed(...)` and return a list of feed rows.
///
/// `PostgreSQL` exposes this as a **function** (`RETURNS TABLE`), so it is
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
    .bind(params.limit.map(|l| l.to_string()))
    .bind(params.sort.as_ref().map(SortOrder::as_str))
    .fetch_all(pool)
    .await?;

    tracing::debug!("PostgreSQL extract returned {} row(s)", rows.len());
    Ok(rows)
}

// ── Create / Update / Delete ──────────────────────────────────────────────────

/// Call `cud_bulk_json_newsfeed(...)` and return the parsed status JSON.
#[instrument(skip(pool), level = "debug")]
pub async fn cud_feed(
    pool: &sqlx::PgPool,
    option_mode: OptionMode,
    params: &[CudParams],
) -> Result<Vec<crate::shared::CudResult>, DbError> {
    let payload = serde_json::to_string(params).map_err(DbError::Json)?;

    let rows: Vec<(Option<String>,)> = sqlx::query_as("CALL cud_bulk_json_newsfeed($1, $2::json)")
        .bind(option_mode.as_str())
        .bind(payload)
        .fetch_all(pool)
        .await?;

    parse_status_rows(rows)
}

/// Query the max `modified_date` across all items
#[instrument(skip(pool), level = "debug")]
pub async fn max_modified_date(
    pool: &sqlx::PgPool,
) -> Result<Option<String>, crate::error::DbError> {
    let row: (Option<String>,) =
        sqlx::query_as("SELECT CAST(MAX(modified_date) AS VARCHAR) FROM newsfeed")
            .fetch_one(pool)
            .await?;
    Ok(row.0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_postgres_extract_error() {
        let pool = sqlx::postgres::PgPoolOptions::new()
            .acquire_timeout(std::time::Duration::from_millis(1))
            .connect_lazy("postgres://fake:fake@255.255.255.255/fake")
            .unwrap();

        let params = ExtractParams {
            title: None,
            image_url: None,
            feed_url: None,
            actual_url: None,
            limit: Some(10),
            sort: Some(newsfeed_models::feed::SortOrder::Asc),
        };

        let res = extract_feed(&pool, &params).await;
        assert!(res.is_err());
    }

    #[tokio::test]
    async fn test_postgres_cud_error() {
        let pool = sqlx::postgres::PgPoolOptions::new()
            .acquire_timeout(std::time::Duration::from_millis(1))
            .connect_lazy("postgres://fake:fake@255.255.255.255/fake")
            .unwrap();

        let params = CudParams {
            title: None,
            image_url: None,
            feed_url: None,
            actual_url: None,
            publish_date: None,
        };

        let res = cud_feed(&pool, OptionMode::InsertFeed, &[params]).await;
        assert!(res.is_err());
    }
}
