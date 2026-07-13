# Cargo Make Commands

The project includes a `Makefile.toml` at the root directory to simplify executing common Rust/Cargo, Docker, and utility commands across all platforms. 

You can run any of these commands from the root directory using:
```bash
cargo make <target>
```

## Available Targets

To view a quick summary of all available targets in your terminal, run:
```bash
cargo make help
```

### 🦀 Rust / Cargo Commands

These targets wrap the standard Cargo commands to act across the entire workspace.

| Target | Description | Underlying Command |
|---|---|---|
| **`cargo make build`** | Builds the release-optimized binary for production. Uses `--locked` to ensure dependencies exactly match `Cargo.lock`. | `cargo build --release --locked` |
| **`cargo make build-dev`** | Builds the unoptimized debug binary for rapid local development. | `cargo build` |
| **`cargo make info`** | Prints out a highly formatted summary of the active Rust toolchain, operating system, and all workspace crates. | `duckscript` (custom) |
| **`cargo make check`** | Quickly checks all workspace crates for compilation errors. | `cargo check --workspace` |
| **`cargo make check:deadcode`** | Runs clippy specifically to deny any dead code across the workspace. | `cargo clippy --workspace -- -D dead_code` |
| **`cargo make clean`** | Removes the `target/` directory and build artifacts. | `cargo clean` |
| **`cargo make fix`** | Formats code and automatically applies clippy fixes. | `cargo fmt --all && cargo clippy --workspace --fix --allow-dirty --allow-staged -- -D warnings` |
| **`cargo make audit`** | Scans dependency tree for security vulnerabilities (requires `cargo-audit`). | `cargo audit` |
| **`cargo make test`** | Runs all unit and integration tests across the entire workspace. | `cargo test --workspace` |
| **`cargo make test:coverage`** | Generates an lcov coverage report for tests (requires `cargo-llvm-cov`). | `cargo llvm-cov --workspace --all-features --lcov --output-path lcov.info` |

### 🐳 Docker Commands

These targets wrap Docker Compose to simplify container orchestration.

| Target | Description | Underlying Command |
|---|---|---|
| **`cargo make docker-build`** | Builds the multi-stage Docker image using `docker-compose.yml`. | `docker compose build` |
| **`cargo make docker-up`** | Starts the application and its dependencies in the background (detached mode). | `docker compose up -d` |
| **`cargo make docker-down`** | Stops and removes the running containers and networks. | `docker compose down` |
| **`cargo make docker-restart`** | Quickly restarts the containers. Useful when changing `.env` variables. | `docker compose down && docker compose up -d` |
| **`cargo make docker-logs`** | Follows (tails) the logs from the `newsfeed-server` container in real time. | `docker compose logs -f newsfeed-server` |

### 🔑 Security & Key Management

Shortcuts for running the API key shell scripts (assumes a bash environment).

| Target | Description | Underlying Command |
|---|---|---|
| **`cargo make key-gen`** | Interactively generates a new secure API key and appends it to `.env`. | `bash scripts/generate-api-key.sh` |
| **`cargo make key-revoke`** | Interactively lists active keys and safely removes a selected key from `.env`. | `bash scripts/revoke-api-key.sh` |
