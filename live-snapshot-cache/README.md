# live-snapshot-cache/

Tools for the three-way classification before storing any derived value: **Live, Snapshot, or Cache**.

**Source article**: *Live, Snapshot, Cache: the three-way decision before storing a derived value* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

Every stored value that resembles a duplication must be classified, before being created or kept, as **Live**, **Snapshot**, or **Cache**. Each category has a distinct implementation contract. A duplication without a category is a bug in waiting.

| Category | Question | Implementation |
|---|---|---|
| **Live** | Must always reflect the current state? | Don't store. Read via SQL view (`v_*`). |
| **Snapshot** | Must remain frozen at a business event? | Store, never recalculate. Protect in writing. |
| **Cache** | Derivable but expensive to compute on every read? | Store + declare a refresher in the same commit. |

## Files

| File | Role |
|---|---|
| [`decision-checklist.md`](./decision-checklist.md) | The 3-question algorithm as a copy-pastable migration review checklist |
| [`live-view.sql`](./live-view.sql) | Example Live read pattern — a view that sums installments dynamically |
| [`snapshot-protection.sql`](./snapshot-protection.sql) | CHECK constraint + trigger that forbids UPDATE on a Snapshot column after creation |
| [`cache-trigger.sql`](./cache-trigger.sql) | Cache refresher pattern — `trg_*` trigger with mandatory `COMMENT ON COLUMN` |
| [`migration-of-category.sql`](./migration-of-category.sql) | Pattern for migrating a Live-disguised-as-Snapshot to a real Live (drop column, route reads to view) |

## How to read this folder

Start with `decision-checklist.md` — it gives the three questions in order. Then pick the SQL example that matches the category you're trying to implement.

The migration file is the one to read carefully if you've inherited a column you stopped trusting. The fix is rarely "recalculate periodically" — it's usually "delete the column and route reads through a view." The migration shows the shape of that surgery.

## What this is not

It's not a recipe for performance optimization. The default is **Live** — don't store. You only fall back to Cache when measurement shows the cost is real, and you only fall back to Snapshot when the value should freeze at a business event. Storing without classification is the bug this folder exists to prevent.
