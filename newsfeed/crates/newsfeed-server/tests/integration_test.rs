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

#[tokio::test]
async fn test_rate_limiting_precedence() {
    let invalid_api_key = "wrong_key";

    let cfg = AppConfig {
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 1,
        rate_limit_burst: 1,
        batch_concurrency_limit: 5,
    };

    let state = create_test_state();
    let app = router::build(state, &cfg).layer(axum::middleware::from_fn(
        |mut req: axum::http::Request<axum::body::Body>, next: axum::middleware::Next| async move {
            req.extensions_mut()
                .insert(axum::extract::ConnectInfo(std::net::SocketAddr::from((
                    [127, 0, 0, 2], // different IP to avoid clashes with other tests
                    8080,
                ))));
            next.run(req).await
        },
    ));

    let limit_server = TestServer::new(app);

    // 1st request hits 401 Unauthorized because it gets through rate limiter
    let res1 = limit_server
        .post("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(invalid_api_key),
        )
        .add_header(
            axum::http::header::HeaderName::from_static("accept"),
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .text("invalid payload")
        .await;

    assert_eq!(res1.status_code(), StatusCode::UNAUTHORIZED);

    // 2nd request hits 429 Too Many Requests because rate limit fires BEFORE auth
    let res2 = limit_server
        .post("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(invalid_api_key),
        )
        .add_header(
            axum::http::header::HeaderName::from_static("accept"),
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .text("invalid payload")
        .await;

    assert_eq!(res2.status_code(), StatusCode::TOO_MANY_REQUESTS);
}

async fn create_live_postgres_state(
    docker: &testcontainers::clients::Cli,
) -> (
    std::sync::Arc<AppState>,
    testcontainers::Container<'_, testcontainers::GenericImage>,
) {
    use sqlx::Executor;
    use testcontainers::GenericImage;

    let image = testcontainers::RunnableImage::from(
        GenericImage::new("postgres", "15")
            .with_env_var("POSTGRES_USER", "postgres")
            .with_env_var("POSTGRES_PASSWORD", "postgres")
            .with_env_var("POSTGRES_DB", "db")
            .with_wait_for(testcontainers::core::WaitFor::message_on_stderr(
                "database system is ready to accept connections",
            )),
    );
    let node = docker.run(image);
    let port = node.get_host_port_ipv4(5432);
    let db_url = format!("postgres://postgres:postgres@localhost:{}/db", port);

    // ── 1. Schema init via a dedicated single-connection pool ─────────────────
    // Running the large SQL batch on the same pool used by AppState can leave
    // session-level state (e.g. search_path mutations) on a pooled connection.
    // Using a separate pool here guarantees AppState starts with clean connections.
    {
        let init_pool = sqlx::postgres::PgPoolOptions::new()
            .max_connections(1)
            .connect(&db_url)
            .await
            .expect("Failed to connect init pool to test postgres");
        let sql = include_str!("../../newsfeed-db/tests/sql/init_postgres.sql")
            .trim_start_matches('\u{feff}');
        init_pool
            .execute(sql)
            .await
            .expect("Failed to execute schema");
        // init_pool is dropped and all its connections closed here
    }

    // ── 2. Fresh pool for AppState ────────────────────────────────────────────
    let pool = sqlx::postgres::PgPoolOptions::new()
        .max_connections(2)
        .connect(&db_url)
        .await
        .expect("Failed to connect to test postgres");

    let mut api_keys = std::collections::HashSet::new();
    use sha2::Digest;
    let mut hasher = sha2::Sha256::new();
    hasher.update(b"nf_test_key_123");
    api_keys.insert(hex::encode(hasher.finalize()));

    (
        std::sync::Arc::new(AppState {
            db: newsfeed_db::pool::DbPool::Postgres(pool),
            api_keys,
            batch_concurrency_limit: 5,
        }),
        node,
    )
}

#[tokio::test]
async fn test_health_check_live_db() {
    let docker = testcontainers::clients::Cli::default();
    let (state, _node) = create_live_postgres_state(&docker).await;

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
    let server = TestServer::new(app);

    let response = server.get("/health").await;
    assert_eq!(response.status_code(), StatusCode::OK);
}

#[tokio::test]
async fn test_postgres_crud_lifecycle() {
    let docker = testcontainers::clients::Cli::default();
    let (state, _node) = create_live_postgres_state(&docker).await;

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
    let server = TestServer::new(app);
    let api_key = "nf_test_key_123";
    let accept = axum::http::header::ACCEPT;
    let accept_val = axum::http::header::HeaderValue::from_static("application/json");
    let content_type = axum::http::header::CONTENT_TYPE;
    let content_type_val =
        axum::http::header::HeaderValue::from_static("application/json; charset=utf-8");

    // ── POST: create a record ─────────────────────────────────────────────────
    let post_resp = server
        .post("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .json(&serde_json::json!({
            "title": "Integration Test Title",
            "image_url": "http://example.com/image.png",
            "feed_url": "http://example.com/feed",
            "actual_url": "http://example.com/actual",
            "publish_date": "2026-07-13 00:00:00"
        }))
        .await;
    assert_eq!(post_resp.status_code(), StatusCode::CREATED);

    // ── GET: read back the created record ─────────────────────────────────────
    let get_resp = server
        .get("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .await;
    assert_eq!(get_resp.status_code(), StatusCode::OK);
    let get_body: serde_json::Value = get_resp.json();
    assert_eq!(get_body["Status"], "Success");
    assert!(get_body["Count"].as_i64().unwrap_or(0) > 0);

    // ── GET: ETag caching — second identical GET should return 304 ────────────
    let first_etag = server
        .get("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .await
        .header("etag")
        .to_str()
        .unwrap()
        .to_owned();

    let cached_resp = server
        .get("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(
            axum::http::header::IF_NONE_MATCH,
            axum::http::header::HeaderValue::from_str(&first_etag).unwrap(),
        )
        .await;
    assert_eq!(cached_resp.status_code(), StatusCode::NOT_MODIFIED);

    // ── GET: ETag mismatch should return 200 OK ────────────
    let mismatch_resp = server
        .get("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(
            axum::http::header::IF_NONE_MATCH,
            axum::http::header::HeaderValue::from_static("\"wrong-etag\""),
        )
        .await;
    assert_eq!(mismatch_resp.status_code(), StatusCode::OK);

    // ── QUERY method: read using the non-standard QUERY HTTP verb ─────────────
    let query_resp = server
        .method(
            axum::http::Method::from_bytes(b"QUERY").unwrap(),
            "/api/newsfeed",
        )
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .json(&serde_json::json!({"title": "Integration Test Title"}))
        .await;
    assert_eq!(query_resp.status_code(), StatusCode::OK);
    let _query_body: serde_json::Value = query_resp.json();

    // ── QUERY: ETag caching path ──────────────────────────────────────────────
    let query_etag = server
        .method(
            axum::http::Method::from_bytes(b"QUERY").unwrap(),
            "/api/newsfeed",
        )
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .await
        .header("etag")
        .to_str()
        .unwrap()
        .to_owned();

    let cached_query_resp = server
        .method(
            axum::http::Method::from_bytes(b"QUERY").unwrap(),
            "/api/newsfeed",
        )
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(
            axum::http::header::IF_NONE_MATCH,
            axum::http::header::HeaderValue::from_str(&query_etag).unwrap(),
        )
        .await;
    assert_eq!(cached_query_resp.status_code(), StatusCode::NOT_MODIFIED);

    // ── QUERY: ETag mismatch should return 200 OK ────────────────────────────────
    let mismatch_query_resp = server
        .method(
            axum::http::Method::from_bytes(b"QUERY").unwrap(),
            "/api/newsfeed",
        )
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(
            axum::http::header::IF_NONE_MATCH,
            axum::http::header::HeaderValue::from_static("\"wrong-etag\""),
        )
        .await;
    assert_eq!(mismatch_query_resp.status_code(), StatusCode::OK);

    // ── QUERY: invalid JSON body should 400 ───────────────────────────────────
    let query_bad_json = server
        .method(
            axum::http::Method::from_bytes(b"QUERY").unwrap(),
            "/api/newsfeed",
        )
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .text("not json {")
        .await;
    assert_eq!(query_bad_json.status_code(), StatusCode::BAD_REQUEST);

    // ── PUT: update the record ────────────────────────────────────────────────
    let put_resp = server
        .put("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .json(&serde_json::json!({
            "title": "Integration Test Title",
            "image_url": "http://example.com/image-updated.png",
            "feed_url": "http://example.com/feed",
            "actual_url": "http://example.com/actual",
            "publish_date": "2026-07-14 00:00:00"
        }))
        .await;
    assert_eq!(put_resp.status_code(), StatusCode::OK);
    let put_body: serde_json::Value = put_resp.json();
    assert_eq!(put_body["Status"], "Success");

    // ── PUT: missing title should 422 ─────────────────────────────────────────
    let put_no_title = server
        .put("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .json(&serde_json::json!({"image_url": "no title provided"}))
        .await;
    assert_eq!(put_no_title.status_code(), StatusCode::UNPROCESSABLE_ENTITY);

    // ── PUT: bad Accept header should 400 ─────────────────────────────────────
    let put_bad_header = server
        .put("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(
            accept.clone(),
            axum::http::header::HeaderValue::from_static("text/html"),
        )
        .add_header(content_type.clone(), content_type_val.clone())
        .json(&serde_json::json!({"title": "Test"}))
        .await;
    assert_eq!(put_bad_header.status_code(), StatusCode::BAD_REQUEST);

    // ── DELETE: remove the record ─────────────────────────────────────────────
    let delete_resp = server
        .delete("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .json(&serde_json::json!({
            "title": "Integration Test Title"
        }))
        .await;
    assert_eq!(delete_resp.status_code(), StatusCode::OK);
    let delete_body: serde_json::Value = delete_resp.json();
    assert_eq!(delete_body["Status"], "Success");

    // ── DELETE: missing title should 422 ──────────────────────────────────────
    let delete_no_title = server
        .delete("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .json(&serde_json::json!({"image_url": "no title provided"}))
        .await;
    assert_eq!(
        delete_no_title.status_code(),
        StatusCode::UNPROCESSABLE_ENTITY
    );

    // ── DELETE: bad Accept header should 400 ──────────────────────────────────
    let delete_bad_header = server
        .delete("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(
            accept.clone(),
            axum::http::header::HeaderValue::from_static("text/html"),
        )
        .add_header(content_type.clone(), content_type_val.clone())
        .json(&serde_json::json!({"title": "Test"}))
        .await;
    assert_eq!(delete_bad_header.status_code(), StatusCode::BAD_REQUEST);

    let unknown_verb = server
        .method(
            axum::http::Method::from_bytes(b"PATCH").unwrap(),
            "/api/newsfeed",
        )
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .await;
    assert_eq!(unknown_verb.status_code(), StatusCode::METHOD_NOT_ALLOWED);
}

