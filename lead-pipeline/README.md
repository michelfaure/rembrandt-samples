# lead-pipeline/

Replace a Zapier/Make spider-web of automations with a single Postgres table as source of truth, plus a parallel fan-out function in TypeScript. Twenty-nine automations cut down to one file.

**Source article**: *29 Zapier + Make automations replaced in four weeks* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

One entry point per source, one place of storage, one *fan-out* in parallel toward notification tools. The pipeline never fails the lead-creation transaction — `Promise.allSettled` lets every notification fail independently and logs each outcome to a dedicated table.

## Files

| File | Role |
|---|---|
| [`lead-pipeline.ts`](./lead-pipeline.ts) | The `runLeadPipeline(lead)` function — `Promise.allSettled` over every outbound integration, each result written to `automation_logs` |
| [`automation-logs-schema.sql`](./automation-logs-schema.sql) | The `automation_logs` table, indexes, and the morning dashboard query |
| [`architecture.md`](./architecture.md) | The hub-and-spoke diagram + commentary on why fan-out goes outside the request lifecycle |

## How to read this folder

Start with `architecture.md` to see what the hub-and-spoke shape looks like and why every external system on the receiving side is downstream of one Postgres table. Then `lead-pipeline.ts` for the parallel fan-out implementation. Finally `automation-logs-schema.sql` for the observability layer that lets you check at a glance which integrations failed overnight.

## Why fan-out outside the request

The web request that creates the lead returns as soon as the row hits Postgres. The fan-out runs in `waitUntil` (Vercel/Next.js) or a queue worker, *not* in the request critical path. Slack being down has zero effect on lead capture. This decoupling is the single most important thing — it's what lets you replace 29 automations without inheriting their failure modes.

## Why `allSettled` and not `all`

`Promise.all` short-circuits on the first rejection, which would mean Slack being down silences the email notification. `Promise.allSettled` runs every notification to completion and returns an array of `{ status: 'fulfilled' | 'rejected' }` results. Each one feeds a row in `automation_logs`. The morning dashboard tells you exactly what worked and what didn't, on what window.
