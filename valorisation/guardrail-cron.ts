// 20-line guardrail on an automatic counter.
// Detects abnormal bumps before they're booked as progress.
// Wire into a cron that already computes the daily snapshot.

// Replace `admin` with your Supabase/Prisma/pg client.
// Replace `postSlack` with your webhook (Slack, Discord, email, SMS).

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
      `:warning: abnormal lines_total bump: +${delta} ` +
      `(7-day average ~${Math.round(avg * 0.02)}). ` +
      `Verify before booking value.`
    )
  }
}
