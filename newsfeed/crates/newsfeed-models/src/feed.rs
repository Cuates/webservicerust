//! Feed data models: operation parameter structs and DB row types.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use utoipa::{IntoParams, ToSchema};

/// Order in which to sort the results.
#[derive(Debug, Clone, Deserialize, Serialize, ToSchema, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum SortOrder {
    Asc,
    Desc,
}

impl SortOrder {
    pub fn as_str(&self) -> &'static str {
        match self {
            SortOrder::Asc => "asc",
            SortOrder::Desc => "desc",
        }
    }
}

// ── Extract (read) operation parameters ──────────────────────────────────────

/// Parameters passed to the extract stored procedure / function.
/// All filter fields are optional; the procedure handles NULL internally.
#[derive(Debug, Clone, Default, ToSchema, IntoParams)]
pub struct ExtractParams {
    pub title: Option<String>,
    pub image_url: Option<String>,
    pub feed_url: Option<String>,
    pub actual_url: Option<String>,
    pub limit: Option<u32>,
    pub sort: Option<SortOrder>,
}

impl ExtractParams {
    /// Build an `ExtractParams` from a normalised (lowercase-keyed) query-param map.
    pub fn from_map(map: &HashMap<String, String>) -> Self {
        Self {
            title: map.get("title").cloned(),
            image_url: map.get("image_url").cloned(),
            feed_url: map.get("feed_url").cloned(),
            actual_url: map.get("actual_url").cloned(),
            limit: map.get("limit").and_then(|s| s.parse::<u32>().ok()),
            sort: map
                .get("sort")
                .and_then(|s| match s.to_lowercase().as_str() {
                    "asc" => Some(SortOrder::Asc),
                    "desc" => Some(SortOrder::Desc),
                    _ => None,
                }),
        }
    }
}

// ── Create / Update / Delete operation parameters ─────────────────────────────

/// Parameters passed to the insert/update/delete stored procedure.
#[derive(Debug, Clone, Default, Deserialize, Serialize, ToSchema)]
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
        assert_eq!(params.limit, Some(10));
        assert_eq!(params.image_url, None);
        assert_eq!(params.sort, None);

        let mut map2 = HashMap::new();
        map2.insert("sort".to_string(), "asc".to_string());
        map2.insert("feed_url".to_string(), "http://foo".to_string());
        let params2 = ExtractParams::from_map(&map2);
        assert_eq!(params2.sort, Some(SortOrder::Asc));
        assert_eq!(params2.feed_url.as_deref(), Some("http://foo"));

        let mut map3 = HashMap::new();
        map3.insert("sort".to_string(), "desc".to_string());
        map3.insert("actual_url".to_string(), "http://bar".to_string());
        let params3 = ExtractParams::from_map(&map3);
        assert_eq!(params3.sort, Some(SortOrder::Desc));
        assert_eq!(params3.actual_url.as_deref(), Some("http://bar"));

        let mut map4 = HashMap::new();
        map4.insert("sort".to_string(), "invalid".to_string());
        let params4 = ExtractParams::from_map(&map4);
        assert_eq!(params4.sort, None);

        let asc_str = SortOrder::Asc.as_str();
        assert_eq!(asc_str, "asc");
        let desc_str = SortOrder::Desc.as_str();
        assert_eq!(desc_str, "desc");
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
