# `newsfeed-service`

The core Business Logic and Orchestration layer.

## Purpose

This crate bridges the gap between the incoming HTTP requests (handled by `newsfeed-server`) and the raw database operations (handled by `newsfeed-db`).

## Features

- **Validation**: Implements efficient JSON deserialization, strict 500-item batch limits for bulk operations, and mandatory header/payload constraints, ensuring all incoming inputs are strictly sanitized before touching the database.
- **Routing Logic**: Determines which specific database execution strategy to invoke based on the configured environment.
- **Separation of Concerns**: Exposes clean interface functions (`extract_records`, `process_cud`) that the HTTP layer calls, keeping the Axum handlers completely unaware of the underlying SQL mechanisms.
- **Unit Testing**: Contains a robust unit test suite (`#[test]`) to verify all edge cases for payload schema validation and mandatory field constraints, achieving >99% code coverage.
