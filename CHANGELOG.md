# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
