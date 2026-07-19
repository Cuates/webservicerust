//! Catch-all 404 handler for unknown routes.

use axum::{
    http::StatusCode,
    response::{IntoResponse, Json},
};
use newsfeed_constants::http::ResponseMessage;
use newsfeed_models::ApiResponse;

pub async fn handler() -> impl IntoResponse {
    (
        StatusCode::NOT_FOUND,
        Json(ApiResponse::<serde_json::Value>::error(
            ResponseMessage::NOT_FOUND,
        )),
    )
        .into_response()
}
