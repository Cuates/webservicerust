# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-07-18

### Added
- **Testing**: Achieved 99.57% workspace-wide test coverage and exposed `test-coverage-run` and `test-coverage-report` as public tasks in `Makefile.toml`.
- **Infrastructure**: Extracted testing databases (`postgres`, `mariadb`, `mssql`) into a dedicated `docker-compose.test.yml`, leaving `docker-compose.yml` exclusively for the core service.

### Changed
- **Testing**: Migrated integration tests to use the `testcontainers` crate for dynamically provisioning ephemeral databases, removing the need for manual compose setups.
- **Code Quality**: Squashed magic string literals across HTTP handlers and middleware, centralizing them into unified `ResponseCode`, `ResponseMessage`, and `HeaderType` constants.
- **Release**: Bumped workspace version to 2.0.0 for the new major release.

## [1.2.0] - 2026-07-13

### Added
- **CI/CD**: Added a GitHub Actions release pipeline (`newsfeed-release.yml`) to automatically build and upload compiled `x86_64` assets for Linux, macOS, and Windows upon tagging `newsfeed-v*`.

### Changed
- **Release**: Bumped workspace version to 1.2.0 for the new release pipeline.

## [1.1.0] - 2026-07-13

### Added
- **Testing**: Implemented comprehensive unit and integration tests (via `axum-test`) for all API endpoints and core logic.
- **CI/CD**: Enforced strict code coverage thresholds (Lines: 35%, Functions: 35%, Regions: 40%) using `cargo-llvm-cov` in `Makefile.toml` and GitHub Actions.

### Changed
- **Release**: Bumped workspace version to 1.1.0 for test coverage enforcement updates.
- **Security**: Updated `spin` crate from `v0.9.8` to `v0.9.9` to resolve a yanked dependency flagged by `cargo audit`.
- **Code Quality**: Cleaned up unused variables in integration tests to ensure a warning-free `cargo clippy` run.

## [1.0.0] - 2026-07-12

### Added
- **Security**: Added explicit CORS configuration logic using `tower_http::cors::CorsLayer`.
- **Tooling**: Implemented cross-platform `cargo-make` build tasks in `Makefile.toml` for unified CI/CD.

### Changed
- **Release**: Bumped workspace version to 1.0.0 for stable release.
- **Error Handling**: Standardized API JSON errors using a custom `AppJson` extractor to prevent plain-text leaks on 400/415 errors.
- **Error Handling**: Formatted `tower_governor` 429 rate limit responses into standardized JSON.
- **Security**: Ignored upstream unpatchable vulnerabilities (`RUSTSEC-2023-0071`, `RUSTSEC-2026-0097`) in `cargo audit` to unblock CI.

### Removed
- **Tooling**: Deleted legacy `Makefile` and `make.ps1` scripts in favor of the new `Makefile.toml`.

## [0.0.2] - 2026-07-12

### Changed
- **Performance**: Replaced per-request MSSQL TCP handshakes with a `bb8-tiberius` async connection pool.
- **Performance**: Upgraded sequential CUD handler loops to run concurrent futures via `buffer_unordered` (bounded by `BATCH_CONCURRENCY_LIMIT`).
- **Security**: Hardened API key validation using `subtle::ConstantTimeEq` to prevent timing side-channel attacks.
- **Correctness**: Ensured GET/QUERY routes don't enforce `Content-Type` headers.
- **Config**: Exposed DB pool tuning settings (`DB_POOL_MAX`, timeouts) and MSSQL TLS encryption settings via environment variables.

## [0.0.1] - 2026-07-11

### Added
- **Monorepo Structure**: Fully initialized the project as a Cargo workspace with 5 dedicated crates (`newsfeed-constants`, `newsfeed-config`, `newsfeed-models`, `newsfeed-db`, `newsfeed-service`, `newsfeed-server`).
- **Data Layer**: Implemented database access logic via `sqlx` (Postgres, MariaDB) and `tiberius` (MSSQL).
- **Service Layer**: Ported all Python business logic for payload and header validation into the `newsfeed-service` crate.
- **API Server**: Replaced FastAPI with an Axum HTTP server in `newsfeed-server`.
- **Security Middleware**: 
  - Added O(1) `HashSet` based `API_KEY` validation middleware.
  - Implemented token bucket rate limiting using `tower_governor` per-IP.
  - Configured `tower_http` for CORS and tracing layers.
- **Docker Support**: Created a highly optimized multi-stage `Dockerfile` and `docker-compose.yml` for isolated container deployment.
- **Security Tooling**: Added cross-platform scripts (`generate-api-key`, `revoke-api-key` in `.sh` and `.ps1`) to securely manage keys in the environment variable.

### Changed
- **Tech Stack**: Migrated the entire codebase from Python (FastAPI) to Rust (Axum, sqlx, tiberius) for improved performance and type safety.

### Removed
- **Legacy Files**: Removed the legacy Python scripts (`constants.py`, `newsfeedwebservice.py`, etc.) as the migration is complete.
