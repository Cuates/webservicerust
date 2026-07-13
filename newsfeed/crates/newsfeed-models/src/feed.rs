//! Feed data models: operation parameter structs and DB row types.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use utoipa::{IntoParams, ToSchema};

// ── Extract (read) operation parameters ──────────────────────────────────────

/// Parameters passed to the extract stored procedure / function.
/// All filter fields are optional; the procedure handles NULL internally.
#[derive(Debug, Clone, Default, ToSchema, IntoParams)]
pub struct ExtractParams {
    pub title: Option<String>,
    pub image_url: Option<String>,
    pub feed_url: Option<String>,
    pub actual_url: Option<String>,
    pub limit: Option<String>,
    pub sort: Option<String>,
}

impl ExtractParams {
    /// Build an `ExtractParams` from a normalised (lowercase-keyed) query-param map.
    pub fn from_map(map: &HashMap<String, String>) -> Self {
        Self {
            title: map.get("title").cloned(),
            image_url: map.get("image_url").cloned(),
            feed_url: map.get("feed_url").cloned(),
            actual_url: map.get("actual_url").cloned(),
            limit: map.get("limit").cloned(),
            sort: map.get("sort").cloned(),
        }
    }
}

// ── Create / Update / Delete operation parameters ─────────────────────────────

/// Parameters passed to the insert/update/delete stored procedure.
#[derive(Debug, Clone, Default, Deserialize, ToSchema)]
#[serde(rename_all = "snake_case")]
pub struct CudParams {
    pub title: Option<String>,
    pub image_url: Option<String>,
    pub feed_url: Option<String>,
    pub actual_url: Option<String>,
    pub publish_date: Option<String>,
}

// ── Database row types ────────────────────────────────────────────────────────

/// A single row returned by the extract stored procedure / function.
/// Represents a single returned row from the database (JSON keys mapped back).
#[derive(Debug, Clone, Serialize, ToSchema, sqlx::FromRow)]
#[serde(rename_all = "snake_case")]
pub struct NewsFeedRow {
    #[serde(rename = "title")]
    pub titlereturn: Option<String>,
    #[serde(rename = "image_url")]
    pub imageurlreturn: Option<String>,
    #[serde(rename = "feed_url")]
    pub feedurlreturn: Option<String>,
    #[serde(rename = "actual_url")]
    pub actualurlreturn: Option<String>,
    #[serde(rename = "publish_date")]
    pub publishdatereturn: Option<String>,
}
