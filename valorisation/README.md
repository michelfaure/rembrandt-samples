# valorisation/

Excerpts from the module that estimates the value of an internal ERP without a market price.

**Source article**: *How much are 91,000 lines produced with Claude Code actually worth?* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

An automatic counter feeding into a value calculation must have a watcher. Without a watcher, the metric becomes an oracle that takes itself at its word.

## Files

| File | Role |
|---|---|
| [`compute.ts`](./compute.ts) | `consolidate(dims)` pattern — sums N dimensions, tracks which were used, accepts `null` |
| [`guardrail-cron.ts`](./guardrail-cron.ts) | 20-line guardrail that detects abnormal LOC counter bumps and posts to Slack |
| [`schema.sql`](./schema.sql) | Minimal `valorisation_snapshots` schema with `snapshot_date UNIQUE` |

## How to adapt it

- Replace `lines_total` with your own metric (revenue, users, tickets resolved)
- Tune the threshold `3 * Math.max(avg * 0.02, 500)` to your order of magnitude
- Wire the Slack webhook (or Discord, or email) to the event you want to see before booking it as progress

## What this pattern is not

It's not a financial valuation tool. It's an instrument of internal judgment. It produces a defensible value, not a market price.
