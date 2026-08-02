<!-- markdownlint-disable MD013 -->
# Newsfeed Web Service

[![GitHub Version](https://img.shields.io/github/v/tag/cuates/webservicerust?label=version&sort=semver)](https://github.com/cuates/webservicerust/releases)
[![Build Status](https://img.shields.io/github/actions/workflow/status/cuates/webservicerust/newsfeed-ci.yml?branch=main)](https://github.com/cuates/webservicerust/actions)
[![Coverage](https://img.shields.io/badge/coverage-99%25-brightgreen.svg)](Makefile.toml)
[![Rust](https://img.shields.io/badge/Rust-1.97+-black?logo=rust)](https://www.rust-lang.org/)
[![Axum](https://img.shields.io/badge/Axum-0.8-red)](https://github.com/tokio-rs/axum)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![MariaDB](https://img.shields.io/badge/MariaDB-003545?logo=mariadb&logoColor=white)](https://mariadb.org/)
[![MSSQL](https://img.shields.io/badge/MSSQL-CC2927?logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/en-us/sql-server)
[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A high-performance, strongly-typed Newsfeed API written in Rust. This project replaces a legacy Python FastAPI monolith with a modular Cargo workspace architecture.

## Overview

The Newsfeed web service handles CRUD operations for user newsfeeds, supporting multiple database backends dynamically at runtime (PostgreSQL, MariaDB, and MSSQL). It provides timing-attack resistant `SHA-256` API key authentication, IP-based token-bucket rate limiting, highly optimized database connection pooling (including tuned `bb8` pools), strict 1000-item batch processing limits, and interactive OpenAPI (Swagger) documentation. It guarantees stability through strict CI/CD code coverage thresholds (currently verified at >99%).

## Architecture & Key Features

The project is structured as a Cargo workspace with the following crates:

- **`newsfeed-constants`**: Static string definitions, routes, unified HTTP error code constants, and compiled regexes.
- **`newsfeed-config`**: Environment variable parsing and type-safe configuration.
- **`newsfeed-models`**: Shared domain models and HTTP payload/response types.
- **`newsfeed-db`**: Database access layer abstracting connection pools and SQL engines.
- **`newsfeed-service`**: Core business logic and request orchestrator. Enforces strict bulk batch processing rules.
- **`newsfeed-server`**: The Axum HTTP server, routing, middleware stack, and strict HTTP payload validation (including strict `RFC3339` date enforcement).

### Rate Limiting Architecture Notice

The IP-based token-bucket rate limiter (`tower_governor`) operates **in-memory per service instance (replica)**. For multi-replica deployments behind a load balancer, clients should be aware that rate limits apply per individual replica unless load balancer session stickiness is enabled or an external distributed rate-limiting layer (e.g., API Gateway, Redis-backed rate limiter) is implemented in front of the cluster.

### Multi-Database Support & Testing

The service dynamically targets PostgreSQL, MariaDB/MySQL, or MSSQL at runtime based on the `DATABASE_TARGET` environment variable (`postgres`, `mariadb`, or `mssql`).

During integration testing, the suite automatically uses `testcontainers` to spin up ephemeral Docker containers for the target database. You can bypass `testcontainers` and connect directly to a live database instance by setting any of the following environment variable overrides:

- `TEST_POSTGRES_URL="postgres://user:pass@host:5432/db"`
- `TEST_MARIADB_URL="mysql://user:pass@host:3306/db"`
- `TEST_MSSQL_URL="sqlserver://host:1433;user=user;password=pass;database=db"` (or `TEST_MSSQL_PORT="1433"`)

## Cross-Platform Development & Quick Start

The service and CI pipelines are built to be completely cross-platform across Linux, Windows (PowerShell/pwsh), and macOS.

1. Clone the repository and install `cargo-make` (`cargo install cargo-make`).
2. Copy `.env.example` to `.env` and configure your target database credentials.
3. Run `./scripts/generate-api-key.sh` (Linux/macOS) or `./scripts/generate-api-key.ps1` (Windows pwsh) to generate an API access key.
4. Verify code compilation and run tests across platforms using Cargo Make:
   - `cargo make check` — Verify syntax and compilation.
   - `cargo make machete` — Audit workspace dependency tree for unused crates.
   - `cargo make test` — Run all unit and integration tests across the workspace.
   - `cargo make test-coverage` — Verify >99% line and function test coverage.
5. Run locally via Docker: `docker compose up --build` to start the application on port `4815`.

## Documentation

Comprehensive guides are available in the `docs/` directory:

- [Architecture Overview](docs/architecture.md)
- [Scaffolding & Setup](docs/scaffolding.md)
- [Distribution, Docker, & GitHub Releases](docs/distribution.md)
- [Cargo Make Commands](docs/cargo-make.md)
- [Troubleshooting](docs/troubleshooting.md)
