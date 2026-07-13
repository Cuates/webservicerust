# `newsfeed-server`

The Application Entrypoint and HTTP Server.

## Purpose

This is the only binary crate in the workspace. It compiles down to the actual executable that serves HTTP traffic.

## Features

- **Axum Router**: Maps HTTP methods (`GET`, `POST`, `PUT`, `DELETE`) to explicit handler functions.
- **Security Middleware**:
  - `api_key::api_key_middleware`: Intercepts requests, checking the `X-API-Key` header against the loaded `HashSet` in `AppState`.
  - `tower_governor`: A Token Bucket rate limiter mitigating DDoS and brute-force attempts on a per-IP basis, equipped with customized JSON `429` error responses.
- **Error Standardization**: Implements a custom `AppJson` extractor overriding Axum's default serialization to ensure `400` and `415` errors are returned as structured JSON instead of plain-text.
- **Tracing & CORS**: Integrates `tower_http` layers for robust structured logging and Cross-Origin Resource Sharing capabilities.
- **Graceful Shutdown**: Listens for SIGINT (Ctrl+C) and terminates active connections gracefully.
