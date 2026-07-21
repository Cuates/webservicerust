//! Axum router construction and middleware stack assembly.
//!
//! Middleware effective order (outer → inner):
//!   `RequestId` → `TraceLayer` → `CorsLayer` → `RequestBodyLimit` → `RateLimitLayer` → `ApiKeyLayer` → Route dispatch
//!
//! CORS sits outermost so browser OPTIONS preflight requests are handled and
//! short-circuited before consuming rate-limit tokens or being checked for an
//! API key (preflight does not carry one).

use std::sync::Arc;

use axum::{middleware as axum_middleware, response::IntoResponse, routing::get, Router};
use tower_http::{
    cors::CorsLayer,
    limit::RequestBodyLimitLayer,
    request_id::{MakeRequestUuid, PropagateRequestIdLayer, SetRequestIdLayer},
    trace::TraceLayer,
};
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

use newsfeed_config::AppConfig;
use newsfeed_constants::http::{API_ROUTE_PREFIX, HEALTH_ROUTE, PROJECT_NAME};
use newsfeed_db::pool::AppState;

use crate::handlers;
use crate::middleware::api_key;
use crate::openapi::ApiDoc;
use newsfeed_constants::http::{ResponseCode, ResponseMessage};
use tower_governor::governor::GovernorConfigBuilder;

/// Maximum accepted request body size for CUD endpoints (bytes).
const MAX_BODY_BYTES: usize = 1024 * 1024; // 1 MiB

/// Build and return the fully-configured Axum `Router`.
#[allow(clippy::expect_used)]
pub fn build(state: Arc<AppState>, cfg: &AppConfig) -> Router {
    let cors = build_cors(cfg);

    let governor_config = Arc::new(
        GovernorConfigBuilder::default()
            .per_second(cfg.rate_limit_rps)
            .burst_size(cfg.rate_limit_burst)
            .finish()
            .expect("Failed to build rate-limit config"),
    );
    tracing::info!(
        rate_limit_rps = cfg.rate_limit_rps,
        rate_limit_burst = cfg.rate_limit_burst,
        "Rate limiting enabled (tower_governor, per-IP token bucket)"
    );
    let governor_layer = tower_governor::GovernorLayer::new(governor_config).error_handler(|_e| {
        let payload = newsfeed_models::ApiResponse::<serde_json::Value>::error_with_code(
            ResponseCode::RATE_LIMIT_EXCEEDED,
            ResponseMessage::TOO_MANY_REQUESTS_RETRY,
        );
        (
            axum::http::StatusCode::TOO_MANY_REQUESTS,
            axum::Json(payload),
        )
            .into_response()
    });

    let newsfeed_path = format!("{API_ROUTE_PREFIX}/{PROJECT_NAME}");

    let api_routes = Router::new()
        .route(
            &newsfeed_path,
            get(handlers::get::handler)
                .post(handlers::post::handler)
                .put(handlers::put::handler)
                .delete(handlers::delete::handler)
                .fallback(handlers::query::handler),
        )
        .layer(axum_middleware::from_fn_with_state(
            Arc::clone(&state),
            api_key::api_key_middleware,
        ))
        .layer(governor_layer);

    Router::new()
        .merge(
            SwaggerUi::new("/api/newsfeed/swagger-ui")
                .url("/api-docs/openapi.json", ApiDoc::openapi()),
        )
        // ── Health check (no auth required) ──────────────────────────────────
        .route(HEALTH_ROUTE, get(handlers::health::handler))
        // ── Authenticated Newsfeed routes ─────────────────────────────────────
        .merge(api_routes)
        // ── Global Middleware stack ───────────────────────────────────────────
        .layer(RequestBodyLimitLayer::new(MAX_BODY_BYTES))
        .layer(cors)
        .layer(
            tower::ServiceBuilder::new()
                .layer(SetRequestIdLayer::x_request_id(MakeRequestUuid))
                .layer(TraceLayer::new_for_http())
                .layer(PropagateRequestIdLayer::x_request_id()),
        )
        // ── Shared state ──────────────────────────────────────────────────────
        .with_state(state)
        // ── Catch-all 404 ─────────────────────────────────────────────────────
        .fallback(handlers::not_found::handler)
}

// ── CORS ──────────────────────────────────────────────────────────────────────

fn build_cors(cfg: &AppConfig) -> CorsLayer {
    use axum::http::{HeaderName, Method};
    use tower_http::cors::AllowOrigin;

    let origins: Vec<_> = cfg
        .origins_vec()
        .into_iter()
        .filter_map(|o| match o.parse() {
            Ok(v) => Some(v),
            Err(e) => {
                tracing::warn!(origin = %o, error = %e, "Skipping unparseable CORS origin");
                None
            }
        })
        .collect();

    assert!(
        !origins.is_empty(),
        "No valid ALLOWED_ORIGINS configured — all CORS preflight requests will \
         be rejected. Check the ALLOWED_ORIGINS env var for typos."
    );

    CorsLayer::new()
        .allow_origin(AllowOrigin::list(origins))
        .allow_methods([
            Method::GET,
            Method::POST,
            Method::PUT,
            Method::DELETE,
            Method::OPTIONS,
        ])
        .allow_headers([
            HeaderName::from_static("content-type"),
            HeaderName::from_static("accept"),
            HeaderName::from_static("x-api-key"),
            HeaderName::from_static("x-request-id"),
        ])
        .allow_credentials(false)
}

#[cfg(test)]
mod tests {
    use super::*;
    use newsfeed_config::AppConfig;

    #[test]
    #[should_panic(expected = "No valid ALLOWED_ORIGINS configured")]
    fn test_cors_empty_origins() {
        let cfg = AppConfig {
            bind_host: "127.0.0.1".to_string(),
            app_port: 4815,
            rust_log: "info".to_string(),
            api_keys: "".to_string(),
            allowed_origins: "".to_string(),
            rate_limit_rps: 10,
            rate_limit_burst: 30,
            batch_concurrency_limit: 5,
        };
        let _ = build_cors(&cfg);
    }

    #[test]
    #[should_panic(expected = "No valid ALLOWED_ORIGINS configured")]
    fn test_cors_invalid_origin() {
        // \x00 is invalid in HTTP headers, so it fails parsing. Because there are no other valid origins, it panics.
        let cfg = AppConfig {
            bind_host: "127.0.0.1".to_string(),
            app_port: 4815,
            rust_log: "info".to_string(),
            api_keys: "".to_string(),
            allowed_origins: "\u{0000}".to_string(),
            rate_limit_rps: 10,
            rate_limit_burst: 30,
            batch_concurrency_limit: 5,
        };
        let _ = build_cors(&cfg);
    }

    #[test]
    fn test_cors_valid_origin_with_one_invalid() {
        // One valid origin, one invalid (NUL byte) — covers the `tracing::warn!` Err branch
        // without triggering the empty-origins panic.
        let cfg = AppConfig {
            bind_host: "127.0.0.1".to_string(),
            app_port: 4815,
            rust_log: "info".to_string(),
            api_keys: "".to_string(),
            allowed_origins: "http://localhost,\u{0000}".to_string(),
            rate_limit_rps: 10,
            rate_limit_burst: 30,
            batch_concurrency_limit: 5,
        };
        // Should not panic — the valid origin is kept, the invalid one is skipped with a warning.
        let _ = build_cors(&cfg);
    }
}
