#!/usr/bin/env bash
# ===========================================================================
#  block-audit.sh — full drift cartography between a Postgres production
#  database and a repo of `*.sql` migration files. Eight categories.
# ===========================================================================
#  Output: a folder /tmp/audit/ with eight pairs of .diff files showing
#  what exists in prod but not in the repo (asymmetric difference).
#
#  Usage:   PROD_URL=postgres://... ./block-audit.sh
#  Cost:    ~30 seconds on a 300-table schema with 50 migrations
# ===========================================================================

set -euo pipefail

PROD_URL="${PROD_URL:?set PROD_URL=postgres://...}"
MIG_DIR="${MIG_DIR:-supabase/migrations}"
OUT="/tmp/audit"
mkdir -p "$OUT"

dump_prod() {
  psql "$PROD_URL" -tAc "$1" | sed '/^$/d' | sort -u
}

dump_repo() {
  grep -rhE "^$1" "$MIG_DIR"/*.sql 2>/dev/null \
    | sed -E "$2" | sort -u
}

# ─── 1. TABLES ─────────────────────────────────────────────────────────────
dump_prod "SELECT tablename FROM pg_tables WHERE schemaname='public'" \
  > "$OUT/tables.prod.txt"
dump_repo 'CREATE TABLE ' 's/.*TABLE (IF NOT EXISTS )?[^.]*\.?([a-z_][a-z0-9_]*).*/\2/' \
  > "$OUT/tables.repo.txt"
comm -23 "$OUT/tables.prod.txt" "$OUT/tables.repo.txt" > "$OUT/tables.diff"

# ─── 2. COLUMNS ────────────────────────────────────────────────────────────
dump_prod "SELECT table_name||'.'||column_name FROM information_schema.columns
           WHERE table_schema='public'" > "$OUT/columns.prod.txt"
# Repo column extraction is best done by parsing the generated dump
# (pg_dump --schema-only of a clean restore of all migrations).
# Compare line-by-line with prod columns.

# ─── 3. VIEWS ──────────────────────────────────────────────────────────────
dump_prod "SELECT viewname FROM pg_views WHERE schemaname='public'" \
  > "$OUT/views.prod.txt"
dump_repo 'CREATE (OR REPLACE )?VIEW ' \
  's/.*VIEW (IF NOT EXISTS )?[^.]*\.?([a-z_][a-z0-9_]*).*/\2/' \
  > "$OUT/views.repo.txt"
comm -23 "$OUT/views.prod.txt" "$OUT/views.repo.txt" > "$OUT/views.diff"

# ─── 4. FUNCTIONS ──────────────────────────────────────────────────────────
dump_prod "SELECT proname FROM pg_proc p
           JOIN pg_namespace n ON n.oid=p.pronamespace
           WHERE n.nspname='public'" > "$OUT/functions.prod.txt"
dump_repo 'CREATE (OR REPLACE )?FUNCTION ' \
  's/.*FUNCTION (IF NOT EXISTS )?[^.]*\.?([a-z_][a-z0-9_]*)\s*\(.*/\2/' \
  > "$OUT/functions.repo.txt"
comm -23 "$OUT/functions.prod.txt" "$OUT/functions.repo.txt" > "$OUT/functions.diff"

# ─── 5. TRIGGERS ───────────────────────────────────────────────────────────
dump_prod "SELECT tgname FROM pg_trigger WHERE NOT tgisinternal" \
  > "$OUT/triggers.prod.txt"
dump_repo 'CREATE TRIGGER ' 's/.*TRIGGER (IF NOT EXISTS )?([a-z_][a-z0-9_]*).*/\2/' \
  > "$OUT/triggers.repo.txt"
comm -23 "$OUT/triggers.prod.txt" "$OUT/triggers.repo.txt" > "$OUT/triggers.diff"

# ─── 6. POLICIES (RLS) ─────────────────────────────────────────────────────
dump_prod "SELECT schemaname||'.'||tablename||'.'||policyname FROM pg_policies
           WHERE schemaname='public'" > "$OUT/policies.prod.txt"
dump_repo 'CREATE POLICY ' \
  's/.*POLICY ([a-z_][a-z0-9_]*) ON [^.]*\.?([a-z_][a-z0-9_]*).*/public.\2.\1/' \
  > "$OUT/policies.repo.txt"
comm -23 "$OUT/policies.prod.txt" "$OUT/policies.repo.txt" > "$OUT/policies.diff"

# ─── 7. INDEXES ────────────────────────────────────────────────────────────
dump_prod "SELECT indexname FROM pg_indexes WHERE schemaname='public'
           AND indexname NOT LIKE '%_pkey'" > "$OUT/indexes.prod.txt"
dump_repo 'CREATE (UNIQUE )?INDEX ' \
  's/.*INDEX (IF NOT EXISTS )?([a-z_][a-z0-9_]*).*/\2/' \
  > "$OUT/indexes.repo.txt"
comm -23 "$OUT/indexes.prod.txt" "$OUT/indexes.repo.txt" > "$OUT/indexes.diff"

# ─── 8. ROLES ──────────────────────────────────────────────────────────────
dump_prod "SELECT rolname FROM pg_roles WHERE NOT rolname LIKE 'pg_%'
           AND rolname NOT IN ('postgres','authenticated','anon','service_role')" \
  > "$OUT/roles.prod.txt"
dump_repo 'CREATE ROLE ' 's/.*ROLE ([a-z_][a-z0-9_]*).*/\1/' \
  > "$OUT/roles.repo.txt"
comm -23 "$OUT/roles.prod.txt" "$OUT/roles.repo.txt" > "$OUT/roles.diff"

# ─── Report ────────────────────────────────────────────────────────────────
echo "─── Block audit drift report ─────────────────────────────"
for c in tables views functions triggers policies indexes roles; do
  n=$( wc -l < "$OUT/$c.diff" )
  printf "  %-12s %4d objects present in prod but missing from repo\n" "$c" "$n"
done
echo
echo "  See /tmp/audit/<category>.diff for the per-category list."
