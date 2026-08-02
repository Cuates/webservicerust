<!-- markdownlint-disable MD013 -->
# `newsfeed-server`

The Application Entrypoint and HTTP Server.

## Purpose

This is the only binary crate in the workspace. It compiles down to the actual executable that serves HTTP traffic.

## Features

- **Axum Router**: Maps HTTP methods (`GET`, `POST`, `PUT`, `DELETE`) to explicit handler functions.
- **Security Middleware**:
  - `tower_governor`: A Token Bucket rate limiter mitigating DDoS and brute-force attempts on a per-IP basis (evaluated *before* API key validation), equipped with customized JSON `429` error responses. Note that this rate limiter operates in-memory per service replica; for multi-replica deployments behind a load balancer without sticky sessions, rate limits apply per individual replica.
  - `ip_extractor::secure_ip_extractor`: Acts as a secure proxy fallback middleware for rate-limiting behind load balancers, extracting real client IPs from `X-Forwarded-For` or `X-Real-IP` headers.
  - `api_key::api_key_middleware`: Intercepts requests, checking the `X-API-Key` header using a timing-attack resistant `SHA-256` hashing mechanism.
- **Error Standardization**: Implements a custom `AppJson` extractor overriding Axum's default serialization, mapping extraction failures into structured JSON using unified constants (e.g., `Code: "BAD_REQUEST"`) instead of plain-text stack traces. Also includes `not_found.rs` as a fallback handler to guarantee unmapped routes return structured JSON `404` errors.
- **Payload Validation**: Houses HTTP boundary validation logic natively within `validation.rs`, ensuring required fields, parameters (like extraction limits), and strict `RFC3339` date formats are validated securely before reaching the core service layer.
- **Tracing & CORS**: Integrates `tower_http` layers for robust structured logging and Cross-Origin Resource Sharing capabilities.
- **Graceful Shutdown**: Employs `shutdown.rs` to listen for SIGINT (Ctrl+C) and OS signals cross-platform (including Windows) and terminates active connections gracefully.
- **OpenAPI / Swagger**: Uses `utoipa` to auto-generate OpenAPI specifications and hosts a Swagger UI dashboard at `/swagger-ui`.
- **Integration Testing**: Contains the workspace's comprehensive `axum-test` integration test suite within the `tests/` directory to verify the full middleware and routing stack. It utilizes `testcontainers` to automatically spin up and tear down fully isolated testing databases across the entire matrix (PostgreSQL, MariaDB, MSSQL). To speed up local testing or test against external databases, you can bypass `testcontainers` by providing live database URLs via `TEST_POSTGRES_URL`, `TEST_MARIADB_URL`, or `TEST_MSSQL_URL`/`TEST_MSSQL_PORT`.
