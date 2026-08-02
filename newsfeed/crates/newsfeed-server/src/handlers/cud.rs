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
    http::{ResponseCode, ResponseMessage},
};
use newsfeed_db::{CudStatus, pool::AppState};
use newsfeed_models::{ApiResponse, CudPayload, FailedItem};
use newsfeed_service::{ServiceError, cud_feed};

use crate::{
    extractors::AppJson,
    validation::{validate_headers, validate_required_fields},
};

#[utoipa::path(
    post,
    path = "/api/v1/newsfeed",
    request_body = CudPayload,
    responses(
        (status = 201, description = "Created newsfeed item", body = ApiResponse<serde_json::Value>)
    )
)]
pub async fn post_handler(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    AppJson(body): AppJson<CudPayload>,
) -> impl IntoResponse {
    process_cud(state, headers, body, OptionMode::InsertFeed).await
}

#[utoipa::path(
    put,
    path = "/api/v1/newsfeed",
    request_body = CudPayload,
    responses(
        (status = 200, description = "Updated newsfeed item", body = ApiResponse<serde_json::Value>)
    )
)]
pub async fn put_handler(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    AppJson(body): AppJson<CudPayload>,
) -> impl IntoResponse {
    process_cud(state, headers, body, OptionMode::UpdateFeed).await
}

#[utoipa::path(
    delete,
    path = "/api/v1/newsfeed",
    request_body = CudPayload,
    responses(
        (status = 200, description = "Deleted newsfeed item", body = ApiResponse<serde_json::Value>)
    )
)]
pub async fn delete_handler(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    AppJson(body): AppJson<CudPayload>,
) -> impl IntoResponse {
    process_cud(state, headers, body, OptionMode::DeleteFeed).await
}

async fn process_cud(
    state: Arc<AppState>,
    headers: HeaderMap,
    body: CudPayload,
    option_mode: OptionMode,
) -> axum::response::Response {
    // ── 1. Validate headers ───────────────────────────────────────────────────
    if let Err(e) = validate_headers(&headers, true) {
        let status = match e {
            ServiceError::UnsupportedContentType(_) => StatusCode::UNSUPPORTED_MEDIA_TYPE,
            _ => StatusCode::BAD_REQUEST,
        };
        #[rustfmt::skip]
        return (status, Json(ApiResponse::<serde_json::Value>::error_with_code(ResponseCode::INVALID_HEADER, e.to_string()))).into_response();
    }

    // ── 2. Validate required fields for each item ─────────────────────────────
    for item in &body {
        if let Err(err_resp) = validate_required_fields(item, &option_mode) {
            return (StatusCode::UNPROCESSABLE_ENTITY, Json(err_resp)).into_response();
        }
    }

    // ── 3. Execute bulk insert via single procedure call ──────────────────────
    let results = match cud_feed(&state, option_mode, &body.items).await {
        Ok(res) => res,
        Err(e) => {
            tracing::error!(error = %e, "CUD database error");
            #[rustfmt::skip]
            return (StatusCode::INTERNAL_SERVER_ERROR, Json(ApiResponse::<serde_json::Value>::error_with_code(ResponseCode::DB_ERROR, "Internal Server Error".to_string()))).into_response();
        }
    };

    // ── 4. Process bulk results and construct FailedItems ─────────────────────
    handle_cud_logic(results, option_mode)
}

fn handle_cud_logic(
    results: Vec<newsfeed_db::CudResult>,
    option_mode: OptionMode,
) -> axum::response::Response {
    let all_skipped = results
        .iter()
        .all(|r| matches!(r.status, CudStatus::Skipped));

    let mut successes = Vec::new();
    let mut failed = Vec::new();

    for res in results {
        match res.status {
            CudStatus::Error => failed.push(FailedItem {
                item: res.item.unwrap_or(serde_json::json!({})),
                reason: res.message,
            }),
            CudStatus::Success | CudStatus::Skipped => successes.push(res),
        }
    }

    let response = if !successes.is_empty() && !failed.is_empty() {
        ApiResponse::partial(ResponseMessage::PARTIAL, successes, failed)
    } else {
        let mut resp = ApiResponse::success(ResponseMessage::PROCESSED, successes);
        resp.failed_items = failed;
        resp
    };

    let status_code = if response.result.is_empty() && !response.failed_items.is_empty() {
        StatusCode::BAD_REQUEST
    } else if !response.failed_items.is_empty() {
        StatusCode::OK
    } else if matches!(option_mode, OptionMode::InsertFeed) && !all_skipped {
        StatusCode::CREATED
    } else {
        StatusCode::OK
    };

    (status_code, Json(response)).into_response()
}

#[cfg(test)]
mod tests {
    use super::*;
    use newsfeed_constants::db::OptionMode;
    use newsfeed_db::{CudResult, CudStatus};

    #[test]
    fn test_handle_cud_logic_partial_failure() {
        #[rustfmt::skip]
        let results = vec![
            CudResult { status: CudStatus::Success, message: "OK".to_string(), item: Some(serde_json::json!({"title": "1"})) },
            CudResult { status: CudStatus::Error, message: "Fail".to_string(), item: Some(serde_json::json!({"title": "2"})) },
        ];

        let res = handle_cud_logic(results, OptionMode::InsertFeed);
        assert_eq!(res.status(), axum::http::StatusCode::OK);
        return;
    }

    #[test]
    fn test_handle_cud_logic_all_failure() {
        #[rustfmt::skip]
        let results = vec![
            CudResult { status: CudStatus::Error, message: "Fail".to_string(), item: Some(serde_json::json!({"title": "2"})) },
            CudResult { status: CudStatus::Error, message: "Fail".to_string(), item: None },
        ];

        let res = handle_cud_logic(results, OptionMode::InsertFeed);
        assert_eq!(res.status(), axum::http::StatusCode::BAD_REQUEST);
        return;
    }

    #[test]
    fn test_handle_cud_logic_all_skipped_insert() {
        #[rustfmt::skip]
        let results = vec![CudResult { status: CudStatus::Skipped, message: "Record already exists".to_string(), item: Some(serde_json::json!({"title": "1"})) }];

        let res = handle_cud_logic(results, OptionMode::InsertFeed);
        // Insert with no errors and all skipped should be OK (200)
        assert_eq!(res.status(), axum::http::StatusCode::OK);
        return;
    }

    #[test]
    fn test_handle_cud_logic_all_skipped_update() {
        #[rustfmt::skip]
        let results = vec![CudResult { status: CudStatus::Skipped, message: "Record does not exist".to_string(), item: Some(serde_json::json!({"title": "1"})) }];

        let res = handle_cud_logic(results, OptionMode::UpdateFeed);
        // Update with no errors and all skipped should be OK (200)
        assert_eq!(res.status(), axum::http::StatusCode::OK);
        return;
    }
}