#[tokio::test]
async fn test_not_found() {
    let server = create_test_server();
    let response = server.get("/api/unknown/route/does/not/exist").await;
    assert_eq!(response.status_code(), StatusCode::NOT_FOUND);

    let body: serde_json::Value = response.json();
    assert_eq!(body["Status"], "Error");
    assert_eq!(body["Code"], "ERROR");
}

#[tokio::test]
async fn test_post_invalid_header_charset() {
    let server = create_test_server();

    let response = server
        .post("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static("nf_test_key_123"),
        )
        .add_header(
            axum::http::header::CONTENT_TYPE,
            axum::http::header::HeaderValue::from_static("application/json; charset=invalid"),
        )
        .add_header(
            axum::http::header::ACCEPT,
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .json(&serde_json::json!([{"title": "Test"}]))
        .await;

    assert_eq!(response.status_code(), StatusCode::BAD_REQUEST);
}

#[tokio::test]
async fn test_query_invalid_header() {
    let server = create_test_server();

    let response = server
        .method(
            axum::http::Method::from_bytes(b"QUERY").unwrap(),
            "/api/newsfeed",
        )
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static("nf_test_key_123"),
        )
        .add_header(
            axum::http::header::ACCEPT,
            axum::http::header::HeaderValue::from_static("text/html"),
        )
        .await;

    assert_eq!(response.status_code(), StatusCode::BAD_REQUEST);
}

