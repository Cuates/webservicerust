//! API key authentication middleware.
//!
//! Validates the `X-API-Key` header against the `HashSet<String>` stored in
//! `AppState`.  Returns `401 Unauthorized` for missing or invalid keys.
//!
//! Security properties:
//! - O(1) lookup via `HashSet` — no timing leak from iteration
//! - Full key is never logged; only the first 6 characters appear in audit logs
//! - Applies to EVERY route except `/health`

use std::sync::Arc;

use axum::{
    body::Body,
    extract::State,
    http::{Request, StatusCode},
    middleware::Next,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;

use newsfeed_db::pool::AppState;

/// Axum middleware function: validates `X-API-Key` on every request.
pub async fn api_key_middleware(
    State(state): State<Arc<AppState>>,
    req: Request<Body>,
    next: Next,
) -> Response {
    // Skip auth for the health check endpoint.
    if req.uri().path() == "/health" {
        return next.run(req).await;
    }

    let provided_key = req
        .headers()
        .get("x-api-key")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");

    if !provided_key.is_empty() && state.api_keys.contains(provided_key) {
        // Audit log: first 6 chars only — never the full key.
        let preview = &provided_key[..provided_key.len().min(6)];
        tracing::debug!(key_prefix = %preview, "API key validated");
        next.run(req).await
    } else {
        tracing::warn!("Unauthorized request — missing or invalid X-API-Key");
        (
            StatusCode::UNAUTHORIZED,
            Json(json!({
                "Status":  "Error",
                "Message": "Unauthorized",
                "Count":   0,
                "Result":  []
            })),
        )
            .into_response()
    }
}
