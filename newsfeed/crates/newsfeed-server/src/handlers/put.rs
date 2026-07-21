//! PUT /api/newsfeed — update handler.

use std::sync::Arc;

use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    response::IntoResponse,
    Json,
};
use futures::StreamExt;

use newsfeed_constants::{
    db::OptionMode,
    http::{PossiblePayloadParams, ResponseCode, ResponseMessage},
};
use newsfeed_db::pool::AppState;
use newsfeed_models::{ApiResponse, CudParams};
use newsfeed_service::{cud_feed, payload_validator::validate_payload, validate_headers};

use crate::handlers::header_map_to_lowercase;

use crate::extractors::AppJson;

#[utoipa::path(
    put,
    path = "/api/newsfeed",
    request_body = CudParams,
    responses(
        (status = 200, description = "Updated newsfeed item", body = ApiResponse<serde_json::Value>)
    )
)]
pub async fn handler(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    AppJson(body): AppJson<serde_json::Value>,
) -> impl IntoResponse {
    // ── 1. Validate headers ───────────────────────────────────────────────────
    let header_map = header_map_to_lowercase(&headers);
    if let Err(e) = validate_headers(&header_map, true) {
        return (
            StatusCode::BAD_REQUEST,
            Json(ApiResponse::<serde_json::Value>::error_with_code(
                ResponseCode::INVALID_HEADER,
                e.to_string(),
            )),
        )
            .into_response();
    }

    // ── 2. Validate payload (title is mandatory for update) ───────────────────
    let items = match validate_payload(body, &[PossiblePayloadParams::TITLE]) {
        Ok(items) => items,
        Err(e) => {
            return (
                StatusCode::UNPROCESSABLE_ENTITY,
                Json(ApiResponse::<serde_json::Value>::error_with_code(
                    ResponseCode::VALIDATION_ERROR,
                    e.to_string(),
                )),
            )
                .into_response();
        }
    };

    // ── 3. Execute updates concurrently (bounded by BATCH_CONCURRENCY_LIMIT) ──
    let concurrency = state.batch_concurrency_limit;
    let state_ref = &state;

    let results: Vec<Result<Vec<serde_json::Value>, _>> =
        futures::stream::iter(items.into_iter().map(|params| async move {
            cud_feed(state_ref, OptionMode::UpdateFeed, &params).await
        }))
        .buffer_unordered(concurrency)
        .collect()
        .await;

    let mut all_results: Vec<serde_json::Value> = Vec::new();
    for result in results {
        match result {
            Ok(mut rows) => all_results.append(&mut rows),
            Err(e) => {
                tracing::error!(error = %e, "PUT /api/newsfeed database error");
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json(ApiResponse::<serde_json::Value>::error_with_code(
                        ResponseCode::DB_ERROR,
                        "Internal Server Error".to_string(),
                    )),
                )
                    .into_response();
            }
        }
    }

    let response = ApiResponse::success(ResponseMessage::PROCESSED, all_results);
    (StatusCode::OK, Json(response)).into_response()
}
