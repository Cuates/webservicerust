<!-- markdownlint-disable MD013 -->
# AI Context: Start Here

Welcome to the Newsfeed Web Service project. If you are an AI agent analyzing this repository, begin your context gathering here.

## Project Context

- **Domain**: This is a core backend service that manages CRUD operations for user newsfeeds.
- **Tech Stack**: Rust (Axum, Tokio), Cargo Workspace, `sqlx` (Postgres, MariaDB), `tiberius` (MSSQL), `utoipa` (OpenAPI), `tower_governor` (Rate Limiting), `xxhash-rust`.
- **History**: This service was completely rewritten from a legacy Python (FastAPI) monolith into a statically-typed Rust monorepo, and has reached its stable `4.4.0` milestone.

## Rules of Engagement

- **No Monoliths**: Do not combine crates. Maintain the strict separation of concerns outlined in `docs/architecture.md`.
- **Compile First**: Before making assertions about code correctness, ensure `cargo make check` passes.
- **Pre-Commit Hygiene**: You MUST pass the full strict pre-commit hygiene pipeline (`cargo make check`, `cargo make check-deadcode`, `cargo make machete`, `cargo make fix`, `cargo make audit`, `cargo make test-coverage`, `cargo make lint-docs`) before submitting code changes.
- **Testing**: All new code must be accompanied by tests, as the workspace enforces strict coverage thresholds (>99% line and function coverage) in CI using `cargo-llvm-cov`. Remember that integration tests can bypass `testcontainers` by setting `TEST_*_URL` environment variables when debugging against live databases.
- **Dependencies**: Before adding or removing dependencies, run `cargo machete` to ensure the workspace remains free of bloat.
- **Configuration**: Any new configuration variables MUST be added to `newsfeed-config` and validated at startup via `envy`. DO NOT use `std::env::var` dynamically in request paths.
- **Security**: Hardcoded secrets are strictly forbidden. API keys are managed securely in `.env` and loaded into an `AppState` `HashSet`.

## Where to Look

- If modifying routing, middleware, or payload validation: `newsfeed/crates/newsfeed-server/src/` (specifically `validation.rs` and `router.rs`)
- If modifying core business orchestration or batch limits: `newsfeed/crates/newsfeed-service/src/`
- If modifying SQL queries: `newsfeed/crates/newsfeed-db/src/`
- If modifying data shapes: `newsfeed/crates/newsfeed-models/src/`
