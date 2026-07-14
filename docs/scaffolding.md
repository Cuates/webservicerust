# Scaffolding & Setup

This guide explains how to set up the Newsfeed web service for local development.

## 1. Prerequisites

- **Rust Toolchain**: Install via [rustup](https://rustup.rs/). The project requires Rust `1.85` or later.
- **Docker**: For running databases and the final container image locally.
- **A Target Database**: PostgreSQL, MariaDB, or MSSQL.
- **`cargo-llvm-cov`** *(Optional)*: Required only if you want to generate code coverage reports. Install globally via `cargo install cargo-llvm-cov`.

## 2. Environment Configuration

The application requires environment variables to run.

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` to configure your target database:
   - `DATABASE_TARGET`: Set this to `postgres`, `mariadb`, or `mssql`.
   - Update the respective connection string (`POSTGRES_DB_URL`, `MARIADB_DB_URL`, or `MSSQL_DB_URL`).
   - Configure `RATE_LIMIT_RPS` and `RATE_LIMIT_BURST` if defaults aren't suitable.

## 3. Generating API Keys

The application requires at least one API key configured in the `API_KEYS` environment variable. 

We provide cross-platform scripts to securely generate keys and append them directly to your `.env` file.

**On Linux/macOS:**
```bash
./scripts/generate-api-key.sh
```

**On Windows (PowerShell):**
```powershell
.\scripts\generate-api-key.ps1
```

You can view or revoke active keys securely using the `revoke-api-key` script in the same folder.

## 4. Building, Testing, and Running Locally

To build and test the workspace locally without Docker, we use `cargo-make` shortcuts:

```bash
# Check compilation across all workspace crates
cargo make check

# Run the test suite and enforce code coverage (Lines: 35%, Functions: 35%, Regions: 40%)
cargo make test-coverage

# Run the server binary directly
cargo make run
```

When running natively, ensure the `.env` file is in the current working directory, as the application uses `dotenvy` to load it dynamically.

Once the server is running, you can view the interactive OpenAPI documentation at:
`http://localhost:4815/swagger-ui`
