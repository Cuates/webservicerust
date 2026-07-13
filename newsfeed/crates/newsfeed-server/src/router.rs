//! Axum router construction and middleware stack assembly.
//!
//! Middleware effective order (outer → inner):
//!   RequestId → TraceLayer → CorsLayer → RequestBodyLimit → ApiKeyLayer → RateLimitLayer → Route dispatch
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

use newsfeed_config::AppConfig;
use newsfeed_constants::http::{API_ROUTE_PREFIX, HEALTH_ROUTE, PROJECT_NAME};
use newsfeed_db::pool::AppState;

use crate::handlers;
use crate::middleware::api_key;
use tower_governor::governor::GovernorConfigBuilder;

/// Maximum accepted request body size for CUD endpoints (bytes).
const MAX_BODY_BYTES: usize = 1024 * 1024; // 1 MiB

/// Build and return the fully-configured Axum `Router`.
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
            "RATE_LIMIT_EXCEEDED",
            "Too many requests. Please wait and try again.",
        );
        (
            axum::http::StatusCode::TOO_MANY_REQUESTS,
            axum::Json(payload),
        )
            .into_response()
    });

    let newsfeed_path = format!("{API_ROUTE_PREFIX}/{PROJECT_NAME}");

    use crate::openapi::ApiDoc;
    use utoipa::OpenApi;
    use utoipa_swagger_ui::SwaggerUi;

    let api_routes = Router::new()
        .route(
            &newsfeed_path,
            get(handlers::get::handler)
                .post(handlers::post::handler)
                .put(handlers::put::handler)
                .delete(handlers::delete::handler)
                .fallback(handlers::query::handler),
        )
        .layer(governor_layer)
        .layer(axum_middleware::from_fn_with_state(
            Arc::clone(&state),
            api_key::api_key_middleware,
        ));

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

    if origins.is_empty() {
        panic!(
            "No valid ALLOWED_ORIGINS configured — all CORS preflight requests will \
             be rejected. Check the ALLOWED_ORIGINS env var for typos."
        );
    }

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
