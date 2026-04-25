# rls-supabase/

SQL and TypeScript patterns for the four traps that silence your Supabase queries — plus the bonus fifth one (infinite recursion on `user_roles`).

**Source article**: *Supabase RLS in production: four traps that silence your queries* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

A permission system that doesn't scream when it fails is a dangerous system. **Row Level Security** misconfigurations don't return errors — they return empty result sets, partial reads, or open writes. Instrument the silence.

## The four traps + bonus

| Trap | Symptom | Fix file |
|---|---|---|
| **1.** Wrong Supabase client in a Server Component | Query returns `[]` with no error | [`client-selection.ts`](./client-selection.ts) |
| **2.** RPC functions executable by `anon` by default | Public endpoint exposes internal logic | [`audit-anon-surface.sql`](./audit-anon-surface.sql) |
| **3.** Write policy missing or without `WITH CHECK` | Authenticated user writes anywhere, or writes rows they can't read back | [`policies-with-check.sql`](./policies-with-check.sql) |
| **4.** Storage bucket left public | Files (signatures, ID photos) accessible by URL | [`storage-bucket-private.sql`](./storage-bucket-private.sql) |
| **+** Infinite recursion on `user_roles` policy | `infinite recursion detected in policy` errors everywhere | covered in [`policies-with-check.sql`](./policies-with-check.sql) §recursion |

## Files

| File | Role |
|---|---|
| [`audit-anon-surface.sql`](./audit-anon-surface.sql) | Detect functions exposed to `anon`, plus REVOKE / GRANT / ALTER DEFAULT PRIVILEGES bulk-fix |
| [`policies-with-check.sql`](./policies-with-check.sql) | The `SELECT` + `INSERT/UPDATE/DELETE` pair with `USING` and `WITH CHECK` clauses, plus the recursion-safe `user_roles` pattern |
| [`storage-bucket-private.sql`](./storage-bucket-private.sql) | Migration `public → private` for a Supabase Storage bucket |
| [`client-selection.ts`](./client-selection.ts) | The three Supabase clients (browser, server, admin) with explicit guidance on when to use each |
| [`list-rls-without-policies.sql`](./list-rls-without-policies.sql) | Detect tables with RLS enabled but no policies — the silent open-or-closed trap on new tables |

## How to read this folder

If you're auditing an existing project, run [`audit-anon-surface.sql`](./audit-anon-surface.sql) and [`list-rls-without-policies.sql`](./list-rls-without-policies.sql) first. They give you the diff in 30 seconds. Then read [`policies-with-check.sql`](./policies-with-check.sql) for the writing pattern, and [`client-selection.ts`](./client-selection.ts) if you're on Next.js Server Components.

If you're starting fresh, copy [`policies-with-check.sql`](./policies-with-check.sql) as your first migration template, and [`client-selection.ts`](./client-selection.ts) into your `lib/` folder.

## What this is not

It's not a substitute for reading the [official Supabase RLS docs](https://supabase.com/docs/guides/database/postgres/row-level-security). It's the field-tested counterpart — the things the docs don't emphasize because they're not bugs in *Supabase*, they're traps in the **default behavior** of *Postgres* + *PostgREST*.
