//! MSSQL query executors using `tiberius` via a `bb8` connection pool.
//!
//! Connections are checked out from the pool per query and automatically
//! returned on drop, eliminating the per-request TCP handshake overhead.

use serde_json::Value;
use tiberius::Query;
use tracing::instrument;

use newsfeed_constants::db::OptionMode;
use newsfeed_models::{CudParams, ExtractParams, NewsFeedRow};

use crate::error::DbError;
use crate::pool::MssqlPool;

// ── Extract ───────────────────────────────────────────────────────────────────

/// Execute `dbo.extractNewsFeed` and return feed rows.
#[instrument(skip(pool), level = "debug")]
pub async fn extract_feed(
    pool: &MssqlPool,
    params: &ExtractParams,
) -> Result<Vec<NewsFeedRow>, DbError> {
    let mut client = pool.get().await?;

    let mut query = Query::new(
        "EXEC dbo.extractNewsFeed \
         @optionMode = @P1, @title = @P2, @imageurl = @P3, \
         @feedurl = @P4, @actualurl = @P5, @limit = @P6, @sort = @P7",
    );
    query.bind(OptionMode::ExtractFeed.as_str());
    query.bind(params.title.as_deref());
    query.bind(params.image_url.as_deref());
    query.bind(params.feed_url.as_deref());
    query.bind(params.actual_url.as_deref());
    query.bind(params.limit.as_deref());
    query.bind(params.sort.as_deref());

    let stream = query.query(&mut *client).await?;
    let rows = stream.into_first_result().await?;

    let mut results = Vec::with_capacity(rows.len());
    for row in rows {
        results.push(NewsFeedRow {
            titlereturn: row.get::<&str, _>("titlereturn").map(str::to_owned),
            imageurlreturn: row.get::<&str, _>("imageurlreturn").map(str::to_owned),
            feedurlreturn: row.get::<&str, _>("feedurlreturn").map(str::to_owned),
            actualurlreturn: row.get::<&str, _>("actualurlreturn").map(str::to_owned),
            publishdatereturn: row.get::<&str, _>("publishdatereturn").map(str::to_owned),
        });
    }
    tracing::debug!("MSSQL extract returned {} row(s)", results.len());
    Ok(results)
}

// ── Create / Update / Delete ──────────────────────────────────────────────────

/// Execute `dbo.insertupdatedeleteNewsFeed` and return the parsed status JSON.
///
/// Returns `DbError::EmptyResult` if the stored procedure returns a `NULL`
/// status column, surfacing it as a 5xx rather than a silent 200 with an
/// error body.
#[instrument(skip(pool), level = "debug")]
pub async fn cud_feed(
    pool: &MssqlPool,
    option_mode: OptionMode,
    params: &CudParams,
) -> Result<Vec<Value>, DbError> {
    let mut client = pool.get().await?;

    let mut query = Query::new(
        "EXEC dbo.insertupdatedeleteNewsFeed \
         @optionMode = @P1, @title = @P2, @imageurl = @P3, \
         @feedurl = @P4, @actualurl = @P5, @publishdate = @P6",
    );
    query.bind(option_mode.as_str());
    query.bind(params.title.as_deref());
    query.bind(params.image_url.as_deref());
    query.bind(params.feed_url.as_deref());
    query.bind(params.actual_url.as_deref());
    query.bind(params.publish_date.as_deref());

    let stream = query.query(&mut *client).await?;
    let rows = stream.into_first_result().await?;

    let mut results = Vec::with_capacity(rows.len());
    for row in rows {
        let json_str = row.get::<&str, _>("status").ok_or(DbError::EmptyResult)?;
        let parsed: Value = serde_json::from_str(json_str)?;
        results.push(parsed);
    }
    Ok(results)
}
