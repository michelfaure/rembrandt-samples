# glue-ratio/

Mesurer le ratio glue / logique métier dans `lib/` et brancher une CI sur la non-régression.

**Article source** : *Le ratio glue/logique : la CI qui bloque l'alourdissement silencieux* ([DEV.to](https://dev.to/michelfaure))

## Règle d'invariant

Tout ce qui n'est pas mesuré dérive. Une règle dans un fichier de contraintes est lue puis oubliée ; une métrique chiffrée qui bloque une PR est vue. Les LLM ne font pas exception — ils produisent volontiers des adapters, parce qu'un adapter est facile à générer.

## Fichiers

| Fichier | Rôle |
|---|---|
| [`glue-ratio.sh`](./glue-ratio.sh) | Script principal : deux listes en dur (glue / business), calcul du ratio global et hors-types, verdict court |
| [`glue-ratio-check.sh`](./glue-ratio-check.sh) | Compare HEAD vs base ref (default `origin/main`), fail si régression au-delà d'une tolérance (default 0) |
| [`ci-workflow.yml`](./ci-workflow.yml) | Extrait GitHub Actions : log sur push main, check bloquant sur PR |

## Pourquoi non-régression et pas seuil absolu

Un projet mature à 35 % de glue qui se tient peut être sain. Un projet à 18 % qui monte à 22 % en une semaine est en train de dériver. Le seuil absolu ne voit pas la dérive, il ne voit que l'arrivée. La non-régression voit la dérive dès la première PR.

Filet secondaire à 40 % : au-delà, alerte textuelle. C'est un garde-fou pour les cas pathologiques, pas la métrique principale.

## Comment l'adapter

- Recopier `glue-ratio.sh`, vider les deux listes, remplir avec tes propres fichiers
- Exclure les fichiers auto-générés (types ORM, schemas générés) du dénominateur
- Ajouter le workflow CI, tolérance 0 pour démarrer
- Observer 2-3 semaines pour voir où la régression vient en pratique avant de durcir
