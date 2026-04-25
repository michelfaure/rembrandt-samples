-- Minimal schema to historize valuation snapshots.
-- snapshot_date UNIQUE guarantees a single snapshot per day.
-- The low/high/dims_used columns mirror the structure of the consolidate(dims) pattern.

CREATE TABLE valorisation_snapshots (
  id             bigserial PRIMARY KEY,
  snapshot_date  date NOT NULL UNIQUE,
  lines_total    integer NOT NULL,
  value_low      numeric(12,2) NOT NULL,
  value_high     numeric(12,2) NOT NULL,
  dims_used      text[] NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now()
);

-- Index for the "last N snapshots" reads used by the guardrail.
CREATE INDEX valorisation_snapshots_date_desc_idx
  ON valorisation_snapshots (snapshot_date DESC);
