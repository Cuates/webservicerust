<!-- markdownlint-disable MD013 -->
# `newsfeed-db`

The Data Access Layer of the application.

## Purpose

This crate establishes the physical database connection pool and acts as the execution layer for all SQL queries.

## Features

- **Multi-Engine Support**: Supports connecting to PostgreSQL, MariaDB, and MSSQL. The target is determined dynamically at startup via the `DATABASE_TARGET` config.
- **`sqlx` & `tiberius`**: Uses `sqlx` (with embedded migrations) for native asynchronous Postgres/MariaDB pooling, and uses `tiberius` with a tuned `bb8` connection pool for robust MSSQL communication.
- **Bulk CUD Operations**: Implements high-performance bulk JSON processing via `cud_bulk_json_newsfeed` across PostgreSQL, MariaDB, and MSSQL, eliminating N+1 query loops when executing batch operations inside transactions.
- **Shared Execution Logic**: Consolidates common query execution, parameter binding, and result mapping patterns across different SQL engine drivers in `shared.rs`.
- **`AppState`**: Holds the long-lived connection pools alongside the parsed set of authorized API keys (pre-decoded SHA-256 digests compared in constant time using `subtle::ConstantTimeEq` to prevent timing side-channel attacks). This state struct is injected via Axum state extractors into the HTTP handlers.
- **Custom Errors**: Maps raw SQL errors from the underlying drivers into a generic `DbError` type.
- **Integration Testing**: Designed to integrate with `testcontainers` during workspace tests to dynamically provision and seed ephemeral PostgreSQL, MariaDB, and MSSQL instances on-the-fly. Tests also support direct connection to live databases via `TEST_POSTGRES_URL`, `TEST_MARIADB_URL`, or `TEST_MSSQL_URL`/`TEST_MSSQL_PORT`.
