-- policies-with-check.sql — Trap #3 + bonus #5
--
-- Two patterns in one file:
--
-- 1. The SELECT + WRITE policy pair, with USING and WITH CHECK clauses
--    explicit. Without WITH CHECK, an authenticated user can write rows
--    they cannot read back — a classic RLS audit finding.
--
-- 2. The recursion-safe user_roles policy. If your policy on user_roles
--    references user_roles, you create a loop and Postgres raises
--    `infinite recursion detected in policy`.

-- ============================================================================
-- Pattern 1: SELECT + WRITE policies on a business table
-- ============================================================================
-- Scenario: contrats_formateurs holds teacher contracts. Read for staff and
-- above, write for admin only. The role is sourced from a separate
-- user_roles table keyed by email.

ALTER TABLE contrats_formateurs ENABLE ROW LEVEL SECURITY;

-- Read policy: staff can see all contracts
CREATE POLICY "select_staff" ON contrats_formateurs
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE email = auth.email()
        AND role IN ('staff', 'admin', 'super_admin')
    )
  );

-- Write policy: admin only — note the WITH CHECK clause
CREATE POLICY "write_admin" ON contrats_formateurs
  FOR ALL  -- INSERT, UPDATE, DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE email = auth.email()
        AND role IN ('admin', 'super_admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE email = auth.email()
        AND role IN ('admin', 'super_admin')
    )
  );

-- Why both USING and WITH CHECK on FOR ALL:
--   USING:      filters which rows the user can read or operate on
--   WITH CHECK: validates that newly written rows would still be visible
-- A WITH CHECK that allows more than USING means a user can write a row
-- they cannot read back. Always make them converge on write policies.

-- ============================================================================
-- Anti-pattern: forgetting the WITH CHECK
-- ============================================================================
-- The following policy is broken — never write it. Without WITH CHECK,
-- the write succeeds, but the row may be invisible to its own author.
--
--   CREATE POLICY "write_admin_broken" ON contrats_formateurs
--     FOR ALL
--     TO authenticated
--     USING (...);   -- WITH CHECK omitted
--
-- Symptom in production: the user submits the form, the API returns 200,
-- the row is in the table, but a SELECT immediately after returns nothing.
-- The bug isn't in the form, it's in the policy that's allowing a write
-- the read filter rejects.

-- ============================================================================
-- Anti-pattern: SELECT-only policy on a table
-- ============================================================================
-- If you write a SELECT policy and forget the write policy, Postgres
-- doesn't lock writes — it allows them by default, because no policy
-- means no restriction. The fix is always: enable RLS, then write all
-- the policies you need.

-- ============================================================================
-- Pattern 2: recursion-safe user_roles policy
-- ============================================================================
-- The trap: a policy on user_roles that references user_roles.
--
--   ❌ INFINITE LOOP
--   CREATE POLICY "select_user_roles" ON user_roles
--     FOR SELECT
--     TO authenticated
--     USING (
--       EXISTS (SELECT 1 FROM user_roles WHERE email = auth.email() AND role = 'admin')
--     );
--
-- Reading user_roles fires the policy that reads user_roles that fires
-- the policy. Postgres raises `infinite recursion detected in policy`,
-- and every query downstream that joins user_roles fails.
--
-- Three escape routes, in order of preference:

-- Option A: route through a SECURITY DEFINER function (preferred)
CREATE OR REPLACE FUNCTION fn_current_user_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
  SELECT role FROM public.user_roles WHERE email = auth.email() LIMIT 1;
$$;

ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "select_user_roles_via_function" ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    fn_current_user_role() IN ('admin', 'super_admin')
    OR email = auth.email()  -- users can always read their own role
  );

-- Option B: read directly from auth.email() without a join (when the
-- policy can be expressed without consulting user_roles itself).

-- Option C: leave user_roles readable to all authenticated users and
-- protect writes elsewhere. Roles are not secrets, in most cases the
-- mapping `email → role` is fine to expose to authenticated users.
-- This is the option I shipped for several weeks before adopting Option A.
