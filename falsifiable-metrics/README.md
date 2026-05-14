# falsifiable-metrics/

Five instrumented metrics for the Counterpart Doctrine v0.3, with **measured values from sixty days of Rembrandt** (a production TypeScript/Next.js/Supabase ERP, ~35 000 lines, 65+ ADRs, 113 feedback memories).

This folder closes the empirical gap pointed out by the second external critique of v0.3 (May 2026): *"the doctrine self-applies in declaration, not in verifiable practice."* The thresholds declared in `doctrine.md` were intuitions until this run. The measurements below either confirm them, reveal them as optimistic, or expose the instrumentation as insufficient.

## How to run

Each metric is a standalone TypeScript file executable via `npx tsx`. Default repo path is `~/tef-erp`; override with `--repo=<path>`.

```bash
npx tsx m1-feedback-recidive.ts --days=7
npx tsx m2-adr-coverage.ts --days=28
npx tsx m3-drift-window.ts --days=90
npx tsx m4-session-audit-delay.ts --days=60
npx tsx m5-brief-mode-ratio.ts --days=7
```

Each script writes a `m<N>-result.json` next to itself.

## Measured values (Rembrandt, 14 May 2026)

| Metric | Measured | Doctrinal target | Verdict |
|---|---|---|---|
| **M1** — recurrence per session (7-day window) | 12.33 / session | ≤ 1 | ❌ overshoot — instrumentation flagged as over-sensitive (see below) |
| **M2** — multi-file commits without ADR (28-day window) | **2.3 %** | ≤ 5 % | ✅ target met — 3 exceptions over 128 multi-file commits |
| **M3** — median drift apparition → detection (90-day window) | 35.3 days | ≤ 7 days | ❌ overshoot — threshold was intuition, real lag is structural |
| **M4** — position of first DB probe in session log | **34 %** (~41 min on 120-min proxy) | ≤ 90 min | ✅ target met — practitioner probes in first third |
| **M5** — pure-command ratio (7-day window) | 0 % pure, 90 % unclassified | alarm > 80 % | ⚠️ instrumentation insufficient — classification heuristic too coarse |

Two cibles met (M2, M4). Two cibles missed empirically — the targets were intuitions that did not survive measurement (M1, M3). One metric reveals that its instrumentation is the bottleneck (M5).

## Per-metric interpretation

### M1 — instrumentation over-sensitive

The script detects 12 *"recurrences"* per session, far above the doctrinal target of ≤ 1. The heuristic — two distinct slug-words of a feedback file co-occurring within a 200-character window of recent text — produces many false positives because the dense PILOTAGE-IA file contains its own meta-references to the feedback memories.

What this teaches: the metric is *measurable in principle* but needs a stricter heuristic. Candidates for v0.3.3:

- exclude any paragraph that explicitly **cites** the feedback filename (a self-reference, not a recurrence)
- require the slug-words to appear in a **prescriptive context** (commit message, action verb, decision noun), not in a descriptive context
- use a small LLM classifier to decide "is this paragraph describing the **return of the failure mode** named in the feedback?"

Until then, M1 should be read as *"the failure modes are still being talked about"*, not as a hard recurrence rate.

### M2 — target met, 2.3 %

Of 128 multi-file commits on Rembrandt in the last 28 days, 125 are accompanied by an ADR (direct in the commit message, or in a neighbouring ±24 h commit). Only 3 are not:

- `bab42bf` 2026-04-27 `fix(sheet-sync): prioriser code_cours_25_26 sur statut historique` — 5 code files, no ADR
- `e315e0e9` 2026-04-16 `feat(communication): email/SMS par cours avec modale partagée` — 10 code files, no ADR
- `b5e9a2e2` 2026-04-16 `chore: purge complète du code Mailchimp` — 31 code files, no ADR

The third (Mailchimp purge) is the clearest case of a multi-file commit that should have produced a deletion ADR. The first two are arguable. Axis 4 (ADR before code on any project > 2 files) is materially observed; the gap is at 2.3 %, not zero.

### M3 — target missed, structural lag

The script finds 41 drift-related ADRs in the last 90 days (markers: *drift*, *silent failure*, *incident*, *rust*, *workaround*, *never reactivate*, *cascade*, *orphan*, *stale*). 29 of them can be paired with a probable apparition commit via `git log -S <keyword>`. Median time from apparition to ADR-recording: **35.3 days**.

The doctrinal target of 7 days was set by intuition and is not met empirically. Three readings:

1. **The target was wrong.** 7 days is too aggressive for a solo who codes mostly evenings and weekends. A monthly audit cadence (≈ 30 days) is the realistic floor, and indeed axis 7 prescribes a monthly light audit. Recalibration: M3 target raised to ≤ 30 days for v0.3.3.

2. **The measurement is approximate.** `git log -S <keyword>` finds the first commit mentioning the keyword, not necessarily the commit that introduced the drift. A manual annotation of (introduction_sha, ADR_sha) for 10 drifts would tighten the result.

3. **Both.** The most likely answer.

### M4 — target met, ~41 min

Of 27 session logs in the last 60 days, 13 contain at least one SQL probe / EXPLAIN / `pg_*` mention. Of those, the median position is 34 % into the log narrative. On a proxy of a 120-minute session, that is ~41 minutes — well under the 90-minute doctrinal target.

What this hides: 14 of 27 sessions have **no** DB probe at all. Either the session didn't need one (legitimate), or it should have had one and didn't (axis-1 violation). A v0.3.3 refinement: split M4 into M4a (positional percentile when probed) and M4b (probed-ratio per session-type). The current measurement conflates the two.

### M5 — instrumentation insufficient

The heuristic classifier extracts 61 candidate *"briefs"* from the last 7 days of PILOTAGE-IA bullet points. 90 % are tagged *unclassified*. The classifier looks for imperative verbs (refactor, rename, apply), oracle markers (find why, p95, EXPLAIN), and question markers (what, where, why, est-ce). PILOTAGE bullets are typically *retrospective observations* — they start with `**bold markdown phrase**` and describe an event, not a brief.

The metric is **valid as a target**, the source is **wrong**. To measure M5 properly we need either:

- a structured brief log (the practitioner tags each brief at issue: command / oracle / question)
- a Claude Code log analyser that reads the user-turn of each conversation and classifies it
- a small LLM classifier applied to a brief-extracted corpus

This is the v0.3.3 work for M5: build the source, then re-run. Until then, M5 = "instrument under construction" — not a measure.

## What this run changed in v0.3.3

The doctrine targets are not all intuitions any more. M2 and M4 were confirmed; M1, M3, M5 will be recalibrated in v0.3.3 with these measurements as the baseline. The closing pillar (#71, 15 July 2026) will publish the time-series of all five metrics over the 60-day arc 2 window, showing whether the doctrinal practice held, drifted, or improved.

## Reproducibility

The five scripts assume:

- `git` available in `PATH`
- The repo to measure exists at `~/tef-erp` (or passed via `--repo=`)
- For M1, the feedback memories live at `~/.claude/projects/-Users-pierre-benoitroux/memory/feedback_*.md`
- For M4, session logs at `~/tef-erp/docs/sessions/*.md` (one file per significant session, axis 7 discipline)
- For M5, a `PILOTAGE-IA.md` at `~/tef-erp/docs/vibe-coding/PILOTAGE-IA.md` (the dialogic journal axis 7 prescribes)

Adapting the scripts to a different project means changing those paths and re-running. The thresholds are doctrine-defined; the *values* are repo-defined. A different project producing very different values is itself a useful finding: it questions either the project's discipline or the doctrine's targets.

## License

MIT, as the rest of `rembrandt-samples`.
