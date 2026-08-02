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
use newsfeed_db::pool::AppState;
use newsfeed_models::{
    ApiErrorResponse, ApiResponse, CudParams, CudPayload, CudResult, CudStatus, FailedItem,
};
use newsfeed_service::{ServiceError, cud_feed};

use crate::{
    extractors::AppJson,
    validation::{ValidationError, validate_headers, validate_required_fields},
};

#[utoipa::path(
    post,
    path = "/api/v1/newsfeed",
    request_body = CudPayload,
    responses(
        (status = 201, description = "Created newsfeed item", body = ApiResponse<CudResult, CudParams>)
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
        (status = 200, description = "Updated newsfeed item", body = ApiResponse<CudResult, CudParams>)
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
        (status = 200, description = "Deleted newsfeed item", body = ApiResponse<CudResult, CudParams>)
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
        return (status, Json(ApiErrorResponse::<newsfeed_models::EmptyPayload>::with_code(ResponseCode::INVALID_HEADER, e.to_string()))).into_response();
    }

    // ── 1.5. Reject duplicate titles ──────────────────────────────────────────
    if let Err(e) = check_duplicates(&body.items) {
        return (
            StatusCode::UNPROCESSABLE_ENTITY,
            Json(
                ApiErrorResponse::<newsfeed_models::EmptyPayload>::with_code(
                    "DUPLICATE_TITLES",
                    e.to_string(),
                ),
            ),
        )
            .into_response();
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
            return (StatusCode::INTERNAL_SERVER_ERROR, Json(ApiErrorResponse::<newsfeed_models::EmptyPayload>::with_code(ResponseCode::DB_ERROR, "Internal Server Error".to_string()))).into_response();
        }
    };

    // ── 4. Process bulk results and construct FailedItems ─────────────────────
    handle_cud_logic(results, option_mode)
}

fn check_duplicates(items: &[newsfeed_models::CudParams]) -> Result<(), ValidationError> {
    let mut seen = std::collections::HashSet::new();
    let mut duplicates = Vec::new();
    for item in items {
        if let Some(ref title) = item.title
            && !seen.insert(title.clone()) {
                duplicates.push(title.clone());
            }
    }
    if duplicates.is_empty() {
        Ok(())
    } else {
        Err(ValidationError::DuplicateTitle(duplicates.join(", ")))
    }
}

fn handle_cud_logic(results: Vec<CudResult>, option_mode: OptionMode) -> axum::response::Response {
    let all_skipped = results
        .iter()
        .all(|r| matches!(r.status, CudStatus::Skipped));

    let mut successes = Vec::new();
    let mut failed = Vec::new();

    for res in results {
        match res.status {
            CudStatus::Error => failed.push(FailedItem {
                item: res.item.unwrap_or_else(CudParams::default),
                reason: res.message,
            }),
            CudStatus::Success | CudStatus::Skipped => successes.push(res),
        }
    }

    let response: ApiResponse<CudResult, CudParams> = if !successes.is_empty() && !failed.is_empty()
    {
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

    #[test]
    fn test_check_duplicates_ok() {
        let items = vec![
            newsfeed_models::CudParams {
                title: Some("1".to_string()),
                ..Default::default()
            },
            newsfeed_models::CudParams {
                title: Some("2".to_string()),
                ..Default::default()
            },
            newsfeed_models::CudParams {
                title: None,
                ..Default::default()
            },
        ];
        assert!(check_duplicates(&items).is_ok());
    }

    #[test]
    fn test_check_duplicates_fails() {
        let items = vec![
            newsfeed_models::CudParams {
                title: Some("1".to_string()),
                ..Default::default()
            },
            newsfeed_models::CudParams {
                title: Some("1".to_string()),
                ..Default::default()
            },
            newsfeed_models::CudParams {
                title: Some("2".to_string()),
                ..Default::default()
            },
            newsfeed_models::CudParams {
                title: Some("2".to_string()),
                ..Default::default()
            },
        ];
        let err = check_duplicates(&items).unwrap_err();
        assert!(matches!(err, ValidationError::DuplicateTitle(t) if t == "1, 2"));
    }

    #[test]
    fn test_handle_cud_logic_partial_failure() {
        #[rustfmt::skip]
        let results = vec![
            CudResult { status: CudStatus::Success, message: "OK".to_string(), item: Some(CudParams { title: Some("1".to_string()), ..Default::default() }) },
            CudResult { status: CudStatus::Error, message: "Fail".to_string(), item: Some(CudParams { title: Some("2".to_string()), ..Default::default() }) },
        ];

        let res = handle_cud_logic(results, OptionMode::InsertFeed);
        assert_eq!(res.status(), axum::http::StatusCode::OK);
        return;
    }

    #[test]
    fn test_handle_cud_logic_all_failure() {
        #[rustfmt::skip]
        let results = vec![
            CudResult { status: CudStatus::Error, message: "Fail".to_string(), item: Some(CudParams { title: Some("2".to_string()), ..Default::default() }) },
            CudResult { status: CudStatus::Error, message: "Fail".to_string(), item: None },
        ];

        let res = handle_cud_logic(results, OptionMode::InsertFeed);
        assert_eq!(res.status(), axum::http::StatusCode::BAD_REQUEST);
        return;
    }

    #[test]
    fn test_handle_cud_logic_all_skipped_insert() {
        #[rustfmt::skip]
        let results = vec![CudResult { status: CudStatus::Skipped, message: "Record already exists".to_string(), item: Some(CudParams { title: Some("1".to_string()), ..Default::default() }) }];

        let res = handle_cud_logic(results, OptionMode::InsertFeed);
        // Insert with no errors and all skipped should be OK (200)
        assert_eq!(res.status(), axum::http::StatusCode::OK);
        return;
    }

    #[test]
    fn test_handle_cud_logic_all_skipped_update() {
        #[rustfmt::skip]
        let results = vec![CudResult { status: CudStatus::Skipped, message: "Record does not exist".to_string(), item: Some(CudParams { title: Some("1".to_string()), ..Default::default() }) }];

        let res = handle_cud_logic(results, OptionMode::UpdateFeed);
        // Update with no errors and all skipped should be OK (200)
        assert_eq!(res.status(), axum::http::StatusCode::OK);
        return;
    }
}
