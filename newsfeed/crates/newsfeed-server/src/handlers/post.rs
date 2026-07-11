//! POST /api/newsfeed — create (insert) handler.

use std::sync::Arc;

use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    response::IntoResponse,
    Json,
};

use newsfeed_constants::{db::OptionMode, http::ResponseMessage};
use newsfeed_db::pool::AppState;
use newsfeed_models::ApiResponse;
use newsfeed_service::{cud_feed, payload_validator::{validate_payload, ValidatedPayload}, validate_headers};

use crate::handlers::header_map_to_lowercase;

pub async fn handler(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(body): Json<serde_json::Value>,
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

    // ── 2. Validate payload (title is mandatory for insert) ───────────────────
    let items = match validate_payload(&body, &["title"]) {
        Ok(ValidatedPayload::BodyItems(items)) => items,
        Err(e) => {
            return (
                StatusCode::UNPROCESSABLE_ENTITY,
                Json(ApiResponse::<serde_json::Value>::error(e.to_string())),
            )
                .into_response();
        }
        _ => return StatusCode::INTERNAL_SERVER_ERROR.into_response(),
    };

    // ── 3. Execute insert for each item ───────────────────────────────────────
    let mut all_results: Vec<serde_json::Value> = Vec::new();
    for params in &items {
        match cud_feed(&state, OptionMode::INSERT_FEED, params).await {
            Ok(mut rows) => all_results.append(&mut rows),
            Err(e) => {
                tracing::error!(error = %e, "POST /api/newsfeed database error");
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiResponse::<serde_json::Value>::error(e.to_string())),
                )
                    .into_response();
            }
        }
    }

    let response = ApiResponse::success(ResponseMessage::PROCESSED, all_results);
    (StatusCode::CREATED, Json(response)).into_response()
}
