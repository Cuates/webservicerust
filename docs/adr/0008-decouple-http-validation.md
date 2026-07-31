<!-- markdownlint-disable MD013 MD025 -->
# Architecture Decision Record

# 0008. Decouple HTTP Payload Validation

## Status

Accepted

## Context

Historically, HTTP payload validation (including checking for required fields, whitespace, and payload sizes) was embedded deeply within the `newsfeed-service` crate (`payload_validator.rs`). While functional, this tightly coupled the core business orchestration logic to HTTP-specific concepts and `serde_json::Value` manipulations. Furthermore, empty strings and whitespace-only strings were passing through the initial deserialization layer and failing late in the service layer.

## Decision

We decided to decouple payload validation entirely from the service layer and move it to the HTTP boundary within the `newsfeed-server` crate (`validation.rs`).

Additionally, we implemented `deserialize_non_empty_option` in `newsfeed-models` to natively instruct `serde` to trim and reject whitespace-only strings at the deserialization boundary. We also clamped extraction limits (1-100) at the `ExtractParams` layer to prevent unbounded GET requests.

## Consequences

- **Positive**: Core business logic in `newsfeed-service` is now significantly cleaner, orchestrating only fully sanitized and strictly typed payloads.
- **Positive**: Invalid, inflated, or whitespace-only payloads are rejected immediately at the HTTP boundary, preserving CPU cycles and preventing bad data from leaking deeper into the stack.
- **Negative**: The `newsfeed-server` crate carries a slightly heavier validation burden, though this properly aligns with its role as the presentation layer.
