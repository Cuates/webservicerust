<!-- markdownlint-disable MD013 -->
# `newsfeed-models`

This crate defines the shared data structures and types that flow through the application.

## Purpose

By isolating data models into their own crate, we prevent cyclic dependencies between the Database (`newsfeed-db`), Service (`newsfeed-service`), and Server (`newsfeed-server`) layers.

## Key Types

- **`ExtractParams` / `CudParams`**: Strongly typed structs mapped from incoming JSON payloads or URL Query parameters. Enforces `#[serde(deny_unknown_fields)]` and custom deserializers (like `deserialize_non_empty_option`) to reject malformed, inflated, or whitespace-only requests with structured validation errors.
- **`CudStatus` / `CudResult`**: Strongly typed enums and structs representing the outcome of Create, Update, and Delete database operations, replacing unstructured JSON responses and normalizing conflict-write outcomes (such as `"Skipped"` for duplicate inserts or missing updates).
- **`NewsFeedRow`**: Represents a single row returned from the database. It derives `sqlx::FromRow` for seamless ORM-style object mapping from raw SQL results.
- **`ApiResponse<T>`**: A generic envelope struct ensuring all HTTP JSON responses follow a consistent `{ "status": ..., "data": ... }` shape.
