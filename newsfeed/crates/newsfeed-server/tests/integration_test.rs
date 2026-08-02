#![allow(clippy::unwrap_used, clippy::expect_used, clippy::pedantic)]

use axum::http::StatusCode;
use axum_test::TestServer;
use sha2::{Digest, Sha256};
use std::sync::Arc;

use newsfeed_config::AppConfig;
use newsfeed_db::pool::{AppState, DbPool};
use newsfeed_server::router;

/// Helper to create a fake app state for testing routing and middleware
fn create_test_state() -> Arc<AppState> {
    // Create a lazy pool so it doesn't actually connect to a real database
    let fake_pool = sqlx::postgres::PgPoolOptions::new()
        .acquire_timeout(std::time::Duration::from_millis(1))
        .connect_lazy("postgres://fake:fake@255.255.255.255/fake")
        .expect("Failed to create lazy pool");

    let plaintext_key = "nf_test_key_123";
    let mut hasher = Sha256::new();
    hasher.update(plaintext_key.as_bytes());
    let hash_bytes: [u8; 32] = hasher.finalize().into();

    Arc::new(AppState {
        is_healthy: std::sync::atomic::AtomicBool::new(true).into(),
        db: DbPool::Postgres(fake_pool),
        api_keys: vec![hash_bytes],
    })
}

fn create_test_server() -> TestServer {
    let cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 100,
        rate_limit_burst: 100,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
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
    let state = create_test_state();
    state
        .is_healthy
        .store(false, std::sync::atomic::Ordering::Relaxed);

    let cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 100,
        rate_limit_burst: 100,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
    };
    let app = router::build(state, &cfg);
    let server = TestServer::new(app);

    let response_ready = server.get("/health/ready").await;
    response_ready.assert_status(StatusCode::SERVICE_UNAVAILABLE);

    let response_live = server.get("/health/live").await;
    response_live.assert_status(StatusCode::OK);
}

#[tokio::test]
async fn test_openapi_json() {
    let server = create_test_server();
    let response = server
        .get("/api-docs/openapi.json")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static("nf_test_key_123"),
        )
        .await;
    assert_eq!(response.status_code(), StatusCode::OK);
}

#[tokio::test]
async fn test_unauthenticated_request() {
    let server = create_test_server();
    let response = server.get("/api/v1/newsfeed").await;

    assert_eq!(response.status_code(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn test_invalid_api_key() {
    let server = create_test_server();
    let response = server
        .get("/api/v1/newsfeed")
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
        .post("/api/v1/newsfeed")
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
    assert_eq!(error_body_415["Code"], "INVALID_HEADER");

    // 2. Test valid JSON but missing mandatory fields (triggers custom 422)
    let response_422 = server
        .post("/api/v1/newsfeed")
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
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!({
                "feed_url": "Missing title which is mandatory for POST"
            }))
            .unwrap(),
        ))
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
        .get("/api/v1/newsfeed")
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
async fn test_post_duplicate_titles_rejected() {
    let server = create_test_server();
    let valid_api_key = "nf_test_key_123";

    let payload = serde_json::json!({
        "items": [
            { "title": "Dup Title", "feed_url": "http://example.com/1" },
            { "title": "Dup Title", "feed_url": "http://example.com/2" }
        ]
    });

    let response = server
        .post("/api/v1/newsfeed")
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
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&payload).unwrap(),
        ))
        .await;

    assert_eq!(response.status_code(), StatusCode::UNPROCESSABLE_ENTITY);
    let error_body: serde_json::Value = response.json();
    assert_eq!(error_body["Code"], "DUPLICATE_TITLES");
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
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 1,
        rate_limit_burst: 1, // Max 1 request,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
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
        .post("/api/v1/newsfeed")
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
        .post("/api/v1/newsfeed")
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
    let body: serde_json::Value = res2.json();
    assert_eq!(body["Code"], "RATE_LIMIT_EXCEEDED");
}

#[tokio::test]
async fn test_rate_limiting_precedence() {
    let invalid_api_key = "wrong_key";

    let cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 1,
        rate_limit_burst: 1,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
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
        .post("/api/v1/newsfeed")
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
        .post("/api/v1/newsfeed")
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
    let body: serde_json::Value = res2.json();
    assert_eq!(body["Code"], "RATE_LIMIT_EXCEEDED");
}

