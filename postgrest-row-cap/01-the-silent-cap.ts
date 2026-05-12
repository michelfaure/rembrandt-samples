/**
 * The PostgREST silent 1000-row cap.
 *
 * The buggy query and the fixed query, side by side. Both look correct.
 * Only the second one returns the full result set when the table has more
 * than 1000 rows.
 *
 * Why the first one is wrong:
 *   - No .order() means PostgREST falls back to ORDER BY ctid (physical tuple
 *     identifier) and applies a default LIMIT 1000 via the Range HTTP header.
 *   - The query succeeds. No exception. No warning. No Sentry breadcrumb.
 *   - The result is a typed T[] of length ≤ 1000. The client cannot tell
 *     more rows were available.
 *   - The ordering is unstable: VACUUM FULL, pg_repack, or routine UPDATE/DELETE
 *     traffic re-shuffles ctid. Pagination based on this is wrong, period.
 */

import { createClient } from '@supabase/supabase-js'
const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!)

// ❌ Silently capped at 1000 rows. Order depends on physical layout.
const buggy = await supabase
  .from('events')
  .select('*')
  .eq('type', 'login')

// ✓ Stable order. The Range header still caps at 1000, but the cap is now
//   on a deterministic slice, and the helper in 03-cursor-pagination.ts can
//   page through the rest reliably.
const fixed = await supabase
  .from('events')
  .select('*')
  .eq('type', 'login')
  .order('id')

// ✓ Also safe: single-row terminator. PostgREST returns at most one row,
//   no Range header involvement.
const oneRow = await supabase
  .from('events')
  .select('*')
  .eq('id', 'evt_42')
  .single()

// ✓ Also safe: count-only HEAD. No rows returned at all.
const { count } = await supabase
  .from('events')
  .select('*', { count: 'exact', head: true })
  .eq('type', 'login')

void buggy
void fixed
void oneRow
void count
