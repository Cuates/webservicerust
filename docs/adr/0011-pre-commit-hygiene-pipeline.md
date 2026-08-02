<!-- markdownlint-disable MD013 -->
# 11. Pre-Commit Hygiene Pipeline

Date: 2026-08-01

## Status

Accepted

## Context

As the monorepo has grown, manual checks for unused dependencies, compilation warnings, dead code, markdown styling, and test coverage regressions have proven insufficient. Allowing unformatted code, bloated manifests, or degraded coverage metrics to reach the GitHub Actions CI pipeline leads to wasted CI minutes, slow feedback loops, and merged technical debt.

## Decision

We establish a mandatory, strictly-enforced local pre-commit hygiene pipeline powered by `cargo make`. 

Developers must run and pass the full suite of checks locally before committing to the repository:

1. **Compilation**: `cargo make check`
2. **Dead Code**: `cargo make check-deadcode`
3. **Dependency Pruning**: `cargo make machete` (must return zero unused crates)
4. **Fixing & Formatting**: `cargo make fix` (applies formatting and safe clippy fixes)
5. **Security Scan**: `cargo make audit`
6. **Code Coverage**: `cargo make test-coverage` (must satisfy the strict `>99%` line and function thresholds)
7. **Documentation Linting**: `cargo make lint-docs`

This pipeline is mirrored exactly by the GitHub Actions `newsfeed-ci.yml` workflow to ensure an impenetrable quality gate.

## Consequences

* **Positive**: Guarantees zero-defect commits regarding style, dependency bloat, and coverage regressions.
* **Positive**: Drastically reduces CI failure rates, saving compute resources and developer time.
* **Negative/Constraint**: Developers face a higher friction loop locally when attempting to quickly commit experimental code, as they must explicitly address all warnings and coverage drops first.