async fn create_live_postgres_state(
    docker: &testcontainers::clients::Cli,
) -> (
    std::sync::Arc<AppState>,
    Option<testcontainers::Container<'_, testcontainers::GenericImage>>,
) {
    use sqlx::Executor;
    use testcontainers::GenericImage;

    let (db_url, node) = if let Ok(url) = std::env::var("TEST_POSTGRES_URL") {
        (url, None)
    } else {
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
        let url = format!("postgres://postgres:postgres@localhost:{}/db", port);
        (url, Some(node))
    };

    // ── 1. Schema init via a dedicated single-connection pool ─────────────────
    {
        let mut retries = 10;
        let mut init_pool = None;
        while retries > 0 {
            match sqlx::postgres::PgPoolOptions::new()
                .max_connections(1)
                .connect(&db_url)
                .await
            {
                Ok(p) => {
                    init_pool = Some(p);
                    break;
                }
                Err(e) => {
                    println!("Postgres connect not ready yet, retrying... ({})", e);
                    tokio::time::sleep(std::time::Duration::from_millis(500)).await;
                    retries -= 1;
                }
            }
        }
        let init_pool = init_pool.expect("Failed to connect init pool to test postgres");
        let sql =
            include_str!("../../newsfeed-db/migrations/postgres/20260718000000_init_postgres.sql")
                .trim_start_matches('\u{feff}');
        init_pool
            .execute(sql)
            .await
            .expect("Failed to execute schema");
    }

    use sha2::Digest;
    let mut hasher = sha2::Sha256::new();
    hasher.update(b"nf_test_key_123");
    let hashed_key = hex::encode(hasher.finalize());

    let app_cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 8080,
        rust_log: "info".to_string(),
        api_keys: hashed_key,
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 10,
        rate_limit_burst: 20,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
    };

    let db_cfg = newsfeed_config::DatabaseConfig {
        database_target: newsfeed_config::DatabaseTarget::Postgres,
        postgres_url: Some(db_url),
        mariadb_url: None,
        mssql_host: None,
        mssql_port: None,
        mssql_database: None,
        mssql_username: None,
        mssql_password: None,
        db_mssql_encrypt: false,
        db_mssql_trust_cert: false,
        db_pool_max: 2,
        db_pool_min: 1,
        db_acquire_timeout_secs: 10,
    };

    let mut retries = 10;
    let mut app_state = None;
    while retries > 0 {
        match newsfeed_db::pool::AppState::init(&app_cfg, &db_cfg).await {
            Ok(state) => {
                app_state = Some(state);
                break;
            }
            Err(e) => {
                println!("Postgres AppState not ready yet, retrying... ({})", e);
                tokio::time::sleep(std::time::Duration::from_millis(500)).await;
                retries -= 1;
            }
        }
    }
    let state = app_state.expect("Failed to init AppState for Postgres");

    (std::sync::Arc::new(state), node)
}

async fn create_live_mariadb_state(
    docker: &testcontainers::clients::Cli,
) -> (
    std::sync::Arc<AppState>,
    Option<testcontainers::Container<'_, testcontainers::GenericImage>>,
) {
    use sqlx::Executor;
    use testcontainers::GenericImage;

    let (db_url, node) = if let Ok(url) = std::env::var("TEST_MARIADB_URL") {
        (url, None)
    } else {
        let image = testcontainers::RunnableImage::from(
            GenericImage::new("mariadb", "10.6")
                .with_env_var("MYSQL_ROOT_PASSWORD", "root")
                .with_env_var("MYSQL_DATABASE", "db")
                .with_wait_for(testcontainers::core::WaitFor::message_on_stderr(
                    "ready for connections",
                )),
        );
        let node = docker.run(image);
        let port = node.get_host_port_ipv4(3306);
        let url = format!("mysql://root:root@localhost:{}/db", port);
        (url, Some(node))
    };

    {
        let mut retries = 10;
        let mut init_pool = None;
        while retries > 0 {
            match sqlx::mysql::MySqlPoolOptions::new()
                .max_connections(1)
                .connect(&db_url)
                .await
            {
                Ok(p) => {
                    init_pool = Some(p);
                    break;
                }
                Err(e) => {
                    println!("MariaDB connect not ready yet, retrying... ({})", e);
                    tokio::time::sleep(std::time::Duration::from_millis(500)).await;
                    retries -= 1;
                }
            }
        }
        let init_pool = init_pool.expect("Failed to connect init pool to test mariadb");

        let schema =
            include_str!("../../newsfeed-db/migrations/mariadb/20260718000000_init_mariadb.sql");
        let schema = schema
            .trim_start_matches('\u{feff}')
            .replace("DEFINER=`gojeda`@`%`", "");

        let mut current_delimiter = ";";
        let mut buffer = String::new();
        let mut conn = init_pool.acquire().await.unwrap();

        for line in schema.lines() {
            if line.starts_with("DELIMITER ") {
                current_delimiter = line.trim_start_matches("DELIMITER ").trim();
                continue;
            }
            buffer.push_str(line);
            buffer.push('\n');

            if line.trim().ends_with(current_delimiter) {
                let stmt = buffer
                    .trim_end_matches('\n')
                    .trim_end_matches(current_delimiter)
                    .trim();
                if !stmt.is_empty() {
                    conn.execute(stmt)
                        .await
                        .expect("Failed to execute mariadb statement");
                }
                buffer.clear();
            }
        }

        if !buffer.trim().is_empty() {
            conn.execute(buffer.as_str())
                .await
                .expect("Failed to execute mariadb statement");
        }
    }

    use sha2::Digest;
    let mut hasher = sha2::Sha256::new();
    hasher.update(b"nf_test_key_123");
    let hashed_key = hex::encode(hasher.finalize());

    let app_cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 8080,
        rust_log: "info".to_string(),
        api_keys: hashed_key,
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 10,
        rate_limit_burst: 20,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
    };

    let db_cfg = newsfeed_config::DatabaseConfig {
        database_target: newsfeed_config::DatabaseTarget::MariaDb,
        postgres_url: None,
        mariadb_url: Some(db_url),
        mssql_host: None,
        mssql_port: None,
        mssql_database: None,
        mssql_username: None,
        mssql_password: None,
        db_mssql_encrypt: false,
        db_mssql_trust_cert: false,
        db_pool_max: 2,
        db_pool_min: 1,
        db_acquire_timeout_secs: 10,
    };

    let mut retries = 10;
    let mut app_state = None;
    while retries > 0 {
        match newsfeed_db::pool::AppState::init(&app_cfg, &db_cfg).await {
            Ok(state) => {
                app_state = Some(state);
                break;
            }
            Err(e) => {
                println!("MariaDB AppState not ready yet, retrying... ({})", e);
                tokio::time::sleep(std::time::Duration::from_millis(500)).await;
                retries -= 1;
            }
        }
    }
    let state = app_state.expect("Failed to init AppState for MariaDB");

    (std::sync::Arc::new(state), node)
}

