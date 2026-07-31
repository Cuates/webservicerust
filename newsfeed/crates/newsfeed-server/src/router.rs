//! Axum router construction and middleware stack assembly.
//!
//! Middleware effective order (outer → inner):
//!   `RequestId` → `TraceLayer` → `CorsLayer` → `RequestBodyLimit` → `RateLimitLayer` → `ApiKeyLayer` → Route dispatch
//!
//! CORS sits outermost so browser OPTIONS preflight requests are handled and
//! short-circuited before consuming rate-limit tokens or being checked for an
//! API key (preflight does not carry one).

use std::sync::Arc;

use axum::{
    Router, handler::Handler, middleware as axum_middleware, response::IntoResponse, routing::get,
};
use tower_http::{
    catch_panic::CatchPanicLayer,
    cors::CorsLayer,
    limit::RequestBodyLimitLayer,
    request_id::{MakeRequestUuid, PropagateRequestIdLayer, SetRequestIdLayer},
    timeout::TimeoutLayer,
    trace::TraceLayer,
};
use utoipa::OpenApi;

use newsfeed_config::AppConfig;
use newsfeed_constants::http::{
    API_ROUTE_PREFIX, HEALTH_LIVE_ROUTE, HEALTH_READY_ROUTE, PROJECT_NAME,
};
use newsfeed_db::pool::AppState;

use crate::handlers;
use crate::middleware::{api_key, ip_extractor::SecureIpExtractor};
use crate::openapi::ApiDoc;
use newsfeed_constants::http::{ResponseCode, ResponseMessage};
use tower_governor::governor::GovernorConfigBuilder;

/// Maximum accepted request body size for CUD endpoints (bytes).
const MAX_BODY_BYTES: usize = 1024 * 1024; // 1 MiB

#[allow(clippy::needless_pass_by_value)]
fn handle_panic(err: Box<dyn std::any::Any + Send + 'static>) -> axum::response::Response {
    let details = if let Some(s) = err.downcast_ref::<String>() {
        s.clone()
    } else if let Some(s) = err.downcast_ref::<&str>() {
        s.to_string()
    } else {
        "Unknown panic".to_string()
    };
    tracing::error!("Service panicked: {details}");

    let payload = newsfeed_models::ApiResponse::<serde_json::Value>::error_with_code(
        ResponseCode::INTERNAL_ERROR,
        "Internal Server Error",
    );
    (
        axum::http::StatusCode::INTERNAL_SERVER_ERROR,
        axum::Json(payload),
    )
        .into_response()
}

/// Build and return the fully-configured Axum `Router`.
#[allow(clippy::expect_used)]
pub fn build(state: Arc<AppState>, cfg: &AppConfig) -> Router {
    let cors = build_cors(cfg);

    let governor_config = Arc::new(
        GovernorConfigBuilder::default()
            .per_second(cfg.rate_limit_rps)
            .burst_size(cfg.rate_limit_burst)
            .key_extractor(SecureIpExtractor::new(cfg.trust_proxy, cfg.proxy_cidrs()))
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

    let standard_timeout = TimeoutLayer::with_status_code(
        axum::http::StatusCode::REQUEST_TIMEOUT,
        std::time::Duration::from_secs(cfg.timeout_standard_secs),
    );

    let extended_timeout = TimeoutLayer::with_status_code(
        axum::http::StatusCode::REQUEST_TIMEOUT,
        std::time::Duration::from_secs(cfg.timeout_cud_secs),
    );

    let api_routes = Router::new()
        .route(
            &newsfeed_path,
            get(handlers::get::handler.layer(standard_timeout))
                .post(handlers::cud::post_handler.layer(extended_timeout))
                .put(handlers::cud::put_handler.layer(extended_timeout))
                .delete(handlers::cud::delete_handler.layer(extended_timeout)),
        )
        .layer(axum_middleware::from_fn_with_state(
            Arc::clone(&state),
            api_key::api_key_middleware,
        ))
        .layer(governor_layer);

    Router::new()
        // ── Health checks & Docs (no auth required) ───────────────────────────
        .route(
            HEALTH_LIVE_ROUTE,
            get(handlers::health::live_handler.layer(standard_timeout)),
        )
        .route(
            HEALTH_READY_ROUTE,
            get(handlers::health::ready_handler.layer(standard_timeout)),
        )
        .route(
            "/api-docs/openapi.json",
            get((|| async { axum::Json(ApiDoc::openapi()) }).layer(standard_timeout)),
        )
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
        // ── Catch panics (outermost) ──────────────────────────────────────────
        .layer(CatchPanicLayer::custom(handle_panic))
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
            trust_proxy: false,
            trusted_proxy_cidr: None,
            timeout_standard_secs: 10,
            timeout_cud_secs: 60,
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
            trust_proxy: false,
            trusted_proxy_cidr: None,
            timeout_standard_secs: 10,
            timeout_cud_secs: 60,
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
            trust_proxy: false,
            trusted_proxy_cidr: None,
            timeout_standard_secs: 10,
            timeout_cud_secs: 60,
        };
        // Should not panic — the valid origin is kept, the invalid one is skipped with a warning.
        let _ = build_cors(&cfg);
    }

    #[test]
    fn test_handle_panic() {
        let r1 = super::handle_panic(Box::new("String panic".to_string()));
        assert_eq!(r1.status(), axum::http::StatusCode::INTERNAL_SERVER_ERROR);

        let r2 = super::handle_panic(Box::new("str panic"));
        assert_eq!(r2.status(), axum::http::StatusCode::INTERNAL_SERVER_ERROR);

        let r3 = super::handle_panic(Box::new(12345));
        assert_eq!(r3.status(), axum::http::StatusCode::INTERNAL_SERVER_ERROR);
    }
}
