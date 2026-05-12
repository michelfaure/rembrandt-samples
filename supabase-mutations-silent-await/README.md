# supabase-mutations-silent-await/

`await supabase.from(X).delete()` (or `.insert()`, `.update()`, `.upsert()`) does not throw on a database error. The return is a `{ data, error }` object. If you don't destructure it, the error evaporates silently. The application then keeps running on a corrupted assumption — until something downstream cracks, and the symptom points at the *wrong* error.

**Source article**: *Why your Supabase mutations lie about their errors* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

Every awaited Supabase mutation must either destructure `{ error }` and decide what to do with it, or chain `.throwOnError()` so it raises like any other exception. A bare `await` on a mutation is a silent-failure factory.

## Files

| File | Role |
|---|---|
| [`01-three-patterns.ts`](./01-three-patterns.ts) | Side-by-side: the anti-pattern (bare await, error evaporates) + the explicit pattern (`{ error }` destructure + throw) + the short pattern (`.throwOnError()`). |
| [`02-eslint-rule.mjs`](./02-eslint-rule.mjs) | ESLint rule `no-bare-await-on-supabase-mutation`. Visitor on `AwaitExpression` whose argument is a chain containing `.insert / .update / .upsert / .delete`, when the await is a bare statement (not destructured, not assigned). |
| [`03-rpc-security-definer.sql`](./03-rpc-security-definer.sql) | Pattern alternatif : when you have a multi-step DELETE cascade, wrap it in a `SECURITY DEFINER` transactional RPC. The transaction fails atomically with the real error code (`23514`, `23503`, ...) — no intermediate applicative step can mask it. |

## How to read this folder

Start with `01-three-patterns.ts` to see the contract. Then `02-eslint-rule.mjs` for the structural defense at write time. Finally `03-rpc-security-definer.sql` for the case where applicative chaining is itself the problem and a DB-side transaction is the right fix.

## How to adapt it

- The lint rule keys off the literal identifier `supabase` is **not** required — it walks the chain by method name (`insert`, `update`, `upsert`, `delete`). If your client is named differently, the rule still fires.
- The RPC pattern in `03-rpc-security-definer.sql` is illustrative — adapt the table names, the conditional checks, and the `RAISE EXCEPTION` codes to your own schema.
- The lint rule treats a bare statement-level `await` as the failure mode. If you have legitimate fire-and-forget mutations (rare), suppress with a line comment and document why.

## Why this matters

The Supabase JS client deliberately doesn't throw — it returns `{ data, error }` so that the same call site can handle 200 OK, 400 PGRST, and 23xx Postgres errors uniformly. The design is sound. The application failure is when a developer (or a coding agent) writes `await supabase.from(X).delete(...)` because the type system says it compiles and the test says it passes. Nothing in the language or in the SDK forbids it. The error class only shows up at runtime, in production, on a row that violates a constraint nobody anticipated.

A code review almost never catches it — the diff looks normal. A test catches it only if you specifically write a test for the error path, which most teams don't. The lint rule is the only defense that fires on every push.
