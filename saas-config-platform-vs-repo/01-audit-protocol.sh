#!/usr/bin/env bash
# ===========================================================================
#  audit-protocol.sh — 30-second audit before any SaaS config update
# ===========================================================================
#  Universal four-step protocol. Plug your platform's CLI in $PLATFORM_CLI.
#  See 02-vercel-example.sh and 03-supabase-example.sh for concrete cases.
# ===========================================================================

set -euo pipefail

PLATFORM_CLI="${PLATFORM_CLI:-vercel}"   # vercel | supabase | stripe | gh | ...
TARGET_CONFIG="${1:-target-config.json}" # path to your intended config

# ---------------------------------------------------------------------------
# Step 1 — Read the current config in full.
# Whatever CLI you use, dump the FULL config object as JSON, not just the
# field you think you're changing. The point is to see what else is there.
# ---------------------------------------------------------------------------
CURRENT=$( $PLATFORM_CLI projects get --json )
echo "$CURRENT" | jq . > /tmp/current-config.json
echo "→ current config saved to /tmp/current-config.json"

# ---------------------------------------------------------------------------
# Step 2 — Diff current vs target, side by side.
# ---------------------------------------------------------------------------
echo "─── Diff (current ← → target) ─────────────────────────────────────"
diff -u <(jq -S . /tmp/current-config.json) <(jq -S . "$TARGET_CONFIG") || true

# ---------------------------------------------------------------------------
# Step 3 — List the REGRESSING fields (present before, absent after).
# This is the silent-failure class: a key that disappears without a trace.
# ---------------------------------------------------------------------------
REGRESSIONS=$( jq -n \
  --slurpfile c /tmp/current-config.json \
  --slurpfile t "$TARGET_CONFIG" \
  '($c[0] | keys) - ($t[0] | keys)' )

if [ "$REGRESSIONS" != "[]" ]; then
  echo "⚠ Fields that will be REMOVED by this update:"
  echo "$REGRESSIONS" | jq .
else
  echo "✓ No regressing field."
fi

# ---------------------------------------------------------------------------
# Step 4 — Explicit confirmation before PATCH. Hard stop, no autopilot.
# In CI, replace this with a fail-fast: `[ "$REGRESSIONS" = "[]" ] || exit 1`.
# ---------------------------------------------------------------------------
read -r -p "Apply update with the above regressions accepted? (y/N) " ok
if [ "${ok,,}" = "y" ]; then
  $PLATFORM_CLI projects update --config "@$TARGET_CONFIG"
  echo "✓ Update applied."
else
  echo "Aborted."
  exit 1
fi
