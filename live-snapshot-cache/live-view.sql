-- live-view.sql — Live read pattern
--
-- A view that always reflects the current state of the system. No storage,
-- no refresher, no risk of divergence. The trade-off is a recomputed JOIN
-- on every read, which Postgres handles fine for a few thousand rows.
--
-- Scenario: each contact has N installments (echeances) attached to enrollments.
-- The total committed amount + the remaining unpaid amount must always reflect
-- the latest state of the schedule. Storing them as columns of `contacts` is
-- the bug from the source article — the column was filled at import and never
-- updated when new installments were added.
--
-- The fix: don't store. Read this view.

CREATE OR REPLACE VIEW v_reste_du_contact AS
SELECT
  c.id                                              AS contact_id,
  c.nom,
  c.prenom,
  COALESCE(SUM(e.montant_prevu), 0)::numeric(10,2)  AS montant_total,
  COALESCE(SUM(e.montant_paye),  0)::numeric(10,2)  AS montant_paye_total,
  COALESCE(
    SUM(e.montant_prevu) - SUM(e.montant_paye),
    0
  )::numeric(10,2)                                  AS reste_du,
  COUNT(e.id)                                       AS nb_echeances,
  COUNT(e.id) FILTER (WHERE e.statut = 'planifie')  AS nb_echeances_a_venir
FROM contacts c
LEFT JOIN inscriptions          i ON i.contact_id = c.id
LEFT JOIN echeances_inscription e ON e.inscription_id = i.id
GROUP BY c.id, c.nom, c.prenom;

COMMENT ON VIEW v_reste_du_contact IS
  'LIVE: dynamic per-contact totals from echeances_inscription. '
  'Replaces the legacy contacts.montant_total column (Live disguised as Snapshot).';

-- Usage from application code (no storage anywhere):
--   SELECT reste_du FROM v_reste_du_contact WHERE contact_id = $1;
--
-- Performance: a contact has typically 10 to 30 installments. The aggregate
-- runs in under 5 ms with the indexes below.

CREATE INDEX IF NOT EXISTS echeances_inscription_inscription_idx
  ON echeances_inscription (inscription_id);

CREATE INDEX IF NOT EXISTS inscriptions_contact_idx
  ON inscriptions (contact_id);
