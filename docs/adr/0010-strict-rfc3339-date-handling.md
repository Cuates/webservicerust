<!-- markdownlint-disable MD013 -->
# 10. Strict RFC3339 Date Handling

Date: 2026-08-01

## Status

Accepted

## Context

In an environment spanning multiple database engines (PostgreSQL, MariaDB, MSSQL) and diverse client integrations, passing ambiguous date strings (e.g., `YYYY-MM-DD` or implicit local times) can lead to mismatched behaviors, timezone drift, and HTTP 500 errors during deserialization. Inconsistent date handling forces backend layers to guess intent, leading to data integrity risks.

## Decision

We enforce strict `RFC3339` date handling universally across the monorepo for all inbound JSON payloads and query parameters.

1. **Validation Boundary**: All date fields in our `ExtractParams` and `CudParams` models must strictly deserialize using an explicit `RFC3339` format (e.g., `2026-07-23T00:00:00Z`).
2. **Rejection Policy**: If a client provides an ambiguous date (e.g., `2026-07-23` without time/timezone), the payload validation layer in `newsfeed-server` will automatically intercept and reject the request with a structured HTTP 422 `VALIDATION_ERROR`, halting execution before it reaches the business logic.

## Consequences

* **Positive**: Absolute cross-engine parity in how dates are serialized to and from the database.
* **Positive**: Eliminates timezone ambiguity bugs.
* **Negative/Constraint**: Clients must ensure their applications format dates strictly according to `RFC3339`, even when only submitting day-level precision data.
