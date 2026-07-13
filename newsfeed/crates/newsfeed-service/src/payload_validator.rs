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

// ── Validated payload type ────────────────────────────────────────────────────

/// The result of successful payload validation.
pub enum ValidatedPayload {
    /// GET / QUERY: normalised query-param map.
    QueryParams(HashMap<String, String>),
    /// POST / PUT / DELETE: list of validated body objects.
    BodyItems(Vec<CudParams>),
}

// ── Payload validation ────────────────────────────────────────────────────────

/// Validate GET / QUERY query parameters (no mandatory params for reads).
pub fn validate_get_params(
    raw: &HashMap<String, String>,
) -> Result<ValidatedPayload, ServiceError> {
    // Keys are expected to match ExtractParams field names exactly (snake_case).
    Ok(ValidatedPayload::QueryParams(raw.clone()))
}

/// Validate POST / PUT / DELETE JSON body.
///
/// `mandatory` is the list of field names that must be present and non-empty.
pub fn validate_payload(
    body: &serde_json::Value,
    mandatory: &[&str],
) -> Result<ValidatedPayload, ServiceError> {
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

    Ok(ValidatedPayload::BodyItems(validated))
}
