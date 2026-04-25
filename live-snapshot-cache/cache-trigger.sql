-- cache-trigger.sql — Cache refresher pattern
--
-- A Cache column stores a derivable value for performance reasons. The
-- contract is non-negotiable: the refresher exists in the same commit
-- as the column. No "we'll add it later." Later doesn't come.
--
-- Scenario: cours.places_inscrits counts the active enrollments for a course.
-- Computing it as a COUNT(*) on every page render works for a few rows but
-- chokes on a planning page that lists fifty courses. The Cache holds the
-- count, the trigger keeps it in sync.

-- ============================================================================
-- Refresher function: recomputes the count for a single course
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_refresh_places_inscrits(p_cours_id bigint)
RETURNS void
LANGUAGE sql
AS $$
  UPDATE cours
     SET places_inscrits = (
       SELECT COUNT(*)
         FROM inscriptions
        WHERE cours_id = p_cours_id
          AND statut   = 'inscrit'
     )
   WHERE id = p_cours_id;
$$;

-- ============================================================================
-- Trigger: refresh on every change of the source table
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_inscriptions_sync_places()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM fn_refresh_places_inscrits(NEW.cours_id);
  ELSIF TG_OP = 'UPDATE' THEN
    -- Refresh both old and new course if cours_id changed
    PERFORM fn_refresh_places_inscrits(OLD.cours_id);
    IF NEW.cours_id IS DISTINCT FROM OLD.cours_id THEN
      PERFORM fn_refresh_places_inscrits(NEW.cours_id);
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    PERFORM fn_refresh_places_inscrits(OLD.cours_id);
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_inscriptions_sync_places ON inscriptions;

CREATE TRIGGER trg_inscriptions_sync_places
  AFTER INSERT OR UPDATE OR DELETE ON inscriptions
  FOR EACH ROW
  EXECUTE FUNCTION fn_inscriptions_sync_places();

-- ============================================================================
-- Mandatory documentation: identifies the column as Cache and names its
-- refresher. Without this comment, a future reader cannot tell a managed
-- Cache from a Live that diverged silently.
-- ============================================================================

COMMENT ON COLUMN cours.places_inscrits IS
  'CACHE: refreshed by trg_inscriptions_sync_places.';

-- ============================================================================
-- Backfill on creation (run once after deploying the trigger)
-- ============================================================================

UPDATE cours c
   SET places_inscrits = (
     SELECT COUNT(*)
       FROM inscriptions i
      WHERE i.cours_id = c.id
        AND i.statut   = 'inscrit'
   );

-- ============================================================================
-- Safety net: a recompute job to detect drift
-- ============================================================================
-- Even with a trigger, a bulk operation that bypasses it (COPY, manual
-- DELETE without the trigger fired, schema migration) can introduce drift.
-- Schedule this query weekly and alert on differences.
--
--   WITH discrepancies AS (
--     SELECT
--       c.id,
--       c.places_inscrits AS cached,
--       (SELECT COUNT(*) FROM inscriptions
--         WHERE cours_id = c.id AND statut = 'inscrit') AS actual
--     FROM cours c
--   )
--   SELECT * FROM discrepancies WHERE cached <> actual;
--
-- Zero rows returned = the Cache holds. Any row = trigger missed an event;
-- investigate before backfilling.
