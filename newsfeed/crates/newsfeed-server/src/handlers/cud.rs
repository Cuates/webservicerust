//! POST / PUT / DELETE /api/newsfeed — CUD handlers.

use std::sync::Arc;

use axum::{
    Json,
    extract::State,
    http::{HeaderMap, StatusCode},
    response::IntoResponse,
};

use newsfeed_constants::{
    db::OptionMode,
    http::{PossiblePayloadParams, ResponseCode, ResponseMessage},
};
use newsfeed_db::pool::AppState;
use newsfeed_models::{ApiResponse, CudParams, FailedItem};
use newsfeed_service::{
    ServiceError, cud_feed, payload_validator::validate_payload, validate_headers,
};

use crate::extractors::AppJson;

#[utoipa::path(
    post,
    path = "/api/newsfeed",
    request_body = CudParams,
    responses(
        (status = 201, description = "Created newsfeed item", body = ApiResponse<serde_json::Value>)
    )
)]
pub async fn post_handler(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    AppJson(body): AppJson<serde_json::Value>,
) -> impl IntoResponse {
    process_cud(
        state,
        headers,
        body,
        OptionMode::InsertFeed,
        &[PossiblePayloadParams::TITLE],
    )
    .await
}

#[utoipa::path(
    put,
    path = "/api/newsfeed",
    request_body = CudParams,
    responses(
        (status = 200, description = "Updated newsfeed item", body = ApiResponse<serde_json::Value>)
    )
)]
pub async fn put_handler(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    AppJson(body): AppJson<serde_json::Value>,
) -> impl IntoResponse {
    process_cud(
        state,
        headers,
        body,
        OptionMode::UpdateFeed,
        &[
            PossiblePayloadParams::TITLE,
            PossiblePayloadParams::PUBLISH_DATE,
        ],
    )
    .await
}

#[utoipa::path(
    delete,
    path = "/api/newsfeed",
    request_body = CudParams,
    responses(
        (status = 200, description = "Deleted newsfeed item", body = ApiResponse<serde_json::Value>)
    )
)]
pub async fn delete_handler(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    AppJson(body): AppJson<serde_json::Value>,
) -> impl IntoResponse {
    process_cud(
        state,
        headers,
        body,
        OptionMode::DeleteFeed,
        &[
            PossiblePayloadParams::TITLE,
            PossiblePayloadParams::PUBLISH_DATE,
        ],
    )
    .await
}

async fn process_cud(
    state: Arc<AppState>,
    headers: HeaderMap,
    body: serde_json::Value,
    option_mode: OptionMode,
    required_params: &[&str],
) -> axum::response::Response {
    // ── 1. Validate headers ───────────────────────────────────────────────────
    if let Err(e) = validate_headers(&headers, true) {
        let status = match e {
            ServiceError::UnsupportedContentType(_) => StatusCode::UNSUPPORTED_MEDIA_TYPE,
            _ => StatusCode::BAD_REQUEST,
        };
        return (
            status,
            Json(ApiResponse::<serde_json::Value>::error_with_code(
                ResponseCode::INVALID_HEADER,
                e.to_string(),
            )),
        )
            .into_response();
    }

    // ── 2. Validate payload ───────────────────────────────────────────────────
    let items = match validate_payload(body, required_params) {
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

    // ── 3. Execute bulk insert via single procedure call ──────────────────────
    let results = match cud_feed(&state, option_mode, &items).await {
        Ok(res) => res,
        Err(e) => {
            tracing::error!(error = %e, "CUD database error");
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(ApiResponse::<serde_json::Value>::error_with_code(
                    ResponseCode::DB_ERROR,
                    "Internal Server Error".to_string(),
                )),
            )
                .into_response();
        }
    };

    // ── 4. Process bulk results and construct FailedItems ─────────────────────
    let mut successes = Vec::new();
    let mut failed = Vec::new();

    for res in results {
        if res.get("Status").and_then(|v| v.as_str()) == Some("Error") {
            let reason = res
                .get("Message")
                .and_then(|v| v.as_str())
                .unwrap_or("Unknown")
                .to_string();
            failed.push(FailedItem {
                item: res.get("Item").cloned().unwrap_or(serde_json::json!({})),
                reason,
            });
        } else {
            successes.push(res);
        }
    }

    let msg = if !successes.is_empty() && !failed.is_empty() {
        ResponseMessage::PARTIAL
    } else {
        ResponseMessage::PROCESSED
    };
    let mut response = ApiResponse::success(msg, successes);
    response.failed_items = failed;

    let status_code = if response.result.is_empty() && !response.failed_items.is_empty() {
        StatusCode::BAD_REQUEST
    } else if !response.failed_items.is_empty() {
        StatusCode::OK
    } else if matches!(option_mode, OptionMode::InsertFeed) {
        StatusCode::CREATED
    } else {
        StatusCode::OK
    };

    (status_code, Json(response)).into_response()
}
