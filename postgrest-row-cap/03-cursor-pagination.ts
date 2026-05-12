/**
 * Cursor pagination helper for Supabase / PostgREST.
 *
 * Pages through a query past the 1000-row cap without using OFFSET. Each
 * page is fetched with `.gt(orderBy, lastValue).limit(PAGE_SIZE)`, so there
 * is no `ORDER BY ctid` fallback and no temp-file sort spill.
 *
 * Usage (cursor mode, default):
 *   const rows = await fetchAll(() =>
 *     supabase.from('events').select('id, type, created_at').eq('type', 'login')
 *   )
 *
 * Usage (OFFSET fallback for views without a stable id):
 *   const rows = await fetchAll(() =>
 *     supabase.from('my_aggregate_view').select('label, total')
 *   , { cursor: false, orderBy: 'label' })
 *
 * Two contracts to respect:
 *   - The callback must return a NEW query builder on each call (don't reuse).
 *   - The cursor column (default 'id') must be in the SELECT.
 *
 * The ESLint rule `no-unordered-select` in 02-eslint-rule.mjs whitelists
 * `fetchAll(() => supabase.from(X).select(...))` because the helper injects
 * its own `.order(orderBy)` inside. Add other helper names to the rule's
 * `HELPER_NAMES` set if you wrap this in your own project.
 */

const PAGE_SIZE = 1000

type QueryWithOrder<T> = {
  order(column: string, options?: { ascending?: boolean }): QueryWithGtLimit<T>
}

type QueryWithGtLimit<T> = {
  gt(column: string, value: unknown): QueryWithLimit<T>
  limit(count: number): PromiseLike<{ data: T[] | null; error: { message: string } | null }>
  order(column: string, options?: { ascending?: boolean }): QueryWithGtLimit<T>
}

type QueryWithLimit<T> = {
  limit(count: number): PromiseLike<{ data: T[] | null; error: { message: string } | null }>
}

type QueryWithRange<T> = {
  order(column: string, options?: { ascending?: boolean }): QueryWithRange<T>
  range(from: number, to: number): PromiseLike<{ data: T[] | null; error: { message: string } | null }>
}

type RangeableQuery<T> = QueryWithOrder<T> | QueryWithRange<T>

export type FetchAllOptions =
  | { cursor?: true; orderBy?: string }
  | { cursor: false; orderBy?: string }

export async function fetchAll<T>(
  buildQuery: () => RangeableQuery<T>,
  options: FetchAllOptions = {},
): Promise<T[]> {
  const { cursor = true, orderBy = 'id' } = options as { cursor?: boolean; orderBy?: string }

  if (!cursor) {
    // OFFSET fallback — for views without a stable id column.
    const all: T[] = []
    let from = 0
    for (;;) {
      const q = buildQuery() as QueryWithRange<T>
      const { data, error } = await q
        .order(orderBy, { ascending: true })
        .range(from, from + PAGE_SIZE - 1)
      if (error) throw new Error(`fetchAll(offset): ${error.message}`)
      if (!data?.length) break
      all.push(...data)
      if (data.length < PAGE_SIZE) break
      from += PAGE_SIZE
    }
    return all
  }

  // Cursor pagination — no OFFSET, no temp-file sort.
  const all: T[] = []
  let lastId: unknown = null
  for (;;) {
    const q = buildQuery() as QueryWithOrder<T>
    const withOrder = q.order(orderBy, { ascending: true })
    const page = lastId !== null
      ? withOrder.gt(orderBy, lastId).limit(PAGE_SIZE)
      : withOrder.limit(PAGE_SIZE)
    const { data, error } = await page
    if (error) throw new Error(`fetchAll(cursor): ${error.message}`)
    if (!data?.length) break
    all.push(...data)
    if (data.length < PAGE_SIZE) break
    const lastRow = data[data.length - 1] as Record<string, unknown>
    lastId = lastRow[orderBy] ?? null
    if (lastId === null) {
      throw new Error(
        `fetchAll: cursor column "${orderBy}" missing from selected fields. ` +
        `Include "${orderBy}" in the SELECT or pass { cursor: false }.`,
      )
    }
  }
  return all
}
