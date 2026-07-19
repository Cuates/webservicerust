use sqlx::Executor;
use std::fs;
use std::time::Duration;
use testcontainers::{clients, core::WaitFor, GenericImage, RunnableImage};
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
    _script_path: &str,
) {
    let script = fs::read_to_string("tests/sql/init_mssql.sql").unwrap();
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

    let db_url = format!("postgres://postgres:postgres@localhost:{}/db", port);
    let app_cfg = newsfeed_config::AppConfig {
        bind_host: "127.0.0.1".into(),
        app_port: 8080,
        rust_log: "info".into(),
        allowed_origins: "*".into(),
        rate_limit_rps: 10,
        rate_limit_burst: 20,
        api_keys: "test_key".into(),
        batch_concurrency_limit: 10,
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
        db_pool_min: 1,
        db_pool_max: 2,
        db_mssql_encrypt: false,
        db_mssql_trust_cert: true,
        db_acquire_timeout_secs: 5,
    };
    let app_state = newsfeed_db::pool::AppState::init(&app_cfg, &db_cfg)
        .await
        .unwrap();
    let pool = match app_state.db {
        newsfeed_db::pool::DbPool::Postgres(p) => p,
        _ => panic!("Expected postgres pool"),
    };

    // Initialize schema
    let schema = fs::read_to_string("tests/sql/init_postgres.sql").unwrap();
    let schema = schema.trim_start_matches('\u{feff}');
    pool.execute(schema)
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
    postgres::cud_feed(&pool, OptionMode::InsertFeed, &cud_params)
        .await
        .unwrap();

    // Test Extract
    let ext_params = ExtractParams {
        title: None,
        image_url: None,
        feed_url: None,
        actual_url: None,
        limit: None,
        sort: None,
    };
    let rows: Vec<(String,)> = sqlx::query_as(
        "SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public'",
    )
    .fetch_all(&pool)
    .await
    .unwrap();
    println!(
        "POSTGRES FUNCTIONS: {:?}",
        rows.iter().map(|r| &r.0).collect::<Vec<_>>()
    );

    let rows = postgres::extract_feed(&pool, &ext_params).await.unwrap();
    assert_eq!(rows.len(), 1);
    assert_eq!(rows[0].titlereturn, Some("Postgres Title".to_string()));
}

#[tokio::test]
async fn test_mariadb_integration() {
    init_tracing_for_tests();
    let docker = clients::Cli::default();
    let image = RunnableImage::from(
        GenericImage::new("mariadb", "10.6")
            .with_env_var("MYSQL_ROOT_PASSWORD", "root")
            .with_env_var("MYSQL_DATABASE", "db")
            .with_wait_for(WaitFor::message_on_stderr("ready for connections")),
    );
    let node = docker.run(image);
    let port = node.get_host_port_ipv4(3306);

    let db_url = format!("mysql://root:root@localhost:{}/db", port);

    // MariaDB might need an extra second to be truly ready even after the log message
    tokio::time::sleep(Duration::from_secs(2)).await;

    let app_cfg = newsfeed_config::AppConfig {
        bind_host: "127.0.0.1".into(),
        app_port: 8080,
        rust_log: "info".into(),
        allowed_origins: "*".into(),
        rate_limit_rps: 10,
        rate_limit_burst: 20,
        api_keys: "test_key".into(),
        batch_concurrency_limit: 10,
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
        db_pool_min: 1,
        db_pool_max: 2,
        db_mssql_encrypt: false,
        db_mssql_trust_cert: true,
        db_acquire_timeout_secs: 5,
    };
    let app_state = newsfeed_db::pool::AppState::init(&app_cfg, &db_cfg)
        .await
        .unwrap();
    let pool = match app_state.db {
        newsfeed_db::pool::DbPool::MariaDb(p) => p,
        _ => panic!("Expected mariadb pool"),
    };

    // Initialize schema
    let schema = fs::read_to_string("tests/sql/init_mariadb.sql").unwrap();
    let schema = schema
        .trim_start_matches('\u{feff}')
        .replace("DEFINER=`gojeda`@`%`", "");

    // MariaDB dump has DELIMITER commands which sqlx doesn't understand natively.
    // We will parse out DELIMITER and split the scripts by `;` and `;;`.
    // A simpler way is to just replace DELIMITER ;; and DELIMITER ; with nothing,
    // but the procedure bodies have semicolons.
    // We will execute each statement using a manual split or just use mysql CLI for MariaDB.
    // For now, let's try just executing the script after replacing DELIMITERs.
    // Wait, since we are executing via simple query protocol, MariaDB can handle multiple statements
    // if configured, but stored procedures with embedded semicolons are tricky.
    // Let's use string splitting by "DELIMITER ;;" and "DELIMITER ;".

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
                if stmt.contains("CREATE PROCEDURE `insertupdatedeletenewsfeed`") {
                    println!(
                        "EXECUTING MARIADB PROCEDURE: {}",
                        &stmt[0..std::cmp::min(stmt.len(), 200)]
                    );
                }
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
    mariadb::cud_feed(&pool, OptionMode::InsertFeed, &cud_params)
        .await
        .unwrap();

    // Test Extract
    let ext_params = ExtractParams {
        title: None,
        image_url: None,
        feed_url: None,
        actual_url: None,
        limit: Some("10".to_string()),
        sort: None,
    };
    let rows = mariadb::extract_feed(&pool, &ext_params).await.unwrap();
    assert_eq!(rows.len(), 1);
    assert_eq!(rows[0].titlereturn, Some("Maria Title".to_string()));
}

