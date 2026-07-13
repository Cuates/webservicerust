# Project Architecture

This document describes the high-level architecture and structure of the Newsfeed web service monorepo.

## Workspace Layout

The repository is structured as a standard Cargo Workspace, dividing the application into focused, modular crates.

```text
webservicerust
|   .dockerignore
|   .env.example
|   .gitignore
|   AGENTS.md
|   Cargo.lock
|   Cargo.toml
|   CHANGELOG.md
|   docker-compose.yml
|   KNOWLEDGE_GRAPH.md
|   LICENSE
|   Makefile.toml
|   plan.md
|   README.md
|   SKILL.md
|   START_HERE.md
|   
+---docs/
|   |   architecture.md
|   |   distribution.md
|   |   cargo-make.md
|   |   scaffolding.md
|   |   troubleshooting.md
|   |   
|   \---adr/
|           0001-rust-monorepo-migration.md
|           
+---newsfeed/
|   +---crates/
|   |   +---newsfeed-config/
|   |   |   |   Cargo.toml
|   |   |   |   README.md
|   |   |   \---src/
|   |   |           app_config.rs
|   |   |           db_config.rs
|   |   |           lib.rs
|   |   |           
|   |   +---newsfeed-constants/
|   |   |   |   Cargo.toml
|   |   |   |   README.md
|   |   |   \---src/
|   |   |           db.rs
|   |   |           http.rs
|   |   |           lib.rs
|   |   +---newsfeed-db/
|   |   |   |   Cargo.toml
|   |   |   |   README.md
|   |   |   \---src/
|   |   |           error.rs
|   |   |           lib.rs
|   |   |           mariadb.rs
|   |   |           mssql.rs
|   |   |           pool.rs
|   |   |           postgres.rs
|   |   |           
|   |   +---newsfeed-models/
|   |   |   |   Cargo.toml
|   |   |   |   README.md
|   |   |   \---src/
|   |   |           feed.rs
|   |   |           lib.rs
|   |   |           response.rs
|   |   |           
|   |   +---newsfeed-server/
|   |   |   |   Cargo.toml
|   |   |   |   README.md
|   |   |   \---src/
|   |   |       |   extractors.rs
|   |   |       |   main.rs
|   |   |       |   router.rs
|   |   |       |   
|   |   |       +---handlers/
|   |   |       |       delete.rs
|   |   |       |       get.rs
|   |   |       |       health.rs
|   |   |       |       mod.rs
|   |   |       |       not_found.rs
|   |   |       |       post.rs
|   |   |       |       put.rs
|   |   |       |       query.rs
|   |   |       |       
|   |   |       \---middleware/
|   |   |               api_key.rs
|   |   |               mod.rs
|   |   |               
|   |   \---newsfeed-service/
|   |       |   Cargo.toml
|   |       |   README.md
|   |       \---src/
|   |               error.rs
|   |               feed_service.rs
|   |               lib.rs
|   |               payload_validator.rs
|   |               
|   \---docker/
|           Dockerfile
|           
\---scripts/
        generate-api-key.ps1
        generate-api-key.sh
        revoke-api-key.ps1
        revoke-api-key.sh
```

## Architectural Layers

1. **`newsfeed-constants`**: Zero-dependency crate that holds static string definitions, HTTP routes, and database engine variants. (No regex or lazy_statics).
2. **`newsfeed-config`**: Responsible for parsing environment variables using `envy` into strictly-typed Rust structs at startup. Ensures the app panics early if configuration is invalid. Includes connection pool sizing and concurrency limits.
3. **`newsfeed-models`**: Contains the core domain models (`ExtractParams`, `CudParams`, `NewsFeedRow`) and handles mapping responses from the database layer and formatting JSON responses.
4. **`newsfeed-db`**: Handles all Database connections and queries. It exposes generic query methods that abstract away the underlying `DATABASE_TARGET` (PostgreSQL, MariaDB, or MSSQL) from the upper layers. MSSQL is managed via a `bb8-tiberius` async connection pool to avoid TCP handshake overhead.
5. **`newsfeed-service`**: Contains the core business logic. It handles payload validation, orchestrates requests, and bridges the HTTP handler parameters with the `newsfeed-db` execution methods.
6. **`newsfeed-server`**: The application entrypoint (binary). It uses `axum` to build the HTTP server, constructs the middleware stack (Rate Limiting, API Key Auth, CORS, Tracing), standardizes custom JSON error extraction via `extractors.rs`, and defines all routing logic mapping to the handlers.
