<!-- markdownlint-disable MD013 MD025 -->
# Architecture Decision Record

# 0009. Cross-Engine Bulk CUD Parity

## Status

Accepted

## Context

Our application natively supports PostgreSQL, MariaDB, and MSSQL. Initially, MSSQL utilized a highly efficient `cud_bulk_json_newsfeed` stored procedure that allowed the Rust layer to serialize up to 500 records into a single JSON string and execute the batch within one transaction. However, Postgres and MariaDB were iterating over the items natively in Rust, executing `N` individual SQL statements per batch.

## Decision

We established architectural parity across all three engines by porting the `cud_bulk_json_newsfeed` procedure pattern to PostgreSQL and MariaDB. The `newsfeed-db` crate now universally serializes the `Vec<CudParams>` into a single JSON payload and invokes the bulk procedure exactly once per request across all supported database backends.

## Consequences

- **Positive**: Massively improved throughput and latency for bulk operations on Postgres and MariaDB, matching the MSSQL performance baseline.
- **Positive**: Simplified the Rust DB codebase by replacing procedural looping constructs with unified single-call execution patterns in `postgres.rs` and `mariadb.rs`.
- **Negative**: The underlying SQL migrations are significantly more complex, as they must parse JSON arrays and manage conflict behaviors dynamically within the respective SQL dialects (PL/pgSQL and MariaDB SQL) rather than natively in Rust.
