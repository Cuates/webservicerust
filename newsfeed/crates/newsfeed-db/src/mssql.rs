//! MSSQL query executors using `tiberius` (no ODBC required).
//!
//! Each public function creates a fresh TCP connection for the operation.
//! This avoids the `bb8`/`deadpool` pool dependency while keeping things
//! correct.  A connection pool can be added in a future optimisation pass.

use std::sync::Arc;

use serde_json::Value;
use tiberius::{AuthMethod, Client, Config, Query};
use tokio::net::TcpStream;
use tokio_util::compat::{TokioAsyncWriteCompatExt};
use tracing::instrument;

use newsfeed_constants::db::OptionMode;
use newsfeed_models::{CudParams, ExtractParams, NewsFeedRow};

use crate::error::DbError;

// ── MSSQL connection configuration ───────────────────────────────────────────

/// Stores the connection parameters needed to create a tiberius `Client`.
#[derive(Debug, Clone)]
pub struct MssqlConfig {
    pub host:     String,
    pub port:     u16,
    pub database: String,
    pub username: String,
    pub password: String,
}

impl MssqlConfig {
    /// Create a new tiberius `Config` from this struct.
    fn to_tiberius_config(&self) -> Config {
        let mut cfg = Config::new();
        cfg.host(&self.host);
        cfg.port(self.port);
        cfg.database(&self.database);
        cfg.authentication(AuthMethod::sql_server(&self.username, &self.password));
        cfg.trust_cert(); // TrustServerCertificate=yes (matches Python reference)
        cfg.encryption(tiberius::EncryptionLevel::NotSupported); // Encrypt=no
        cfg
    }

    /// Open a new TCP connection and return an authenticated `Client`.
    pub async fn connect(&self) -> Result<Client<tokio_util::compat::Compat<TcpStream>>, DbError> {
        let cfg = self.to_tiberius_config();
        let tcp = TcpStream::connect(format!("{}:{}", self.host, self.port)).await?;
        tcp.set_nodelay(true)?;
        let client = Client::connect(cfg, tcp.compat_write()).await?;
        Ok(client)
    }
}

// ── Extract ───────────────────────────────────────────────────────────────────

/// Execute `dbo.extractNewsFeed` and return feed rows.
#[instrument(skip(cfg), level = "debug")]
pub async fn extract_feed(
    cfg: &Arc<MssqlConfig>,
    params: &ExtractParams,
) -> Result<Vec<NewsFeedRow>, DbError> {
    let mut client = cfg.connect().await?;

    let mut query = Query::new(
        "EXEC dbo.extractNewsFeed \
         @optionMode = @P1, @title = @P2, @imageurl = @P3, \
         @feedurl = @P4, @actualurl = @P5, @limit = @P6, @sort = @P7"
    );
    query.bind(OptionMode::EXTRACT_FEED);
    query.bind(params.title.as_deref());
    query.bind(params.imageurl.as_deref());
    query.bind(params.feedurl.as_deref());
    query.bind(params.actualurl.as_deref());
    query.bind(params.limit.as_deref());
    query.bind(params.sort.as_deref());

    let stream = query.query(&mut client).await?;
    let rows = stream.into_first_result().await?;

    let mut results = Vec::with_capacity(rows.len());
    for row in rows {
        results.push(NewsFeedRow {
            titlereturn:       row.get::<&str, _>("titlereturn").map(str::to_owned),
            imageurlreturn:    row.get::<&str, _>("imageurlreturn").map(str::to_owned),
            feedurlreturn:     row.get::<&str, _>("feedurlreturn").map(str::to_owned),
            actualurlreturn:   row.get::<&str, _>("actualurlreturn").map(str::to_owned),
            publishdatereturn: row.get::<&str, _>("publishdatereturn").map(str::to_owned),
        });
    }
    tracing::debug!("MSSQL extract returned {} row(s)", results.len());
    Ok(results)
}

// ── Create / Update / Delete ──────────────────────────────────────────────────

/// Execute `dbo.insertupdatedeleteNewsFeed` and return the parsed status JSON.
#[instrument(skip(cfg), level = "debug")]
pub async fn cud_feed(
    cfg: &Arc<MssqlConfig>,
    option_mode: &str,
    params: &CudParams,
) -> Result<Vec<Value>, DbError> {
    let mut client = cfg.connect().await?;

    let mut query = Query::new(
        "EXEC dbo.insertupdatedeleteNewsFeed \
         @optionMode = @P1, @title = @P2, @imageurl = @P3, \
         @feedurl = @P4, @actualurl = @P5, @publishdate = @P6"
    );
    query.bind(option_mode);
    query.bind(params.title.as_deref());
    query.bind(params.imageurl.as_deref());
    query.bind(params.feedurl.as_deref());
    query.bind(params.actualurl.as_deref());
    query.bind(params.publishdate.as_deref());

    let stream = query.query(&mut client).await?;
    let rows = stream.into_first_result().await?;

    let mut results = Vec::with_capacity(rows.len());
    for row in rows {
        let json_str: &str = row
            .get::<&str, _>("status")
            .unwrap_or(r#"{"Status":"Error","Message":"Missing status from procedure"}"#);
        let parsed: Value = serde_json::from_str(json_str)?;
        results.push(parsed);
    }
    Ok(results)
}