async fn execute_mssql_script_str(
    client: &mut tiberius::Client<tokio_util::compat::Compat<tokio::net::TcpStream>>,
    script: &str,
) {
    let mut batch = String::new();
    for line in script.lines() {
        if line.trim().eq_ignore_ascii_case("GO") {
            if !batch.trim().is_empty() {
                client.simple_query(&batch).await.unwrap();
                batch.clear();
            }
        } else {
            batch.push_str(line);
            batch.push('\n');
        }
    }
    if !batch.trim().is_empty() {
        client.simple_query(&batch).await.unwrap();
    }
}

async fn create_live_mssql_state(
    docker: &testcontainers::clients::Cli,
) -> (
    std::sync::Arc<AppState>,
    Option<testcontainers::Container<'_, testcontainers::GenericImage>>,
) {
    use testcontainers::GenericImage;
    use tiberius::{AuthMethod, Client, Config};
    use tokio::net::TcpStream;
    use tokio_util::compat::TokioAsyncWriteCompatExt;

    let (host, port, user, pass, db, node) = if let Ok(port_str) = std::env::var("TEST_MSSQL_PORT")
    {
        let port = port_str.parse::<u16>().unwrap_or(1433);
        let host = std::env::var("TEST_MSSQL_HOST").unwrap_or_else(|_| "localhost".to_string());
        let user = std::env::var("TEST_MSSQL_USER").unwrap_or_else(|_| "SA".to_string());
        let pass =
            std::env::var("TEST_MSSQL_PASSWORD").unwrap_or_else(|_| "Password123!".to_string());
        let db = std::env::var("TEST_MSSQL_DB").unwrap_or_else(|_| "media".to_string());
        (host, port, user, pass, db, None)
    } else if let Ok(_url_str) = std::env::var("TEST_MSSQL_URL") {
        (
            "localhost".to_string(),
            1433,
            "SA".to_string(),
            "Password123!".to_string(),
            "media".to_string(),
            None,
        )
    } else {
        let image = testcontainers::RunnableImage::from(
            GenericImage::new("mcr.microsoft.com/mssql/server", "2022-latest")
                .with_env_var("ACCEPT_EULA", "Y")
                .with_env_var("MSSQL_SA_PASSWORD", "Password123!")
                .with_wait_for(testcontainers::core::WaitFor::message_on_stdout(
                    "Service Broker manager has started",
                )),
        );
        let node = docker.run(image);
        let port = node.get_host_port_ipv4(1433);
        (
            "localhost".to_string(),
            port,
            "SA".to_string(),
            "Password123!".to_string(),
            "media".to_string(),
            Some(node),
        )
    };

    {
        let mut config = Config::new();
        config.host(&host);
        config.port(port);
        config.authentication(AuthMethod::sql_server(&user, &pass));
        config.trust_cert();

        let mut retries = 20;
        let mut client_res = None;
        while retries > 0 {
            match TcpStream::connect(config.get_addr()).await {
                Ok(tcp) => {
                    tcp.set_nodelay(true).unwrap();
                    match Client::connect(config.clone(), tcp.compat_write()).await {
                        Ok(client) => {
                            client_res = Some(client);
                            break;
                        }
                        Err(e) => {
                            println!("MSSQL TDS not ready yet, retrying... ({})", e);
                        }
                    }
                }
                Err(e) => {
                    println!("MSSQL TCP not ready yet, retrying... ({})", e);
                }
            }
            tokio::time::sleep(std::time::Duration::from_millis(500)).await;
            retries -= 1;
        }
        let mut client = client_res.expect("Failed to connect to mssql after retries");

        let schema =
            include_str!("../../newsfeed-db/migrations/mssql/20260718000000_init_mssql.sql")
                .trim_start_matches('\u{feff}');
        execute_mssql_script_str(&mut client, schema).await;
    }

    use sha2::Digest;
    let mut hasher = sha2::Sha256::new();
    hasher.update(b"nf_test_key_123");
    let hashed_key = hex::encode(hasher.finalize());

    let app_cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 8080,
        rust_log: "info".to_string(),
        api_keys: hashed_key,
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 10,
        rate_limit_burst: 20,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
    };

    let db_cfg = newsfeed_config::DatabaseConfig {
        database_target: newsfeed_config::DatabaseTarget::MsSql,
        postgres_url: None,
        mariadb_url: None,
        mssql_host: Some(host),
        mssql_port: Some(port),
        mssql_database: Some(db),
        mssql_username: Some(user),
        mssql_password: Some(pass),
        db_mssql_encrypt: false,
        db_mssql_trust_cert: true,
        db_pool_max: 2,
        db_pool_min: 1,
        db_acquire_timeout_secs: 10,
    };

    let mut retries = 10;
    let mut app_state = None;
    while retries > 0 {
        match newsfeed_db::pool::AppState::init(&app_cfg, &db_cfg).await {
            Ok(state) => {
                app_state = Some(state);
                break;
            }
            Err(e) => {
                println!("MSSQL AppState not ready yet, retrying... ({})", e);
                tokio::time::sleep(std::time::Duration::from_millis(500)).await;
                retries -= 1;
            }
        }
    }
    let state = app_state.expect("Failed to init AppState for MSSQL");

    (std::sync::Arc::new(state), node)
}

