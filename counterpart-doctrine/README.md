# counterpart-doctrine/

The seven-axis discipline that emerged after 35 effective days of solo coding with Claude Code. Each axis was born from a recurring failure mode, not from upfront design. Versioned, dated, falsifiable — including the doctrine itself.

**Source article**: *The Counterpart Doctrine: a seven-axis spec for working with an AI coding agent* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

Working with an AI coding agent on the long run produces drift — silently, measurably, all the more so as the project grows. The doctrine doesn't make the agent smarter. It *constrains* the human's exchanges with the agent and with themselves, so that incoherence is detected before it ships.

The seven axes:

1. **Material verification** — claims come with proof in the same message
2. **Bidirectional adversariality** — challenger before locking, no revision without new fact
3. **Data taxonomy and single source** — Live / Snapshot / Cache categorization mandatory
4. **Session discipline** — ADR before code, FIFO 3 projects max, manual trigger post-deploy
5. **Root cause, not patch** — workaround only if explicitly assumed
6. **Implicit pedagogy and business transversality** — regulated vocabulary, citations for obligations
7. **Long-term auditability** — quarterly memory audit, doctrine itself versioned

## Files

| File | Role |
|---|---|
| [`DOCTRINE.md`](./DOCTRINE.md) | The full v0.2 doctrine in one file: 7 axes, anti-patterns, style and posture. Drop into the root `CLAUDE.md` of your project, or alongside it. |
| [`ADR-template.md`](./ADR-template.md) | One-page Architecture Decision Record template. ADR before any project > 2 files (axis 4). |
| [`anti-patterns-checklist.md`](./anti-patterns-checklist.md) | Eight anti-patterns to flag immediately when the conversation drifts. Paste into PR review templates or session retrospectives. |

For the feedback file template (axis 7 — long-term auditability), see [`../claude-md/feedback-template.md`](../claude-md/feedback-template.md).

For the material verification axis explored in depth (axis 1), see [`../material-verification/`](../material-verification/).

For the data taxonomy decision (axis 3 — Live / Snapshot / Cache), see [`../live-snapshot-cache/`](../live-snapshot-cache/).

## How to read this folder

If you have an hour: read `DOCTRINE.md` end to end, then pick the three axes most relevant to your current pain (probably 1, 5, 7) and write them into your `CLAUDE.md`.

If you have ten minutes: read the seven axis titles in `DOCTRINE.md`, paste `anti-patterns-checklist.md` into your next PR review, move on.

## How to adapt it

- The doctrine is project-agnostic — every axis applies to any long collaboration with a coding agent (Claude Code, Cursor, Copilot, agentic IDE, etc.)
- Disable any axis for a sprint if you assume the cost explicitly. The doctrine is not a dogma, it's a convention that sediments
- The day a recurring failure mode appears that the seven axes don't cover, add an eighth. The doctrine is versioned (currently v0.2) and audited like an ADR

## Why this matters

The doctrine is not the condition for producing code with an AI agent — you can produce without it. But you cannot, without it, preserve the *coherence* of the code produced as the project grows. It's a discipline of long coherence, not a short productivity method. The bet of formalizing it: a citable rule (*"Material verification"*) saves ten minutes per session compared to re-discovering the same rule each time. Over a month, a working day. Over a year, a working month.
