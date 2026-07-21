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
|   docker-compose.test.yml
|   docker-compose.yml
|   KNOWLEDGE_GRAPH.md
|   LICENSE
|   Makefile.toml
|   plan.md
|   README.md
|   SKILL.md
|   START_HERE.md
|   
+---.github/
|   +---actions/
|   |   \---newsfeed-setup/
|   |           action.yml
|   \---workflows/
|           newsfeed-ci.yml
|           newsfeed-release.yml
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
|           0002-github-actions-release-pipeline.md
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
|   |   |   |   test_columns.rs
|   |   |   |   
|   |   |   +---migrations/
|   |   |   |   +---mariadb/
|   |   |   |   |       20260718000000_init_mariadb.sql
|   |   |   |   +---mssql/
|   |   |   |   |       20260718000000_init_mssql.sql
|   |   |   |   \---postgres/
|   |   |   |           20260718000000_init_postgres.sql
|   |   |   |           
|   |   |   +---src/
|   |   |   |       error.rs
|   |   |   |       lib.rs
|   |   |   |       mariadb.rs
|   |   |   |       mssql.rs
|   |   |   |       pool.rs
|   |   |   |       postgres.rs
|   |   |   |       
|   |   |   \---tests/
|   |   |       |   integration_test.rs
|   |   |       \---sql/
|   |   |               init_mariadb.sql
|   |   |               init_mssql.sql
|   |   |               init_postgres.sql
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
|   |   |   +---src/
|   |   |   |   |   extractors.rs
|   |   |   |   |   lib.rs
|   |   |   |   |   main.rs
|   |   |   |   |   openapi.rs
|   |   |   |   |   router.rs
|   |   |   |   |   
|   |   |   |   +---handlers/
|   |   |   |   |       delete.rs
|   |   |   |   |       get.rs
|   |   |   |   |       health.rs
|   |   |   |   |       mod.rs
|   |   |   |   |       not_found.rs
|   |   |   |   |       post.rs
|   |   |   |   |       put.rs
|   |   |   |   |       query.rs
|   |   |   |   |       
|   |   |   |   \---middleware/
|   |   |   |           api_key.rs
|   |   |   |           mod.rs
|   |   |   |           
|   |   |   \---tests/
|   |   |           integration_test.rs
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

1. **`newsfeed-constants`**: Zero-dependency crate that holds static string definitions, HTTP routes, unified HTTP error codes/messages (`ResponseCode`, `ResponseMessage`), and database engine variants. (No regex or lazy_statics).
2. **`newsfeed-config`**: Responsible for parsing environment variables using `envy` into strictly-typed Rust structs at startup. Ensures the app panics early if configuration is invalid. Includes connection pool sizing and concurrency limits.
3. **`newsfeed-models`**: Contains the core domain models (`ExtractParams`, `CudParams`, `NewsFeedRow`) and handles mapping responses from the database layer and formatting JSON responses.
4. **`newsfeed-db`**: Handles all Database connections and queries. It exposes generic query methods that abstract away the underlying `DATABASE_TARGET` (PostgreSQL, MariaDB, or MSSQL) from the upper layers. MSSQL is managed via a `bb8-tiberius` async connection pool to avoid TCP handshake overhead. Employs `sqlx` migrations for Postgres/MariaDB, and custom raw scripts for testing.
5. **`newsfeed-service`**: Contains the core business logic. It handles payload validation (including a strict 500-item batch limit and efficient JSON deserialization), orchestrates requests, and bridges the HTTP handler parameters with the `newsfeed-db` execution methods.
6. **`newsfeed-server`**: The application entrypoint (binary). It uses `axum` to build the HTTP server, constructs the middleware stack (Rate Limiting via `tower_governor`, Timing-attack resistant API Key Auth via `SHA-256`, CORS, Tracing, Body Limits), standardizes custom JSON error extraction via `extractors.rs` (using unified `ResponseCode`s), and exposes the OpenAPI Swagger UI (`/swagger-ui`). It also houses the suite of `axum-test` integration tests.

## Continuous Integration & Testing
- The workspace enforces code coverage thresholds via `cargo-llvm-cov` locally (`cargo make test-coverage`) and in CI (`.github/workflows/newsfeed-ci.yml`).
- Core logic and payload validation are tested via standard `#[test]` unit tests inside the library crates.
- API routing and middleware are verified via in-memory server testing in `newsfeed-server/tests/integration_test.rs`.
- Integration tests dynamically provision fully isolated, ephemeral databases on random ports using the `testcontainers` crate, eliminating the need for manual Compose setups during automated testing. Manual test databases are available in `docker-compose.test.yml`.
