//! Catch-all 404 handler for unknown routes.

use axum::{http::StatusCode, response::IntoResponse, Json};
use newsfeed_models::ApiResponse;

pub async fn handler() -> impl IntoResponse {
    (
        StatusCode::NOT_FOUND,
        Json(ApiResponse::<serde_json::Value>::error("Not Found")),
    )
        .into_response()
}
