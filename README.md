# rembrandt-samples

Snippets pulled from the article series **"My ERP with Claude Code"** published on DEV.to by [@michelfaure](https://dev.to/michelfaure).

Rembrandt is the codename of a vertical ERP coded solo with Claude Code for a ceramic art school (six locations, a few hundred students). This repo is not the Rembrandt codebase. It's a curated set of reproducible patterns, pseudonymized and de-contextualized, ready to drop into your own project.

## Contents

| Folder | DEV.to article | What you'll find |
|---|---|---|
| [`valorisation/`](./valorisation) | *How much are 91,000 lines produced with Claude Code actually worth?* | `consolidate(dims)` pattern + Slack guardrail on a LOC counter |
| [`inscriptions-places/`](./inscriptions-places) | *1 enrollment = N seats: when a table name lies* | 3 SQL queries + minimal contact × course schema |
| [`claude-md/`](./claude-md) | *My CLAUDE.md for an ERP: structure and 4-week evolution* | 4-layer template (CLAUDE.md, AGENTS.md, vertical rules, skill) |
| [`glue-ratio/`](./glue-ratio) | *The glue/business ratio: a CI gate against silent code bloat* | Measurement script + non-regression CI + GitHub Actions workflow |
| [`live-snapshot-cache/`](./live-snapshot-cache) | *Live, Snapshot, Cache: the three-way decision before storing a derived value* | Decision checklist + 4 SQL patterns (Live view, Snapshot protection, Cache trigger, category migration) |

## How to read this repo

Each folder ships a `README.md` that points to the source article, frames the invariant rule, and explains what each file illustrates. The TypeScript/SQL/Markdown excerpts are meant to be copied, not run as-is — there's no runtime, no package.json, no tests in this repo.

If you want to understand the reasoning behind a snippet, read the article first. If you just want the code, come here.

## License

[MIT](./LICENSE) — do whatever you want with it, credit if it helps you.
