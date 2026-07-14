# Project-Scoped Rules for AI Agents

These rules apply universally to any AI agent operating within the `webservicerust` workspace.

## 1. Safety and Security First
- **No Secret Generation in Code**: Never hardcode API keys or credentials. If tests require keys, instruct the user to run `./scripts/generate-api-key.sh`.
- **Destructive Actions**: Always ask for explicit permission before running destructive SQL queries or deleting structural directories.

## 2. Compilation and Testing
- If you modify Rust code, you MUST run `cargo make check` to verify your changes. Do not assume your code compiles.
- Run `cargo make test-coverage` to ensure your new logic does not drop the coverage thresholds below the CI-enforced limits.
- Fix all warnings (e.g., unused imports) before completing a task to maintain a clean CI pipeline.

## 3. Documentation Sync
- If you introduce a new feature or crate, you must update the relevant `README.md` files.
- If you change the directory structure, you must update the ASCII tree in `docs/architecture.md`.
- If you make a significant architectural change, you must propose a new ADR in `docs/adr/`.

## 4. Communication Style
- Be concise. The codebase is fully established; you do not need to explain basic Rust concepts (like what `tokio` or `axum` is) unless explicitly asked.
- Focus strictly on the task requested.