async fn create_live_state(
    docker: &testcontainers::clients::Cli,
) -> (
    std::sync::Arc<AppState>,
    Option<testcontainers::Container<'_, testcontainers::GenericImage>>,
) {
    let target = std::env::var("DATABASE_TARGET").unwrap_or_else(|_| "postgres".to_string());
    match target.to_lowercase().as_str() {
        "mariadb" | "mysql" => create_live_mariadb_state(docker).await,
        "mssql" | "sqlserver" => create_live_mssql_state(docker).await,
        _ => create_live_postgres_state(docker).await,
    }
}

#[tokio::test]
async fn test_health_check_live_db() {
    let docker = testcontainers::clients::Cli::default();
    let (state, _node) = create_live_state(&docker).await;

    let cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 100,
        rate_limit_burst: 100,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
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

    let response = server.get("/health/ready").await;
    assert_eq!(response.status_code(), StatusCode::OK);
}

#[tokio::test]
async fn test_db_crud_lifecycle() {
    let docker = testcontainers::clients::Cli::default();
    let (state, _node) = create_live_state(&docker).await;

    let cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 100,
        rate_limit_burst: 100,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
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

    // ── GET: read from empty DB ─────────────────────────────────────────────
    let get_empty = server
        .get("/api/v1/newsfeed?limit=10&sort=desc")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .await;
    assert_eq!(get_empty.status_code(), StatusCode::OK);
    let empty_body: serde_json::Value = get_empty.json();
    assert_eq!(empty_body["Status"], "Success");
    assert_eq!(empty_body["Count"].as_i64().unwrap_or(-1), 0);
    assert!(empty_body["Result"].as_array().unwrap().is_empty());

    // ── POST: create a record ─────────────────────────────────────────────────
    let post_resp = server
        .post("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!({
                "title": "Integration Test Title",
                "image_url": "http://example.com/image.png",
                "feed_url": "http://example.com/feed",
                "actual_url": "http://example.com/actual",
                "publish_date": "2026-07-13T00:00:00Z"
            }))
            .unwrap(),
        ))
        .await;
    assert_eq!(post_resp.status_code(), StatusCode::CREATED);

    // ── GET: read back the created record ─────────────────────────────────────
    let get_resp = server
        .get("/api/v1/newsfeed?limit=10&sort=desc")
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
        .get("/api/v1/newsfeed?limit=10&sort=desc")
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
        .get("/api/v1/newsfeed?limit=10&sort=desc")
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
        .get("/api/v1/newsfeed?limit=10&sort=desc")
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

    // ── PUT: update the record ────────────────────────────────────────────────
    let put_resp = server
        .put("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!({
                "title": "Integration Test Title",
                "image_url": "http://example.com/image-updated.png",
                "feed_url": "http://example.com/feed",
                "actual_url": "http://example.com/actual",
                "publish_date": "2026-07-14T00:00:00Z"
            }))
            .unwrap(),
        ))
        .await;
    assert_eq!(put_resp.status_code(), StatusCode::OK);
    let put_body: serde_json::Value = put_resp.json();
    assert_eq!(put_body["Status"], "Success");

    // ── PUT: missing title should 422 ─────────────────────────────────────────
    let put_no_title = server
        .put("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!({"image_url": "no title provided"})).unwrap(),
        ))
        .await;
    assert_eq!(put_no_title.status_code(), StatusCode::UNPROCESSABLE_ENTITY);

    // ── PUT: bad Accept header should 400 ─────────────────────────────────────
    let put_bad_header = server
        .put("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(
            accept.clone(),
            axum::http::header::HeaderValue::from_static("text/html"),
        )
        .add_header(content_type.clone(), content_type_val.clone())
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!({"title": "Test"})).unwrap(),
        ))
        .await;
    assert_eq!(put_bad_header.status_code(), StatusCode::BAD_REQUEST);

    // ── DELETE: remove the record ─────────────────────────────────────────────
    let delete_resp = server
        .delete("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!([{
                "title": "Integration Test Title",
                "publish_date": "2026-07-14T00:00:00Z"
            }]))
            .unwrap(),
        ))
        .await;
    assert_eq!(delete_resp.status_code(), StatusCode::OK);
    let delete_body: serde_json::Value = delete_resp.json();
    assert_eq!(delete_body["Status"], "Success");

    // ── DELETE: missing title should 422 ──────────────────────────────────────
    let delete_no_title = server
        .delete("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!({"image_url": "no title provided"})).unwrap(),
        ))
        .await;
    assert_eq!(
        delete_no_title.status_code(),
        StatusCode::UNPROCESSABLE_ENTITY
    );

    // ── DELETE: bad Accept header should 400 ──────────────────────────────────
    let delete_bad_header = server
        .delete("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(
            accept.clone(),
            axum::http::header::HeaderValue::from_static("text/html"),
        )
        .add_header(content_type.clone(), content_type_val.clone())
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!({"title": "Test"})).unwrap(),
        ))
        .await;
    assert_eq!(delete_bad_header.status_code(), StatusCode::BAD_REQUEST);

    let unknown_verb = server
        .method(
            axum::http::Method::from_bytes(b"PATCH").unwrap(),
            "/api/v1/newsfeed",
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
        .post("/api/v1/newsfeed")
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
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!([{"title": "Test"}])).unwrap(),
        ))
        .await;

    assert_eq!(response.status_code(), StatusCode::UNSUPPORTED_MEDIA_TYPE);
}

