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
    #[must_use]
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
#[derive(Debug, Clone, Default, ToSchema, IntoParams, Serialize, Deserialize)]
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
    #[must_use]
    pub fn from_map(map: &HashMap<String, String>) -> Self {
        let limit = map
            .get("limit")
            .and_then(|s| s.parse::<u32>().ok())
            .unwrap_or(25)
            .clamp(1, 100);

        Self {
            title: map.get("title").cloned(),
            image_url: map.get("image_url").cloned(),
            feed_url: map.get("feed_url").cloned(),
            actual_url: map.get("actual_url").cloned(),
            limit: Some(limit),
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

fn validate_string(s: &str, max_len: usize) -> Result<String, &'static str> {
    let trimmed = s.trim();
    if trimmed.is_empty() {
        return Err("field cannot be empty or whitespace-only");
    }
    if trimmed.len() > max_len {
        return Err("field exceeds maximum length");
    }
    Ok(trimmed.to_string())
}

pub fn deserialize_title<'de, D>(deserializer: D) -> Result<Option<String>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let opt = Option::<String>::deserialize(deserializer)?;
    match opt {
        Some(s) => validate_string(&s, 255)
            .map(Some)
            .map_err(serde::de::Error::custom),
        None => Ok(None),
    }
}

pub fn deserialize_url<'de, D>(deserializer: D) -> Result<Option<String>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let opt = Option::<String>::deserialize(deserializer)?;
    match opt {
        Some(s) => {
            let s = validate_string(&s, 2048).map_err(serde::de::Error::custom)?;
            if !s.starts_with("http://") && !s.starts_with("https://") {
                return Err(serde::de::Error::custom(
                    "URL must start with http:// or https://",
                ));
            }
            Ok(Some(s))
        }
        None => Ok(None),
    }
}

pub fn deserialize_date<'de, D>(deserializer: D) -> Result<Option<String>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let opt = Option::<String>::deserialize(deserializer)?;
    match opt {
        Some(s) => {
            let s = validate_string(&s, 50).map_err(serde::de::Error::custom)?;
            // Simple format check (e.g. basic ISO format sanity, no deep chrono parsing needed to prevent basic abuse)
            if !s.chars().any(|c| c.is_ascii_digit()) {
                return Err(serde::de::Error::custom("invalid date format"));
            }
            Ok(Some(s))
        }
        None => Ok(None),
    }
}

#[derive(Debug, Clone, Default, Deserialize, Serialize, ToSchema, PartialEq, Eq)]
#[serde(rename_all = "snake_case", deny_unknown_fields)]
pub struct CudParams {
    #[serde(default, deserialize_with = "deserialize_title")]
    pub title: Option<String>,
    #[serde(default, deserialize_with = "deserialize_url")]
    pub image_url: Option<String>,
    #[serde(default, deserialize_with = "deserialize_url")]
    pub feed_url: Option<String>,
    #[serde(default, deserialize_with = "deserialize_url")]
    pub actual_url: Option<String>,
    #[serde(default, deserialize_with = "deserialize_date")]
    pub publish_date: Option<String>,
}

/// Wrapper for CUD request payloads that can be deserialized from either a single JSON object
/// or a JSON array of objects, normalizing both into a `Vec<CudParams>`.
#[derive(Debug, Clone, Serialize, ToSchema, PartialEq, Eq, Default)]
pub struct CudPayload {
    pub idempotency_key: Option<String>,
    pub items: Vec<CudParams>,
}

impl<'de> serde::Deserialize<'de> for CudPayload {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        #[derive(serde::Deserialize)]
        #[serde(untagged)]
        enum Helper {
            Wrapper {
                idempotency_key: Option<String>,
                items: Vec<CudParams>,
            },
            Batch(Vec<CudParams>),
            Single(CudParams),
        }

