# semantic-layer-drift/

Detect when the semantic layer of an AI SQL agent has drifted from the actual database schema. A test that fails in six seconds where the bug had been silent for six days.

**Source article**: *Six days, six seconds: a CI test against semantic-layer drift on an AI agent* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

A semantic layer is a second database. It has its schema, its constraints, its vocabulary, and like any database it drifts if you don't audit it. The documentation is a writing guide, **not** a source of truth. Whenever a column carries an enumeration consumed by the layer, seed that enumeration from the database, and test the consistency in CI.

## Files

| File | Role |
|---|---|
| [`sync-semantic-enums.ts`](./sync-semantic-enums.ts) | Pre-commit / CI script that reads enum-bearing columns from the database and writes a generated TS module. The contract follows the schema, with no human in the loop. |
| [`semantic-drift.test.ts`](./semantic-drift.test.ts) | Vitest test that loops over every whitelisted table in the semantic layer, compares the declared `enum` to the actual values in the DB, and fails the build on divergence. |
| [`agent-runs-schema.sql`](./agent-runs-schema.sql) | Minimal schema for the `agent_runs` table that records each query run, including `result_row_count` — the column that surfaces silent zero-row drift. |

## How to read this folder

Start with `sync-semantic-enums.ts` — it explains why the doc isn't the source. Then `semantic-drift.test.ts` — the CI gate that catches drift on the next push. Finally `agent-runs-schema.sql` — the observability layer that lets you also detect drift *retroactively* on questions already answered (zero rows on a business-reasonable question is a smell).

## How to adapt it

- Replace the table list and column names in `targets` (sync script) with your own enum-bearing columns
- The Vitest test assumes a `semanticTables` registry — adapt to your own structure (one table per file, exporting a `columns` map with optional `enum` field)
- The `agent_runs` table fits any agent that runs SQL on behalf of users, regardless of the LLM provider

## Why this matters

A SQL-generating agent that filters on values that don't exist in the database returns zero rows. The SQL is valid. The validator passes. The LLM-written comment to the end user rationalises the zero ("the year's payments may be up to date"). Nothing throws. Nothing alerts. The bug is rigorously invisible until you query the column by hand and see that the four values the layer declared aren't anywhere in the DB.

The fix isn't smarter prompting. It's a contract test. Run it on every push, and the drift surfaces at the next commit instead of at the next demo.