#[tokio::test]
async fn test_post_db_error() {
    let server = create_test_server();
    let response = server
        .post("/api/v1/newsfeed")
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
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!([{
                "title": "Valid title, but DB will fail",
                "feed_url": "http://example.com",
                "publish_date": "2026-07-26T00:00:00Z"
            }]))
            .unwrap(),
        ))
        .await;

    assert_eq!(response.status_code(), StatusCode::INTERNAL_SERVER_ERROR);
    let body: serde_json::Value = response.json();
    assert_eq!(body["Status"], "Error");
    assert_eq!(body["Code"], "DB_ERROR");
    assert_eq!(body["Message"], "Internal Server Error");
}

#[tokio::test]
async fn test_get_db_error() {
    let server = create_test_server();
    let response = server
        .get("/api/v1/newsfeed")
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
    assert_eq!(body["Status"], "Error");
    assert_eq!(body["Code"], "DB_ERROR");
    assert_eq!(body["Message"], "Internal Server Error");
}

#[tokio::test]
async fn test_put_db_error() {
    let server = create_test_server();
    let response = server
        .put("/api/v1/newsfeed")
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
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!([{
                "title": "Update", "publish_date": "2026-07-23T00:00:00Z"
            }]))
            .unwrap(),
        ))
        .await;

    assert_eq!(response.status_code(), StatusCode::INTERNAL_SERVER_ERROR);
    let body: serde_json::Value = response.json();
    assert_eq!(body["Status"], "Error");
    assert_eq!(body["Code"], "DB_ERROR");
    assert_eq!(body["Message"], "Internal Server Error");
}

#[tokio::test]
async fn test_delete_db_error() {
    let server = create_test_server();
    let response = server
        .delete("/api/v1/newsfeed")
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
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!([{
                "title": "Delete", "publish_date": "2026-07-23T00:00:00Z"
            }]))
            .unwrap(),
        ))
        .await;

    assert_eq!(response.status_code(), StatusCode::INTERNAL_SERVER_ERROR);
    let body: serde_json::Value = response.json();
    assert_eq!(body["Status"], "Error");
    assert_eq!(body["Code"], "DB_ERROR");
    assert_eq!(body["Message"], "Internal Server Error");
}

#[tokio::test]
async fn test_get_invalid_accept_header() {
    let server = create_test_server();
    let response = server
        .get("/api/v1/newsfeed")
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
async fn test_db_partial_failure() {
    let docker = testcontainers::clients::Cli::default();
    let (state, _node) = create_live_state(&docker).await;
    let cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 100,
        rate_limit_burst: 100,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
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
    // Send a bulk PUT with two items. The first will fail because it does not exist.
    // The second could theoretically succeed if it existed, but since neither exists,
    // they will both fail. But even one failure triggers BAD_REQUEST.
    let put_resp = server
        .put("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!([
                {
                    "title": "Duplicate Title",
                    "feed_url": "http://example.com/feed1",
                    "publish_date": "2026-07-23T00:00:00Z"
                },
                {
                    "title": "Another Title",
                    "feed_url": "http://example.com/feed2",
                    "publish_date": "2026-07-23T01:00:00Z"
                }
            ]))
            .unwrap(),
        ))
        .await;

    // It should return OK because non-existent updates are now Skipped, not Errors
    assert_eq!(put_resp.status_code(), StatusCode::OK);

    let body: serde_json::Value = put_resp.json();
    assert_eq!(body["Status"], "Success");
    assert!(
        body["FailedItems"]
            .as_array()
            .map(|a| a.is_empty())
            .unwrap_or(true)
    );
}

