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

#[cfg(test)]
mod tests {
    use super::*;

    fn make_config(api_keys: &str, allowed_origins: &str) -> AppConfig {
        AppConfig {
            bind_host: "127.0.0.1".to_owned(),
            app_port: 4815,
            rust_log: "info".to_owned(),
            api_keys: api_keys.to_owned(),
            allowed_origins: allowed_origins.to_owned(),
            rate_limit_rps: 10,
            rate_limit_burst: 30,
            batch_concurrency_limit: 5,
        }
    }

    #[test]
    fn test_origins_vec_single() {
        let cfg = make_config("key1", "http://localhost");
        assert_eq!(cfg.origins_vec(), vec!["http://localhost"]);
    }

    #[test]
    fn test_origins_vec_multiple() {
        let cfg = make_config("key1", "http://localhost, https://example.com");
        assert_eq!(
            cfg.origins_vec(),
            vec!["http://localhost", "https://example.com"]
        );
    }

    #[test]
    fn test_origins_vec_filters_empty() {
        let cfg = make_config("key1", "http://localhost,,");
        assert_eq!(cfg.origins_vec(), vec!["http://localhost"]);
    }

    #[test]
    fn test_api_keys_set_single() {
        let cfg = make_config("abc123", "http://localhost");
        let keys = cfg.api_keys_set();
        assert!(keys.contains("abc123"));
        assert_eq!(keys.len(), 1);
    }

    #[test]
    fn test_api_keys_set_multiple() {
        let cfg = make_config("key_a, key_b, key_c", "http://localhost");
        let keys = cfg.api_keys_set();
        assert!(keys.contains("key_a"));
        assert!(keys.contains("key_b"));
        assert!(keys.contains("key_c"));
        assert_eq!(keys.len(), 3);
    }

    #[test]
    fn test_api_keys_set_filters_empty() {
        let cfg = make_config("key_a,,key_b", "http://localhost");
        let keys = cfg.api_keys_set();
        assert_eq!(keys.len(), 2);
    }

    #[test]
    fn test_default_fields() {
        let cfg = make_config("k", "o");
        assert_eq!(cfg.bind_host, "127.0.0.1");
        assert_eq!(cfg.app_port, 4815);
        assert_eq!(cfg.rate_limit_rps, 10);
        assert_eq!(cfg.rate_limit_burst, 30);
        assert_eq!(cfg.batch_concurrency_limit, 5);
    }

    #[test]
    fn test_app_config_defaults() {
        let config: AppConfig = envy::from_iter(vec![
            ("API_KEYS".to_string(), "".to_string()),
            ("ALLOWED_ORIGINS".to_string(), "".to_string()),
        ])
        .unwrap();
        assert_eq!(config.bind_host, "127.0.0.1");
        assert_eq!(config.app_port, 4815);
        assert_eq!(config.rust_log, "info");
        assert_eq!(config.rate_limit_rps, 10);
        assert_eq!(config.rate_limit_burst, 30);
        assert_eq!(config.batch_concurrency_limit, 5);
        assert!(config.api_keys.is_empty());
        assert!(config.allowed_origins.is_empty());
    }
    #[test]
    fn test_app_config_defaults_serde() {
        // Deserializing an empty JSON object forces serde to invoke all default_ functions
        // for fields that are missing, which perfectly exercises the default fallback code paths.
        let json_str = r#"{"api_keys":"", "allowed_origins":""}"#;
        let config: AppConfig = serde_json::from_str(json_str).unwrap();

        assert_eq!(config.bind_host, "127.0.0.1");
        assert_eq!(config.app_port, 4815);
        assert_eq!(config.rust_log, "info");
        assert_eq!(config.rate_limit_rps, 10);
        assert_eq!(config.rate_limit_burst, 30);
        assert_eq!(config.batch_concurrency_limit, 5);
        assert!(config.api_keys.is_empty());
        assert!(config.allowed_origins.is_empty());
    }
}
