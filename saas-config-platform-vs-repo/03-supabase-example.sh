#!/usr/bin/env bash
# ===========================================================================
#  03-supabase-example.sh — Supabase RLS policies + Auth hooks audit
# ===========================================================================
#  Two Supabase configs that famously drift between repo and platform:
#
#  1. Row Level Security policies on a table. The SQL Editor lets you
#     CREATE / DROP / ALTER policies directly in production. Unless you also
#     commit a migration, the repo and the platform diverge silently.
#
#  2. Auth custom access token hooks (`SECURITY DEFINER` functions wired in
#     the Auth settings). The function body lives in the DB, but the wiring
#     (which function is the active hook) is a platform-side setting.
#
#  This script dumps both for a given table + hook name, and refuses to
#  push a migration that would drop policies present in production.
# ===========================================================================

set -euo pipefail

TABLE="${1:?usage: $0 <table> [hook_function_name]}"
HOOK_FN="${2:-custom_access_token_hook}"

# ---------------------------------------------------------------------------
# Step 1 — Dump current policies on $TABLE from production.
# ---------------------------------------------------------------------------
echo "─── Policies currently on \"$TABLE\" ──────────────────────────────"
supabase db remote pg_dump --table="$TABLE" --schema-only \
  | grep -E '^(CREATE POLICY|ALTER TABLE .* ENABLE ROW LEVEL SECURITY)' \
  | tee /tmp/current-policies.sql

# ---------------------------------------------------------------------------
# Step 2 — Compare with what your migrations declare.
# ---------------------------------------------------------------------------
echo
echo "─── Policies declared in supabase/migrations/ ─────────────────────"
grep -hE 'CREATE POLICY [^ ]+ ON public\.'"$TABLE"'\b' \
  supabase/migrations/*.sql \
  | sort -u \
  | tee /tmp/repo-policies.sql

DROPPED=$( comm -23 \
  <(sort -u /tmp/current-policies.sql) \
  <(sort -u /tmp/repo-policies.sql) )

if [ -n "$DROPPED" ]; then
  echo
  echo "⚠ Policies present in PRODUCTION but absent in repo migrations:"
  echo "$DROPPED" | sed 's/^/  /'
  echo "  → either commit a migration that recreates them, or document why"
  echo "    they should no longer exist."
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 3 — Dump the active Auth hook function body.
# This catches the case where someone redefined the function in the SQL
# Editor without committing a new migration.
# ---------------------------------------------------------------------------
echo
echo "─── Active Auth hook \"$HOOK_FN\" body (production) ───────────────"
supabase db remote sql --json "$( cat <<SQL
SELECT pg_get_functiondef(p.oid) AS body
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = '$HOOK_FN'
SQL
)" | jq -r '.[0].body'

echo
echo "Compare the above with the version in supabase/migrations/ before"
echo "pushing any change that touches \"$HOOK_FN\"."
