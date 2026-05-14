#!/usr/bin/env -S npx tsx
/**
 * M1 — Anti-pattern recurrence per session
 *
 * Definition: number of times a previously-flagged anti-pattern (a `feedback_*.md` file
 * dated J-N to J-1) recurs in sessions or PILOTAGE-IA entries dated J to J+W (default W=7).
 *
 * Doctrinal target (v0.3.2): below one recurrence per session across a 7-day window.
 *
 * Method:
 * - For each feedback_*.md older than 7 days, extract its slug (filename minus `feedback_` prefix).
 * - Convert slug to a search regex: words separated by `_` become `(word1|word2|...)` alternation.
 * - Grep recent PILOTAGE-IA entries and docs/sessions/ for occurrences.
 * - Count distinct (feedback, session) pairs where the feedback's symptom resurfaced.
 *
 * Sources:
 * - ~/.claude/projects/-Users-pierre-benoitroux/memory/feedback_*.md
 * - ~/tef-erp/docs/vibe-coding/PILOTAGE-IA.md (last 7 days of entries)
 * - ~/tef-erp/docs/sessions/*.md (mtime in last 7 days)
 *
 * Run: npx tsx m1-feedback-recidive.ts [--days=7] [--output=m1-result.json]
 */

import { readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs'
import { join, basename } from 'node:path'

const MEMORY_DIR = `${process.env.HOME}/.claude/projects/-Users-pierre-benoitroux/memory`
const PILOTAGE = `${process.env.HOME}/tef-erp/docs/vibe-coding/PILOTAGE-IA.md`
const SESSIONS_DIR = `${process.env.HOME}/tef-erp/docs/sessions`

function parseArgs() {
  const days = Number(process.argv.find(a => a.startsWith('--days='))?.split('=')[1] ?? 7)
  const output = process.argv.find(a => a.startsWith('--output='))?.split('=')[1] ?? 'm1-result.json'
  return { days, output }
}

function slugWords(filename: string): string[] {
  // feedback_anti_rustine_robustesse_par_defaut.md → ['anti', 'rustine', 'robustesse', 'par', 'defaut']
  const slug = basename(filename, '.md').replace(/^feedback_/, '')
  return slug.split('_').filter(w => w.length >= 4)  // discard short words ('par', 'des', etc.)
}

function feedbackEligible(filename: string, days: number): boolean {
  const mtime = statSync(join(MEMORY_DIR, filename)).mtimeMs
  const ageDays = (Date.now() - mtime) / (1000 * 60 * 60 * 24)
  return ageDays >= days  // older than the window, so a recurrence is meaningful
}

function recentTextWindow(days: number): { source: string; text: string }[] {
  const cutoff = Date.now() - days * 24 * 60 * 60 * 1000
  const sources: { source: string; text: string }[] = []

  // PILOTAGE-IA full file (we'll filter by entry dates inside)
  if (statSync(PILOTAGE).mtimeMs >= cutoff) {
    sources.push({ source: 'PILOTAGE-IA', text: readFileSync(PILOTAGE, 'utf-8') })
  }

  // Recent session logs
  try {
    for (const f of readdirSync(SESSIONS_DIR)) {
      if (!f.endsWith('.md')) continue
      const full = join(SESSIONS_DIR, f)
      if (statSync(full).mtimeMs >= cutoff) {
        sources.push({ source: `sessions/${f}`, text: readFileSync(full, 'utf-8') })
      }
    }
  } catch {}

  return sources
}

function detectRecurrence(slugWords: string[], text: string): number {
  if (slugWords.length === 0) return 0
  // Require at least 2 distinct slug-words to co-occur within a 200-char window
  // to avoid false positives on a single common word.
  const lower = text.toLowerCase()
  let hits = 0
  const stride = 200
  for (let i = 0; i < lower.length; i += stride / 2) {
    const window = lower.slice(i, i + stride)
    const matches = slugWords.filter(w => window.includes(w.toLowerCase()))
    if (matches.length >= 2) hits++
  }
  return hits
}

function main() {
  const { days, output } = parseArgs()
  const feedbacks = readdirSync(MEMORY_DIR)
    .filter(f => f.startsWith('feedback_') && f.endsWith('.md'))
    .filter(f => feedbackEligible(f, days))

  const recentSources = recentTextWindow(days)

  if (recentSources.length === 0) {
    console.log(`M1: no PILOTAGE or session activity in last ${days} days. Result = 0 recurrences.`)
    return
  }

  const recurrences: { feedback: string; source: string; hits: number }[] = []

  for (const fb of feedbacks) {
    const words = slugWords(fb)
    if (words.length < 2) continue
    for (const src of recentSources) {
      const hits = detectRecurrence(words, src.text)
      if (hits > 0) {
        recurrences.push({ feedback: fb, source: src.source, hits })
      }
    }
  }

  // Aggregate: count distinct (feedback, source) pairs
  const pairs = recurrences.length
  const sessionsCount = recentSources.filter(s => s.source.startsWith('sessions/')).length || 1
  const ratio = pairs / sessionsCount

  const result = {
    metric: 'M1',
    window_days: days,
    feedbacks_examined: feedbacks.length,
    sources_examined: recentSources.length,
    sessions_in_window: sessionsCount,
    recurrences_detected: pairs,
    ratio_per_session: Number(ratio.toFixed(2)),
    target_doctrinal: '≤ 1 recurrence per session',
    target_met: ratio <= 1,
    top_recurrences: recurrences.sort((a, b) => b.hits - a.hits).slice(0, 10),
  }

  console.log(JSON.stringify(result, null, 2))
  writeFileSync(output, JSON.stringify(result, null, 2))
}

main()
