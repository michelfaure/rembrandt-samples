#!/usr/bin/env -S npx tsx
/**
 * M3 — Median window between drift apparition and probe detection
 *
 * Definition: for each ADR that documents a drift / silent failure / late detection,
 * compute the hours between the commit that introduced the drift (best-effort)
 * and the ADR commit that documents/resolves it. Report the median over 90 days.
 *
 * Doctrinal target (v0.3.2): median below 7 days (168 h).
 *
 * Method:
 * - Find ADRs whose body mentions "drift", "silent failure", "incident", "rust",
 *   "workaround" in the last 90 days.
 * - For each such ADR, find the commit that created the ADR file in `docs/adr/`.
 * - Find the commit that introduced the drifted artefact (heuristic: first commit
 *   that touches a symbol/file mentioned in the ADR title, before the ADR commit).
 * - Compute window in hours, median across all detected drifts.
 *
 * Note: this is approximate. Manual annotation of (introduction_sha, detection_sha)
 * pairs in a CSV would give a stronger signal. The script outputs what it can find
 * and flags entries where automated detection failed.
 *
 * Run: npx tsx m3-drift-window.ts [--repo=~/tef-erp] [--days=90] [--output=m3-result.json]
 */

import { execFileSync } from 'node:child_process'
import { readFileSync, writeFileSync, readdirSync } from 'node:fs'
import { join } from 'node:path'

function parseArgs() {
  const repo = process.argv.find(a => a.startsWith('--repo='))?.split('=')[1]
    ?? `${process.env.HOME}/tef-erp`
  const days = Number(process.argv.find(a => a.startsWith('--days='))?.split('=')[1] ?? 90)
  const output = process.argv.find(a => a.startsWith('--output='))?.split('=')[1] ?? 'm3-result.json'
  return { repo, days, output }
}

function git(repo: string, ...args: string[]): string {
  return execFileSync('git', ['-C', repo, ...args], { maxBuffer: 50 * 1024 * 1024 }).toString()
}

const DRIFT_MARKERS = /drift|silent[\s_-]failure|silent[\s_-]bug|incident|missed|rust(ine)?|workaround|never reactivat|cascade|orphan|stale|sclerosis/i

type DriftAdr = {
  file: string
  number: number
  title: string
  detectionDate: number  // unix seconds — commit that introduced the ADR
  detectionSha: string
  apparitionDate?: number  // unix seconds — heuristic
  apparitionSha?: string
  windowHours?: number
}

function findDriftAdrs(repo: string, days: number): DriftAdr[] {
  const adrDir = join(repo, 'docs/adr')
  const files = readdirSync(adrDir).filter(f => /^\d{4}-.*\.md$/.test(f))
  const drifts: DriftAdr[] = []

  for (const file of files) {
    const text = readFileSync(join(adrDir, file), 'utf-8')
    if (!DRIFT_MARKERS.test(text)) continue

    // Find the commit that created the ADR
    const log = git(
      repo,
      'log',
      '--diff-filter=A',
      `--since=${days}.days.ago`,
      '--pretty=format:%H%x09%ct',
      '--', `docs/adr/${file}`,
    ).trim()
    if (!log) continue

    const [sha, ctStr] = log.split('\n')[0].split('\x09')
    const detectionDate = Number(ctStr)
    const number = Number(file.match(/^(\d{4})/)?.[1] ?? '0')
    const title = file.replace(/^\d{4}-/, '').replace(/\.md$/, '').replace(/-/g, ' ')

    drifts.push({ file: `docs/adr/${file}`, number, title, detectionDate, detectionSha: sha })
  }

  return drifts
}

function findApparition(repo: string, drift: DriftAdr): void {
  // Heuristic: extract the most specific keyword from the ADR title (longest word
  // that's not a stopword), find the earliest commit that mentions it in code files.
  const STOPWORDS = new Set(['the', 'and', 'of', 'in', 'on', 'for', 'with', 'a', 'to', 'is', 'be', 'pas', 'sans', 'sur', 'des', 'les', 'une', 'un', 'le', 'la'])
  const words = drift.title.split(/\s+/)
    .filter(w => w.length >= 5 && !STOPWORDS.has(w.toLowerCase()))
    .sort((a, b) => b.length - a.length)
  if (words.length === 0) return

  const keyword = words[0]
  try {
    const log = git(
      repo,
      'log',
      '--all',
      `--until=${new Date(drift.detectionDate * 1000).toISOString()}`,
      '--pretty=format:%H%x09%ct',
      '-S', keyword,
      '--', 'app/', 'lib/', 'supabase/',
    ).trim()
    if (!log) return
    const lines = log.split('\n')
    const earliest = lines[lines.length - 1]
    if (!earliest) return
    const [sha, ctStr] = earliest.split('\x09')
    drift.apparitionDate = Number(ctStr)
    drift.apparitionSha = sha
    drift.windowHours = Number(((drift.detectionDate - drift.apparitionDate) / 3600).toFixed(1))
  } catch {
    // git -S can fail on some symbols; skip
  }
}

function median(values: number[]): number {
  if (values.length === 0) return 0
  const sorted = [...values].sort((a, b) => a - b)
  const mid = Math.floor(sorted.length / 2)
  return sorted.length % 2 === 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
}

function main() {
  const { repo, days, output } = parseArgs()
  const drifts = findDriftAdrs(repo, days)
  for (const d of drifts) findApparition(repo, d)
  const withWindow = drifts.filter(d => d.windowHours !== undefined && d.windowHours > 0)
  const med = median(withWindow.map(d => d.windowHours!))
  const targetHours = 7 * 24

  const result = {
    metric: 'M3',
    repo,
    window_days: days,
    drift_adrs_found: drifts.length,
    drift_adrs_with_window: withWindow.length,
    median_window_hours: Number(med.toFixed(1)),
    median_window_days: Number((med / 24).toFixed(1)),
    target_doctrinal: '≤ 7 days (168 h)',
    target_met: med <= targetHours,
    note: 'Apparition detected by `git log -S <keyword>` heuristic — approximate. Manual annotation would tighten the result.',
    examples: withWindow.slice(0, 10).map(d => ({
      adr: d.number,
      title: d.title.slice(0, 60),
      window_days: Number((d.windowHours! / 24).toFixed(1)),
    })),
  }

  console.log(JSON.stringify(result, null, 2))
  writeFileSync(output, JSON.stringify(result, null, 2))
}

main()
