-- migration-of-category.sql — Migrating a Live disguised as Snapshot to real Live
--
-- This is the surgery to apply when audit reveals a column that should track
-- the current state but was filled once and never refreshed. The wrong fix
-- is "recalculate periodically" — that just postpones the next divergence
-- by exactly one upstream event.
--
-- The right fix: drop the column, route reads through a view.
--
-- Scenario from the source article: contacts.montant_total was populated at
-- import in March from a SUM at a single point in time. Three weeks later,
-- new installments were added, the column didn't move. 488 NULLs + 72
-- divergences > 1 EUR across 560 contacts.
--
-- This migration assumes you've already deployed v_reste_du_contact (see
-- live-view.sql) and migrated the application reads to use it.

BEGIN;

-- ============================================================================
-- Step 1: pre-flight checks
-- ============================================================================
-- Refuse to drop the column if any application code still queries it.
-- Run a grep across the codebase first; this query just confirms nothing
-- is currently selecting it from a stored procedure or view.

DO $$
DECLARE
  v_dependency_count integer;
BEGIN
  SELECT COUNT(*)
    INTO v_dependency_count
    FROM pg_depend d
    JOIN pg_attribute a
      ON a.attrelid = d.refobjid
     AND a.attnum   = d.refobjsubid
    JOIN pg_class c
      ON c.oid = a.attrelid
   WHERE c.relname = 'contacts'
     AND a.attname = 'montant_total'
     AND d.deptype = 'n';

  IF v_dependency_count > 0 THEN
    RAISE EXCEPTION
      'contacts.montant_total has % database dependencies. '
      'Drop or rewrite them before running this migration.',
      v_dependency_count;
  END IF;
END $$;

-- ============================================================================
-- Step 2: snapshot of current state (audit trail before destruction)
-- ============================================================================
-- Save the pre-migration values to a one-off table. Keep for one full
-- accounting cycle, then drop. This protects against the "we lost the data"
-- panic that follows any column-drop migration.

CREATE TABLE _archive_contacts_montant_total_2026_04 AS
  SELECT id, montant_total, NOW() AS archived_at
    FROM contacts
   WHERE montant_total IS NOT NULL;

COMMENT ON TABLE _archive_contacts_montant_total_2026_04 IS
  'One-off archive before dropping contacts.montant_total. '
  'Drop this table after FY26 close (around 2026-12-31).';

-- ============================================================================
-- Step 3: drop the column
-- ============================================================================

ALTER TABLE contacts DROP COLUMN montant_total;

-- ============================================================================
-- Step 4: confirm the view is the only source of truth
-- ============================================================================

COMMENT ON VIEW v_reste_du_contact IS
  'LIVE — the single source of truth for per-contact totals as of '
  || NOW()::date::text
  || '. Replaces the dropped contacts.montant_total column.';

COMMIT;

-- ============================================================================
-- Application-side checklist (do these BEFORE running this migration)
-- ============================================================================
--
-- 1. Search the codebase for "montant_total" — should return zero hits in
--    application source. Hits in migrations/ are fine (history).
--
--    rg --type ts --type sql 'montant_total'
--
-- 2. Replace any remaining read with the view:
--
--      // before
--      const { data } = await supabase
--        .from('contacts').select('montant_total').eq('id', id).single();
--
--      // after
--      const { data } = await supabase
--        .from('v_reste_du_contact').select('montant_total').eq('contact_id', id).single();
--
-- 3. Run the test suite. The view returns the same shape, so most tests
--    pass without change. Tests that mocked an UPDATE on montant_total
--    must be deleted — there's no longer anything to update.
--
-- 4. Deploy the application change FIRST. Then run this migration. The
--    reverse order would 500 every read between deploy and migration.

-- ============================================================================
-- Why not "just refresh montant_total nightly"
-- ============================================================================
-- That fix re-establishes the divergence at the next installment created
-- between 00:00 and 23:59. The bug isn't the staleness window; the bug is
-- that there's a window at all. Live means "no window."
--
-- It also leaves the column as a temptation: the next dev sees it, assumes
-- it's authoritative, queries it directly. The drift returns under a new name.
-- Removing the column removes the temptation.
