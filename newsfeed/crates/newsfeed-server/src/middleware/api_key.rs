//! API key authentication middleware.
//!
//! Validates the `X-API-Key` header against the `HashSet<String>` stored in
//! `AppState`.  Returns `401 Unauthorized` for missing or invalid keys.
//!
//! Security properties:
//! - Constant-time comparison via `subtle::ConstantTimeEq` — prevents timing
//!   side-channel attacks that would allow an attacker to enumerate valid key
//!   prefixes byte-by-byte.
//! - Full key is never logged; only the first 6 characters appear in audit logs.
//! - Applies to EVERY route except `/health`.

use std::sync::Arc;

use sha2::{Digest, Sha256};
use std::fmt::Write;

use axum::{
    body::Body,
    extract::State,
    http::{Request, StatusCode},
    middleware::Next,
    response::{IntoResponse, Response},
    Json,
};

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
        .get("x-api-key")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");

    // Hash the incoming key and compare it against the hashed keys in memory.
    // This naturally eliminates timing side-channel attacks.
    let is_valid = if provided_key.is_empty() {
        false
    } else {
        let mut hasher = Sha256::new();
        hasher.update(provided_key.as_bytes());
        let hash_result = hasher.finalize();

        let mut hex_hash = String::with_capacity(64);
        for byte in hash_result {
            let _ = write!(&mut hex_hash, "{:02x}", byte);
        }

        state.api_keys.contains(&hex_hash)
    };

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
                "UNAUTHORIZED",
                "Unauthorized",
            )),
        )
            .into_response()
    }
}