        match Helper::deserialize(deserializer)? {
            Helper::Wrapper {
                idempotency_key,
                items,
            } => {
                if items.is_empty() {
                    return Err(serde::de::Error::custom("payload array cannot be empty"));
                }
                if items.len() > 1000 {
                    return Err(serde::de::Error::custom(
                        "payload array exceeds maximum size of 1000 items",
                    ));
                }
                Ok(CudPayload {
                    idempotency_key,
                    items,
                })
            }
            Helper::Single(item) => Ok(CudPayload {
                idempotency_key: None,
                items: vec![item],
            }),
            Helper::Batch(items) => {
                if items.is_empty() {
                    return Err(serde::de::Error::custom("payload array cannot be empty"));
                }
                if items.len() > 1000 {
                    return Err(serde::de::Error::custom(
                        "payload array exceeds maximum size of 1000 items",
                    ));
                }
                Ok(CudPayload {
                    idempotency_key: None,
                    items,
                })
            }
        }
    }
}

impl std::ops::Deref for CudPayload {
    type Target = Vec<CudParams>;
    fn deref(&self) -> &Self::Target {
        &self.items
    }
}

impl std::ops::DerefMut for CudPayload {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.items
    }
}

impl IntoIterator for CudPayload {
    type Item = CudParams;
    type IntoIter = std::vec::IntoIter<CudParams>;
    fn into_iter(self) -> Self::IntoIter {
        self.items.into_iter()
    }
}

impl<'a> IntoIterator for &'a CudPayload {
    type Item = &'a CudParams;
    type IntoIter = std::slice::Iter<'a, CudParams>;
    fn into_iter(self) -> Self::IntoIter {
        self.items.iter()
    }
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

        let mut map5 = HashMap::new();
        map5.insert("sort".to_string(), "unsupported".to_string());
        let params5 = ExtractParams::from_map(&map5);
        assert_eq!(params5.sort, None);

