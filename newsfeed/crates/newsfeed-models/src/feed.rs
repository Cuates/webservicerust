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

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_extract_params_from_map() {
        let mut map = HashMap::new();
        map.insert("title".to_string(), "Test Title".to_string());
        map.insert("limit".to_string(), "10".to_string());

        let params = ExtractParams::from_map(&map);
        assert_eq!(params.title.as_deref(), Some("Test Title"));
        assert_eq!(params.limit.as_deref(), Some("10"));
        assert_eq!(params.image_url, None);
    }

    #[test]
    fn test_cud_params_deserialize() {
        let json_data = json!({
            "title": "New Title",
            "publish_date": "2026-07-13"
        });

        let params: CudParams = serde_json::from_value(json_data).unwrap();
        assert_eq!(params.title.as_deref(), Some("New Title"));
        assert_eq!(params.publish_date.as_deref(), Some("2026-07-13"));
        assert_eq!(params.image_url, None);
    }

    #[test]
    fn test_newsfeed_row_serialize() {
        let row = NewsFeedRow {
            titlereturn: Some("Test Row".to_string()),
            imageurlreturn: Some("http://image.url".to_string()),
            feedurlreturn: None,
            actualurlreturn: None,
            publishdatereturn: None,
        };

        let serialized = serde_json::to_value(&row).unwrap();
        assert_eq!(serialized["title"], "Test Row");
        assert_eq!(serialized["image_url"], "http://image.url");
        assert!(serialized.get("feed_url").unwrap().is_null());
    }
}
