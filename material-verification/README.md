# material-verification/

The first axis of the Counterpart Doctrine: every factual claim by an AI agent comes with its material proof in the same message, or it has zero evidentiary value. This folder ships the rule (as a `CLAUDE.md` snippet) and the script that hardens it for git pushes.

**Source article**: *Why "green build" without the raw output has zero evidentiary value* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

When an AI agent says *"build green / tests pass / drift detected / contact not found"*, the sentence is not a proof — it's an assertion. In 80% of cases it's right. In 20%, it's wrong the same way: model-internal confidence decoupled from verifiable external state. Survival rule: **every factual claim comes with the verification command and its raw output, in the same message, or it has zero evidentiary value**.

## Files

| File | Role |
|---|---|
| [`CLAUDE.md.snippet`](./CLAUDE.md.snippet) | The five imperative bullets to drop into the root `CLAUDE.md` of your project. Codifies the rule for the agent. |
| [`verify-head-builds.sh`](./verify-head-builds.sh) | Bash script that stashes the working tree, runs `tsc --noEmit` on HEAD only, restores. Run before `git push` on multi-commit branches. |

## How to read this folder

Start with `CLAUDE.md.snippet` — five bullets, no reasoning, a contract of format. Then `verify-head-builds.sh` — what hardens the rule on the path that matters most: the commit you're about to push. The script catches the case where staged files import symbols from non-staged files; the working tree compiles, the HEAD doesn't.

## How to adapt it

- The `CLAUDE.md.snippet` is project-agnostic — drop it as-is into your `CLAUDE.md` (or `AGENTS.md`, depending on which agent you use)
- `verify-head-builds.sh` assumes `npx tsc --noEmit` and `git stash`; substitute your typecheck command if needed (e.g., `pnpm typecheck`, `cargo check`, `mypy`)
- The script returns exit code 1 on type error and exit code 2 on infrastructure failure (stash failed) — wire it into a pre-push hook or a CI workflow

## Why this matters

When an agent hands you *"Compiled successfully"* without the raw compiler output, you can neither confirm nor deny the claim. It's a state of mind of the system that produced it, not a fact of the world. This is a problem of evidentiary value, not of truthfulness — an agent that always speaks true with no proof is structurally indistinguishable from one that occasionally lies.

Asking for the raw output every time costs thirty seconds. It saves the bug that would surface in production at 3pm, which costs an afternoon. Mathematically obvious. Behaviorally hard for the first week, transparent after.
