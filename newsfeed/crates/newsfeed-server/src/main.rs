//! newsfeed-server — application entry point.
//!
//! Startup sequence:
//! 1. Load `.env` file (silently ok if absent; env vars may be pre-set)
//! 2. Parse `AppConfig` and `DatabaseConfig` from env — panic fast on missing vars
//! 3. Initialise `tracing` (once, never re-initialised)
//! 4. Build `AppState`: DB pool + API key `HashSet`
//! 5. Build the Axum router with the full middleware stack
//! 6. Bind and serve with graceful shutdown on SIGTERM / SIGINT
//! 7. Drop `AppState` to close DB pool connections cleanly

// Exclude this entrypoint binary from llvm-cov instrumentation.
// The real business logic lives in lib.rs (handlers, router, middleware) and
// is fully covered by the integration test suite. The main() function itself
// only wires up sockets and OS shutdown signals — it cannot be unit-tested.

#![allow(clippy::expect_used)]

use newsfeed_server::router;
use std::io::{Read, Write};
use std::sync::Arc;

use newsfeed_config::{AppConfig, DatabaseConfig};
use newsfeed_db::pool::AppState;

use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter};
#[tokio::main]
async fn main() {
    // ── 0. Internal Health Check ─────────────────────────────────────────────
    if std::env::args().any(|a| a == "--health-check") {
        let port = std::env::var("APP_PORT").unwrap_or_else(|_| "4815".to_string());
        let Ok(mut stream) = std::net::TcpStream::connect(format!("127.0.0.1:{port}")) else {
            std::process::exit(1);
        };
        if stream
            .write_all(b"GET /health HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n")
            .is_err()
        {
            std::process::exit(1);
        }
        let mut response = String::new();
        if stream.read_to_string(&mut response).is_err() {
            std::process::exit(1);
        }
        if response.contains("200 OK") {
            std::process::exit(0);
        } else {
            std::process::exit(1);
        }
    }

    // ── 1. Load .env ─────────────────────────────────────────────────────────
    dotenvy::dotenv().ok();

    // ── 2. Parse typed config — panics with descriptive message on error ──────
    let app_cfg: AppConfig = envy::from_env()
        .expect("AppConfig error: check APP_PORT, BIND_HOST, API_KEYS, ALLOWED_ORIGINS, RATE_LIMIT_RPS, RATE_LIMIT_BURST");
    let db_cfg: DatabaseConfig = envy::from_env()
        .expect("DatabaseConfig error: check DATABASE_TARGET and the corresponding DB env vars");

    // Validate that required DB env vars are present for the active target.
    db_cfg.validate();

    // ── 3. Initialise tracing (ONCE) ─────────────────────────────────────────
    init_tracing(&app_cfg.rust_log);

    tracing::info!(
        port  = app_cfg.app_port,
        host  = %app_cfg.bind_host,
        db    = %db_cfg.database_target,
        batch_concurrency_limit = app_cfg.batch_concurrency_limit,
        "Starting newsfeed-server"
    );

    // ── 4. Build AppState ─────────────────────────────────────────────────────
    let state = Arc::new(
        AppState::init(&app_cfg, &db_cfg)
            .await
            .expect("Failed to initialise application state"),
    );

    // ── 5. Build router ───────────────────────────────────────────────────────
    let app = router::build(Arc::clone(&state), &app_cfg);

    // ── 6. Bind and serve ─────────────────────────────────────────────────────
    let addr = format!("{}:{}", app_cfg.bind_host, app_cfg.app_port);
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .unwrap_or_else(|e| panic!("Failed to bind {addr}: {e}"));

    tracing::info!("Listening on {addr}");

    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<std::net::SocketAddr>(),
    )
    .with_graceful_shutdown(shutdown_signal())
    .await
    .expect("Server error");

    // ── 7. Drain DB pools ─────────────────────────────────────────────────────
    // Dropping state signals sqlx/bb8 to close all pooled connections cleanly,
    // so the database server sees normal disconnects rather than TCP resets.
    state.db.close().await;
    drop(state);
    tracing::info!("Database pools closed. Shutdown complete.");
}

// ── Tracing initialisation ────────────────────────────────────────────────────

fn init_tracing(rust_log: &str) {
    tracing_subscriber::registry()
        .with(EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new(rust_log)))
        .with(tracing_subscriber::fmt::layer())
        .init();
}

// ── Graceful shutdown ─────────────────────────────────────────────────────────

async fn shutdown_signal() {
    use tokio::signal;

    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("Failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("Failed to install SIGTERM handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        () = ctrl_c    => { tracing::info!("Received Ctrl+C, shutting down"); }
        () = terminate => { tracing::info!("Received SIGTERM, shutting down"); }
    }
}
