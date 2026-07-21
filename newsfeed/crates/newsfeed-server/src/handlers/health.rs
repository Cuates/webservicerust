//! GET /health — health check endpoint (no API key required).
//!
//! Returns `200 OK` when the service is running and the active database pool
//! is reachable.  Returns `503 Service Unavailable` when the DB ping fails,
//! allowing load balancers to remove the instance from rotation.

use std::sync::Arc;

use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};
use serde_json::json;

use newsfeed_db::pool::AppState;

#[utoipa::path(
    get,
    path = "/health",
    responses(
        (status = 200, description = "Service is healthy")
    )
)]
pub async fn handler(State(state): State<Arc<AppState>>) -> impl IntoResponse {
    let db_status = state.db.ping().await;

    match db_status {
        Ok(()) => (StatusCode::OK, Json(json!({ "status": "ok", "db": "ok" }))).into_response(),
        Err(e) => {
            tracing::error!(error = %e, "Health check DB ping failed");
            (
                StatusCode::SERVICE_UNAVAILABLE,
                Json(json!({ "status": "degraded", "db": "error" })),
            )
                .into_response()
        }
    }
}
