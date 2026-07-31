//! GET /health/live and GET /health/ready endpoints.
//!
//! `/health/live` returns `200 OK` if the HTTP server is up and running.
//! `/health/ready` returns `200 OK` when the service is running and the active database pool
//! is reachable. Returns `503 Service Unavailable` when the DB ping fails,
//! allowing load balancers to remove the instance from rotation.

use std::sync::{Arc, atomic::Ordering};

use axum::{Json, extract::State, http::StatusCode, response::IntoResponse};
use serde_json::json;

use newsfeed_db::pool::AppState;

#[utoipa::path(
    get,
    path = "/health/live",
    responses(
        (status = 200, description = "Service is alive")
    )
)]
pub async fn live_handler() -> impl IntoResponse {
    (StatusCode::OK, Json(json!({ "status": "ok" }))).into_response()
}

#[utoipa::path(
    get,
    path = "/health/ready",
    responses(
        (status = 200, description = "Service is ready"),
        (status = 503, description = "Service is degraded")
    )
)]
pub async fn ready_handler(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let is_healthy = state.is_healthy.load(Ordering::Relaxed);

    if is_healthy {
        (StatusCode::OK, Json(json!({ "status": "ok", "db": "ok" }))).into_response()
    } else {
        (
            StatusCode::SERVICE_UNAVAILABLE,
            Json(json!({ "status": "degraded", "db": "error" })),
        )
            .into_response()
    }
}
