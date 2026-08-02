//! Catch-all 404 handler for unknown routes.

use axum::{
    http::StatusCode,
    response::{IntoResponse, Json},
};
use newsfeed_constants::http::ResponseMessage;
use newsfeed_models::ApiErrorResponse;

pub async fn handler() -> impl IntoResponse {
    (
        StatusCode::NOT_FOUND,
        Json(ApiErrorResponse::<()>::new(ResponseMessage::NOT_FOUND)),
    )
        .into_response()
}
