# Decision checklist — Live / Snapshot / Cache

Run this in order before adding any column that ressembles a duplication. Stop at the first decisive answer.

## Question 1 — Frozen past or moving present?

> **Must the value evolve with the upstream data?**

- **No** — the value records a past business event (price at enrollment, invoice number, signed amount). It's a **Snapshot**.
  → Store. Never recalculate. Add write protection (CHECK / trigger / discipline).
  → Skip to "Snapshot implementation" below.

- **Yes** — the value tracks something that keeps changing. Continue to question 2.

## Question 2 — Compute on the fly or store?

> **Is computing it at read time acceptable performance-wise?**

Quick test: a join under 10 ms, an aggregate over a few hundred rows, a query that doesn't appear in a hot loop.

- **Yes** — it's **Live**.
  → Don't store. Create a SQL view (`v_*`).
  → Skip to "Live implementation" below.

- **No** — the read cost is genuinely too high. Continue to question 3.

## Question 3 — Which refresh mechanism?

> **How will the cached value stay in sync with its source?**

Three mechanisms admitted, in order of preference:

1. **`GENERATED ALWAYS AS (...)`** — the value derives from other columns of the same row. Postgres maintains it for free.

2. **Trigger `trg_*`** — the value derives from another table modified frequently. The trigger fires on INSERT/UPDATE/DELETE of the source table.

3. **Materialized view `mv_*`** — the value derives from heavy aggregation. Refresh on a schedule (cron) or after bulk operations.

Whichever you choose, the refresher exists **in the same commit as the column**. Not "later." Later doesn't come.

If none of the three is tenable, the value should not be stored. Fall back to Live and accept the compute cost — or question whether the business need justifies any storage at all.

## Mandatory documentation for Cache columns

Every Cache column carries a SQL comment at migration time:

```sql
COMMENT ON COLUMN your_table.cached_column
  IS 'CACHE: refreshed by trg_source_table_sync_cache';
```

Without this comment, the next reader of the schema cannot distinguish a managed Cache from a Live that diverged silently.

## Naming conventions

| Prefix | Type |
|---|---|
| `v_*` | SQL view (Live read) |
| `mv_*` | Materialized view (Cache at DB level) |
| `trg_*` | Trigger (typically a Cache refresher) |
| `fn_*` | SQL function |

## Anti-patterns to refuse in review

- **Storing a copy "to avoid the join"** without a refresher — divergence guaranteed.
- **Recalculating a Snapshot retroactively for consistency** — that steals history. New event = new row, not edit of old row.
- **Adding a Cache column with the refresher "to be added in the next PR"** — the next PR doesn't come.
- **A column whose category nobody can name** — refuse the migration. Classify or remove.

## When you find a violation in production

Don't patch by recalculating once. That re-establishes the divergence at the next upstream event. The fix is **migration of category**:

- Live disguised as Snapshot → drop the column, route reads through a view.
- Cache without refresher → write the trigger, backfill once, document.
- Snapshot being mutated → freeze with CHECK constraint, fix the writers.

See [`migration-of-category.sql`](./migration-of-category.sql) for the pattern.
