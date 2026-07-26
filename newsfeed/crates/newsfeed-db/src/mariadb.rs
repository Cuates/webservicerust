//! `MariaDB` query executors.
//!
//! Calls `extractnewsfeed` and `insertupdatedeletenewsfeed` stored procedures
//! using sqlx's `MySQL` driver (compatible with `MariaDB`).

use sqlx::MySqlPool;
use tracing::instrument;

use newsfeed_constants::db::OptionMode;
use newsfeed_models::{CudParams, ExtractParams, NewsFeedRow, SortOrder};

use crate::{error::DbError, shared::parse_status_rows};

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
        .bind(params.limit.map(|l| l.to_string()))
        .bind(params.sort.as_ref().map(SortOrder::as_str))
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
    pool: &sqlx::MySqlPool,
    option_mode: OptionMode,
    params: &[CudParams],
) -> Result<Vec<serde_json::Value>, DbError> {
    let mut results = Vec::with_capacity(params.len());
    let mut tx = pool.begin().await?;

    for param in params {
        let rows: Vec<(Option<String>,)> =
            sqlx::query_as("CALL insertupdatedeletenewsfeed(?, ?, ?, ?, ?, ?)")
                .bind(option_mode.as_str())
                .bind(param.title.as_deref())
                .bind(param.image_url.as_deref())
                .bind(param.feed_url.as_deref())
                .bind(param.actual_url.as_deref())
                .bind(param.publish_date.as_deref())
                .fetch_all(&mut *tx)
                .await?;

        let mut status_vals = parse_status_rows(rows)?;
        results.append(&mut status_vals);
    }
    tx.commit().await?;

    Ok(results)
}

#[cfg(test)]
mod tests {
    use super::*;
    #[tokio::test]
    async fn test_mariadb_extract_error() {
        let pool = sqlx::mysql::MySqlPoolOptions::new()
            .acquire_timeout(std::time::Duration::from_millis(1))
            .connect_lazy("mysql://fake:fake@255.255.255.255/fake")
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
    async fn test_mariadb_cud_error() {
        let pool = sqlx::mysql::MySqlPoolOptions::new()
            .acquire_timeout(std::time::Duration::from_millis(1))
            .connect_lazy("mysql://fake:fake@255.255.255.255/fake")
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
