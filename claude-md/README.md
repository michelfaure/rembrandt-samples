# claude-md/

Documentation architecture template for steering a project with Claude Code.

**Source article**: *My CLAUDE.md for an ERP: structure and 4-week evolution* ([DEV.to](https://dev.to/michelfaure))

## Principle

An effective `CLAUDE.md` doesn't document, it **constrains**. Every rule answers a moment when the agent got it wrong. Write the prohibition before the best practice.

## 4-layer structure

| Layer | File | Scope |
|---|---|---|
| 1. General | [`CLAUDE.md.example`](./CLAUDE.md.example) | Stack, commands, cross-cutting conventions, no-go zones |
| 2. Meta-agent | [`AGENTS.md.example`](./AGENTS.md.example) | Pre-requisites the agent must internalize before any task |
| 3. Vertical | [`rules/module.md.example`](./rules/module.md.example) | Business rules of a module, loaded only when relevant |
| 4. Skill | *(out of repo)* | Auto-invoked by scope, consolidates rules with pointers to incidents |

Each task loads exactly what it needs. Mixing vertical rules into the root `CLAUDE.md` would drown the agent in irrelevant context every session.

## Recommended rule format

> "never X, because Y crashed on DATE"

- **Explicit scope**: X is bounded, not generic
- **Cited incident**: Y is a fact, not an opinion
- **Dated**: verifiable, defensible, traceable

An abstract rule dissolves. A traced rule holds.

## Discipline

Re-read your own `CLAUDE.md` every two weeks. If a rule hasn't been invoked in a month, either the problem is solved (archive it), or it's too abstract (rewrite it). A file that sleeps doesn't help the agent.
