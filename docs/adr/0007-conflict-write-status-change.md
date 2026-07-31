<!-- markdownlint-disable MD013 MD025 -->
# Architecture Decision Record

# 0007. Conflict-Write Status Normalization ("Success" → "Skipped")

## Status

Accepted

## Context

In previous iterations of the web service and its underlying stored procedures/functions across PostgreSQL, MariaDB, and MSSQL, conflict-write no-op operations (such as inserting a record with a title that already exists, or attempting to update a record that does not exist) returned a status of `"Success"` with message strings such as `"Record exist"` or `"Record does not exist"`.

This behavior created semantic ambiguity: consumers could not easily distinguish between a mutation that actually altered database state versus a no-op conflict without parsing human-readable error messages. Furthermore, maintaining strict behavioral parity with legacy systems required a clean, strongly typed discrimination of operation outcomes at the Rust layer.

## Decision

We decided to normalize all conflict-write no-op responses across all database engines and the Rust service layer from `"Success"` to `"Skipped"`:

1. **Database Migration SQL**: Updated the `insertupdatedeletenewsfeed` stored procedures and functions across PostgreSQL, MariaDB, and MSSQL to return `"Status": "Skipped"` with explicit descriptive messages (`"Record already exists"` or `"Record does not exist"`) when an operation is bypassed due to existing or missing state.
2. **Typed Result Models**: Introduced the `CudStatus` enum (`Success`, `Skipped`, `Error`) and `CudResult` struct in `newsfeed-db` / `newsfeed-models`, replacing untyped `serde_json::Value` responses.
3. **Legacy Parity & Normalization**: To preserve compatibility during rollout and ensure resilience against legacy database instances, `parse_status_rows` in `shared.rs` normalizes both explicit `"Skipped"` statuses and legacy `"Success"` responses bearing `"Record exist"` messages into `CudStatus::Skipped`.

## Consequences

- **Positive**: Eliminates semantic ambiguity between true state mutations and no-op conflicts, allowing API clients and service logic to handle idempotent retries reliably.
- **Positive**: Establishes strict type safety across the CUD handler boundary by replacing unstructured JSON values with `CudResult` and `CudStatus`.
- **Negative / Backward Compatibility**: API consumers that previously relied on receiving `"Status": "Success"` for duplicate inserts must be updated to expect `"Status": "Skipped"`. The normalization layer in `parse_status_rows` mitigates internal risk by bridging legacy database outputs to the new enum.
