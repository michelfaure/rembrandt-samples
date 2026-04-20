// Pattern de consolidation multi-dimensions.
// Somme N dimensions indépendantes, garde trace de celles utilisées,
// accepte les null pour qu'une dimension non encore instrumentée
// ne casse pas le calcul mais s'absente honnêtement.

export type Dimension = {
  id: 'saas' | 'usage' | 'donnees' | 'strategique'
  low: number | null
  high: number | null
  source: string        // table ou méthode d'origine
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
