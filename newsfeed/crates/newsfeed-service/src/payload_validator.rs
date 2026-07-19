//! Header and payload validation — port of `check_headers()` and `check_payload()`
//! from `newsfeedwebserviceclass.py`.

use std::collections::HashMap;

use newsfeed_constants::http::{HeaderType, PossibleHeaderType};
use newsfeed_models::CudParams;

use crate::error::ServiceError;

// ── Public API ────────────────────────────────────────────────────────────────

/// Validate request headers against expected values.
///
/// `requires_body` — when `true` (POST / PUT / DELETE), enforces the presence
/// of `Content-Type: application/json; charset=utf-8`.  When `false` (GET /
/// QUERY), only the `Accept` header is checked, since bodyless requests do not
/// carry a `Content-Type` by RFC convention.
pub fn validate_headers(
    headers: &HashMap<String, String>,
    requires_body: bool,
) -> Result<(), ServiceError> {
    let accept = headers
        .get(HeaderType::ACCEPT)
        .map(|s| s.to_lowercase())
        .unwrap_or_default();

    if accept != PossibleHeaderType::ACCEPT {
        return Err(ServiceError::InvalidHeader("HTTP accept invalid".into()));
    }

    if requires_body {
        let raw_ct = headers
            .get(HeaderType::CONTENT_TYPE)
            .map(|s| s.to_lowercase())
            .unwrap_or_default();

        // Split "application/json; charset=utf-8" into content-type and charset parts.
        let mut parts = raw_ct.splitn(2, ';');
        let content_type = parts.next().unwrap_or("").trim().to_owned();
        let charset = parts
            .next()
            .and_then(|p| p.split('=').nth(1))
            .map(|s| s.trim().to_owned())
            .unwrap_or_default();

        if content_type != PossibleHeaderType::CONTENT_TYPE {
            return Err(ServiceError::InvalidHeader("Content type invalid".into()));
        }
        if charset != PossibleHeaderType::CHARSET {
            return Err(ServiceError::InvalidHeader(
                "Content-Type charset invalid".into(),
            ));
        }
    }

    Ok(())
}

// ── Payload validation ────────────────────────────────────────────────────────

/// Validate GET / QUERY query parameters (no mandatory params for reads).
pub fn validate_get_params(raw: &HashMap<String, String>) -> HashMap<String, String> {
    // Keys are expected to match ExtractParams field names exactly (snake_case).
    raw.clone()
}

/// Validate POST / PUT / DELETE JSON body.
///
/// `mandatory` is the list of field names that must be present and non-empty.
pub fn validate_payload(
    body: &serde_json::Value,
    mandatory: &[&str],
) -> Result<Vec<CudParams>, ServiceError> {
    let items = match body {
        serde_json::Value::Array(arr) => arr.clone(),
        obj @ serde_json::Value::Object(_) => vec![obj.clone()],
        _ => {
            return Err(ServiceError::InvalidPayload(
                "Payload must be a JSON object or array".into(),
            ))
        }
    };

    if items.is_empty() {
        return Err(ServiceError::InvalidPayload(
            "Payload elements missing".into(),
        ));
    }

    let mut validated: Vec<CudParams> = Vec::with_capacity(items.len());

    for item in &items {
        // Check all mandatory fields are present and non-null.
        for &key in mandatory {
            match item.get(key) {
                None | Some(serde_json::Value::Null) => {
                    return Err(ServiceError::MissingMandatoryParam(key.to_owned()));
                }
                Some(serde_json::Value::String(s)) if s.trim().is_empty() => {
                    return Err(ServiceError::MissingMandatoryParam(format!(
                        "{key} must not be blank"
                    )));
                }
                _ => {}
            }
        }

        let params: CudParams = serde_json::from_value(item.clone()).map_err(|e| {
            ServiceError::InvalidPayload(format!("Failed to parse payload item: {e}"))
        })?;
        validated.push(params);
    }

    Ok(validated)
}

#[cfg(test)]
mod tests {
    use super::*;
    use newsfeed_constants::http::{HeaderType, PossibleHeaderType};
    use serde_json::json;

    #[test]
    fn test_validate_headers_requires_body_success() {
        let mut headers = HashMap::new();
        headers.insert(
            HeaderType::ACCEPT.to_string(),
            PossibleHeaderType::ACCEPT.to_string(),
        );
        headers.insert(
            HeaderType::CONTENT_TYPE.to_string(),
            "application/json; charset=utf-8".to_string(),
        );
        assert!(validate_headers(&headers, true).is_ok());
    }

    #[test]
    fn test_validate_headers_requires_body_missing_content_type() {
        let mut headers = HashMap::new();
        headers.insert(
            HeaderType::ACCEPT.to_string(),
            PossibleHeaderType::ACCEPT.to_string(),
        );

        let result = validate_headers(&headers, true);
        assert!(matches!(result, Err(ServiceError::InvalidHeader(_))));
    }

