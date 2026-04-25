-- The 3 queries that translate the invariant "1 commercial enrollment = N course seats".
-- Drop them into any schema where a composite-key table stores relations
-- rather than entities.

-- ----------------------------------------------------------------------------
-- 1. Count distinct people, never rows.
-- COUNT(*) counts seats. COUNT(DISTINCT contact_id) counts students.
-- ----------------------------------------------------------------------------
SELECT COUNT(DISTINCT contact_id) AS eleves
FROM inscriptions;

-- ----------------------------------------------------------------------------
-- 2. Count seats in a given course.
-- Here COUNT(*) is correct since the cours_id = $1 filter guarantees
-- no contact is counted twice.
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS places_occupees
FROM inscriptions
WHERE cours_id = $1;

-- ----------------------------------------------------------------------------
-- 3. Multi-course upsert without overwriting the contact's other seats.
-- onConflict targets the composite key, not contact_id alone.
-- A contact enrolling in a 2nd course creates a 2nd row, replaces nothing.
-- ----------------------------------------------------------------------------
INSERT INTO inscriptions (contact_id, cours_id, statut)
VALUES ($1, $2, $3)
ON CONFLICT (contact_id, cours_id)
DO UPDATE SET statut = EXCLUDED.statut;
