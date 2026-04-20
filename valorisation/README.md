# valorisation/

Extraits du module qui estime la valeur d'un ERP interne sans prix de marché.

**Article source** : *Pourquoi j'ai codé un module qui me dit combien vaut mon ERP* ([DEV.to](https://dev.to/michelfaure))

## Règle d'invariant

Un compteur automatique qui entre dans un calcul de valeur doit avoir un veilleur. Sans veilleur, la métrique devient un oracle qui se croit sur parole.

## Fichiers

| Fichier | Rôle |
|---|---|
| [`compute.ts`](./compute.ts) | Pattern `consolidate(dims)` — somme N dimensions, garde trace des dimensions utilisées, accepte les `null` |
| [`guardrail-cron.ts`](./guardrail-cron.ts) | Garde-fou de 20 lignes qui détecte les bumps anormaux de compteur LOC et poste sur Slack |
| [`schema.sql`](./schema.sql) | Schéma minimal `valorisation_snapshots` avec `snapshot_date UNIQUE` |

## Comment l'adapter

- Remplace `lines_total` par ta métrique (revenus, utilisateurs, tickets résolus)
- Ajuste le seuil `3 * Math.max(avg * 0.02, 500)` à ton ordre de grandeur
- Branche le webhook Slack (ou Discord, ou email) sur l'événement que tu veux voir avant de l'encaisser comme progression

## Ce que ce pattern n'est pas

Ce n'est pas un outil de valorisation financière. C'est un instrument de jugement interne. Il fabrique une valeur opposable, pas un prix de marché.
