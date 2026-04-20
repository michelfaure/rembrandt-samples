-- Schéma minimal illustrant l'invariant "1 inscription commerciale = N places cours".
-- Les tables réelles ont beaucoup plus de colonnes. Ce qui compte ici :
--   1. UNIQUE (contact_id, cours_id) — une place par couple
--   2. FK ON DELETE CASCADE — supprimer un contact libère ses places
--   3. colonne statut au niveau place, pas au niveau contact

CREATE TABLE contacts (
  id           bigserial PRIMARY KEY,
  nom          text NOT NULL,
  prenom       text NOT NULL,
  email        text,
  -- code_cours agrège les codes des cours occupés (dénormalisation maintenue par trigger)
  code_cours   text,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE cours (
  id               bigserial PRIMARY KEY,
  code             text NOT NULL UNIQUE,
  intitule         text NOT NULL,
  places_max       integer NOT NULL DEFAULT 12,
  -- places_inscrits dénormalisée, maintenue par trigger pour éviter un COUNT à chaque affichage
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
