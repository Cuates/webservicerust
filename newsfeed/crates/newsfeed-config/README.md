# `newsfeed-config`

This crate manages application startup configuration and environment variable resolution.

## Purpose

Instead of using `std::env::var` dynamically at runtime, this crate leverages the `envy` crate to deserialize the `.env` configuration into a strongly-typed `AppConfig` struct immediately upon application startup. 

## Features

- **Early Panics**: Validates that all required environment variables (e.g., `API_KEYS`, `DATABASE_TARGET`) are present at startup, preventing missing-config panics deep in the application runtime.
- **Type Safety**: Automatically parses primitive types like `u64` (for rate limits) and sets sane defaults using `serde` default annotations where applicable.
- **Sub-Configs**: Provides granular configuration blocks (like `DatabaseConfig`) for clean dependency injection into other crates.