#[tokio::test]
async fn test_db_true_partial_success() {
    let docker = testcontainers::clients::Cli::default();
    let (state, _node) = create_live_state(&docker).await;
    let cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 100,
        rate_limit_burst: 100,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
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

    // POST two feeds: feed1 (missing feed_url -> error) and feed2 (valid -> success)
    let post_resp = server
        .post("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!([
                {
                    "title": "Feed One (Invalid)",
                    "publish_date": "2026-07-23T00:00:00Z"
                },
                {
                    "title": "Feed Two (Valid)",
                    "feed_url": "http://example.com/feed2",
                    "publish_date": "2026-07-23T01:00:00Z"
                }
            ]))
            .unwrap(),
        ))
        .await;

    let body: serde_json::Value = post_resp.json();
    assert_eq!(body["Status"], "Error");
}

#[tokio::test]
async fn test_cud_endpoint_unsupported_content_type() {
    let server = create_test_server();
    let valid_api_key = "nf_test_key_123";

    let response = server
        .post("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(valid_api_key),
        )
        .add_header(
            axum::http::header::HeaderName::from_static("content-type"),
            axum::http::header::HeaderValue::from_static("text/plain"),
        )
        .text("not json")
        .await;

    assert_eq!(response.status_code(), StatusCode::UNSUPPORTED_MEDIA_TYPE);
    let body: serde_json::Value = response.json();
    assert_eq!(body["Status"], "Error");
    assert_eq!(body["Code"], "INVALID_HEADER");
}

#[tokio::test]
async fn test_cud_endpoint_deny_unknown_fields_http_400() {
    let server = create_test_server();
    let valid_api_key = "nf_test_key_123";

    let response = server
        .post("/api/v1/newsfeed")
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
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!({
                "title": "Valid Title",
                "unknown_param": "illegal field value"
            }))
            .unwrap(),
        ))
        .await;

    assert_eq!(response.status_code(), StatusCode::UNPROCESSABLE_ENTITY);
    let body: serde_json::Value = response.json();
    assert_eq!(body["Status"], "Error");
    assert_eq!(body["Code"], "VALIDATION_ERROR");
    assert_eq!(body["Message"], "Failed to read request body");
}

#[tokio::test]
async fn test_malformed_json_payload_returns_generic_error_c6() {
    let server = create_test_server();
    let response = server
        .post("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static("nf_test_key_123"),
        )
        .add_header(
            axum::http::header::HeaderName::from_static("content-type"),
            axum::http::header::HeaderValue::from_static("application/json; charset=utf-8"),
        )
        .add_header(
            axum::http::header::HeaderName::from_static("accept"),
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .bytes(axum::body::Bytes::from(
            b"{malformed json string...".to_vec(),
        ))
        .await;

    assert_eq!(response.status_code(), StatusCode::BAD_REQUEST);
    let body: serde_json::Value = response.json();
    assert_eq!(body["Status"], "Error");
    assert_eq!(body["Code"], "BAD_REQUEST");
    assert_eq!(body["Message"], "Failed to read request body");
}

#[tokio::test]
async fn test_cud_endpoint_partial_batch_failure_response() {
    let docker = testcontainers::clients::Cli::default();
    let (state, _node) = create_live_state(&docker).await;
    let cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 100,
        rate_limit_burst: 100,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
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

    let post_resp = server
        .post("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(
            axum::http::header::HeaderName::from_static("accept"),
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .add_header(
            axum::http::header::HeaderName::from_static("content-type"),
            axum::http::header::HeaderValue::from_static("application/json; charset=utf-8"),
        )
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!([
                {
                    "title": "TC8 Invalid Item",
                    "publish_date": "2026-07-23T00:00:00Z"
                },
                {
                    "title": "TC8 Valid Item",
                    "feed_url": "http://example.com/tc8",
                    "publish_date": "2026-07-23T01:00:00Z"
                }
            ]))
            .unwrap(),
        ))
        .await;

    assert_eq!(post_resp.status_code(), StatusCode::UNPROCESSABLE_ENTITY);
    let body: serde_json::Value = post_resp.json();
    assert_eq!(body["Status"], "Error");
}

#[tokio::test]
async fn test_not_found_handler_structure() {
    let server = create_test_server();
    let response = server.get("/api/non/existent/path/for/tc9").await;
    assert_eq!(response.status_code(), StatusCode::NOT_FOUND);

    let body: serde_json::Value = response.json();
    assert_eq!(body["Status"], "Error");
    assert_eq!(body["Code"], "ERROR");
    assert_eq!(body["Message"], "Not Found");
    assert_eq!(body["Count"], 0);
    assert!(body.get("Result").is_none());
}

