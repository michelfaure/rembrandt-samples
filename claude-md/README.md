# claude-md/

Template d'architecture documentaire pour piloter un projet avec Claude Code.

**Article source** : *Mon CLAUDE.md pour un ERP : structure et évolution en 4 semaines* ([DEV.to](https://dev.to/michelfaure))

## Principe

Un `CLAUDE.md` efficace ne documente pas, il **contraint**. Chaque règle répond à une fois où l'agent s'est trompé. Écrire l'interdit avant la bonne pratique.

## Structure à 4 couches

| Couche | Fichier | Portée |
|---|---|---|
| 1. Général | [`CLAUDE.md.example`](./CLAUDE.md.example) | Stack, commandes, conventions transversales, zones interdites |
| 2. Méta-agent | [`AGENTS.md.example`](./AGENTS.md.example) | Pre-requisites que l'agent doit intérioriser avant toute tâche |
| 3. Vertical | [`rules/module.md.example`](./rules/module.md.example) | Règles métier d'un module, chargées uniquement si pertinent |
| 4. Skill | *(hors repo)* | Auto-invocation par périmètre, consolide les règles avec pointeurs vers incidents |

Chaque tâche charge exactement ce dont elle a besoin. Mélanger les règles verticales dans le `CLAUDE.md` racine noierait l'agent sous du contexte non pertinent à chaque session.

## Format de règle recommandé

> « ne jamais X, parce que Y a crashé le DATE »

- **Portée explicite** : X est borné, pas général
- **Incident cité** : Y est un fait, pas une opinion
- **Date datée** : vérifiable, opposable, traçable

Une règle abstraite se dissout. Une règle tracée tient.

## Discipline

Relire son propre `CLAUDE.md` tous les 15 jours. Si une règle n'a pas été convoquée depuis un mois, soit le problème est résolu (on l'archive), soit elle est trop abstraite (on la réécrit). Un fichier qui dort n'aide pas l'agent.
