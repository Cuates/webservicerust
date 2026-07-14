# 2. GitHub Actions Release Pipeline

Date: 2026-07-13

## Status

Accepted

## Context

As the `webservicerust` monorepo grows, we need a reliable, automated way to build and distribute compiled release artifacts for the `newsfeed` web service API. The official `actions/create-release` action was deprecated and archived by GitHub, requiring us to choose a community standard alternative. Furthermore, the monorepo structure introduces complexities around triggering releases without kicking off builds for unrelated sibling projects.

## Decision

We will implement a GitHub Actions workflow to automate the release process with the following architectural choices:

1.  **Community Action**: We will use `softprops/action-gh-release` to handle the creation of GitHub Releases and the uploading of assets, as it is the most widely adopted and stable community replacement.
2.  **Monorepo Tagging Convention**: To isolate the `newsfeed` release lifecycle from future web services in this monorepo, the workflow will only trigger on tags matching the `newsfeed-v*` pattern (e.g., `newsfeed-v1.1.0`).
3.  **Target Architectures**: The build matrix will explicitly target the default `x86_64` architecture for Linux and Windows, and the universal/default architecture for macOS. No specialized cross-compilation targets (e.g., `aarch64-unknown-linux-gnu`) will be added to avoid immediate complexities with cross-compiling native C-dependencies.
4.  **Bundled Assets**: To ensure operators have the necessary operational context, the compiled `newsfeed-server` binary will be bundled into a compressed archive (`.tar.gz` or `.zip`) alongside the `.env.example`, `README.md`, and `LICENSE` files.

## Consequences

*   **Positive**: Releases are fully automated, consistent, and strictly isolated per project within the monorepo. Operators receive a self-contained archive with the binary and necessary configuration templates.
*   **Negative/Constraint**: Deployment environments must be `x86_64` (or universal macOS). If we require deployment to ARM-based Linux servers (like AWS Graviton) in the future, we will need to revisit the pipeline to handle cross-compilation for native dependencies (like `sqlx` and `native-tls`).