#[tokio::test]
async fn test_db_conflict_skipped() {
    let docker = testcontainers::clients::Cli::default();
    let (state, _node) = create_live_state(&docker).await;
    let cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 100,
        rate_limit_burst: 100,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
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

    // 1. Insert a new record
    let post_resp1 = server
        .post("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!([{
                "title": "Conflict Test Title",
                "feed_url": "http://example.com/feed",
                "publish_date": "2026-07-24T00:00:00Z"
            }]))
            .unwrap(),
        ))
        .await;
    assert_eq!(post_resp1.status_code(), StatusCode::CREATED);

    // 2. Insert it again, expecting "Skipped" and overall 200 OK since we don't error out on conflict for bulk insertions
    let post_resp2 = server
        .post("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(accept.clone(), accept_val.clone())
        .add_header(content_type.clone(), content_type_val.clone())
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!([{
                "title": "Conflict Test Title",
                "feed_url": "http://example.com/feed",
                "publish_date": "2026-07-24T00:00:00Z"
            }]))
            .unwrap(),
        ))
        .await;

    // Should be OK because our implementation treats all-skipped batches as 200 OK
    assert_eq!(post_resp2.status_code(), StatusCode::OK);
    let body: serde_json::Value = post_resp2.json();
    assert_eq!(body["Status"], "Success");

    // The specific record should have status Skipped
    let results = body["Result"].as_array().unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0]["Status"], "Skipped");
    assert!(results[0]["Message"].as_str().unwrap() == "SKIPPED_EXISTS");
}

#[tokio::test]
async fn test_cud_timeout_408() {
    let cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 100,
        rate_limit_burst: 100,
        timeout_standard_secs: 10,
        timeout_cud_secs: 0, // Artificially low timeout (0s will timeout instantly)
    };

    // We configure the mock DB to take a while to fail (1 second) so the 0s route timeout trips first.
    let fake_pool = sqlx::postgres::PgPoolOptions::new()
        .acquire_timeout(std::time::Duration::from_millis(1000))
        .connect_lazy("postgres://fake:fake@192.0.2.1/fake") // 192.0.2.1 is TEST-NET-1, usually blackholed
        .expect("Failed to create lazy pool");

    let plaintext_key = "nf_test_key_123";
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(plaintext_key.as_bytes());
    let hash_bytes: [u8; 32] = hasher.finalize().into();

    let state = std::sync::Arc::new(AppState {
        is_healthy: std::sync::atomic::AtomicBool::new(true).into(),
        db: DbPool::Postgres(fake_pool),
        api_keys: vec![hash_bytes],
    });

    let app = newsfeed_server::router::build(state, &cfg).layer(axum::middleware::from_fn(
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

    let response = server
        .post("/api/v1/newsfeed")
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
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!([{
                "title": "Valid title, but will timeout",
                "feed_url": "http://example.com",
                "publish_date": "2026-07-26T00:00:00Z"
            }]))
            .unwrap(),
        ))
        .await;

    assert_eq!(
        response.status_code(),
        axum::http::StatusCode::REQUEST_TIMEOUT
    );
}

#[tokio::test]
async fn test_etag_body_hash_304_regression() {
    let docker = testcontainers::clients::Cli::default();
    let (state, _node) = create_live_state(&docker).await;
    let cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 100,
        rate_limit_burst: 100,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
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

    // 1. Initial GET on empty table
    let response1 = server
        .get("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(
            axum::http::header::ACCEPT,
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .await;

    assert_eq!(response1.status_code(), StatusCode::OK);
    let etag = response1.header(&axum::http::header::ETAG);
    let etag_val = etag.to_str().unwrap().to_owned();

    // 2. Second GET with If-None-Match
    let response2 = server
        .get("/api/v1/newsfeed")
        .add_header(
            axum::http::header::HeaderName::from_static("x-api-key"),
            axum::http::header::HeaderValue::from_static(api_key),
        )
        .add_header(
            axum::http::header::ACCEPT,
            axum::http::header::HeaderValue::from_static("application/json"),
        )
        .add_header(
            axum::http::header::IF_NONE_MATCH,
            axum::http::header::HeaderValue::from_str(&etag_val).unwrap(),
        )
        .await;

    assert_eq!(response2.status_code(), StatusCode::NOT_MODIFIED);
}

#[tokio::test]
async fn test_delete_missing_title() {
    let server = create_test_server();
    let response = server
        .delete("/api/v1/newsfeed")
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
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!([{
                "publish_date": "2026-07-23T00:00:00Z"
            }]))
            .unwrap(),
        ))
        .await;

    assert_eq!(response.status_code(), StatusCode::UNPROCESSABLE_ENTITY);
    let body: serde_json::Value = response.json();
    assert_eq!(body["Code"], "VALIDATION_ERROR");
}

