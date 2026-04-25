-- list-rls-without-policies.sql — Detect the silent open-or-closed trap
--
-- When you create a new table, you typically run two commands:
--   1. ALTER TABLE foo ENABLE ROW LEVEL SECURITY;
--   2. CREATE POLICY ... ON foo ...;
--
-- Forgetting step 2 is one of the most common RLS mistakes. The behavior
-- depends on which roles the table is granted to:
--
--   - If the table is granted to authenticated and has no policies,
--     authenticated users get NO rows (deny-all by default).
--   - If a column is granted differently or a function references the
--     table, behavior diverges in subtle ways.
--
-- Either way: a table with RLS enabled but zero policies is a bug — it's
-- either silently denying everything to legitimate users, or it's a
-- sign that someone enabled RLS without thinking through access.
--
-- This audit query lists those tables in 30 seconds.

-- ============================================================================
-- Tables with RLS enabled but no policies attached
-- ============================================================================

SELECT
  schemaname,
  tablename,
  rowsecurity AS rls_enabled,
  (
    SELECT COUNT(*)
      FROM pg_policies p
     WHERE p.schemaname = t.schemaname
       AND p.tablename  = t.tablename
  ) AS policy_count
FROM pg_tables t
WHERE schemaname = 'public'
  AND rowsecurity = true
  AND NOT EXISTS (
    SELECT 1 FROM pg_policies p
     WHERE p.schemaname = t.schemaname
       AND p.tablename  = t.tablename
  )
ORDER BY tablename;

-- Expected: zero rows in a healthy schema.
-- If the query returns rows, each one is a table that has RLS turned on
-- but no policies — fix immediately, either by writing the policies or
-- by disabling RLS if it was enabled by mistake.

-- ============================================================================
-- Inverse audit: tables with policies but RLS disabled
-- ============================================================================
-- Less common, but symmetrical: someone wrote policies but forgot to
-- enable RLS. The policies exist in pg_policies but Postgres ignores
-- them entirely.

SELECT DISTINCT
  p.schemaname,
  p.tablename,
  t.rowsecurity AS rls_enabled,
  COUNT(*) OVER (PARTITION BY p.schemaname, p.tablename) AS policy_count
FROM pg_policies p
JOIN pg_tables   t
  ON t.schemaname = p.schemaname
 AND t.tablename  = p.tablename
WHERE p.schemaname = 'public'
  AND t.rowsecurity = false
ORDER BY p.tablename;

-- Expected: zero rows. Any row is a policy that's been written but is
-- never enforced because RLS is off on its table.

-- ============================================================================
-- Schedule this as a CI check
-- ============================================================================
-- Run these queries in CI on every migration. A non-empty result fails
-- the build. The reasoning: RLS misconfigurations don't fail at runtime
-- — they fail silently. A test that runs at migration time is the
-- earliest possible alarm.
--
-- Pseudo-code (psql):
--
--   psql "$DATABASE_URL" -tAc "
--     SELECT COUNT(*) FROM pg_tables t
--     WHERE schemaname = 'public'
--       AND rowsecurity = true
--       AND NOT EXISTS (
--         SELECT 1 FROM pg_policies p
--          WHERE p.schemaname = t.schemaname
--            AND p.tablename  = t.tablename
--       );
--   " | (read count; [ "$count" = "0" ] || { echo "RLS without policies"; exit 1; })
