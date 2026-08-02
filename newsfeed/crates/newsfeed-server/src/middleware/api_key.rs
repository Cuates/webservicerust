//! API key authentication middleware.
//!
//! Validates the `X-API-Key` header against the `Vec<[u8; 32]>` stored in
//! `AppState`.  Returns `401 Unauthorized` for missing or invalid keys.
//!
//! Security properties:
//! - The incoming key is SHA-256 hashed and compared against the in-memory
//!   digest list using `subtle::ConstantTimeEq::ct_eq` in a non-short-circuiting fold.
//!   This prevents timing side-channel attacks.
//! - Full key is never logged; only the first 6 characters appear in audit logs.
//! - Applies to EVERY route except `/health`.

use std::sync::Arc;

use sha2::{Digest, Sha256};
use subtle::ConstantTimeEq;

use axum::{
    body::Body,
    extract::{Request, State},
    http::StatusCode,
    middleware::Next,
    response::{IntoResponse, Json, Response},
};

use newsfeed_constants::http::{HeaderType, ResponseCode, ResponseMessage};
use newsfeed_db::pool::AppState;
use newsfeed_models::ApiErrorResponse;

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
        let preview: String = provided_key.chars().take(6).collect();
        tracing::debug!(key_prefix = %preview, "API key validated");
        next.run(req).await
    } else {
        tracing::warn!("Unauthorized request — missing or invalid X-API-Key");
        (
            StatusCode::UNAUTHORIZED,
            Json(ApiErrorResponse::<()>::with_code(
                ResponseCode::UNAUTHORIZED,
                ResponseMessage::UNAUTHORIZED,
            )),
        )
            .into_response()
    }
}

pub(crate) fn is_api_key_valid(provided_key: &str, valid_keys: &[[u8; 32]]) -> bool {
    if provided_key.is_empty() {
        return false;
    }
    let mut hasher = Sha256::new();
    hasher.update(provided_key.as_bytes());
    let hash_result: [u8; 32] = hasher.finalize().into();

    let mut is_valid = subtle::Choice::from(0);
    for key in valid_keys {
        is_valid |= key.ct_eq(&hash_result);
    }
    is_valid.into()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_api_key_valid() {
        let key_str = "nf_test_key_123";
        let mut hasher = Sha256::new();
        hasher.update(key_str.as_bytes());
        let hash_result: [u8; 32] = hasher.finalize().into();
        let valid_keys = vec![hash_result];

        assert!(is_api_key_valid(key_str, &valid_keys));
        assert!(!is_api_key_valid("wrong_key", &valid_keys));
        assert!(!is_api_key_valid("", &valid_keys));
    }
}
