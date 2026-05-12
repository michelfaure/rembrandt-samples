# saas-config-platform-vs-repo/

Some of your production configuration lives in the repo. Some of it lives on the platform's side (Vercel, Supabase, Stripe, GitHub) and is invisible to `git diff`. The trap is the reflex: you grep the repo, you find nothing, you conclude "no config" — when in fact the rule exists elsewhere, in silence, and your next `update` is about to overwrite it without a trace.

**Source article**: *The SaaS config you can't `git diff`: a 30-second audit before every `update`* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

Before any `updateProject` / `updateConfig` / PATCH against a SaaS platform, **read the current config in full**, diff it field-by-field against your target, and list explicitly which fields **regress** (present before, absent after). No "replace with what I want" without auditing what was there.

## Files

| File | Role |
|---|---|
| [`01-audit-protocol.sh`](./01-audit-protocol.sh) | Pseudo-bash protocol in four named steps. Universalized via `$PLATFORM_CLI`. Drop-in adapter for any CLI that supports `get` + `update --config @file`. |
| [`02-vercel-example.sh`](./02-vercel-example.sh) | Concrete instance for the case that prompted this rule: Vercel `commandForIgnoringBuildStep`. The trap is that this setting is project-level, not in `vercel.json` — you cannot find it by grepping the repo. |
| [`03-supabase-example.sh`](./03-supabase-example.sh) | Concrete instance for Supabase RLS policies and Auth hooks. Both live in the platform, mutable by SQL or API, with no automatic mirror in the repo unless you commit migrations religiously. |

## How to read this folder

Start with `01-audit-protocol.sh` for the abstract pattern. The two concrete examples then show what "current config" actually looks like at the platform layer for two common cases. Adapt to your own platform list — the structure is the same across Stripe webhooks, GitHub branch protection rules, Datadog monitors, and any other SaaS that has a config API.

## How to adapt it

- Replace `$PLATFORM_CLI` with your actual CLI (`vercel`, `supabase`, `stripe`, `gh`, `datadog-ci`, ...).
- The protocol assumes JSON-shaped configs. For YAML, replace `jq` with `yq`.
- The "regression list" step in the protocol uses naive key-set difference. For nested objects, walk recursively or use `jd` (JSON Diff) for a structured diff.
- The `read -p` confirmation step is a hard stop. In a CI context, replace with a fail-fast if regressions are non-empty.

## Why this matters

Most platforms don't tell you that a setting changed silently. Vercel doesn't email when your Ignored Build Step rule mutates. Supabase doesn't notify when an RLS policy is replaced via the SQL editor. GitHub doesn't flag when a ruleset shifts. The audit trail exists on the platform side (usually under a "Project Activity" or "Audit Log" tab) but it's not in your repo, not in your CI, not in your `git log`.

A bad overwrite can mean: a build credit bill multiplied tenfold for a month before you notice; a public-facing endpoint exposed for a weekend because RLS got rewritten; a webhook quietly redirected to a stale URL while events pile up. None of these trigger an alarm by default. The 30-second audit is the only cheap defense — and once you've done it three times for the same platform, the reflex sticks.
