# Architecture Decision Record
# 0001. Migration to Rust Cargo Workspace Monorepo

## Status
Accepted

## Context
The Newsfeed web service was initially implemented as a 6-file Python FastAPI monolith. While Python enabled rapid prototyping, it lacked the strong compile-time guarantees, performance characteristics, and strict separation of concerns required for a core backend service querying multiple diverse database engines (Postgres, MariaDB, MSSQL).

Furthermore, the monolith architecture resulted in a high degree of coupling between HTTP handlers, business logic, and database access code.

## Decision
We chose to completely rewrite the service in Rust, leveraging a Cargo workspace monorepo architecture. 

Specifically, we decided to:
1. Divide the application into strict vertical slices (Crates): `newsfeed-constants`, `newsfeed-config`, `newsfeed-models`, `newsfeed-db`, `newsfeed-service`, and `newsfeed-server`.
2. Use `axum` for the HTTP layer due to its robust ecosystem and seamless integration with `tokio`.
3. Use `sqlx` for native asynchronous pooling with Postgres/MariaDB, and `tiberius` for MSSQL (since `sqlx` support for MSSQL is less mature).
4. Implement infrastructure and security through custom middleware (O(1) `HashSet` API key validation) and established community crates (`tower_governor` for rate limiting).

## Consequences
- **Positive**: Strict compilation checks eliminate entire classes of runtime bugs.
- **Positive**: Crate separation enforces architectural boundaries; the HTTP layer (`newsfeed-server`) cannot directly access the database without routing through `newsfeed-service`.
- **Positive**: High performance, predictable memory usage, and minimal Docker container size (< 100MB).
- **Negative**: Increased complexity in the build system and learning curve for maintainers used to Python.
- **Negative**: Dual database driver approach (`sqlx` + `tiberius`) requires slightly more complex trait abstraction and state management.

## Update (2026-07-12)
The monorepo architecture has successfully reached its 1.0.0 stable milestone. All legacy Python scripts, `Makefile`s, and ad-hoc powershell scripts have been entirely removed in favor of native cross-platform Rust build tooling (`cargo-make`) and strict JSON HTTP extractors.
