//! OS signal handling for graceful shutdown.
//!
//! Listens for Ctrl+C on all platforms, plus SIGTERM on Unix and Windows Ctrl+Close / Ctrl+Break / Ctrl+Shutdown signals.

/// Wait for an OS shutdown signal (SIGINT, SIGTERM, or Windows console signals).
#[cfg_attr(coverage_nightly, coverage(off))]
#[allow(clippy::expect_used)]
pub async fn shutdown_signal() {
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

    #[cfg(windows)]
    let terminate = async {
        let mut ctrl_close =
            signal::windows::ctrl_close().expect("Failed to install Ctrl+Close handler");
        let mut ctrl_break =
            signal::windows::ctrl_break().expect("Failed to install Ctrl+Break handler");
        let mut ctrl_shutdown =
            signal::windows::ctrl_shutdown().expect("Failed to install Ctrl+Shutdown handler");

        tokio::select! {
            _ = ctrl_close.recv() => {}
            _ = ctrl_break.recv() => {}
            _ = ctrl_shutdown.recv() => {}
        }
    };

    #[cfg(not(any(unix, windows)))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        () = ctrl_c    => { tracing::info!("Received Ctrl+C, shutting down"); }
        () = terminate => { tracing::info!("Received OS termination signal, shutting down"); }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_shutdown_signal_installation() {
        // Poll the future with a 10ms timeout to ensure signal handlers install cleanly without panicking.
        let res =
            tokio::time::timeout(std::time::Duration::from_millis(10), shutdown_signal()).await;
        assert!(res.is_err(), "Expected timeout since no signal was sent");
    }
}
