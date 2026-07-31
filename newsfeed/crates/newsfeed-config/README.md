<!-- markdownlint-disable MD013 -->
# `newsfeed-config`

This crate manages application startup configuration and environment variable resolution.

## Purpose

Instead of using `std::env::var` dynamically at runtime, this crate leverages the `envy` crate to deserialize the `.env` configuration into a strongly-typed `AppConfig` struct immediately upon application startup.

## Features

- **Early Panics**: Validates that all required environment variables (e.g., `API_KEYS`, `DATABASE_TARGET`) are present at startup, preventing missing-config panics deep in the application runtime.
- **Type Safety**: Automatically parses primitive types like `u64` (for rate limits, MSSQL idle timeouts, and connection pool limits) and sets sane defaults using `serde` default annotations.
- **Connection Pool Tuning**: Manages configurable parameters for connection pool sizing, acquisition timeouts, and MSSQL idle connection recycling.
- **Security Redaction**: Overrides the `Debug` trait for `DatabaseConfig` to aggressively redact connection strings and passwords (`***REDACTED***`), preventing accidental credential leaks in application startup logs or crash traces.
- **Sub-Configs**: Provides granular configuration blocks (like `DatabaseConfig`) for clean dependency injection into other crates.
