/**
 * semantic-drift.test.ts
 *
 * Vitest test that loops over every whitelisted table in the semantic layer
 * and compares the declared `enum` of each column to the actual distinct
 * values in the DB. Fails the build on divergence.
 *
 * Run: npx vitest run semantic-drift
 *
 * Assumes a `semanticTables` registry exported from your semantic-layer
 * module. The shape used here:
 *
 *   type ColumnDef = { type: string; description: string; enum?: readonly string[] }
 *   type TableDef  = { name: string; columns: Record<string, ColumnDef> }
 *   export const semanticTables: TableDef[] = [...]
 *
 * Adapt to your own structure if it differs.
 */

import { describe, it, expect } from 'vitest'
import { createClient } from '@supabase/supabase-js'
import { semanticTables } from '../lib/analytics/semantic'

const admin = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
)

describe('semantic layer drift', () => {
  for (const table of semanticTables) {
    for (const [col, def] of Object.entries(table.columns)) {
      if (!def.enum) continue

      it(`${table.name}.${col} matches DB enum values`, async () => {
        const { data, error } = await admin.from(table.name).select(col)
        expect(error, `query failed: ${error?.message}`).toBeNull()

        const real = new Set(data?.map((r) => r[col]).filter(Boolean))
        const declared = new Set(def.enum)

        // Every value present in the DB must be declared in the layer.
        // (Reverse direction is also catchable; see note below.)
        for (const v of real) {
          expect(
            declared,
            `DB has "${v}" but semantic layer declares ${JSON.stringify([...declared])}`,
          ).toContain(v)
        }

        // Optional: also catch declared-but-never-seen values (cleanup signal).
        // Comment out if your DB occasionally lacks a legitimate value (e.g. annule
        // before the first cancellation event).
        for (const v of declared) {
          expect(
            real,
            `semantic layer declares "${v}" but DB never carries it`,
          ).toContain(v)
        }
      })
    }
  }
})