    #[test]
    fn test_validate_headers_no_body_success() {
        let mut headers = HashMap::new();
        headers.insert(
            HeaderType::ACCEPT.to_string(),
            PossibleHeaderType::ACCEPT.to_string(),
        );

        // Even if Content-Type is missing, it should succeed when requires_body is false
        assert!(validate_headers(&headers, false).is_ok());
    }

    #[test]
    fn test_validate_headers_invalid_accept() {
        let mut headers = HashMap::new();
        headers.insert(HeaderType::ACCEPT.to_string(), "text/html".to_string());

        let result = validate_headers(&headers, false);
        assert!(matches!(result, Err(ServiceError::InvalidHeader(_))));
    }

    #[test]
    fn test_validate_payload_valid_object() {
        let payload = json!({
            "id": 1,
            "feed_id": "test_feed",
            "name": "Test"
        });

        let result = validate_payload(&payload, &["feed_id"]);
        assert!(result.is_ok());
        let items = result.unwrap();
        assert_eq!(items.len(), 1);
    }

    #[test]
    fn test_validate_payload_valid_array() {
        let payload = json!([
            { "id": 1, "feed_id": "test_feed_1" },
            { "id": 2, "feed_id": "test_feed_2" }
        ]);

        let result = validate_payload(&payload, &["feed_id"]);
        assert!(result.is_ok());
        let items = result.unwrap();
        assert_eq!(items.len(), 2);
    }

    #[test]
    fn test_validate_payload_missing_mandatory() {
        let payload = json!({
            "id": 1
        });

        let result = validate_payload(&payload, &["feed_id"]);
        assert!(matches!(
            result,
            Err(ServiceError::MissingMandatoryParam(_))
        ));
    }

    #[test]
    fn test_validate_payload_blank_mandatory() {
        let payload = json!({
            "feed_id": "   "
        });

        let result = validate_payload(&payload, &["feed_id"]);
        assert!(matches!(
            result,
            Err(ServiceError::MissingMandatoryParam(_))
        ));
    }

    #[test]
    fn test_validate_payload_invalid_root_type() {
        let payload = json!("not an object or array");

        let result = validate_payload(&payload, &[]);
        assert!(matches!(result, Err(ServiceError::InvalidPayload(_))));
    }

    #[test]
    fn test_validate_get_params() {
        let mut query = HashMap::new();
        query.insert("feed_id".to_string(), "test_feed".to_string());

        let params = validate_get_params(&query);
        assert_eq!(params.get("feed_id").unwrap(), "test_feed");
    }

    #[test]
    fn test_validate_payload_empty_array() {
        let payload = json!([]);
        let err = validate_payload(&payload, &["feed_id"]).unwrap_err();
        assert_eq!(err.to_string(), "Invalid payload: Payload elements missing");
    }

    #[test]
    fn test_validate_payload_invalid_item() {
        // structural error, title should be string (if present) but got number
        let payload = json!({
            "feed_id": "feed1",
            "title": 123
        });
        let err = validate_payload(&payload, &["feed_id"]).unwrap_err();
        assert!(err
            .to_string()
            .starts_with("Invalid payload: Failed to parse payload item:"));
    }

    #[test]
    fn test_validate_payload_null_mandatory_field() {
        // Covers the `Some(serde_json::Value::Null)` arm of the None|Null pattern
        let payload = json!({"feed_id": null});
        let err = validate_payload(&payload, &["feed_id"]).unwrap_err();
        assert!(matches!(err, ServiceError::MissingMandatoryParam(_)));
    }

    #[test]
    fn test_validate_headers_missing_accept() {
        // Empty header map — accept defaults to "" which fails the check
        let headers = HashMap::new();
        let result = validate_headers(&headers, false);
        assert!(matches!(result, Err(ServiceError::InvalidHeader(_))));
    }

    #[test]
    fn test_validate_headers_invalid_charset() {
        // Covers the charset != PossibleHeaderType::CHARSET branch
        let mut headers = HashMap::new();
        headers.insert(
            HeaderType::ACCEPT.to_string(),
            PossibleHeaderType::ACCEPT.to_string(),
        );
        headers.insert(
            HeaderType::CONTENT_TYPE.to_string(),
            "application/json; charset=latin-1".to_string(),
        );
        let result = validate_headers(&headers, true);
        assert!(matches!(result, Err(ServiceError::InvalidHeader(_))));
    }

    #[test]
    fn test_validate_headers_invalid_content_type() {
        // Covers the content_type != PossibleHeaderType::CONTENT_TYPE branch
        let mut headers = HashMap::new();
        headers.insert(
            HeaderType::ACCEPT.to_string(),
            PossibleHeaderType::ACCEPT.to_string(),
        );
        headers.insert(
            HeaderType::CONTENT_TYPE.to_string(),
            "text/plain; charset=utf-8".to_string(),
        );
        let result = validate_headers(&headers, true);
        assert!(matches!(result, Err(ServiceError::InvalidHeader(_))));
    }
}
