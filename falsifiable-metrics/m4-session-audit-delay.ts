#!/usr/bin/env -S npx tsx
/**
 * M4 — Time within a session before the first database audit
 *
 * Definition: for each `docs/sessions/YYYY-MM-DD_*.md` entry, find the first SQL
 * probe / EXPLAIN / SELECT mentioned in the body and measure the position from
 * the session start. Output: median position across recent sessions.
 *
 * Doctrinal target (v0.3.2): below 90 minutes (≈ first third of a typical session).
 *
 * Method:
 * - For each session log, count characters or paragraphs up to the first `SELECT`,
 *   `EXPLAIN`, or `pg_` mention.
 * - Normalize by session length: position = chars_to_first_probe / total_chars.
 * - Median across all session logs in the last N days.
 *
 * Note: session logs are not timestamped at the sub-event level — the result is a
 * narrative-position proxy, not a wall-clock measurement. A session log that
 * mentions SQL in its first paragraph means the practitioner probed early. A log
 * that mentions SQL only in the last third means probe came late.
 *
 * Run: npx tsx m4-session-audit-delay.ts [--days=60] [--output=m4-result.json]
 */

import { readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'

function parseArgs() {
  const days = Number(process.argv.find(a => a.startsWith('--days='))?.split('=')[1] ?? 60)
  const output = process.argv.find(a => a.startsWith('--output='))?.split('=')[1] ?? 'm4-result.json'
  return { days, output }
}

const SESSIONS_DIR = `${process.env.HOME}/tef-erp/docs/sessions`
const PROBE_MARKERS = /\b(SELECT\s+|EXPLAIN\s+|\bpg_|information_schema|::regclass|BEGIN;|ROLLBACK;)\b/i

function median(values: number[]): number {
  if (values.length === 0) return 0
  const sorted = [...values].sort((a, b) => a - b)
  const mid = Math.floor(sorted.length / 2)
  return sorted.length % 2 === 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
}

function main() {
  const { days, output } = parseArgs()
  const cutoff = Date.now() - days * 24 * 60 * 60 * 1000
  const files = readdirSync(SESSIONS_DIR).filter(f => f.endsWith('.md'))

  const results: Array<{
    file: string
    total_chars: number
    chars_to_first_probe: number
    position_percentile: number
    probed: boolean
  }> = []

  for (const f of files) {
    const full = join(SESSIONS_DIR, f)
    if (statSync(full).mtimeMs < cutoff) continue
    const text = readFileSync(full, 'utf-8')
    const total = text.length
    const match = text.match(PROBE_MARKERS)
    if (match && match.index !== undefined) {
      results.push({
        file: f,
        total_chars: total,
        chars_to_first_probe: match.index,
        position_percentile: Number(((match.index / total) * 100).toFixed(1)),
        probed: true,
      })
    } else {
      results.push({
        file: f,
        total_chars: total,
        chars_to_first_probe: -1,
        position_percentile: 100,
        probed: false,
      })
    }
  }

  const probed = results.filter(r => r.probed)
  const medianPosition = median(probed.map(r => r.position_percentile))
  const probedRatio = results.length === 0 ? 0 : (probed.length / results.length) * 100

  // Proxy: a session of ~ 2 h. Position 50 % = ~ 60 min into the session.
  const estimatedMedianMinutes = (medianPosition / 100) * 120

  const result = {
    metric: 'M4',
    window_days: days,
    sessions_examined: results.length,
    sessions_with_probe: probed.length,
    probed_ratio_percent: Number(probedRatio.toFixed(1)),
    median_position_percentile: Number(medianPosition.toFixed(1)),
    note: 'Position % within session log narrative, not wall-clock. Proxy for "how early did the practitioner probe the DB."',
    estimated_median_minutes_if_120min_session: Number(estimatedMedianMinutes.toFixed(0)),
    target_doctrinal: '≤ 90 minutes (≈ first third of session)',
    target_met: estimatedMedianMinutes <= 90,
    sessions_without_probe: results.filter(r => !r.probed).map(r => r.file),
    earliest_probers: probed.sort((a, b) => a.position_percentile - b.position_percentile).slice(0, 5).map(r => ({
      file: r.file,
      position_percentile: r.position_percentile,
    })),
    latest_probers: probed.sort((a, b) => b.position_percentile - a.position_percentile).slice(0, 5).map(r => ({
      file: r.file,
      position_percentile: r.position_percentile,
    })),
  }

  console.log(JSON.stringify(result, null, 2))
  writeFileSync(output, JSON.stringify(result, null, 2))
}

main()
