//! `MSSQL` query executors using `tiberius` via a `bb8` connection pool.
//!
//! Connections are checked out from the pool per query and automatically
//! returned on drop, eliminating the per-request `TCP` handshake overhead.

use tiberius::Query;
use tracing::instrument;

use newsfeed_constants::db::OptionMode;
use newsfeed_models::{CudParams, ExtractParams, NewsFeedRow, SortOrder};

use crate::pool::MssqlPool;
use crate::{
    error::DbError,
    shared::{parse_status_rows, row_to_news_feed_row},
};

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
    let limit_str = params.limit.map(|l| l.to_string());
    query.bind(limit_str);
    query.bind(params.sort.as_ref().map(SortOrder::as_str));

    let stream = query.query(&mut *client).await?;
    let rows = stream.into_first_result().await?;

    let mut results = Vec::with_capacity(rows.len());
    for row in rows {
        results.push(row_to_news_feed_row(
            row.try_get::<&str, _>("title")?.map(str::to_owned),
            row.try_get::<&str, _>("imageurl")?.map(str::to_owned),
            row.try_get::<&str, _>("feedurl")?.map(str::to_owned),
            row.try_get::<&str, _>("actualurl")?.map(str::to_owned),
            row.try_get::<&str, _>("publishdate")?.map(str::to_owned),
        ));
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
    params: &[CudParams],
) -> Result<Vec<crate::shared::CudResult>, DbError> {
    let mut conn = pool
        .get()
        .await
        .map_err(|e| DbError::MssqlPool(format!("{e:?}")))?;
    let payload = serde_json::to_string(params).map_err(DbError::Json)?;

    let mut query = tiberius::Query::new("EXEC cud_bulk_json_newsfeed @P1, @P2");
    query.bind(option_mode.as_str());
    query.bind(payload);

    let stream = query.query(&mut conn).await?;
    let tiberius_rows = stream.into_first_result().await?;

    let mut rows: Vec<(Option<String>,)> = Vec::with_capacity(tiberius_rows.len());
    for row in tiberius_rows {
        let status: Option<&str> = row.try_get(0)?;
        rows.push((status.map(std::string::ToString::to_string),));
    }

    parse_status_rows(rows)
}

/// Query the max `modified_date` across all items
#[instrument(skip(pool), level = "debug")]
pub async fn max_modified_date(
    pool: &bb8::Pool<bb8_tiberius::ConnectionManager>,
) -> Result<Option<String>, crate::error::DbError> {
    let mut conn = pool.get().await?;

    let stream = conn
        .query(
            "SELECT CAST(MAX(modified_date) AS VARCHAR(50)) FROM dbo.NewsFeed",
            &[],
        )
        .await?;
    let row = stream.into_row().await?;
    if let Some(r) = row {
        Ok(r.get::<&str, _>(0).map(ToString::to_string))
    } else {
        Ok(None)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_mssql_extract_error() {
        let mut cfg = tiberius::Config::new();
        cfg.host("127.0.0.2"); // non-routable
        cfg.port(1);
        cfg.authentication(tiberius::AuthMethod::sql_server("fake", "fake"));
        cfg.encryption(tiberius::EncryptionLevel::NotSupported);

        let mgr = bb8_tiberius::ConnectionManager::new(cfg);
        let pool = bb8::Pool::builder().build_unchecked(mgr);

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
    async fn test_mssql_cud_error() {
        let mut cfg = tiberius::Config::new();
        cfg.host("127.0.0.2"); // non-routable
        cfg.port(1);
        cfg.authentication(tiberius::AuthMethod::sql_server("fake", "fake"));
        cfg.encryption(tiberius::EncryptionLevel::NotSupported);

        let mgr = bb8_tiberius::ConnectionManager::new(cfg);
        let pool = bb8::Pool::builder().build_unchecked(mgr);

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
