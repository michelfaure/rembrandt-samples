# one-day-thrown-away-rule/

My agent spent a full day coding a new file format for an existing domain, persuaded something was missing. At six in the morning I looked at the rendering — unreadable. The component that did the job already existed in a neighboring file. Better done. Two minutes of `find` before starting would have surfaced it. This folder is the Phase 0 protocol that prevents the next reverted day.

**Source article**: *The 1-day-thrown-away rule: read the code before letting your AI write new code* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

Before letting an AI coding agent write any new format, template, or component in a domain already covered by code, run a Phase 0 grep: enumerate the existing files in the domain folder, identify any pattern that already implements the target capability, read the candidates, then decide whether to extend, refactor, or write new. Skipping this step costs roughly one dev-day per occurrence, measured empirically.

## Files

| File | Role |
|---|---|
| [`phase-0-grep.sh`](./phase-0-grep.sh) | The Phase 0 enumeration script. Takes a domain keyword, walks `app/` and `lib/` for files in that domain, looks for canonical patterns (`Render`, `Export`, `Generate`, ...), and prints the inventory on one screen. Two minutes to run, one screen of output. |
| [`checklist.md`](./checklist.md) | The five-question checklist to verbalize *before* asking the agent to write. Used as a pre-prompt for any new-domain ask, or as a review gate on agent-produced drafts that suspiciously look like clean reinventions. |

## How to read this folder

Start with `checklist.md` — it's the cheapest defense and the one most often skipped. Then `phase-0-grep.sh` for when you do want to spend two minutes producing material evidence of the neighborhood.

## How to adapt it

- The grep patterns in `phase-0-grep.sh` (`Render`, `Export`, `Pdf`, `Generate`) match the most common "produce output" verbs in a TypeScript codebase. If your codebase uses other conventions (`Build`, `Compose`, `Format`), extend the list.
- The `$DOMAIN` parameter is a single keyword. For multi-word domains, pass the most distinctive token (`emargement` over `feuille`, `invoicing` over `billing`).
- The checklist is calibrated for solo-with-agent workflows. In a team, the same five questions become a PR description prerequisite — the reviewer can refuse to read code without them.

## Why this matters

The failure mode this folder addresses isn't an agent error. It's a pilot error — describing a target without describing the neighborhood. Agents that don't know what already exists code plausible solutions to half-specified problems. The output looks clean, compiles, passes the tests you ran, and quietly duplicates a file that lives one directory away.

The cost is empirically one dev-day. Not because the agent is slow, but because the work has to be entirely reverted once the duplication surfaces. The reverted day isn't a learning experience that improves the next iteration — it's a tax on the absence of a two-minute check.

There's a secondary signal worth flagging: when an agent re-reads its own work in light of existing code and *proposes to revert*, that's a good sign of metacognitive function. An agent that locks itself into an invented design is the worse failure mode. But the good signal still comes a day too late. The rule is to not get there.
