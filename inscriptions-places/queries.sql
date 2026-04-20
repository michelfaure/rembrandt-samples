-- Les 3 requêtes qui traduisent l'invariant "1 inscription commerciale = N places cours".
-- À copier-coller dans tout schema où une table à clé composite stocke des relations
-- plutôt que des entités.

-- ----------------------------------------------------------------------------
-- 1. Compter des personnes distinctes, jamais des lignes.
-- COUNT(*) compte les places. COUNT(DISTINCT contact_id) compte les élèves.
-- ----------------------------------------------------------------------------
SELECT COUNT(DISTINCT contact_id) AS eleves
FROM inscriptions;

-- ----------------------------------------------------------------------------
-- 2. Compter des places dans un cours donné.
-- Ici COUNT(*) est correct puisque le filtre cours_id = $1 garantit
-- qu'aucun contact n'est compté deux fois.
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS places_occupees
FROM inscriptions
WHERE cours_id = $1;

-- ----------------------------------------------------------------------------
-- 3. Upsert multi-cours sans écraser les autres places du même contact.
-- onConflict cible la clé composite, pas contact_id seul.
-- Un contact qui s'inscrit à un 2e cours crée une 2e ligne, ne remplace rien.
-- ----------------------------------------------------------------------------
INSERT INTO inscriptions (contact_id, cours_id, statut)
VALUES ($1, $2, $3)
ON CONFLICT (contact_id, cours_id)
DO UPDATE SET statut = EXCLUDED.statut;
