#!/usr/bin/env bash
# =============================================================================
#  generate-api-key.sh
#  Generates a cryptographically secure API key and appends it to API_KEYS
#  in the .env file at the repository root.
#
#  Usage:  bash scripts/generate-api-key.sh
#          make key-gen
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$REPO_ROOT/.env"

# ── Ensure .env exists ────────────────────────────────────────────────────────
if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: .env file not found at $ENV_FILE"
    echo "       Copy .env.example to .env and fill in your values first."
    exit 1
fi

# ── Generate 32 random bytes → 64-character hex key ──────────────────────────
NEW_KEY=$(openssl rand -hex 32)
NEW_HASH=$(echo -n "$NEW_KEY" | openssl dgst -sha256 | awk '{print $NF}')

# ── Prompt for a human-readable label ────────────────────────────────────────
read -rp "Enter a label for this key (e.g. angular-prod, postman-dev): " LABEL
LABEL="${LABEL:-unlabelled}"
echo ""

# ── Append the key to API_KEYS in .env ────────────────────────────────────────
# Reads the current API_KEYS value, appends the new key, and writes it back.
CURRENT_KEYS=$(grep -E '^API_KEYS=' "$ENV_FILE" | sed 's/^API_KEYS=//' || true)

if [[ -z "$CURRENT_KEYS" ]]; then
    # No existing keys — set the value directly
    if grep -q '^API_KEYS=' "$ENV_FILE"; then
        sed -i "s/^API_KEYS=.*/API_KEYS=${NEW_HASH}/" "$ENV_FILE"
    else
        echo "API_KEYS=${NEW_HASH}" >> "$ENV_FILE"
    fi
else
    # Append to existing comma-separated list
    sed -i "s/^API_KEYS=.*/API_KEYS=${CURRENT_KEYS},${NEW_HASH}/" "$ENV_FILE"
fi

# Count new total
TOTAL=$(grep -E '^API_KEYS=' "$ENV_FILE" | sed 's/^API_KEYS=//' | tr ',' '\n' | grep -c .)

# ── Print the new key (ONCE — copy it immediately) ───────────────────────────
echo "============================================================"
echo "  New API key generated for: $LABEL"
echo "------------------------------------------------------------"
echo "  Key: $NEW_KEY"
echo "------------------------------------------------------------"
echo "  COPY THIS KEY NOW — it will not be shown again."
echo "  API_KEYS now contains $TOTAL key(s)."
echo "  Restart the container to apply: docker compose restart newsfeed-server"
echo "============================================================"
