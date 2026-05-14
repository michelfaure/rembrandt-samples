#!/usr/bin/env -S npx tsx
/**
 * M5 — Ratio of pure commands over total briefs across a 7-day window
 *
 * Definition: pure-command ratio of brief modes in axis 8 sense:
 *   pure command         — outcome known ≥ 90 % before brief
 *   command with oracle  — outcome unknown but metric/test arbitrates
 *   question             — outcome unknown, no scalar oracle
 *
 * Doctrinal target (v0.3.2): alarm above 80 % pure command, requalification below
 * 60 % sustained.
 *
 * Method (heuristic, semi-automatic — full classification requires human or LLM):
 * - For each entry in PILOTAGE-IA dated in the last 7 days, count its briefs.
 * - Classify by trigger:
 *     * pure command: imperative verb at start + named target (refactor X / rename Y
 *       / apply pattern Z / fix bug B). Indicators: words "refactor", "rename",
 *       "apply", "implement", "add", "remove", "delete".
 *     * command with oracle: imperative + metric/test/probe mentioned. Indicators:
 *       "find why", "reach p95", "make tests pass", "EXPLAIN", "probe".
 *     * question: open form. Indicators: starts with "what", "where", "why", "is",
 *       "should", "qu'est-ce", "où", "pourquoi", "est-ce".
 * - Output the ratio plus a sample of classified briefs for human verification.
 *
 * Note: this is semi-automatic. The output should be reviewed by hand for
 * misclassification before publication.
 *
 * Run: npx tsx m5-brief-mode-ratio.ts [--days=7] [--output=m5-result.json]
 */

import { readFileSync, writeFileSync } from 'node:fs'

const PILOTAGE = `${process.env.HOME}/tef-erp/docs/vibe-coding/PILOTAGE-IA.md`

function parseArgs() {
  const days = Number(process.argv.find(a => a.startsWith('--days='))?.split('=')[1] ?? 7)
  const output = process.argv.find(a => a.startsWith('--output='))?.split('=')[1] ?? 'm5-result.json'
  return { days, output }
}

type Mode = 'pure_command' | 'command_with_oracle' | 'question' | 'unclassified'

const PURE_COMMAND_PATTERNS = [
  /^\s*(refactor|rename|apply|implement|add|remove|delete|fix|move|update|cr[eé]e|renomm|appliqu|ajoute|enl[èe]ve|supprime|d[eé]place|mets? à jour)/i,
]

const ORACLE_PATTERNS = [
  /\b(find why|find the cause|reach |p95|EXPLAIN|measure|probe|metric|test (?:pass|red|green)|until.*green|build green|trouve\s+pourquoi|trouve\s+la cause|atteint|mesure|sonde|m[eé]trique)\b/i,
]

const QUESTION_PATTERNS = [
  /^\s*(what|where|why|is\s|should|how|can|could|would|qu['’]est[‐-]ce|o[uù]\s|pourquoi|est[‐-]ce|comment|peut[‐-]on|devrais)/i,
  /\?$/,
]

function classify(brief: string): Mode {
  const trimmed = brief.trim()
  if (trimmed.length < 10) return 'unclassified'
  for (const p of QUESTION_PATTERNS) if (p.test(trimmed)) return 'question'
  for (const p of ORACLE_PATTERNS) if (p.test(trimmed)) return 'command_with_oracle'
  for (const p of PURE_COMMAND_PATTERNS) if (p.test(trimmed)) return 'pure_command'
  return 'unclassified'
}

function extractRecentBriefs(text: string, days: number): string[] {
  // PILOTAGE-IA entries start with `## YYYY-MM-DD ...`
  const cutoff = new Date(Date.now() - days * 24 * 60 * 60 * 1000)
  const cutoffStr = cutoff.toISOString().slice(0, 10)

  const sections = text.split(/^## (\d{4}-\d{2}-\d{2})/gm)
  // sections = [preamble, date1, body1, date2, body2, ...]
  const briefs: string[] = []
  for (let i = 1; i < sections.length; i += 2) {
    const date = sections[i]
    if (date < cutoffStr) continue
    const body = sections[i + 1] ?? ''
    // Crude brief extraction: bullet points starting with "- ", or lines in quotes,
    // or imperatives at the start of a paragraph. We take bullets in `Ce que je veux
    // essayer / Ce qui a marché / Ce qui a foiré` sections as candidate briefs.
    const lines = body.split('\n')
    for (const line of lines) {
      const m = line.match(/^\s*-\s+(.{15,200})/)
      if (m) briefs.push(m[1])
    }
  }
  return briefs
}

function main() {
  const { days, output } = parseArgs()
  const text = readFileSync(PILOTAGE, 'utf-8')
  const briefs = extractRecentBriefs(text, days)

  const classified = briefs.map(b => ({ brief: b.slice(0, 120), mode: classify(b) }))

  const counts: Record<Mode, number> = {
    pure_command: 0,
    command_with_oracle: 0,
    question: 0,
    unclassified: 0,
  }
  for (const c of classified) counts[c.mode]++

  const totalClassified = counts.pure_command + counts.command_with_oracle + counts.question
  const pureRatio = totalClassified === 0 ? 0 : (counts.pure_command / totalClassified) * 100

  const result = {
    metric: 'M5',
    window_days: days,
    briefs_extracted: classified.length,
    counts,
    total_classified: totalClassified,
    unclassified_ratio_percent: classified.length === 0 ? 0 : Number(((counts.unclassified / classified.length) * 100).toFixed(1)),
    pure_command_ratio_percent: Number(pureRatio.toFixed(1)),
    target_doctrinal: 'alarm > 80 %, requalification expected < 60 % sustained',
    target_met_alarm: pureRatio <= 80,
    target_met_requalification: pureRatio >= 60,
    note: 'Heuristic classification. Unclassified ratio > 30 % suggests rules need refinement. Hand-verify a sample before publishing.',
    samples_per_mode: {
      pure_command: classified.filter(c => c.mode === 'pure_command').slice(0, 5),
      command_with_oracle: classified.filter(c => c.mode === 'command_with_oracle').slice(0, 5),
      question: classified.filter(c => c.mode === 'question').slice(0, 5),
      unclassified: classified.filter(c => c.mode === 'unclassified').slice(0, 5),
    },
  }

  console.log(JSON.stringify(result, null, 2))
  writeFileSync(output, JSON.stringify(result, null, 2))
}

main()
