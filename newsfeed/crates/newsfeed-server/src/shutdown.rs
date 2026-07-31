//! OS signal handling for graceful shutdown.
//!
//! Listens for Ctrl+C on all platforms, plus SIGTERM on Unix and Windows Ctrl+Close / Ctrl+Break / Ctrl+Shutdown signals.

/// Wait for an OS shutdown signal (SIGINT, SIGTERM, or Windows console signals).
#[cfg_attr(coverage_nightly, coverage(off))]
#[allow(clippy::expect_used)]
pub async fn shutdown_signal() {
    let (_tx, rx) = tokio::sync::oneshot::channel();
    shutdown_signal_with_abort(rx).await;
}

/// Wait for an OS shutdown signal or an explicit internal abort.
#[cfg_attr(coverage_nightly, coverage(off))]
#[allow(clippy::expect_used)]
pub async fn shutdown_signal_with_abort(mut abort_rx: tokio::sync::oneshot::Receiver<()>) {
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
        biased;
        () = ctrl_c    => { tracing::info!("Received Ctrl+C, shutting down"); }
        () = terminate => { tracing::info!("Received OS termination signal, shutting down"); }
        _ = &mut abort_rx => { tracing::info!("Received internal abort signal, shutting down"); }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_shutdown_signal_abort() {
        let (tx, rx) = tokio::sync::oneshot::channel();
        let task = tokio::spawn(shutdown_signal_with_abort(rx));

        // Trigger the abort immediately
        tx.send(()).unwrap();

        // Ensure the task resolves deterministically without panicking
        let res = tokio::time::timeout(std::time::Duration::from_secs(1), task).await;
        assert!(res.is_ok(), "Expected task to finish after abort");
    }

    #[tokio::test]
    async fn test_shutdown_signal_wrapper() {
        let task = tokio::spawn(shutdown_signal());
        tokio::time::sleep(std::time::Duration::from_millis(10)).await;
        task.abort();
    }
}
