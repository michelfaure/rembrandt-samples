# rembrandt-samples

Snippets extraits de la série d'articles **« Mon ERP avec Claude Code »** publiée sur DEV.to par [@michelfaure](https://dev.to/michelfaure).

Rembrandt est le nom de code d'un ERP vertical codé seul avec Claude Code pour une école d'art céramique (six sites, quelques centaines d'élèves). Ce repo n'est pas le code de Rembrandt. C'est une sélection de patterns reproductibles, pseudonymisés et dé-contextualisés, directement copiables dans ton propre projet.

## Contenu

| Dossier | Article DEV.to | Ce que tu trouves |
|---|---|---|
| [`valorisation/`](./valorisation) | *« Pourquoi j'ai codé un module qui me dit combien vaut mon ERP »* | Pattern `consolidate(dims)` + garde-fou Slack sur compteur LOC |
| [`inscriptions-places/`](./inscriptions-places) | *« Modéliser 1 inscription = N places : quand le nom d'une table ment »* | 3 requêtes SQL + schema minimal contact × cours |
| [`claude-md/`](./claude-md) | *« Mon CLAUDE.md pour un ERP : structure et évolution en 4 semaines »* | Template à 4 couches (CLAUDE.md, AGENTS.md, règles verticales, skill) |

## Comment lire ce repo

Chaque dossier porte un `README.md` qui pointe vers l'article source, cadre la règle d'invariant, et explique ce que chaque fichier illustre. Les extraits TypeScript/SQL/Markdown sont pensés pour être copiés, pas exécutés tels quels — ce repo n'a pas de runtime, pas de package.json, pas de tests.

Si tu veux comprendre le raisonnement derrière un snippet, lis l'article d'abord. Si tu veux juste le code, viens ici.

## Licence

[MIT](./LICENSE) — fais-en ce que tu veux, cite si ça te rend service.
