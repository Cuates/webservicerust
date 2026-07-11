#!/usr/bin/env bash
# =============================================================================
#  revoke-api-key.sh
#  Lists existing API keys (masked) and removes the selected one from
#  API_KEYS in the .env file at the repository root.
#
#  Usage:  bash scripts/revoke-api-key.sh
#          make key-revoke
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$REPO_ROOT/.env"

# ── Ensure .env exists ────────────────────────────────────────────────────────
if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: .env file not found at $ENV_FILE"
    exit 1
fi

# ── Read current API_KEYS ─────────────────────────────────────────────────────
CURRENT_KEYS=$(grep -E '^API_KEYS=' "$ENV_FILE" | sed 's/^API_KEYS=//' || true)
CURRENT_KEYS="${CURRENT_KEYS//,/$'\n'}"  # split on commas

mapfile -t KEY_ARRAY <<< "$CURRENT_KEYS"

# Filter empty entries
KEYS=()
for k in "${KEY_ARRAY[@]}"; do
    k=$(echo "$k" | tr -d '[:space:]')
    [[ -n "$k" ]] && KEYS+=("$k")
done

if [[ ${#KEYS[@]} -eq 0 ]]; then
    echo "No API keys found in $ENV_FILE. Nothing to revoke."
    exit 0
fi

# ── Display masked keys (first 6 chars only) ──────────────────────────────────
echo ""
echo "Current API keys:"
echo "─────────────────────────────────────"
for i in "${!KEYS[@]}"; do
    MASKED="${KEYS[$i]:0:6}..."
    echo "  $((i+1)). $MASKED"
done
echo "─────────────────────────────────────"
echo ""

read -rp "Enter the number of the key to revoke (or 0 to cancel): " CHOICE

if [[ "$CHOICE" == "0" ]]; then
    echo "Cancelled."
    exit 0
fi

# Validate selection
if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || \
   [[ "$CHOICE" -lt 1 ]] || \
   [[ "$CHOICE" -gt "${#KEYS[@]}" ]]; then
    echo "Invalid selection."
    exit 1
fi

REVOKE_IDX=$((CHOICE - 1))

# ── Remove the selected key ───────────────────────────────────────────────────
REMAINING=()
for i in "${!KEYS[@]}"; do
    [[ "$i" -ne "$REVOKE_IDX" ]] && REMAINING+=("${KEYS[$i]}")
done

NEW_VALUE=$(IFS=','; echo "${REMAINING[*]}")
sed -i "s/^API_KEYS=.*/API_KEYS=${NEW_VALUE}/" "$ENV_FILE"

TOTAL="${#REMAINING[@]}"
MASKED="${KEYS[$REVOKE_IDX]:0:6}..."

echo ""
echo "============================================================"
echo "  Key revoked: $MASKED"
echo "  API_KEYS now contains $TOTAL key(s)."
echo "  Restart: docker compose restart newsfeed-server"
echo "============================================================"
