//! QUERY /api/newsfeed — safe read method with optional JSON body.
//!
//! # Status: Pre-standard — do not use in production until RFC finalises
//!
//! The QUERY HTTP method is defined in IETF draft
//! `draft-ietf-httpbis-safe-method-w-body`.  It behaves like GET (safe,
//! idempotent, cacheable) but additionally allows a request body for richer
//! filter expressions.
//!
//! ## Current behaviour
//! - Accepts the same query parameters as GET (URL query string)
//! - Optionally accepts a JSON body with the same filter keys for complex
//!   filter criteria that do not fit in the URL
//! - Body fields take precedence over query-string fields when both are present
//!
//! ## Design note
//! Axum's `MethodFilter` does not support non-standard methods.  QUERY is
//! dispatched via the `.fallback()` on the `MethodRouter` for `/api/newsfeed`.
//! Unknown methods (anything other than QUERY) are rejected with 405.

use axum::{
    body::Body,
    extract::State,
    http::{
        header::{ETAG, IF_NONE_MATCH},
        Request, StatusCode,
    },
    response::{IntoResponse, Json},
};
use newsfeed_constants::http::{MethodType, ResponseCode, ResponseMessage};
use newsfeed_db::pool::AppState;
use newsfeed_models::{ApiResponse, ExtractParams};
use newsfeed_service::{extract_feed, payload_validator::validate_get_params, validate_headers};
use std::collections::HashMap;

use std::sync::Arc;

use crate::handlers::header_map_to_lowercase;

pub async fn handler(State(state): State<Arc<AppState>>, req: Request<Body>) -> impl IntoResponse {
    // Only handle the QUERY method — reject everything else with 405.
    if req.method().as_str() != MethodType::QUERY {
        return (
            StatusCode::METHOD_NOT_ALLOWED,
            Json(ApiResponse::<serde_json::Value>::error(
                ResponseMessage::METHOD_NOT_ALLOWED,
            )),
        )
            .into_response();
    }

    let header_map = header_map_to_lowercase(req.headers());

    // ── 1. Validate headers ───────────────────────────────────────────────────
    // QUERY is a safe read-like method — no body Content-Type is required.
    if let Err(e) = validate_headers(&header_map, false) {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiResponse::<serde_json::Value>::error_with_code(
                ResponseCode::INVALID_HEADER,
                e.to_string(),
            )),
        )
            .into_response();
    }

    // ── 2. Extract URL query params ───────────────────────────────────────────
    let url_params: HashMap<String, String> = req
        .uri()
        .query()
        .map(|q| {
            url::form_urlencoded::parse(q.as_bytes())
                .into_owned()
                .map(|(k, v)| (k.to_lowercase(), v))
                .collect()
        })
        .unwrap_or_default();

    // ── 3. Parse optional JSON body (body fields override URL params) ─────────
    let (parts, body_bytes_stream) = req.into_parts();
    let Ok(body_bytes) = axum::body::to_bytes(body_bytes_stream, 1024 * 1024).await else {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiResponse::<serde_json::Value>::error(
                ResponseMessage::FAILED_TO_READ_BODY,
            )),
        )
            .into_response();
    };

    let mut merged_params = url_params;

    if !body_bytes.is_empty() {
        match serde_json::from_slice::<HashMap<String, serde_json::Value>>(&body_bytes) {
            Ok(body_map) => {
                for (k, v) in body_map {
                    if let Some(s) = v.as_str() {
                        merged_params.insert(k.to_lowercase(), s.to_owned());
                    }
                }
            }
            Err(e) => {
                return (
                    StatusCode::BAD_REQUEST,
                    Json(ApiResponse::<serde_json::Value>::error_with_code(
                        ResponseCode::BAD_REQUEST,
                        e.to_string(),
                    )),
                )
                    .into_response();
            }
        }
    }

    // ── 4. Validate merged params ─────────────────────────────────────────────
    let p = validate_get_params(&merged_params);
    let params = ExtractParams::from_map(&p);

    // ── 5. Execute extract ────────────────────────────────────────────────────
    match extract_feed(&state, &params).await {
        Ok(rows) => {
            let response = ApiResponse::success(ResponseMessage::PROCESSED, rows);
            let body_bytes = serde_json::to_vec(&response).unwrap_or_default();

            let hash = xxhash_rust::xxh64::xxh64(&body_bytes, 0);
            let etag = format!("\"{hash:016x}\"");

            if let Some(if_none_match) = parts.headers.get(IF_NONE_MATCH) {
                if if_none_match.as_bytes() == etag.as_bytes() {
                    return (StatusCode::NOT_MODIFIED, [(ETAG, etag)]).into_response();
                }
            }

            (StatusCode::OK, [(ETAG, etag)], body_bytes).into_response()
        }
        Err(e) => {
            tracing::error!(error = %e, "QUERY /api/newsfeed database error");
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiResponse::<serde_json::Value>::error_with_code(
                    ResponseCode::DB_ERROR,
                    "Internal Server Error".to_string(),
                )),
            )
                .into_response()
        }
    }
}
