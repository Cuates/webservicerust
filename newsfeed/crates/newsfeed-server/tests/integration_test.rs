use axum::http::StatusCode;
use axum_test::TestServer;
use sha2::{Digest, Sha256};
use std::collections::HashSet;
use std::sync::Arc;

use newsfeed_config::AppConfig;
use newsfeed_db::pool::{AppState, DbPool};
use newsfeed_server::router;

/// Helper to create a fake app state for testing routing and middleware
fn create_test_state() -> Arc<AppState> {
    // Create a lazy pool so it doesn't actually connect to a real database
    let fake_pool = sqlx::postgres::PgPoolOptions::new()
        .connect_lazy("postgres://fake:fake@localhost/fake")
        .expect("Failed to create lazy pool");

    let mut api_keys = HashSet::new();
    let plaintext_key = "nf_test_key_123";
    let mut hasher = Sha256::new();
    hasher.update(plaintext_key.as_bytes());
    let hash_hex = hex::encode(hasher.finalize());
    api_keys.insert(hash_hex);

    Arc::new(AppState {
        db: DbPool::Postgres(fake_pool),
        api_keys,
        batch_concurrency_limit: 5,
    })
}

fn create_test_server() -> TestServer {
    let cfg = AppConfig {
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 100,
        rate_limit_burst: 100,
        batch_concurrency_limit: 5,
    };

    let state = create_test_state();
    let app = router::build(state, &cfg).layer(axum::middleware::from_fn(
        |mut req: axum::http::Request<axum::body::Body>, next: axum::middleware::Next| async move {
            req.extensions_mut()
                .insert(axum::extract::ConnectInfo(std::net::SocketAddr::from((
                    [127, 0, 0, 1],
                    8080,
                ))));
            next.run(req).await
        },
    ));

    TestServer::new(app)
}

#[tokio::test]
async fn test_health_check() {
    let server = create_test_server();
    let response = server.get("/health").await;
    // Note: We expect 503 SERVICE_UNAVAILABLE here because the test state uses
    // a lazy `sqlx` Postgres pool (`postgres://fake:fake@localhost/fake`).
    // Since we deferred `testcontainers` DB integration for now, the health check
    // correctly fails to ping the fake database and returns 503.
    response.assert_status(StatusCode::SERVICE_UNAVAILABLE);
}

#[tokio::test]
async fn test_swagger_ui() {
    let server = create_test_server();
    let response = server.get("/api/newsfeed/swagger-ui/").await;
    // Should be OK or REDIRECT, not 401
    assert_ne!(response.status_code(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn test_unauthenticated_request() {
    let server = create_test_server();
    let response = server.get("/api/newsfeed").await;

    assert_eq!(response.status_code(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn test_invalid_api_key() {
    let server = create_test_server();
    let response = server
        .get("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static("nf_invalid_key"),
        )
        .await;

    assert_eq!(response.status_code(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn test_invalid_json_payload() {
    let server = create_test_server();
    let valid_api_key = "nf_test_key_123";

    // 1. Test missing Content-Type (triggers 415 via AppJson)
    let response_415 = server
        .post("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(valid_api_key),
        )
        // deliberately send as text to avoid Content-Type: application/json
        .text("not json at all")
        .await;

    assert_eq!(
        response_415.status_code(),
        StatusCode::UNSUPPORTED_MEDIA_TYPE
    );
    let error_body_415: serde_json::Value = response_415.json(); // should parse successfully as JSON
    assert_eq!(error_body_415["Status"], "Error");
    assert_eq!(error_body_415["Code"], "BAD_REQUEST");

    // 2. Test valid JSON but missing mandatory fields (triggers custom 422)
    let response_422 = server
        .post("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(valid_api_key),
        )
        .add_header(
            axum::http::header::HeaderName::from_static("content-type"),
            axum::http::header::HeaderValue::from_static("application/json; charset=utf-8"),
        )
        .add_header(
            axum::http::header::HeaderName::from_static("accept"),
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .json(&serde_json::json!({
            "feed_url": "Missing title which is mandatory for POST"
        }))
        .await;

    assert_eq!(response_422.status_code(), StatusCode::UNPROCESSABLE_ENTITY);
    let error_body_422: serde_json::Value = response_422.json();
    assert_eq!(error_body_422["Status"], "Error");
    assert_eq!(error_body_422["Code"], "VALIDATION_ERROR");
}

#[tokio::test]
async fn test_cors_headers_on_get() {
    let server = create_test_server();
    let valid_api_key = "nf_test_key_123";

    let response = server
        .get("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(valid_api_key),
        )
        .add_header(
            axum::http::header::HeaderName::from_static("origin"),
            axum::http::header::HeaderValue::from_static("http://localhost"),
        )
        .await;

    // It might return 503 from the DB layer but it should still have CORS headers attached
    let allow_origin = response.header("access-control-allow-origin");
    assert_eq!(allow_origin.to_str().unwrap(), "http://localhost");
}

#[tokio::test]
async fn test_rate_limiting() {
    let valid_api_key = "nf_test_key_123";

    // Since our test config uses rate_limit_burst = 100, we'll need to hit it 101 times
    // However, to keep the test fast, we can just assume the middleware is tested if we
    // at least verify it allows normal requests. But to truly test rate limiting, we would
    // need to configure the burst to 1 for the test.
    // Since we don't want to change the create_test_server default for other tests,
    // we'll create a custom tight-limit server here.

    let cfg = AppConfig {
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 1,
        rate_limit_burst: 1, // Max 1 request
        batch_concurrency_limit: 5,
    };

    let state = create_test_state();
    let app = router::build(state, &cfg).layer(axum::middleware::from_fn(
        |mut req: axum::http::Request<axum::body::Body>, next: axum::middleware::Next| async move {
            req.extensions_mut()
                .insert(axum::extract::ConnectInfo(std::net::SocketAddr::from((
                    [127, 0, 0, 1],
                    8080,
                ))));
            next.run(req).await
        },
    ));

    let limit_server = TestServer::new(app);

    // 1st request should be fine through rate limit (but hit 415 or 422 instantly
    // because we deliberately send an invalid payload to avoid the 60s DB timeout).
    let res1 = limit_server
        .post("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(valid_api_key),
        )
        .add_header(
            axum::http::header::HeaderName::from_static("accept"),
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .text("invalid payload")
        .await;

    assert_ne!(res1.status_code(), StatusCode::TOO_MANY_REQUESTS);

    // 2nd request in quick succession should hit 429 Too Many Requests
    let res2 = limit_server
        .post("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(valid_api_key),
        )
        .add_header(
            axum::http::header::HeaderName::from_static("accept"),
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .text("invalid payload")
        .await;

    assert_eq!(res2.status_code(), StatusCode::TOO_MANY_REQUESTS);
}
