# 3. Testcontainers for Integration Testing

Date: 2026-07-18

## Status

Accepted

## Context

Previously, integration testing required manually spinning up a dedicated `docker-compose.test.yml` to host PostgreSQL, MariaDB, and MSSQL instances. This approach was brittle, required developers to remember to start and stop services, often led to port conflicts on local machines, and made CI/CD pipeline automation cumbersome as we had to manage the lifecycle of external daemon processes.

## Decision

We will use the `testcontainers` crate to programmatically provision fully isolated, ephemeral database instances during the `axum-test` integration test suite.

1. **Dynamic Provisioning**: Integration tests will dynamically download (if missing) and start the necessary Docker images (`postgres`, `mariadb`, `mcr.microsoft.com/mssql/server`) directly within the Rust test runner.
2. **Randomized Ports**: Each container will bind to a random host port, completely eliminating port collisions and allowing parallel test execution across multiple CI runners.
3. **Automated Teardown**: `testcontainers` utilizes the `Drop` trait to automatically stop and remove the containers once the tests conclude or if a panic occurs, guaranteeing no orphaned processes.
4. **Active Connection Polling**: To circumvent startup race conditions inherent to container lifecycles (where a database engine logs that it is "ready" before actually opening its TCP socket), tests will employ a dynamic retry loop to repeatedly attempt a connection rather than relying on static timeouts.
5. **Separation of Concerns**: The manual `docker-compose.test.yml` will remain in the repository *strictly* for developers who wish to connect a GUI client (like DBeaver) for manual inspection, but it is entirely decoupled from the automated test suite.

## Consequences

*   **Positive**: Zero-configuration testing. A developer or CI runner simply types `cargo make test` and the entire matrix of databases is bootstrapped, seeded, and destroyed automatically.
*   **Positive**: Eliminates state leakage between test runs.
*   **Negative/Constraint**: The host machine (or CI runner) MUST have a Docker daemon installed and running for the Rust test suite to execute successfully. If Docker is missing, `cargo test` will panic.
