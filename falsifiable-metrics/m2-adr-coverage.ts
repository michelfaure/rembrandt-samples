#!/usr/bin/env -S npx tsx
/**
 * M2 — Ratio of multi-file commits without an accompanying ADR
 *
 * Definition: (commits touching >= 3 code files / total multi-file commits) where the
 * commit message OR a neighbouring commit (±24h) does NOT reference an ADR-NNNN.
 *
 * Doctrinal target (v0.3.2): below 5 %.
 *
 * Method:
 * - List commits in the last N days (default 28).
 * - For each commit, count "code files" touched: extensions .ts/.tsx/.sql/.py outside
 *   articles/, docs/, .claude/.
 * - "Multi-file" = >= 3 code files in a single commit.
 * - "With ADR" = commit message contains ADR-\d+ OR commits within ±24h create/modify
 *   docs/adr/.
 * - Compute the ratio of multi-file commits without ADR coverage.
 *
 * Run: npx tsx m2-adr-coverage.ts [--repo=~/tef-erp] [--days=28] [--output=m2-result.json]
 */

import { execFileSync } from 'node:child_process'
import { writeFileSync } from 'node:fs'

function parseArgs() {
  const repo = process.argv.find(a => a.startsWith('--repo='))?.split('=')[1]
    ?? `${process.env.HOME}/tef-erp`
  const days = Number(process.argv.find(a => a.startsWith('--days='))?.split('=')[1] ?? 28)
  const output = process.argv.find(a => a.startsWith('--output='))?.split('=')[1] ?? 'm2-result.json'
  return { repo, days, output }
}

function git(repo: string, ...args: string[]): string {
  return execFileSync('git', ['-C', repo, ...args], { maxBuffer: 50 * 1024 * 1024 }).toString()
}

const CODE_EXT = /\.(ts|tsx|sql|py|js|jsx|go|rs)$/
const NON_CODE_PATH = /^(articles|docs|\.claude|node_modules|public|covers|exports)\//

function isCodeFile(path: string): boolean {
  if (NON_CODE_PATH.test(path)) return false
  return CODE_EXT.test(path)
}

type Commit = {
  sha: string
  date: number  // unix seconds
  message: string
  codeFiles: number
  adrFiles: string[]  // adr files touched in this commit
}

function parseCommits(repo: string, days: number): Commit[] {
  const since = `${days}.days.ago`
  const raw = git(
    repo,
    'log',
    `--since=${since}`,
    '--pretty=format:%x1e%H%x09%ct%x09%s',
    '--name-only',
    '--no-merges',
  )
  const commits: Commit[] = []
  for (const block of raw.split('\x1e').filter(b => b.trim())) {
    const [header, ...files] = block.split('\n').filter(l => l.trim())
    const [sha, ctStr, ...msgParts] = header.split('\x09')
    const message = msgParts.join('\t')
    const date = Number(ctStr)
    const codeFiles = files.filter(isCodeFile).length
    const adrFiles = files.filter(f => f.startsWith('docs/adr/') && f.endsWith('.md'))
    commits.push({ sha, date, message, codeFiles, adrFiles })
  }
  return commits
}

function hasAdrCoverage(commit: Commit, allCommits: Commit[]): boolean {
  // Direct: commit message references ADR-NNNN
  if (/ADR-\d+/.test(commit.message)) return true
  // Indirect: a neighbouring commit (±24h) touches docs/adr/
  const window = 24 * 60 * 60  // 24h in seconds
  for (const other of allCommits) {
    if (Math.abs(other.date - commit.date) <= window && other.adrFiles.length > 0) {
      return true
    }
  }
  return false
}

function main() {
  const { repo, days, output } = parseArgs()
  const commits = parseCommits(repo, days)
  const multiFile = commits.filter(c => c.codeFiles >= 3)
  const withoutAdr = multiFile.filter(c => !hasAdrCoverage(c, commits))

  const ratio = multiFile.length === 0 ? 0 : withoutAdr.length / multiFile.length

  const result = {
    metric: 'M2',
    repo,
    window_days: days,
    total_commits: commits.length,
    multi_file_commits: multiFile.length,
    multi_file_without_adr: withoutAdr.length,
    ratio: Number((ratio * 100).toFixed(1)),
    ratio_unit: '%',
    target_doctrinal: '≤ 5 %',
    target_met: ratio * 100 <= 5,
    examples_without_adr: withoutAdr.slice(0, 10).map(c => ({
      sha: c.sha.slice(0, 8),
      date: new Date(c.date * 1000).toISOString().slice(0, 10),
      message: c.message.slice(0, 70),
      code_files: c.codeFiles,
    })),
  }

  console.log(JSON.stringify(result, null, 2))
  writeFileSync(output, JSON.stringify(result, null, 2))
}

main()
