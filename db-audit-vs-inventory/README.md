# db-audit-vs-inventory/

A baseline resync ticket said "at least two missing objects". The block audit found over a hundred — across tables, columns, views, functions, triggers, policies, indexes, roles, plus a fully desynchronized migration tracker. This folder is the protocol that detects all of them in under ten minutes, one category at a time.

**Source article**: *Why your DB audit always finds more than your inventory says* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

Beyond three or four drifts found by iteration on a long-lived database, switch to block audit. Iterating drift-by-drift means you don't know the scope — the sixth one shows up after you've patched five. The block audit gives you the full list before you touch the first object.

## Files

| File | Role |
|---|---|
| [`block-audit.sh`](./block-audit.sh) | One script, eight categories: tables, columns, views, functions, triggers, policies, indexes, roles. Dumps each from `pg_*` / `information_schema.*` on production, diffs against `CREATE` statements in your `migrations/` folder, prints the asymmetric difference. |
| [`tracker-sync-check.sh`](./tracker-sync-check.sh) | Detects the silent killer: when `supabase_migrations.schema_migrations` (or your migrations tracker) has diverged so far from the repo that the two sets share zero rows. The case-archetype of three months of Web Studio operations gone untracked. |

## How to read this folder

Start with `block-audit.sh` and run it against a database you trust to be in sync with its repo (a staging clone is ideal). The output should be empty on every category. The day it isn't, you've measured the drift before it surprised you in production.

`tracker-sync-check.sh` is the early-warning probe. Run it monthly. If the intersection of repo versions and prod versions drops below 90%, your migration discipline has slipped — investigate before the next audit pile-up.

## How to adapt it

- Replace `$PROD_URL` with your psql connection string. The block audit only needs `SELECT` rights on `information_schema.*` and `pg_catalog.*`.
- The grep heuristic in `block-audit.sh` assumes flat `CREATE TABLE public.x` syntax. If your migrations use a more complex DDL generator (Prisma, Drizzle, Atlas), parse the generator's output instead.
- For non-Postgres databases (MySQL, SQL Server), the categories map differently but the protocol is the same: dump from system catalogs, dump from migrations, diff.

## Why this matters

Drift on a database that runs in production for several months is structural, not accidental. Even if your team is disciplined, even if every change is supposed to go through a migration, you have at least one ticket where someone opened the Web Studio "just to fix something quickly" and never wrote the migration after. Multiply that by every hotfix, every analytics column, every Stripe integration evening, every emergency role grant. After six months, your inventory is wrong by an order of magnitude — and the worst part is you don't know by how much.

The block audit doesn't prevent drift. It surfaces it before the next baseline resync chains five patches into a fifty-object cleanup.
