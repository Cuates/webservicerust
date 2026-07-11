//! Feed data models: operation parameter structs and DB row types.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// ── Extract (read) operation parameters ──────────────────────────────────────

/// Parameters passed to the extract stored procedure / function.
/// All filter fields are optional; the procedure handles NULL internally.
#[derive(Debug, Clone, Default)]
pub struct ExtractParams {
    pub title:      Option<String>,
    pub imageurl:   Option<String>,
    pub feedurl:    Option<String>,
    pub actualurl:  Option<String>,
    pub limit:      Option<String>,
    pub sort:       Option<String>,
}

impl ExtractParams {
    /// Build an `ExtractParams` from a normalised (lowercase-keyed) query-param map.
    pub fn from_map(map: &HashMap<String, String>) -> Self {
        Self {
            title:     map.get("title").cloned(),
            imageurl:  map.get("imageurl").cloned(),
            feedurl:   map.get("feedurl").cloned(),
            actualurl: map.get("actualurl").cloned(),
            limit:     map.get("limit").cloned(),
            sort:      map.get("sort").cloned(),
        }
    }
}

// ── Create / Update / Delete operation parameters ─────────────────────────────

/// Parameters passed to the insert/update/delete stored procedure.
#[derive(Debug, Clone, Default, Deserialize)]
#[serde(rename_all = "lowercase")]
pub struct CudParams {
    pub title:       Option<String>,
    #[serde(rename = "imageurl")]
    pub imageurl:    Option<String>,
    #[serde(rename = "feedurl")]
    pub feedurl:     Option<String>,
    #[serde(rename = "actualurl")]
    pub actualurl:   Option<String>,
    #[serde(rename = "publishdate")]
    pub publishdate: Option<String>,
}

// ── Database row types ────────────────────────────────────────────────────────

/// A single row returned by the extract stored procedure / function.
/// Column names match the PostgreSQL function's `RETURNS TABLE` definition.
#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct NewsFeedRow {
    #[serde(rename = "Title")]
    pub titlereturn:       Option<String>,
    #[serde(rename = "Image URL")]
    pub imageurlreturn:    Option<String>,
    #[serde(rename = "Feed URL")]
    pub feedurlreturn:     Option<String>,
    #[serde(rename = "Actual URL")]
    pub actualurlreturn:   Option<String>,
    #[serde(rename = "Publish Date")]
    pub publishdatereturn: Option<String>,
}

/// A single row returned by the CUD stored procedure.
/// The `status` column contains a JSON string produced by the procedure.
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct CudRow {
    pub status: Option<String>,
}