#[tokio::test]
async fn test_query_url_params() {
    let server = create_test_server();

    // Pass valid accept to get past validate_headers
    let response = server
        .method(
            axum::http::Method::from_bytes(b"QUERY").unwrap(),
            "/api/newsfeed?title=foo",
        )
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static("nf_test_key_123"),
        )
        .add_header(
            axum::http::header::ACCEPT,
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .await;

    assert_eq!(response.status_code(), StatusCode::INTERNAL_SERVER_ERROR); // Will fail in fake pool, but hits URL parsing!
}

#[tokio::test]
async fn test_query_large_body() {
    let server = create_test_server();

    // Generate a 2MB string
    let huge_string = "a".repeat(2 * 1024 * 1024);

    let response = server
        .method(
            axum::http::Method::from_bytes(b"QUERY").unwrap(),
            "/api/newsfeed",
        )
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static("nf_test_key_123"),
        )
        .add_header(
            axum::http::header::ACCEPT,
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .text(&huge_string)
        .await;

    assert_eq!(response.status_code(), StatusCode::BAD_REQUEST); // Hits axum::body::to_bytes size limit
}

#[tokio::test]
async fn test_query_invalid_json_body() {
    let server = create_test_server();

    let response = server
        .method(
            axum::http::Method::from_bytes(b"QUERY").unwrap(),
            "/api/newsfeed",
        )
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static("nf_test_key_123"),
        )
        .add_header(
            axum::http::header::ACCEPT,
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .text("{ invalid json }")
        .await;

    assert_eq!(response.status_code(), StatusCode::BAD_REQUEST);
}

