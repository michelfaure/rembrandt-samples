# inscriptions-places/

Excerpts from the contact × course modeling of a school ERP.

**Source article**: *1 enrollment = N seats: when a table name lies* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

A row in the `inscriptions` table represents a **seat** (one contact × one course), not a commercial enrollment. The commercial enrollment — the annual contract signed by a student who takes N courses — is *derived*, not stored.

## Files

| File | Role |
|---|---|
| [`queries.sql`](./queries.sql) | The 3 queries that translate the invariant and stop lying |
| [`schema.sql`](./schema.sql) | Minimal `contacts` / `cours` / `inscriptions` schema with `UNIQUE (contact_id, cours_id)` |

## When this pattern applies

Whenever you store an N×M relation whose usual business name ("enrollment", "order", "booking") refers to a single commercial concept, while each row represents a component unit.

The right reflex isn't to rename the table — it's to **inscribe the invariant rule in your `CLAUDE.md`** so that neither you nor the agent generate a naive query again.

## The three options always considered (and the fourth that wins)

| Option | Cost | Semantics |
|---|---|---|
| Status quo | 0 | Lifelong trap |
| Rename `inscriptions` → `places` | Heavy (FK, RLS, triggers, views, code) | Clean |
| Split into 2 tables | Multi-week | Very clean |
| **Keep the schema, hold the documented invariant** | Low | Ambiguous but bounded |

Reasoning details in the article.
