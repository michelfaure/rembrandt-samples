-- Schéma minimal pour historiser des snapshots de valorisation.
-- snapshot_date en UNIQUE garantit un seul snapshot par jour.
-- Les colonnes low/high/dims_used reflètent la structure du pattern consolidate(dims).

CREATE TABLE valorisation_snapshots (
  id             bigserial PRIMARY KEY,
  snapshot_date  date NOT NULL UNIQUE,
  lines_total    integer NOT NULL,
  value_low      numeric(12,2) NOT NULL,
  value_high     numeric(12,2) NOT NULL,
  dims_used      text[] NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now()
);

-- Index pour les lectures "derniers N snapshots" utilisées par le garde-fou.
CREATE INDEX valorisation_snapshots_date_desc_idx
  ON valorisation_snapshots (snapshot_date DESC);
