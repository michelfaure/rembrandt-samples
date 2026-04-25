-- snapshot-protection.sql — Snapshot protection pattern
--
-- A Snapshot column records the value at a business event and must NEVER
-- be modified retroactively. The implementation is "store + protect against
-- writes after creation."
--
-- Scenario: inscriptions.tarif_applique is the price at the date of enrollment.
-- If the course is repriced later, existing enrollments keep the old price.
-- Modifying a past tarif_applique would silently rewrite history — a financial
-- audit nightmare and a tax-compliance bug waiting to happen.
--
-- Two layers of protection: a trigger that rejects UPDATE on the Snapshot
-- column, and a comment that warns future readers.

-- ============================================================================
-- Layer 1: trigger forbidding UPDATE of Snapshot columns
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_block_snapshot_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.tarif_applique IS DISTINCT FROM OLD.tarif_applique THEN
    RAISE EXCEPTION
      'Snapshot column inscriptions.tarif_applique is immutable. '
      'To change a price after enrollment, issue a credit note + new invoice.'
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_inscriptions_snapshot_protect ON inscriptions;

CREATE TRIGGER trg_inscriptions_snapshot_protect
  BEFORE UPDATE ON inscriptions
  FOR EACH ROW
  EXECUTE FUNCTION fn_block_snapshot_update();

-- ============================================================================
-- Layer 2: documentation in the schema
-- ============================================================================

COMMENT ON COLUMN inscriptions.tarif_applique IS
  'SNAPSHOT: price at the date of enrollment, immutable after creation. '
  'Protected by trg_inscriptions_snapshot_protect.';

-- ============================================================================
-- Variant: CHECK constraint for simpler cases (whole-row immutability)
-- ============================================================================
-- If an entire row is a Snapshot (e.g. an emitted invoice line), you can
-- skip the trigger and use a CHECK that locks all columns. This is rougher
-- but simpler to reason about.
--
--   ALTER TABLE factures ADD CONSTRAINT factures_immutable_after_emission
--     CHECK (statut <> 'emitted' OR (statut, numero, montant_ttc) IS NOT DISTINCT
--            FROM (statut, numero, montant_ttc));
--
-- The trigger pattern is preferred when only a subset of columns is frozen.

-- ============================================================================
-- Test of the protection (run after applying)
-- ============================================================================
--
-- BEGIN;
--   -- Try to mutate a Snapshot — must fail with the message above.
--   UPDATE inscriptions SET tarif_applique = 999 WHERE id = 1;
-- ROLLBACK;
--
-- Expected output:
--   ERROR:  Snapshot column inscriptions.tarif_applique is immutable.
--   To change a price after enrollment, issue a credit note + new invoice.
