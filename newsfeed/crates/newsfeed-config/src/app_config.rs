//! Application-level configuration (non-database).
//! All values come from environment variables deserialized by `envy`.

/// Application configuration loaded from environment variables.
///
/// Required env vars (no defaults for security-sensitive fields):
/// - `BIND_HOST`                — TCP listener host address
/// - `APP_PORT`                 — TCP listener port
/// - `RUST_LOG`                 — tracing log level filter
/// - `API_KEYS`                 — comma-separated list of valid API keys
/// - `ALLOWED_ORIGINS`          — comma-separated list of allowed CORS origins
/// - `RATE_LIMIT_RPS`           — token-bucket replenish rate (requests/sec per IP)
/// - `RATE_LIMIT_BURST`         — token-bucket burst capacity
/// - `BATCH_CONCURRENCY_LIMIT`  — max parallel DB futures per batch CUD request (default: 5)
#[derive(serde::Deserialize, Debug, Clone)]
pub struct AppConfig {
    /// TCP bind address (e.g. `127.0.0.1` or `0.0.0.0`).
    #[serde(default = "default_bind_host")]
    pub bind_host: String,

    /// TCP port (default 4815).
    #[serde(default = "default_port")]
    pub app_port: u16,

    /// `RUST_LOG` filter string (e.g. `info`, `debug`, `newsfeed_server=trace`).
    #[serde(default = "default_log")]
    pub rust_log: String,

    /// Raw comma-separated API keys string.  Split into a `HashSet` in `AppState`.
    pub api_keys: String,

    /// Raw comma-separated CORS-allowed origins.
    pub allowed_origins: String,

    /// Token-bucket replenish rate: requests per second per client IP.
    #[serde(default = "default_rps")]
    pub rate_limit_rps: u64,

    /// Token-bucket burst capacity above the steady-state rate.
    #[serde(default = "default_burst")]
    pub rate_limit_burst: u32,

    /// Maximum number of concurrent database futures when processing a batch
    /// CUD request (POST/PUT/DELETE with multiple items).
    ///
    /// Caps parallelism to avoid exhausting the connection pool.
    /// Environment variable: `BATCH_CONCURRENCY_LIMIT` (default: 5)
    #[serde(default = "default_batch_concurrency")]
    pub batch_concurrency_limit: usize,
}

impl AppConfig {
    /// Parse `allowed_origins` into a `Vec<String>`.
    pub fn origins_vec(&self) -> Vec<String> {
        self.allowed_origins
            .split(',')
            .map(|s| s.trim().to_owned())
            .filter(|s| !s.is_empty())
            .collect()
    }

    /// Parse `api_keys` into a `std::collections::HashSet<String>`.
    pub fn api_keys_set(&self) -> std::collections::HashSet<String> {
        self.api_keys
            .split(',')
            .map(|s| s.trim().to_owned())
            .filter(|s| !s.is_empty())
            .collect()
    }
}

fn default_bind_host() -> String {
    "127.0.0.1".to_owned()
}
fn default_port() -> u16 {
    4815
}
fn default_log() -> String {
    "info".to_owned()
}
fn default_rps() -> u64 {
    10
}
fn default_burst() -> u32 {
    30
}
fn default_batch_concurrency() -> usize {
    5
}
