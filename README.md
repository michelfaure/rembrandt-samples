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
| [`rls-supabase/`](./rls-supabase) | *Supabase RLS in production: four traps that silence your queries* | Anon-surface audit + policies with USING/WITH CHECK + storage privatization + client selection + RLS-without-policies detector |
| [`lead-pipeline/`](./lead-pipeline) | *29 Zapier + Make automations replaced in four weeks* | `runLeadPipeline` with `Promise.allSettled` + `automation_logs` schema + hub-and-spoke architecture diagram |
| [`semantic-layer-drift/`](./semantic-layer-drift) | *Six days, six seconds: a CI test against semantic-layer drift on an AI agent* | Enum sync script + Vitest contract test + `agent_runs` schema with zero-row canary index |
| [`lazy-sdk-proxy/`](./lazy-sdk-proxy) | *Fifteen lines of Proxy to keep an SDK from breaking my CI* | Lazy-Proxy pattern on Stripe + Twilio + Anthropic — defers the constructor credential check from build to first call |
| [`silent-failure-modes/`](./silent-failure-modes) | *Five silent failure modes I codified after 35 effective days of solo ERP coding* | Negative contract test (anti-tautology) + quarterly DB ↔ code enum audit script |
| [`material-verification/`](./material-verification) | *Why "green build" without the raw output has zero evidentiary value* | `CLAUDE.md` evidentiality rule (5 bullets) + `verify-head-builds.sh` (stash + tsc HEAD + restore) |
| [`counterpart-doctrine/`](./counterpart-doctrine) | *The Counterpart Doctrine: a seven-axis spec for working with an AI coding agent* | Full v0.2 doctrine + one-page ADR template + 8-anti-patterns checklist |
| [`postgrest-row-cap/`](./postgrest-row-cap) | *Why your Supabase query stops at exactly 1000 rows (and never tells you)* | Buggy/fixed `.select()` pair + `no-unordered-select` ESLint rule with 5 false-positive guards + cursor pagination helper |
| [`supabase-mutations-silent-await/`](./supabase-mutations-silent-await) | *Why your Supabase mutations lie about their errors* | Three contracts for awaited mutations (bare / destructured / `.throwOnError()`) + `no-bare-await-on-supabase-mutation` ESLint rule + `SECURITY DEFINER` transactional RPC alternative |
| [`saas-config-platform-vs-repo/`](./saas-config-platform-vs-repo) | *The SaaS config you can't `git diff`: a 30-second audit before every `update`* | Four-step audit protocol + concrete Vercel `commandForIgnoringBuildStep` example + Supabase RLS / Auth hook drift detector |

## How to read this repo

Each folder ships a `README.md` that points to the source article, frames the invariant rule, and explains what each file illustrates. The TypeScript/SQL/Markdown excerpts are meant to be copied, not run as-is — there's no runtime, no package.json, no tests in this repo.

If you want to understand the reasoning behind a snippet, read the article first. If you just want the code, come here.

## License

[MIT](./LICENSE) — do whatever you want with it, credit if it helps you.
