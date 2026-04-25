-- Minimal schema illustrating the invariant "1 commercial enrollment = N course seats".
-- The real tables have many more columns. What matters here:
--   1. UNIQUE (contact_id, cours_id) — one seat per pair
--   2. FK ON DELETE CASCADE — deleting a contact frees its seats
--   3. statut column at the seat level, not the contact level

CREATE TABLE contacts (
  id           bigserial PRIMARY KEY,
  nom          text NOT NULL,
  prenom       text NOT NULL,
  email        text,
  -- code_cours aggregates the codes of the occupied courses (denormalized, maintained by trigger)
  code_cours   text,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE cours (
  id               bigserial PRIMARY KEY,
  code             text NOT NULL UNIQUE,
  intitule         text NOT NULL,
  places_max       integer NOT NULL DEFAULT 12,
  -- places_inscrits denormalized, maintained by trigger to avoid a COUNT on every render
  places_inscrits  integer NOT NULL DEFAULT 0
);

CREATE TABLE inscriptions (
  id           bigserial PRIMARY KEY,
  contact_id   bigint NOT NULL REFERENCES contacts (id) ON DELETE CASCADE,
  cours_id     bigint NOT NULL REFERENCES cours    (id) ON DELETE CASCADE,
  statut       text   NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),

  UNIQUE (contact_id, cours_id)
);

CREATE INDEX inscriptions_contact_idx ON inscriptions (contact_id);
CREATE INDEX inscriptions_cours_idx   ON inscriptions (cours_id);
