# `newsfeed-models`

This crate defines the shared data structures and types that flow through the application.

## Purpose

By isolating data models into their own crate, we prevent cyclic dependencies between the Database (`newsfeed-db`), Service (`newsfeed-service`), and Server (`newsfeed-server`) layers.

## Key Types

- **`ExtractParams` / `CudParams`**: Strongly typed structs mapped from incoming JSON payloads or URL Query parameters.
- **`NewsFeedRow`**: Represents a single row returned from the database. It derives `sqlx::FromRow` for seamless ORM-style object mapping from raw SQL results.
- **`ApiResponse<T>`**: A generic envelope struct ensuring all HTTP JSON responses follow a consistent `{ "status": ..., "data": ... }` shape.
