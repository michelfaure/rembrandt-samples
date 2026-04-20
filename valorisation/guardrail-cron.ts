// Garde-fou de 20 lignes sur un compteur automatique.
// Détecte les bumps anormaux avant qu'ils soient encaissés comme progression.
// À brancher dans un cron qui calcule déjà le snapshot du jour.

// Remplace `admin` par ton client Supabase/Prisma/pg.
// Remplace `postSlack` par ton webhook (Slack, Discord, email, SMS).

type Snapshot = { lines_total: number }
type Loc = { lines_total: number }

declare const admin: {
  from: (t: string) => {
    select: (cols: string) => {
      order: (col: string, opts: { ascending: boolean }) => {
        limit: (n: number) => Promise<{ data: Snapshot[] }>
      }
    }
  }
}
declare function postSlack(msg: string): Promise<void>
declare const loc: Loc

export async function guardrail() {
  const { data: last7 } = await admin
    .from('valorisation_snapshots')
    .select('lines_total')
    .order('snapshot_date', { ascending: false })
    .limit(7)

  const avg = last7.reduce((a, r) => a + r.lines_total, 0) / last7.length
  const delta = loc.lines_total - (last7[0]?.lines_total ?? loc.lines_total)

  if (delta > 3 * Math.max(avg * 0.02, 500)) {
    await postSlack(
      `:warning: bump anormal lines_total : +${delta} ` +
      `(moyenne 7j ~${Math.round(avg * 0.02)}). ` +
      `Vérifier avant comptabilisation valeur.`
    )
  }
}