#[tokio::test]
async fn test_put_missing_publish_date() {
    let server = create_test_server();
    let response = server
        .put("/api/v1/newsfeed")
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
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!([{
                "title": "Missing publish date"
            }]))
            .unwrap(),
        ))
        .await;

    assert_eq!(response.status_code(), StatusCode::UNPROCESSABLE_ENTITY);
    let body: serde_json::Value = response.json();
    assert_eq!(body["Code"], "VALIDATION_ERROR");
}

#[tokio::test]
async fn test_post_wrapper_payload() {
    let docker = testcontainers::clients::Cli::default();
    let (state, _node) = create_live_state(&docker).await;
    let cfg = AppConfig {
        trust_proxy: false,
        trusted_proxy_cidr: None,
        bind_host: "127.0.0.1".to_string(),
        app_port: 4815,
        rust_log: "info".to_string(),
        api_keys: "nf_test_key_123".to_string(),
        allowed_origins: "http://localhost".to_string(),
        rate_limit_rps: 100,
        rate_limit_burst: 100,
        timeout_standard_secs: 10,
        timeout_cud_secs: 60,
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

    let response = server
        .post("/api/v1/newsfeed")
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
        .bytes(axum::body::Bytes::from(
            serde_json::to_vec(&serde_json::json!({
                "items": [{
                    "title": "Wrapper format title",
                    "feed_url": "http://example.com/wrapper",
                    "publish_date": "2026-07-26T00:00:00Z"
                }],
                "idempotency_key": "k"
            }))
            .unwrap(),
        ))
        .await;

    assert_eq!(response.status_code(), StatusCode::UNPROCESSABLE_ENTITY);
}

#[tokio::test]
async fn test_post_over_1000_items() {
    let server = create_test_server();

    let mut items = Vec::new();
    for i in 0..1001 {
        items.push(serde_json::json!({
            "title": format!("Title {}", i),
            "feed_url": format!("http://example.com/{}", i),
            "publish_date": "2026-07-26T00:00:00Z"
        }));
    }

    let response = server
        .post("/api/v1/newsfeed")
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
        .bytes(axum::body::Bytes::from(serde_json::to_vec(&items).unwrap()))
        .await;

    assert_eq!(response.status_code(), StatusCode::UNPROCESSABLE_ENTITY);
}

#[tokio::test]
async fn test_health_ready_healthy() {
    let server = create_test_server();

    let response = server.get("/health/ready").await;

    assert_eq!(response.status_code(), StatusCode::OK);
    let body: serde_json::Value = response.json();
    assert_eq!(body["status"], "ok");
}

#[tokio::test]
async fn test_options_preflight() {
    let server = create_test_server();

    let response = server
        .method(axum::http::Method::OPTIONS, "/api/v1/newsfeed")
        .add_header(
            axum::http::header::ORIGIN,
            axum::http::header::HeaderValue::from_static("http://localhost"),
        )
        .add_header(
            axum::http::header::ACCESS_CONTROL_REQUEST_METHOD,
            axum::http::header::HeaderValue::from_static("POST"),
        )
        .await;

    assert_eq!(response.status_code(), StatusCode::OK);

    let allow_methods = response.header(&axum::http::header::ACCESS_CONTROL_ALLOW_METHODS);
    assert!(allow_methods.to_str().unwrap().contains("POST"));

    let allow_origin = response.header(&axum::http::header::ACCESS_CONTROL_ALLOW_ORIGIN);
    assert_eq!(allow_origin.to_str().unwrap(), "http://localhost");
}

#[tokio::test(flavor = "multi_thread", worker_threads = 4)]
async fn test_db_concurrent_inserts() {
    let docker = testcontainers::clients::Cli::default();
    let (state, _node) = create_live_state(&docker).await;

    let time_nanos = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_nanos();
    let title = format!("Concurrent Title {}", time_nanos);
    let mut set = tokio::task::JoinSet::new();

    for _ in 0..10 {
        let state_clone = Arc::clone(&state);
        let t = title.clone();
        set.spawn(async move {
            let item = newsfeed_models::CudParams {
                title: Some(t),
                feed_url: Some("http://concurrent.com".to_string()),
                publish_date: Some("2026-07-26T12:00:00Z".to_string()),
                ..Default::default()
            };
            newsfeed_service::cud_feed(
                &state_clone,
                newsfeed_constants::db::OptionMode::InsertFeed,
                &[item],
            )
            .await
        });
    }

    let mut successes = 0;
    let mut skipped = 0;
    let mut errors = 0;

    while let Some(res) = set.join_next().await {
        let db_res_list = res.expect("Task panicked").expect("DB error");
        assert_eq!(db_res_list.len(), 1);
        match db_res_list[0].status {
            newsfeed_db::CudStatus::Success => successes += 1,
            newsfeed_db::CudStatus::Skipped => skipped += 1,
            newsfeed_db::CudStatus::Error => errors += 1,
        }
    }

    assert_eq!(errors, 0, "Expected zero database errors");
    assert_eq!(successes, 1, "Expected exactly one insert to succeed");
    assert_eq!(
        skipped, 9,
        "Expected exactly 9 inserts to be skipped due to conflicts"
    );
}
