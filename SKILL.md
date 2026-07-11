---
name: newsfeed-developer
description: Core guidelines and architectural rules for developing the Newsfeed Rust Web Service
---

# Newsfeed Developer Skill

When working on the Newsfeed Rust Web Service, you must strictly adhere to the following architectural and development rules.

## Core Directives

1. **Workspace Integrity**: This is a multi-crate Cargo workspace. Never merge crates into a monolith.
2. **Configuration Over Hardcoding**: Do not hardcode configuration strings, routes, or settings. Use `newsfeed-config` (parsed via `envy`) for environment variables, and `newsfeed-constants` for static application constants.
3. **Strict Crate Boundaries**:
   - `newsfeed-server` handles ONLY HTTP transport (Extractors, Responses, Middleware).
   - `newsfeed-service` handles ONLY business logic and validation.
   - `newsfeed-db` handles ONLY SQL queries and connection pools.
   - You must NOT bypass a layer (e.g., `newsfeed-server` querying `newsfeed-db` directly is forbidden).
4. **Error Handling**: Use the custom error types `DbError` (in `newsfeed-db`) and `ServiceError` (in `newsfeed-service`). Never use `.unwrap()` or `.expect()` in runtime request paths; always bubble up errors via `Result`.
5. **Database Agnosticism**: The `newsfeed-service` must remain agnostic to the underlying database. Let `DATABASE_TARGET` in `newsfeed-db` dictate whether to use `postgres.rs`, `mariadb.rs`, or `mssql.rs`.
6. **Zero-Trust Validation**: Never trust incoming HTTP payloads. All data must pass through `ExtractParams` or `CudParams` validation in `newsfeed-service` before being processed.
