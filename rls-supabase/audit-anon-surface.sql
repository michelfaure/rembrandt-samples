-- audit-anon-surface.sql — Trap #2 audit and bulk fix
--
-- Supabase generates a REST endpoint for every Postgres function declared
-- SECURITY DEFINER, and PUBLIC has EXECUTE rights by default. PUBLIC includes
-- the `anon` role, which is the role used when someone hits your endpoint
-- with `curl` and no token. Result: your internal calculation functions
-- (pay_*, publish_*, convert_*) are exposed to the internet by default.
--
-- This file gives the audit query and the bulk fix.

-- ============================================================================
-- Step 1: list functions executable by anon (the dangerous surface)
-- ============================================================================

SELECT
  n.nspname  AS schema,
  p.proname  AS function_name,
  pg_get_function_arguments(p.oid) AS args,
  CASE p.prosecdef WHEN true THEN 'DEFINER' ELSE 'INVOKER' END AS security
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND has_function_privilege('anon', p.oid, 'EXECUTE')
ORDER BY p.proname;

-- Read this list before running the bulk fix below.
-- If a function is intentionally public (e.g. an enrollment-form helper),
-- note it down — the bulk fix will close it and you'll need to GRANT it
-- back individually.

-- ============================================================================
-- Step 2: bulk close anon access (run only after reviewing the list above)
-- ============================================================================

-- Close all existing functions to anon
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
GRANT  EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated, service_role;

-- Make future functions inherit the rule by default
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT  EXECUTE ON FUNCTIONS TO authenticated, service_role;

-- ============================================================================
-- Step 3: re-open the functions that genuinely need to be public
-- ============================================================================
-- For each function you noted as intentionally public, GRANT it back
-- individually. A typical case is a signup helper or an enrollment-form
-- handler that runs without a token.
--
--   GRANT EXECUTE ON FUNCTION public.create_enrollment(text, text, bigint)
--     TO anon, authenticated, service_role;
--
-- Prefer this over leaving the bulk anon access open: every public function
-- becomes an explicit, reviewable choice instead of a default.

-- ============================================================================
-- Step 4: verify the closure
-- ============================================================================
-- Re-run Step 1's query. The list should now contain only the functions
-- you explicitly re-opened in Step 3.

-- ============================================================================
-- Periodic re-audit
-- ============================================================================
-- Schedule this query monthly (a cron, a CI job, a calendar reminder).
-- New developers and AI agents add functions; defaults can drift.
-- A function you didn't intend to expose, exposed for a week, is a
-- post-mortem you don't want to write.
