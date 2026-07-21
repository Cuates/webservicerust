# Newsfeed Web Service

[![GitHub Version](https://img.shields.io/github/v/tag/cuates/webservicerust?label=version&sort=semver)](https://github.com/cuates/webservicerust/releases)
[![Build Status](https://img.shields.io/github/actions/workflow/status/cuates/webservicerust/newsfeed-ci.yml?branch=main)](https://github.com/cuates/webservicerust/actions)
[![Coverage](https://img.shields.io/badge/coverage-99%25-brightgreen.svg)](Makefile.toml)
[![Rust](https://img.shields.io/badge/Rust-1.97+-black?logo=rust)](https://www.rust-lang.org/)
[![Axum](https://img.shields.io/badge/Axum-0.8-red)](https://github.com/tokio-rs/axum)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A high-performance, strongly-typed Newsfeed API written in Rust. This project replaces a legacy Python FastAPI monolith with a modular Cargo workspace architecture.

## Overview

The Newsfeed web service handles CRUD operations for user newsfeeds, supporting multiple database backends dynamically at runtime (PostgreSQL, MariaDB, and MSSQL). It provides timing-attack resistant `SHA-256` API key authentication, IP-based token-bucket rate limiting, highly optimized database connection pooling (including tuned `bb8` pools), strict 500-item batch processing limits, and interactive OpenAPI (Swagger) documentation. It guarantees stability through strict CI/CD code coverage thresholds (currently verified at 99.54%).

## Architecture

The project is structured as a Cargo workspace with the following crates:

- **`newsfeed-constants`**: Static string definitions, routes, unified HTTP error code constants, and compiled regexes.
- **`newsfeed-config`**: Environment variable parsing and type-safe configuration.
- **`newsfeed-models`**: Shared domain models and HTTP payload/response types.
- **`newsfeed-db`**: Database access layer abstracting connection pools and SQL engines.
- **`newsfeed-service`**: Core business logic and request orchestrator.
- **`newsfeed-server`**: The Axum HTTP server and middleware stack.

## Documentation

Comprehensive guides are available in the `docs/` directory:

- [Architecture Overview](docs/architecture.md)
- [Scaffolding & Setup](docs/scaffolding.md)
- [Distribution, Docker, & GitHub Releases](docs/distribution.md)
- [Cargo Make Commands](docs/cargo-make.md)
- [Troubleshooting](docs/troubleshooting.md)

## Quick Start

1. Clone the repository.
2. Copy `.env.example` to `.env` and fill in your database credentials.
3. Run `./scripts/generate-api-key.sh` to generate an access token.
4. Run `docker compose up --build` to start the application on port `4815`.
