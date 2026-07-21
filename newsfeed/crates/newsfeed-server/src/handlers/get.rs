//! GET /api/newsfeed — extract (read) handler.

use axum::{
    extract::{Query, State},
    http::{
        header::{ETAG, IF_NONE_MATCH},
        HeaderMap, StatusCode,
    },
    response::{IntoResponse, Json},
};
use newsfeed_constants::http::{ResponseCode, ResponseMessage};
use newsfeed_db::pool::AppState;
use newsfeed_models::{ApiResponse, ExtractParams};
use newsfeed_service::{extract_feed, payload_validator::validate_get_params, validate_headers};
use std::collections::HashMap;

use std::sync::Arc;

use crate::handlers::header_map_to_lowercase;

#[utoipa::path(
    get,
    path = "/api/newsfeed",
    params(
        newsfeed_models::ExtractParams
    ),
    responses(
        (status = 200, description = "List of newsfeed items", body = ApiResponse<serde_json::Value>)
    )
)]
#[allow(clippy::implicit_hasher)]
pub async fn handler(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Query(raw_params): Query<HashMap<String, String>>,
) -> impl IntoResponse {
    // ── 1. Validate headers ───────────────────────────────────────────────────
    // GET requests carry no body, so Content-Type validation is skipped.
    let header_map = header_map_to_lowercase(&headers);
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

    // ── 2. Validate / normalise query params ──────────────────────────────────
    let p = validate_get_params(&raw_params);
    let params = ExtractParams::from_map(&p);

    // ── 3. Execute extract ────────────────────────────────────────────────────
    match extract_feed(&state, &params).await {
        Ok(rows) => {
            let response = ApiResponse::success(ResponseMessage::PROCESSED, rows);
            let body_bytes = serde_json::to_vec(&response).unwrap_or_default();

            let hash = xxhash_rust::xxh64::xxh64(&body_bytes, 0);
            let etag = format!("\"{hash:016x}\"");

            if let Some(if_none_match) = headers.get(IF_NONE_MATCH) {
                if if_none_match.as_bytes() == etag.as_bytes() {
                    return (StatusCode::NOT_MODIFIED, [(ETAG, etag)]).into_response();
                }
            }

            (StatusCode::OK, [(ETAG, etag)], body_bytes).into_response()
        }
        Err(e) => {
            tracing::error!(error = %e, "GET /api/newsfeed database error");
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
