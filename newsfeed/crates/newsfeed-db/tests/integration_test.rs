#![allow(
    clippy::unwrap_used,
    clippy::expect_used,
    clippy::pedantic,
    clippy::cloned_ref_to_slice_refs
)]

use sqlx::Executor;
use std::fs;
use std::path::{MAIN_SEPARATOR, PathBuf};
use std::time::Duration;
use testcontainers::{GenericImage, RunnableImage, clients, core::WaitFor};
use tiberius::{AuthMethod, Client, Config};
use tokio::net::TcpStream;
use tokio_util::compat::TokioAsyncWriteCompatExt;

use newsfeed_constants::db::OptionMode;
use newsfeed_db::{mariadb, mssql, postgres};
use newsfeed_models::{CudParams, ExtractParams};

// Helper to initialize tracing
fn init_tracing_for_tests() {
    // Mute noisy sqlx pool acquire warnings and tiberius TLS warnings during tests
    let _ = tracing_subscriber::fmt()
        .with_env_filter(
            "info,sqlx=error,tiberius=error,newsfeed_db::pool=error,testcontainers=error",
        )
        .try_init();
}

// Helper to run MSSQL scripts by splitting on GO
async fn execute_mssql_script(
    client: &mut Client<tokio_util::compat::Compat<TcpStream>>,
    script_path: std::path::PathBuf,
) {
    let script = fs::read_to_string(script_path).unwrap();
    let script = script.trim_start_matches('\u{feff}');

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

#[tokio::test]
async fn test_postgres_integration() {
    init_tracing_for_tests();
    let docker = clients::Cli::default();
    let (db_url, _node) = if let Ok(url) = std::env::var("TEST_POSTGRES_URL") {
        (url, None)
    } else {
        let image = RunnableImage::from(
            GenericImage::new("postgres", "15")
                .with_env_var("POSTGRES_USER", "postgres")
                .with_env_var("POSTGRES_PASSWORD", "postgres")
                .with_env_var("POSTGRES_DB", "db")
                .with_wait_for(WaitFor::message_on_stderr(
                    "database system is ready to accept connections",
                )),
        );
        let node = docker.run(image);
        let port = node.get_host_port_ipv4(5432);
        let url = format!("postgres://postgres:postgres@localhost:{}/db", port);
        (url, Some(node))
    };
    let app_cfg = newsfeed_config::AppConfig {
        bind_host: "127.0.0.1".into(),
        app_port: 8080,
        rust_log: "info".into(),
        allowed_origins: "*".into(),
        rate_limit_rps: 10,
        rate_limit_burst: 20,
        api_keys: newsfeed_constants::test_constants::TEST_API_KEY_HEX.into(),
        trust_proxy: false,
        trusted_proxy_cidr: Some("".to_string()),
        timeout_standard_secs: newsfeed_constants::http::Timeouts::STANDARD_SECS,
        timeout_cud_secs: newsfeed_constants::http::Timeouts::CUD_SECS,
    };
    let db_cfg = newsfeed_config::DatabaseConfig {
        database_target: newsfeed_config::DatabaseTarget::Postgres,
        postgres_url: Some(db_url.clone()),
        mariadb_url: None,
        mssql_host: None,
        mssql_port: None,
        mssql_database: None,
        mssql_username: None,
        mssql_password: None,
        db_pool_min: newsfeed_constants::db::PoolDefaults::MIN_CONNECTIONS,
        db_pool_max: newsfeed_constants::db::PoolDefaults::MAX_CONNECTIONS,
        db_mssql_encrypt: false,
        db_mssql_trust_cert: true,
        db_acquire_timeout_secs: newsfeed_constants::db::PoolDefaults::ACQUIRE_TIMEOUT_SECS,
    };
    let mut retries = 5;
    let mut app_state = None;
    while retries > 0 {
        match newsfeed_db::pool::AppState::init(&app_cfg, &db_cfg).await {
            Ok(state) => {
                app_state = Some(state);
                break;
            }
            Err(e) => {
                println!("Postgres not ready yet, retrying... ({})", e);
                tokio::time::sleep(Duration::from_secs(2)).await;
                retries -= 1;
            }
        }
    }
    let app_state = app_state.expect("Failed to initialize Postgres pool after retries");
    let pool = match app_state.db {
        newsfeed_db::pool::DbPool::Postgres(p) => p,
        _ => panic!("Expected postgres pool"),
    };

    let mut path = PathBuf::new();
    path.push("migrations");
    path.push("postgres");
    path.push("20260718000000_init_postgres.sql");
    let schema = fs::read_to_string(path).unwrap();
    let schema = schema.replace(
        "SELECT pg_catalog.set_config('search_path', '', false);",
        "SELECT pg_catalog.set_config('search_path', 'public', false);",
    );
    pool.execute(schema.as_str())
        .await
        .expect("Failed to execute postgres schema");

    // Test CUD (Create)
    let cud_params = CudParams {
        title: Some("Postgres Title".to_string()),
        image_url: Some("http://image.pg".to_string()),
        feed_url: Some("http://feed.pg".to_string()),
        actual_url: Some("http://actual.pg".to_string()),
        publish_date: Some("2026-07-13 00:00:00".to_string()),
    };
    let res = postgres::cud_feed(&pool, OptionMode::InsertFeed, &[cud_params.clone()]).await;
    if let Err(e) = &res {
        println!("POSTGRES CUD ERROR: {:?}", e);
    }
    let res = res.unwrap();
    assert_eq!(res.len(), 1);
    assert_eq!(res[0].status, newsfeed_db::CudStatus::Success);

    // Test conflict-write returns Skipped
    let res_dup = postgres::cud_feed(&pool, OptionMode::InsertFeed, &[cud_params.clone()])
        .await
        .unwrap();
    assert_eq!(res_dup.len(), 1);
    assert_eq!(res_dup[0].status, newsfeed_db::CudStatus::Skipped);

    // Test bulk CUD batch correctness
    let batch = vec![
        CudParams {
            title: Some("Batch Title 1".to_string()),
            image_url: Some("http://image1.pg".to_string()),
            feed_url: Some("http://feed1.pg".to_string()),
            actual_url: Some("http://actual1.pg".to_string()),
            publish_date: Some("2026-07-14 00:00:00".to_string()),
        },
        CudParams {
            title: Some("Batch Title 2".to_string()),
            image_url: Some("http://image2.pg".to_string()),
            feed_url: Some("http://feed2.pg".to_string()),
            actual_url: Some("http://actual2.pg".to_string()),
            publish_date: Some("2026-07-15 00:00:00".to_string()),
        },
    ];
    let res_batch = postgres::cud_feed(&pool, OptionMode::InsertFeed, &batch)
        .await
        .unwrap();
    assert_eq!(res_batch.len(), 2);
    assert_eq!(res_batch[0].status, newsfeed_db::CudStatus::Success);
    assert_eq!(res_batch[1].status, newsfeed_db::CudStatus::Success);

    // Test Extract (unfiltered)
    let ext_params = ExtractParams {
        title: None,
        image_url: None,
        feed_url: None,
        actual_url: None,
        limit: None,
        sort: None,
    };
    let rows = postgres::extract_feed(&pool, &ext_params).await.unwrap();
    assert_eq!(rows.len(), 3);

    // Test filter semantics: title filter
    let ext_title = ExtractParams {
        title: Some("Batch Title 1".to_string()),
        image_url: None,
        feed_url: None,
        actual_url: None,
        limit: None,
        sort: None,
    };
    let rows_title = postgres::extract_feed(&pool, &ext_title).await.unwrap();
    assert_eq!(rows_title.len(), 1);
    assert_eq!(rows_title[0].titlereturn, Some("Batch Title 1".to_string()));

    // Test filter semantics: limit filter (Asc order)
    let ext_limit = ExtractParams {
        title: None,
        image_url: None,
        feed_url: None,
        actual_url: None,
        limit: Some(2),
        sort: Some(newsfeed_models::feed::SortOrder::Asc),
    };
    let rows_limit = postgres::extract_feed(&pool, &ext_limit).await.unwrap();
    assert_eq!(rows_limit.len(), 2);
    assert_eq!(
        rows_limit[0].titlereturn,
        Some("Postgres Title".to_string())
    );

    // Test filter semantics: sort order Desc
    let ext_desc = ExtractParams {
        title: None,
        image_url: None,
        feed_url: None,
        actual_url: None,
        limit: Some(10),
        sort: Some(newsfeed_models::feed::SortOrder::Desc),
    };
    let rows_desc = postgres::extract_feed(&pool, &ext_desc).await.unwrap();
    assert_eq!(rows_desc.len(), 3);
    assert_eq!(rows_desc[0].titlereturn, Some("Batch Title 2".to_string()));
    assert_eq!(rows_desc[2].titlereturn, Some("Postgres Title".to_string()));
}

#[tokio::test]
async fn test_mariadb_integration() {
    init_tracing_for_tests();
    let docker = clients::Cli::default();
    let (db_url, _node) = if let Ok(url) = std::env::var("TEST_MARIADB_URL") {
        (url, None)
    } else {
        let image = RunnableImage::from(
            GenericImage::new("mariadb", "10.6")
                .with_env_var("MYSQL_ROOT_PASSWORD", "root")
                .with_env_var("MYSQL_DATABASE", "db")
                .with_wait_for(WaitFor::message_on_stderr("ready for connections")),
        );
        let node = docker.run(image);
        let port = node.get_host_port_ipv4(3306);
        let url = format!("mysql://root:root@localhost:{}/db", port);
        (url, Some(node))
    };

    // Removed hardcoded sleep, using retry loop during AppState::init

    let app_cfg = newsfeed_config::AppConfig {
        bind_host: "127.0.0.1".into(),
        app_port: 8080,
        rust_log: "info".into(),
        allowed_origins: "*".into(),
        rate_limit_rps: 10,
        rate_limit_burst: 20,
        api_keys: newsfeed_constants::test_constants::TEST_API_KEY_HEX.into(),
        trust_proxy: false,
        trusted_proxy_cidr: Some("".to_string()),
        timeout_standard_secs: newsfeed_constants::http::Timeouts::STANDARD_SECS,
        timeout_cud_secs: newsfeed_constants::http::Timeouts::CUD_SECS,
    };
    let db_cfg = newsfeed_config::DatabaseConfig {
        database_target: newsfeed_config::DatabaseTarget::MariaDb,
        postgres_url: None,
        mariadb_url: Some(db_url.clone()),
        mssql_host: None,
        mssql_port: None,
        mssql_database: None,
        mssql_username: None,
        mssql_password: None,
        db_pool_min: newsfeed_constants::db::PoolDefaults::MIN_CONNECTIONS,
        db_pool_max: newsfeed_constants::db::PoolDefaults::MAX_CONNECTIONS,
        db_mssql_encrypt: false,
        db_mssql_trust_cert: true,
        db_acquire_timeout_secs: newsfeed_constants::db::PoolDefaults::ACQUIRE_TIMEOUT_SECS,
    };
    let mut retries = 5;
    let mut app_state = None;
    while retries > 0 {
        match newsfeed_db::pool::AppState::init(&app_cfg, &db_cfg).await {
            Ok(state) => {
                app_state = Some(state);
                break;
            }
            Err(e) => {
                println!("MariaDB not ready yet, retrying... ({})", e);
                tokio::time::sleep(Duration::from_secs(3)).await;
                retries -= 1;
            }
        }
    }
    let app_state = app_state.expect("Failed to initialize MariaDB pool after retries");
    let pool = match app_state.db {
        newsfeed_db::pool::DbPool::MariaDb(p) => p,
        _ => panic!("Expected mariadb pool"),
    };

    // Initialize schema
    let mut path = PathBuf::new();
    path.push("migrations");
    path.push("mariadb");
    path.push("20260718000000_init_mariadb.sql");
    let schema = fs::read_to_string(path).unwrap();
    let schema = schema
        .trim_start_matches('\u{feff}')
        .replace("DEFINER=`gojeda`@`%`", "");

    let mut current_delimiter = ";";
    let mut buffer = String::new();
    let mut conn = pool.acquire().await.unwrap();

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

    // Test CUD (Create)
    let cud_params = CudParams {
        title: Some("Maria Title".to_string()),
        image_url: Some("http://image.maria".to_string()),
        feed_url: Some("http://feed.maria".to_string()),
        actual_url: Some("http://actual.maria".to_string()),
        publish_date: Some("2026-01-01 00:00:00".to_string()),
    };
    mariadb::cud_feed(&pool, OptionMode::InsertFeed, &[cud_params.clone()])
        .await
        .unwrap();

    // Test Extract
    let ext_params = ExtractParams {
        title: None,
        image_url: None,
        feed_url: None,
        actual_url: None,
        limit: Some(10),
        sort: None,
    };
    let rows = mariadb::extract_feed(&pool, &ext_params).await.unwrap();
    assert_eq!(rows.len(), 1);
    assert_eq!(rows[0].titlereturn, Some("Maria Title".to_string()));

    let ext_params_sorted = ExtractParams {
        title: None,
        image_url: None,
        feed_url: None,
        actual_url: None,
        limit: Some(10),
        sort: Some(newsfeed_models::feed::SortOrder::Desc),
    };
    let rows_sorted = mariadb::extract_feed(&pool, &ext_params_sorted)
        .await
        .unwrap();
    assert_eq!(rows_sorted.len(), 1);
}

#[tokio::test]
async fn test_mssql_integration() {
    init_tracing_for_tests();
    let docker = clients::Cli::default();
    let (host, port, user, pass, db, _node) = if let Ok(port_str) = std::env::var("TEST_MSSQL_PORT")
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
        let image = RunnableImage::from(
            GenericImage::new("mcr.microsoft.com/mssql/server", "2022-latest")
                .with_env_var("ACCEPT_EULA", "Y")
                .with_env_var("MSSQL_SA_PASSWORD", "Password123!")
                .with_wait_for(WaitFor::message_on_stdout(
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

    // Removed hardcoded sleep, using retry loop during TCP connect

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
        tokio::time::sleep(Duration::from_secs(3)).await;
        retries -= 1;
    }
    let mut client = client_res.expect("Failed to connect to mssql after retries");

    let mut path = PathBuf::new();
    path.push("migrations");
    path.push("mssql");
    path.push("20260718000000_init_mssql.sql");
    execute_mssql_script(&mut client, path).await;

    // We must use master or media DB? The init script creates `media` and then `USE media`.
    // Wait, the Tiberius connection is made to `master` by default. We need to create a connection pool for `media` after creation,
    // or just execute `USE media` on our test pool. The bb8 pool needs `media`.
    let app_cfg = newsfeed_config::AppConfig {
        bind_host: "127.0.0.1".into(),
        app_port: 8080,
        rust_log: "info".into(),
        allowed_origins: "*".into(),
        rate_limit_rps: 10,
        rate_limit_burst: 20,
        api_keys: newsfeed_constants::test_constants::TEST_API_KEY_HEX.into(),
        trust_proxy: false,
        trusted_proxy_cidr: Some("".to_string()),
        timeout_standard_secs: newsfeed_constants::http::Timeouts::STANDARD_SECS,
        timeout_cud_secs: newsfeed_constants::http::Timeouts::CUD_SECS,
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
        db_pool_min: newsfeed_constants::db::PoolDefaults::MIN_CONNECTIONS,
        db_pool_max: newsfeed_constants::db::PoolDefaults::MAX_CONNECTIONS,
        db_mssql_encrypt: false,
        db_mssql_trust_cert: true,
        db_acquire_timeout_secs: newsfeed_constants::db::PoolDefaults::ACQUIRE_TIMEOUT_SECS,
    };
    let app_state = newsfeed_db::pool::AppState::init(&app_cfg, &db_cfg)
        .await
        .unwrap();
    let pool = match app_state.db {
        newsfeed_db::pool::DbPool::MsSql(p) => p,
        _ => panic!("Expected mssql pool"),
    };

    // Test max_modified_date on empty DB
    let empty_max_date = mssql::max_modified_date(&pool).await.unwrap();
    assert!(empty_max_date.is_none());

    // Test CUD (Create)
    let cud_params = CudParams {
        title: Some("MSSQL Title".to_string()),
        image_url: Some("http://image.mssql".to_string()),
        feed_url: Some("http://feed.mssql".to_string()),
        actual_url: Some("http://actual.mssql".to_string()),
        publish_date: Some("2026-01-01 00:00:00".to_string()),
    };
    mssql::cud_feed(&pool, OptionMode::InsertFeed, &[cud_params.clone()])
        .await
        .unwrap();

    // Test Extract
    let ext_params = ExtractParams {
        title: None,
        image_url: None,
        feed_url: None,
        actual_url: None,
        limit: Some(10),
        sort: None,
    };
    let rows = mssql::extract_feed(&pool, &ext_params).await.unwrap();
    assert_eq!(rows.len(), 1);
    assert_eq!(rows[0].titlereturn, Some("MSSQL Title".to_string()));

    let ext_params_sorted = ExtractParams {
        title: None,
        image_url: None,
        feed_url: None,
        actual_url: None,
        limit: Some(10),
        sort: Some(newsfeed_models::feed::SortOrder::Asc),
    };
    let rows_sorted = mssql::extract_feed(&pool, &ext_params_sorted)
        .await
        .unwrap();
    assert_eq!(rows_sorted.len(), 1);

    // Test max_modified_date on populated DB
    let max_date = mssql::max_modified_date(&pool).await.unwrap();
    assert!(max_date.is_some());
}
