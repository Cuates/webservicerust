//! newsfeed-config
//!
//! Typed configuration loaded from environment variables at startup via `envy`.
//! The application panics fast with a descriptive message if any required
//! variable is absent or cannot be parsed — no silent defaults for secrets.

pub mod app_config;
pub mod db_config;

pub use app_config::AppConfig;
pub use db_config::{DatabaseConfig, DatabaseTarget};
