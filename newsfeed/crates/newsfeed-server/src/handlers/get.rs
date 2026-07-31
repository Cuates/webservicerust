//! GET /api/newsfeed — extract (read) handler.

use axum::{
    extract::{Query, State},
    http::{
        HeaderMap, StatusCode,
        header::{ETAG, IF_NONE_MATCH},
    },
    response::{IntoResponse, Json},
};
use newsfeed_constants::http::{ResponseCode, ResponseMessage};
use newsfeed_db::pool::AppState;
use newsfeed_models::{ApiResponse, ExtractParams};
use newsfeed_service::extract_feed;
use std::collections::HashMap;

use crate::validation::validate_headers;
use std::sync::Arc;

#[utoipa::path(
    get,
    path = "/api/v1/newsfeed",
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
    if let Err(e) = validate_headers(&headers, false) {
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
    let params = ExtractParams::from_map(&raw_params);

    // ── 3. ETag check (Fast Path) ─────────────────────────────────────────────
    let mut db_etag = None;
    if let Ok(Some(max_date)) = newsfeed_service::feed_service::max_modified_date(&state).await {
        let params_str = serde_json::to_string(&params).unwrap_or_default();
        let etag_input = format!("{max_date}_{params_str}");
        let hash = xxhash_rust::xxh64::xxh64(etag_input.as_bytes(), 0);
        let etag = format!("\"{hash:016x}\"");

        if let Some(if_none_match) = headers.get(IF_NONE_MATCH)
            && if_none_match.as_bytes() == etag.as_bytes()
        {
            return (StatusCode::NOT_MODIFIED, [(ETAG, etag)]).into_response();
        }
        db_etag = Some(etag);
    }

    // ── 4. Execute extract ────────────────────────────────────────────────────
    match extract_feed(&state, &params).await {
        Ok(rows) => {
            let response = ApiResponse::success(ResponseMessage::PROCESSED, rows);
            let body_bytes = serde_json::to_vec(&response).unwrap_or_default();

            let etag = if let Some(e) = db_etag {
                e
            } else {
                let hash = xxhash_rust::xxh64::xxh64(&body_bytes, 0);
                format!("\"{hash:016x}\"")
            };

            (
                StatusCode::OK,
                [
                    (
                        ETAG,
                        etag.parse()
                            .unwrap_or(axum::http::HeaderValue::from_static("")),
                    ),
                    (
                        axum::http::header::CONTENT_TYPE,
                        axum::http::HeaderValue::from_static("application/json"),
                    ),
                ],
                body_bytes,
            )
                .into_response()
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
