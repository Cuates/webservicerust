//! GET /health — lightweight health check (no API key required).

use axum::{http::StatusCode, response::IntoResponse, Json};
use serde_json::json;

pub async fn handler() -> impl IntoResponse {
    (StatusCode::OK, Json(json!({ "status": "ok" }))).into_response()
}