        let asc_str = SortOrder::Asc.as_str();
        assert_eq!(asc_str, "asc");
        let desc_str = SortOrder::Desc.as_str();
        assert_eq!(desc_str, "desc");
    }

    #[test]
    fn test_extract_params_limit_clamping() {
        let mut map = HashMap::new();
        let p1 = ExtractParams::from_map(&map);
        assert_eq!(p1.limit, Some(25));

        map.insert("limit".to_string(), "0".to_string());
        let p2 = ExtractParams::from_map(&map);
        assert_eq!(p2.limit, Some(1));

        map.insert("limit".to_string(), "500".to_string());
        let p3 = ExtractParams::from_map(&map);
        assert_eq!(p3.limit, Some(100));

        map.insert("limit".to_string(), "not_a_number".to_string());
        let p4 = ExtractParams::from_map(&map);
        assert_eq!(p4.limit, Some(25));
    }

    #[test]
    fn test_cud_params_deserialize() {
        let json_data = json!({
            "title": "  New Title  ",
            "publish_date": "2026-07-13"
        });

        let params: CudParams = serde_json::from_value(json_data).unwrap();
        assert_eq!(params.title.as_deref(), Some("New Title"));
        assert_eq!(params.publish_date.as_deref(), Some("2026-07-13"));
        assert_eq!(params.image_url, None);
    }

    #[test]
    fn test_cud_params_reject_whitespace_only() {
        let json_data = json!({
            "title": "   ",
            "publish_date": "2026-07-13"
        });
        let err = serde_json::from_value::<CudParams>(json_data).unwrap_err();
        assert!(
            err.to_string()
                .contains("field cannot be empty or whitespace-only")
        );
    }

    #[test]
    fn test_cud_params_deny_unknown_fields() {
        let json_data = json!({
            "title": "New Title",
            "unknown_field": "bad"
        });
        assert!(serde_json::from_value::<CudParams>(json_data).is_err());
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

    #[test]
    fn test_cud_params_deny_unknown_fields_deserialization_failure() {
        let json_str = r#"{"id": 1, "title": "Test", "illegal_attr": 123}"#;
        let err = serde_json::from_str::<CudParams>(json_str)
            .expect_err("deserialization must fail when unknown fields are present");
        assert!(err.to_string().contains("unknown field"));
    }

    #[test]
    fn test_cud_payload_deserialize_single() {
        let json_str = r#"{"title": "Single Title"}"#;
        let payload: CudPayload = serde_json::from_str(json_str).unwrap();
        assert_eq!(payload.len(), 1);
        assert_eq!(payload[0].title.as_deref(), Some("Single Title"));
    }

    #[test]
    fn test_cud_payload_deserialize_batch() {
        let json_str = r#"[{"title": "Title 1"}, {"title": "Title 2"}]"#;
        let payload: CudPayload = serde_json::from_str(json_str).unwrap();
        assert_eq!(payload.len(), 2);
        assert_eq!(payload[0].title.as_deref(), Some("Title 1"));
        assert_eq!(payload[1].title.as_deref(), Some("Title 2"));
    }

    #[test]
    fn test_cud_payload_coverage() {
        let json_str = r#"{"title": null, "feed_url": null}"#;
        let mut payload: CudPayload = serde_json::from_str(json_str).unwrap();
        assert!(payload[0].title.is_none());
        assert!(payload[0].feed_url.is_none());

        std::ops::DerefMut::deref_mut(&mut payload)[0].title = Some("Mutated".to_string());
        assert_eq!(payload[0].title.as_deref(), Some("Mutated"));

        let items: Vec<CudParams> = <CudPayload as IntoIterator>::into_iter(payload).collect();
        assert_eq!(items.len(), 1);
        assert_eq!(items[0].title.as_deref(), Some("Mutated"));
    }

    #[test]
    fn test_cud_payload_idempotency_key() {
        let json_str =
            r#"{"items": [{"title": "Idempotent Title"}], "idempotency_key": "key-12345"}"#;
        let payload: CudPayload = serde_json::from_str(json_str).unwrap();
        assert_eq!(payload.len(), 1);
        assert_eq!(payload.idempotency_key.as_deref(), Some("key-12345"));
        assert_eq!(payload[0].title.as_deref(), Some("Idempotent Title"));
    }

    #[test]
    fn test_feed_validation_edges() {
        // String too long for title
        let long_title = "a".repeat(256);
        let json_str = format!(r#"{{"title": "{}"}}"#, long_title);
        let err = serde_json::from_str::<CudParams>(&json_str).expect_err("should fail");
        assert!(err.to_string().contains("field exceeds maximum length"));

        // Invalid date format
        let json_str = r#"{"publish_date": "abcd"}"#;
        let err = serde_json::from_str::<CudParams>(json_str).expect_err("should fail");
        assert!(err.to_string().contains("invalid date format"));

        // Null publish date
        let json_str = r#"{"publish_date": null}"#;
        let params: CudParams = serde_json::from_str(json_str).unwrap();
        assert!(params.publish_date.is_none());

        // Wrapper empty
        let json_str = r#"{"items": []}"#;
        let err = serde_json::from_str::<CudPayload>(json_str).expect_err("should fail");
        assert!(err.to_string().contains("payload array cannot be empty"));

        // Wrapper > 1000
        let items = vec![r#"{"title": "t"}"#; 1001].join(",");
        let json_str = format!(r#"{{"items": [{}]}}"#, items);
        let err = serde_json::from_str::<CudPayload>(&json_str).expect_err("should fail");
        assert!(err.to_string().contains("exceeds maximum size"));

        // Batch empty
        let json_str = r#"[]"#;
        let err = serde_json::from_str::<CudPayload>(json_str).expect_err("should fail");
        assert!(err.to_string().contains("payload array cannot be empty"));

        // Batch > 1000
        let json_str = format!(r#"[{}]"#, items);
        let err = serde_json::from_str::<CudPayload>(&json_str).expect_err("should fail");
        assert!(err.to_string().contains("exceeds maximum size"));
    }
}
