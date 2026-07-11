//! GET /api/newsfeed — extract (read) handler.

use std::sync::Arc;

use axum::{
    extract::{Query, State},
    http::{HeaderMap, StatusCode},
    response::IntoResponse,
    Json,
};
use std::collections::HashMap;

use newsfeed_constants::http::ResponseMessage;
use newsfeed_db::pool::AppState;
use newsfeed_models::{ApiResponse, ExtractParams};
use newsfeed_service::{
    extract_feed,
    payload_validator::{validate_get_params, ValidatedPayload},
    validate_headers,
};

use crate::handlers::header_map_to_lowercase;

pub async fn handler(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Query(raw_params): Query<HashMap<String, String>>,
) -> impl IntoResponse {
    // ── 1. Validate headers ───────────────────────────────────────────────────
    let header_map = header_map_to_lowercase(&headers);
    if let Err(e) = validate_headers(&header_map) {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiResponse::<serde_json::Value>::error(e.to_string())),
        )
            .into_response();
    }

    // ── 2. Validate / normalise query params ──────────────────────────────────
    let params = match validate_get_params(&raw_params) {
        Ok(ValidatedPayload::QueryParams(p)) => ExtractParams::from_map(&p),
        Err(e) => {
            return (
                StatusCode::BAD_REQUEST,
                Json(ApiResponse::<serde_json::Value>::error(e.to_string())),
            )
                .into_response();
        }
        _ => ExtractParams::default(),
    };

    // ── 3. Execute extract ────────────────────────────────────────────────────
    match extract_feed(&state, &params).await {
        Ok(rows) => {
            let response = ApiResponse::success(ResponseMessage::PROCESSED, rows);
            (StatusCode::OK, Json(response)).into_response()
        }
        Err(e) => {
            tracing::error!(error = %e, "GET /api/newsfeed database error");
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiResponse::<serde_json::Value>::error(e.to_string())),
            )
                .into_response()
        }
    }
}
