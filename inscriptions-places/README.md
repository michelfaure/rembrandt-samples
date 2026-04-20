# inscriptions-places/

Extraits de la modélisation contact × cours d'un ERP d'école.

**Article source** : *Modéliser 1 inscription = N places : quand le nom d'une table ment* ([DEV.to](https://dev.to/michelfaure))

## Règle d'invariant

Une ligne de la table `inscriptions` représente une **place** (un contact × un cours), pas une inscription commerciale. L'inscription commerciale — le contrat annuel signé par un élève qui prend N cours — est *dérivée*, pas stockée.

## Fichiers

| Fichier | Rôle |
|---|---|
| [`queries.sql`](./queries.sql) | Les 3 requêtes qui traduisent l'invariant et arrêtent de mentir |
| [`schema.sql`](./schema.sql) | Schéma minimal `contacts` / `cours` / `inscriptions` avec `UNIQUE (contact_id, cours_id)` |

## Quand ce pattern s'applique

Dès que tu stockes une relation N×M dont le nom métier usuel (« inscription », « commande », « réservation ») renvoie à un concept commercial unique, alors que chaque ligne représente une unité composante.

Le réflexe correct n'est pas de renommer la table — c'est d'**inscrire la règle d'invariant dans ton `CLAUDE.md`** pour que ni toi ni l'agent ne génériez plus une requête naïve.

## Les trois options qu'on envisage toujours (et la quatrième qui gagne)

| Option | Coût | Sémantique |
|---|---|---|
| Statu quo | 0 | Piège à vie |
| Renommer `inscriptions` → `places` | Lourd (FK, RLS, triggers, vues, code) | Propre |
| Scinder en 2 tables | Multi-semaines | Très propre |
| **Garder le schema, tenir l'invariant documenté** | Faible | Ambigu mais borné |

Détails du raisonnement dans l'article.
