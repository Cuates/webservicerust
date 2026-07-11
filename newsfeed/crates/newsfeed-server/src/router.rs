//! Axum router construction and middleware stack assembly.
//!
//! Middleware is applied in this order (outer → inner):
//!   TraceLayer → CorsLayer → ApiKeyLayer → RateLimitLayer → Route dispatch

use std::sync::Arc;

use axum::{
    middleware as axum_middleware,
    routing::get,
    Router,
};
use tower_http::{
    cors::CorsLayer,
    trace::TraceLayer,
    request_id::{MakeRequestUuid, SetRequestIdLayer, PropagateRequestIdLayer},
};

use newsfeed_config::AppConfig;
use newsfeed_db::pool::AppState;
use newsfeed_constants::http::{API_ROUTE_PREFIX, PROJECT_NAME, HEALTH_ROUTE};

use crate::handlers;
use crate::middleware::api_key;
use tower_governor::governor::GovernorConfigBuilder;

/// Build and return the fully-configured Axum `Router`.
pub fn build(state: Arc<AppState>, cfg: &AppConfig) -> Router {
    let cors = build_cors(cfg);
    
    let governor_config = Arc::new(
        GovernorConfigBuilder::default()
            .per_second(cfg.rate_limit_rps)
            .burst_size(cfg.rate_limit_burst)
            .finish()
            .expect("Failed to build rate-limit config")
    );
    tracing::info!(
        rate_limit_rps = cfg.rate_limit_rps,
        rate_limit_burst = cfg.rate_limit_burst,
        "Rate limiting enabled (tower_governor, per-IP token bucket)"
    );
    let governor_layer = tower_governor::GovernorLayer::new(governor_config);

    let newsfeed_path = format!("{API_ROUTE_PREFIX}/{PROJECT_NAME}");

    Router::new()
        // ── Health check (no auth required) ──────────────────────────────────
        .route(HEALTH_ROUTE, get(handlers::health::handler))

        // ── Newsfeed routes ───────────────────────────────────────────────────
        // Standard HTTP methods are registered explicitly.
        // QUERY (non-standard) and unknown methods are caught by `any()` via a
        // method-level fallback on the same path.
        .route(
            &newsfeed_path,
            get(handlers::get::handler)
                .post(handlers::post::handler)
                .put(handlers::put::handler)
                .delete(handlers::delete::handler)
                .fallback(handlers::query::handler),
        )

        // ── Middleware stack ──────────────────────────────────────────────────
        // Applied in reverse order of .layer() calls (innermost first).
        .layer(axum_middleware::from_fn_with_state(
            Arc::clone(&state),
            api_key::api_key_middleware,
        ))
        .layer(governor_layer)
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
        .filter_map(|o| o.parse().ok())
        .collect();

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