#[tokio::test]
async fn test_post_db_error() {
    let server = create_test_server();
    let response = server
        .post("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static("nf_test_key_123"),
        )
        .add_header(
            axum::http::header::CONTENT_TYPE,
            axum::http::header::HeaderValue::from_static("application/json; charset=utf-8"),
        )
        .add_header(
            axum::http::header::ACCEPT,
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .json(&serde_json::json!([{
            "title": "Valid title, but DB will fail",
            "feed_url": "http://example.com"
        }]))
        .await;

    let _body: serde_json::Value = response.json();
    assert_eq!(response.status_code(), StatusCode::INTERNAL_SERVER_ERROR);
    let body: serde_json::Value = response.json();
    assert_eq!(body["Code"], "DB_ERROR");
}

#[tokio::test]
async fn test_get_db_error() {
    let server = create_test_server();
    let response = server
        .get("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static("nf_test_key_123"),
        )
        .add_header(
            axum::http::header::ACCEPT,
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .await;

    assert_eq!(response.status_code(), StatusCode::INTERNAL_SERVER_ERROR);
    let body: serde_json::Value = response.json();
    assert_eq!(body["Code"], "DB_ERROR");
}

#[tokio::test]
async fn test_query_db_error() {
    let server = create_test_server();
    let response = server
        .method(
            axum::http::Method::from_bytes(b"QUERY").unwrap(),
            "/api/newsfeed",
        )
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static("nf_test_key_123"),
        )
        .add_header(
            axum::http::header::CONTENT_TYPE,
            axum::http::header::HeaderValue::from_static("application/json; charset=utf-8"),
        )
        .add_header(
            axum::http::header::ACCEPT,
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .json(&serde_json::json!({
            "title": "Search title, but DB will fail"
        }))
        .await;

    assert_eq!(response.status_code(), StatusCode::INTERNAL_SERVER_ERROR);
    let body: serde_json::Value = response.json();
    assert_eq!(body["Code"], "DB_ERROR");
}

#[tokio::test]
async fn test_put_db_error() {
    let server = create_test_server();
    let response = server
        .put("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static("nf_test_key_123"),
        )
        .add_header(
            axum::http::header::CONTENT_TYPE,
            axum::http::header::HeaderValue::from_static("application/json; charset=utf-8"),
        )
        .add_header(
            axum::http::header::ACCEPT,
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .json(&serde_json::json!([{
            "title": "Valid title, but DB will fail"
        }]))
        .await;

    assert_eq!(response.status_code(), StatusCode::INTERNAL_SERVER_ERROR);
    let body: serde_json::Value = response.json();
    assert_eq!(body["Code"], "DB_ERROR");
}

#[tokio::test]
async fn test_delete_db_error() {
    let server = create_test_server();
    let response = server
        .delete("/api/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static("nf_test_key_123"),
        )
        .add_header(
            axum::http::header::CONTENT_TYPE,
            axum::http::header::HeaderValue::from_static("application/json; charset=utf-8"),
        )
        .add_header(
            axum::http::header::ACCEPT,
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .json(&serde_json::json!([{
            "title": "Valid title, but DB will fail"
        }]))
        .await;

    assert_eq!(response.status_code(), StatusCode::INTERNAL_SERVER_ERROR);
    let body: serde_json::Value = response.json();
    assert_eq!(body["Code"], "DB_ERROR");
}
