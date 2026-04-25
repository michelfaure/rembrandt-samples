// Multi-dimension consolidation pattern.
// Sums N independent dimensions, tracks which were used,
// accepts null so a not-yet-instrumented dimension
// doesn't break the calculation but bows out honestly.

export type Dimension = {
  id: 'saas' | 'usage' | 'donnees' | 'strategique'
  low: number | null
  high: number | null
  source: string        // origin table or method
  refreshed_at: string  // ISO date
}

export type Consolidated = {
  value_low: number
  value_high: number
  dims_used: Dimension['id'][]
}

export function consolidate(dims: Dimension[]): Consolidated {
  const present = dims.filter(d => d.low !== null && d.high !== null)
  return {
    value_low:  present.reduce((a, d) => a + (d.low  ?? 0), 0),
    value_high: present.reduce((a, d) => a + (d.high ?? 0), 0),
    dims_used:  present.map(d => d.id),
  }
}
