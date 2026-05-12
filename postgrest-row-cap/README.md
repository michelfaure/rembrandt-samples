# postgrest-row-cap/

A `.from(X).select(...)` without an explicit `.order()` falls back to `ORDER BY ctid` server-side and is silently capped at 1000 rows by PostgREST. The query succeeds. No exception, no warning. The bug surfaces only when the table grows past a thousand rows in production, and the symptom is always something else (a UI filter that looks broken, a dropdown that seems incomplete, an aggregate that doesn't match).

**Source article**: *Why your Supabase query stops at exactly 1000 rows (and never tells you)* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

Every multi-row Supabase `.from(X).select(...)` must declare an explicit `.order()`. No `.order()` means an unstable, capped result — and the symptom never points at the query. The fallback `ORDER BY ctid` is not a stable ordering: `VACUUM FULL`, `pg_repack`, or even routine `UPDATE`/`DELETE` traffic re-shuffles it.

This is the kind of failure that no test catches by accident. You need a lint rule.

## Files

| File | Role |
|---|---|
| [`01-the-silent-cap.ts`](./01-the-silent-cap.ts) | The minimal reproduction: the buggy query, the fixed query, side by side. Annotated in comments. |
| [`02-eslint-rule.mjs`](./02-eslint-rule.mjs) | Production-grade ESLint rule. Detects `.from(X).select(...)` without `.order()` or single-row terminator. Five guard mechanisms inside to keep noise around ~40% of the raw signal. |
| [`03-cursor-pagination.ts`](./03-cursor-pagination.ts) | `fetchAll(() => ...)` helper that pages a query past the 1000-row cap without `OFFSET` (cursor pagination on `id`). The helper injects its own `.order()` — the lint rule recognizes it as a safe wrapper. |

## How to read this folder

Start with `01-the-silent-cap.ts` to see the exact pattern in three lines. Then read `02-eslint-rule.mjs` — the rule is short on the detection itself but heavy on the guards. Each guard is documented inline with the false-positive class it neutralizes. Finally `03-cursor-pagination.ts` if you need to actually page through a large table without re-introducing `OFFSET` Disk IO spill.

## How to adapt it

- The rule keys off the literal identifier `supabase` in the chain (`.from()` resolution by name). If your client variable is named differently (e.g. `db`, `sb`), adjust the `chainContainsFromCall` helper.
- The `fetchAll` helper assumes the table has a stable, monotonic `id` column. If yours doesn't, pass `{ cursor: false, orderBy: 'your_column' }` for the OFFSET fallback.
- The error message in the rule mentions an ADR — replace with your own internal reference.

## Why this matters

The 1000-row cap is documented in the Supabase docs under "Modifying default values", in a paragraph titled "API settings". It is not surfaced anywhere in the client library's TypeScript types. The query returns a typed `T[]` of length ≤ 1000 with no signal that more rows were available. A junior dev writing `await supabase.from('events').select('*')` has no way of knowing the result is partial. A senior dev sometimes forgets. A code review rarely catches it because the diff looks normal.

The only viable defense is a lint rule that fires at write time, on every push. Anything less and the next pagination bug is already in your repo, waiting for the table to grow.
