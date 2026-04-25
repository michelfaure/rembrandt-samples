# Feedback file template

A versioned `feedback_*.md` file is the artifact that turns a one-off
correction into an opposable rule. The structure below is the format
used in `~/.claude/agent-memory/` for the Rembrandt project.

**Source articles**:
- *Memory → code audit: the anti-drift discipline* ([DEV.to](https://dev.to/michelfaure))
- *When a memorized rule fits your bug too well: a meta-trap of agent workflows* ([DEV.to](https://dev.to/michelfaure))

## Structure

Three blocks. The rule, **Why**, **How to apply**. Knowing *why* lets you
judge edge cases later instead of blindly following the rule.

```markdown
---
name: <short title, distinct from filename>
description: <one-line, used by the agent to decide relevance>
type: feedback
---

<The rule itself. One or two sentences. Lead with the prohibition or
the prescription, not the reasoning.>

**Why**: <The reason. Often a past incident with a date. The cost in
time, money, or trust. Not "best practice" — the actual story.>

**How to apply**: <When the rule fires. Concrete trigger conditions.
What to verify before invoking. What to do instead of the failure mode.>
```

## Example: the meta-feedback from article #30

```markdown
---
name: Memorized rule does not short-circuit code verification
description: A memorized rule explains plausibly but applies to a precise
  location; verify the producing code before invoking it.
type: feedback
---

A memorized rule (e.g. "1 enrollment = N seats") applies to a precise
location in the model (the table inscriptions). It does NOT automatically
apply to every counter that displays related data.

**Why**: 22/04/2026 — investigating a delta on /crm/eleves (785 vs 862).
I assumed the studio tabs counted seats (N per person) because the rule
exists in memory. They actually read v_eleves which deduplicates by
contact (DISTINCT contact_id). The real delta came from a different
status filter between tabs. I skipped verification because the memorized
rule fit the symptom approximately. Cost: 20 minutes of pointless SQL
exploration.

**How to apply**: when a UI number looks inconsistent and a memorized
rule seems to explain the delta, open the code that produces the number
BEFORE invoking the rule. Read the SQL view or query used. If it does
DISTINCT or routes through a deduplicated source, the "N per person"
rule does not apply to that specific counter. Read first, invoke second.
```

## Discipline of writing

- **Date the incident.** Absolute date (`2026-04-22`), never relative
  ("last week"). Memory doesn't age if it's dated.
- **Lead with the rule, not the story.** The reader who skims sees the
  prohibition first; the *Why* is for when they want to challenge it.
- **One file per rule.** Don't pile related rules into a single file —
  the agent loads files by relevance, and a fat file is irrelevant
  most of the time.
- **Rewrite when the world changes.** A rule that's still firing weekly
  has earned its place. A rule that hasn't fired in two months is either
  solved (archive it) or too abstract (rewrite it).

## What this is not

It's not documentation. Documentation describes how the system works.
A feedback describes what the agent is forbidden or required to do,
because something specific went wrong. The two are distinct artifacts
and live in distinct files.
