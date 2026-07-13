# =============================================================================
#  Newsfeed Web Service — Multi-Stage Dockerfile
#
#  Stage 1 (builder): Compiles the release binary using the official Rust image.
#  Stage 2 (runtime): Minimal Debian runtime — no Rust toolchain, no Python,
#                     no ODBC.  Final image ≈ 50–80 MB.
#
#  Build args:
#    TIMEZONE_LOCATION — e.g. America/Los_Angeles (passed from docker-compose)
# =============================================================================

# ── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM rust:1.97-slim-bookworm AS builder

WORKDIR /build

# Install build-time OS dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy workspace manifests first so Cargo can fetch dependencies in a
# separate layer — rebuilt only when Cargo.toml / Cargo.lock change.
COPY Cargo.toml Cargo.lock ./

# Copy all crate source trees
COPY newsfeed/crates/ newsfeed/crates/

# Build the release binary with locked dependencies (no network fetch at build time).
RUN cargo build --release --locked -p newsfeed-server

# ── Stage 2: Runtime (minimal) ────────────────────────────────────────────────
FROM debian:bookworm-slim AS runtime

ARG TIMEZONE_LOCATION=America/Los_Angeles
ENV TZ=${TIMEZONE_LOCATION}

# Install only what the runtime binary needs
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        tzdata \
        ca-certificates \
    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/bin

# Copy the compiled binary from the builder stage
COPY --from=builder /build/target/release/newsfeed-server ./newsfeed-server

# Make the binary executable
RUN chmod +x ./newsfeed-server

EXPOSE 4815

# Run as a non-root user for security
RUN useradd -r -s /bin/false newsfeed
USER newsfeed

ENTRYPOINT ["./newsfeed-server"]
