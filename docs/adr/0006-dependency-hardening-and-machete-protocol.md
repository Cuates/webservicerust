<!-- markdownlint-disable MD013 -->
# 6. Dependency Hardening and Machete Protocol

Date: 2026-07-25

## Status

Accepted

## Context

In a multi-crate Rust monorepo, dependencies can easily become bloated as features evolve, crates are refactored, or libraries are replaced. Unused dependencies increase compilation times, inflate Docker binary sizes, expand the surface area for security vulnerabilities, and complicate dependency auditing. Furthermore, standard Cargo tooling does not aggressively flag unused dependencies in `Cargo.toml`.

## Decision

We will adopt `cargo-machete` as a mandatory dependency auditing tool across the entire `webservicerust` workspace.

1. **Automated Auditing**: Developers must run `cargo make machete` locally (which wraps the standard tool via our `Makefile.toml`) before submitting changes that modify crate manifests.
2. **CI Enforcement**: The continuous integration pipeline (`newsfeed-ci.yml`) executes `cargo-machete` against all workspace crates. Any detected unused dependency fails the CI build immediately.
3. **Zero Unused Crates Policy**: Every crate listed in `[dependencies]`, `[dev-dependencies]`, or `[build-dependencies]` must be actively used in code.

## Consequences

* **Positive**: Reduced compilation times and smaller final binary footprints.
* **Positive**: A cleaner, minimal dependency graph that is easier to maintain and audit for security vulnerabilities (`cargo audit`).
* **Negative/Constraint**: Developers must explicitly remove leftover crate dependencies when refactoring code away from a library, rather than leaving them in `Cargo.toml`.
