/**
 * The three contracts for awaited Supabase mutations.
 *
 * The Supabase JS client returns `{ data, error }` on every mutation. It does
 * NOT throw on database errors. A bare await silently discards the error;
 * the application keeps running on a wrong assumption until something
 * downstream cracks — and the symptom points at the wrong cause.
 *
 * Anti-pattern, explicit pattern, short pattern. Pick one of the latter two.
 */

import { createClient } from '@supabase/supabase-js'
const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!)

const id = 'evt_42'

// ❌ Anti-pattern: the DB error evaporates.
//    A CHECK violation, FK violation, RLS denial — all silent.
//    The application continues. The UI eventually shows an unrelated error.
await supabase.from('events').delete().eq('id', id)

// ✓ Explicit pattern: destructure { error }, decide what to do with it.
//    Verbose but unambiguous. Use this when the caller has context
//    to handle specific error classes (e.g. 23503 → "still has dependents").
{
  const { error } = await supabase.from('events').delete().eq('id', id)
  if (error) {
    throw new Error(`delete events ${id}: ${error.code} ${error.message}`)
  }
}

// ✓ Short pattern: convert to a thrown exception via .throwOnError().
//    Use this when the caller wants standard try/catch + middleware handling
//    and doesn't need to branch on the error class at the call site.
await supabase.from('events').delete().eq('id', id).throwOnError()

// ───────────────────────────────────────────────────────────────────────
// Same three contracts apply to insert / update / upsert. The lint rule
// in 02-eslint-rule.mjs flags bare awaits on all four mutation methods.
// ───────────────────────────────────────────────────────────────────────

const payload = { id: 'evt_43', type: 'login' }

// ❌
await supabase.from('events').insert(payload)

// ✓
{
  const { error } = await supabase.from('events').insert(payload)
  if (error) throw new Error(error.message)
}

// ✓
await supabase.from('events').insert(payload).throwOnError()
