# AI Context: Start Here

Welcome to the Newsfeed Web Service project. If you are an AI agent analyzing this repository, begin your context gathering here.

## Project Context
- **Domain**: This is a core backend service that manages CRUD operations for user newsfeeds.
- **Tech Stack**: Rust (Axum, Tokio), Cargo Workspace, `sqlx` (Postgres, MariaDB), `tiberius` (MSSQL), `utoipa` (OpenAPI).
- **History**: This service was completely rewritten from a legacy Python (FastAPI) monolith into a statically-typed Rust monorepo, and has reached its stable `1.1.0` milestone.

## Rules of Engagement
- **No Monoliths**: Do not combine crates. Maintain the strict separation of concerns outlined in `docs/architecture.md`.
- **Compile First**: Before making assertions about code correctness, ensure `cargo make check` passes.
- **Testing**: All new code must be accompanied by tests, as the workspace enforces strict coverage thresholds (Lines: 35%, Functions: 35%, Regions: 40%) in CI using `cargo-llvm-cov`.
- **Configuration**: Any new configuration variables MUST be added to `newsfeed-config` and validated at startup via `envy`. DO NOT use `std::env::var` dynamically in request paths.
- **Security**: Hardcoded secrets are strictly forbidden. API keys are managed securely in `.env` and loaded into an `AppState` `HashSet`.

## Where to Look
- If modifying routing or adding HTTP handlers: `newsfeed/crates/newsfeed-server/src/router.rs`
- If modifying business logic or validations: `newsfeed/crates/newsfeed-service/src/`
- If modifying SQL queries: `newsfeed/crates/newsfeed-db/src/`
- If modifying data shapes: `newsfeed/crates/newsfeed-models/src/`
