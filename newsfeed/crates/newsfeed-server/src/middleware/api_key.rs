//! API key authentication middleware.
//!
//! Validates the `X-API-Key` header against the `HashSet<String>` stored in
//! `AppState`.  Returns `401 Unauthorized` for missing or invalid keys.
//!
//! Security properties:
//! - The incoming key is SHA-256 hashed before comparison against the in-memory
//!   `HashSet`. This naturally mitigates timing side-channel attacks.
//! - Full key is never logged; only the first 6 characters appear in audit logs.
//! - Applies to EVERY route except `/health`.

use std::sync::Arc;

use sha2::{Digest, Sha256};
use std::fmt::Write;

use axum::{
    body::Body,
    extract::{Request, State},
    http::StatusCode,
    middleware::Next,
    response::{IntoResponse, Json, Response},
};

use newsfeed_constants::http::{HeaderType, ResponseCode, ResponseMessage};
use newsfeed_db::pool::AppState;
use newsfeed_models::ApiResponse;

/// Axum middleware function: validates `X-API-Key` on every request.
pub async fn api_key_middleware(
    State(state): State<Arc<AppState>>,
    req: Request<Body>,
    next: Next,
) -> Response {
    // The middleware is only mounted on authenticated API routes,
    // so no manual path exclusions (like /health or Swagger) are needed here.

    let provided_key = req
        .headers()
        .get(HeaderType::API_KEY)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");

    let is_valid = is_api_key_valid(provided_key, &state.api_keys);

    if is_valid {
        // Audit log: first 6 chars only — never the full key.
        let preview = &provided_key[..provided_key.len().min(6)];
        tracing::debug!(key_prefix = %preview, "API key validated");
        next.run(req).await
    } else {
        tracing::warn!("Unauthorized request — missing or invalid X-API-Key");
        (
            StatusCode::UNAUTHORIZED,
            Json(ApiResponse::<serde_json::Value>::error_with_code(
                ResponseCode::UNAUTHORIZED,
                ResponseMessage::UNAUTHORIZED,
            )),
        )
            .into_response()
    }
}

pub(crate) fn is_api_key_valid(
    provided_key: &str,
    valid_keys: &std::collections::HashSet<String>,
) -> bool {
    if provided_key.is_empty() {
        return false;
    }
    let mut hasher = Sha256::new();
    hasher.update(provided_key.as_bytes());
    let hash_result = hasher.finalize();

    let mut hex_hash = String::with_capacity(64);
    for byte in hash_result {
        let _ = write!(&mut hex_hash, "{byte:02x}");
    }

    valid_keys.contains(&hex_hash)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashSet;

    #[test]
    fn test_is_api_key_valid() {
        let mut valid_keys = HashSet::new();
        // hash of "nf_test_key_123"
        let key_str = "nf_test_key_123";
        let mut hasher = Sha256::new();
        hasher.update(key_str.as_bytes());
        let hash_result = hasher.finalize();
        let mut hex_hash = String::with_capacity(64);
        for byte in hash_result {
            let _ = write!(&mut hex_hash, "{byte:02x}");
        }
        valid_keys.insert(hex_hash);

        assert!(is_api_key_valid(key_str, &valid_keys));
        assert!(!is_api_key_valid("wrong_key", &valid_keys));
        assert!(!is_api_key_valid("", &valid_keys));
    }
}
