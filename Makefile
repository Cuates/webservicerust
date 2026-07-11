# =============================================================================
#  Newsfeed Web Service — Makefile
#  All commands delegate to cargo or docker compose.
#  Run: make <target>
# =============================================================================

.PHONY: build build-dev check check:deadcode clean fix audit test test:coverage \
        docker-build docker-up docker-down docker-logs docker-restart \
        key-gen key-revoke help

# ── Rust / Cargo ─────────────────────────────────────────────────────────────

build:
	cargo build --release --locked

build-dev:
	cargo build

check:
	cargo check --workspace

check\:deadcode:
	cargo clippy --workspace -- -D dead_code

clean:
	cargo clean

fix:
	cargo fmt --all
	cargo clippy --workspace --fix --allow-dirty --allow-staged -- -D warnings

audit:
	cargo audit

test:
	cargo test --workspace

test\:coverage:
	cargo llvm-cov --workspace --all-features --lcov --output-path lcov.info

# ── Docker ────────────────────────────────────────────────────────────────────

docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-restart:
	docker compose down && docker compose up -d

docker-logs:
	docker compose logs -f newsfeed-server

# ── API Key Management ────────────────────────────────────────────────────────

key-gen:
	@bash scripts/generate-api-key.sh

key-revoke:
	@bash scripts/revoke-api-key.sh

# ── Help ──────────────────────────────────────────────────────────────────────

help:
	@echo "Available targets:"
	@echo "  build          Build release binary (--locked)"
	@echo "  build-dev      Build debug binary"
	@echo "  check          cargo check all crates"
	@echo "  check:deadcode cargo clippy to deny dead code across all crates"
	@echo "  clean          cargo clean build artifacts"
	@echo "  fix            Format code and automatically fix clippy warnings"
	@echo "  audit          Run cargo audit for vulnerabilities"
	@echo "  test           Run all workspace tests"
	@echo "  test:coverage  Run tests and generate lcov.info coverage report"
	@echo "  docker-build   Build Docker image"
	@echo "  docker-up      Start containers (detached)"
	@echo "  docker-down    Stop containers"
	@echo "  docker-restart Restart containers"
	@echo "  docker-logs    Follow container logs"
	@echo "  key-gen        Generate a new API key"
	@echo "  key-revoke     Revoke an existing API key"
