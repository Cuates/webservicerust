# `newsfeed-server`

The Application Entrypoint and HTTP Server.

## Purpose

This is the only binary crate in the workspace. It compiles down to the actual executable that serves HTTP traffic.

## Features

- **Axum Router**: Maps HTTP methods (`GET`, `POST`, `PUT`, `DELETE`) to explicit handler functions.
- **Security Middleware**:
  - `tower_governor`: A Token Bucket rate limiter mitigating DDoS and brute-force attempts on a per-IP basis (evaluated *before* API key validation), equipped with customized JSON `429` error responses.
  - `api_key::api_key_middleware`: Intercepts requests, checking the `X-API-Key` header using a timing-attack resistant `SHA-256` hashing mechanism.
- **Error Standardization**: Implements a custom `AppJson` extractor overriding Axum's default serialization. It maps extraction failures into structured JSON using unified constants (e.g., `Code: "BAD_REQUEST"`) instead of plain-text stack traces.
- **Tracing & CORS**: Integrates `tower_http` layers for robust structured logging and Cross-Origin Resource Sharing capabilities.
- **Graceful Shutdown**: Listens for SIGINT (Ctrl+C) and terminates active connections gracefully.
- **OpenAPI / Swagger**: Uses `utoipa` to auto-generate OpenAPI specifications and hosts a Swagger UI dashboard at `/swagger-ui`.
- **Integration Testing**: Contains the workspace's comprehensive `axum-test` integration test suite within the `tests/` directory to verify the full middleware and routing stack. It utilizes `testcontainers` to automatically spin up and tear down isolated testing databases.
