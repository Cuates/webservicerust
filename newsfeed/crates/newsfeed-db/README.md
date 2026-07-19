# `newsfeed-db`

The Data Access Layer of the application.

## Purpose

This crate establishes the physical database connection pool and acts as the execution layer for all SQL queries.

## Features

- **Multi-Engine Support**: Supports connecting to PostgreSQL, MariaDB, and MSSQL. The target is determined dynamically at startup via the `DATABASE_TARGET` config.
- **`sqlx` & `tiberius`**: Uses `sqlx` for native asynchronous Postgres/MariaDB pooling, and uses `tiberius` over a Tokio TCP stream for MSSQL communication.
- **`AppState`**: Holds the long-lived connection pools alongside the parsed set of authorized API keys. This state struct is injected via Axum state extractors into the HTTP handlers.
- **Custom Errors**: Maps raw SQL errors from the underlying drivers into a generic `DbError` type.
- **Integration Testing**: Designed to integrate with `testcontainers` during workspace tests to dynamically provision and seed ephemeral PostgreSQL, MariaDB, and MSSQL instances on-the-fly.