#[tokio::test]
async fn test_mssql_integration() {
    let docker = clients::Cli::default();
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

    // Give MSSQL a couple of seconds to become fully ready after the log message
    tokio::time::sleep(Duration::from_secs(3)).await;

    let mut config = Config::new();
    config.host("localhost");
    config.port(port);
    config.authentication(AuthMethod::sql_server("SA", "Password123!"));
    config.trust_cert();

    let tcp = TcpStream::connect(config.get_addr())
        .await
        .expect("Failed to connect to mssql tcp");
    tcp.set_nodelay(true).unwrap();
    let mut client = Client::connect(config, tcp.compat_write())
        .await
        .expect("Failed to connect to mssql");

    // Initialize schema
    execute_mssql_script(&mut client, "tests/sql/init_mssql.sql").await;

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
        api_keys: "test_key".into(),
        batch_concurrency_limit: 10,
    };
    let db_cfg = newsfeed_config::DatabaseConfig {
        database_target: newsfeed_config::DatabaseTarget::MsSql,
        postgres_url: None,
        mariadb_url: None,
        mssql_host: Some("localhost".to_string()),
        mssql_port: Some(port),
        mssql_database: Some("media".to_string()),
        mssql_username: Some("SA".to_string()),
        mssql_password: Some("Password123!".to_string()),
        db_pool_min: 1,
        db_pool_max: 2,
        db_mssql_encrypt: false,
        db_mssql_trust_cert: true,
        db_acquire_timeout_secs: 5,
    };
    let app_state = newsfeed_db::pool::AppState::init(&app_cfg, &db_cfg)
        .await
        .unwrap();
    let pool = match app_state.db {
        newsfeed_db::pool::DbPool::MsSql(p) => p,
        _ => panic!("Expected mssql pool"),
    };

    // Test CUD (Create)
    let cud_params = CudParams {
        title: Some("MSSQL Title".to_string()),
        image_url: Some("http://image.mssql".to_string()),
        feed_url: Some("http://feed.mssql".to_string()),
        actual_url: Some("http://actual.mssql".to_string()),
        publish_date: Some("2026-01-01 00:00:00".to_string()),
    };
    mssql::cud_feed(&pool, OptionMode::InsertFeed, &cud_params)
        .await
        .unwrap();

    // Test Extract
    let ext_params = ExtractParams {
        title: None,
        image_url: None,
        feed_url: None,
        actual_url: None,
        limit: Some("10".to_string()),
        sort: None,
    };
    let rows = mssql::extract_feed(&pool, &ext_params).await.unwrap();
    assert_eq!(rows.len(), 1);
    assert_eq!(rows[0].titlereturn, Some("MSSQL Title".to_string()));
}
