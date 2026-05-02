# ADR-NNNN — <Decision title>

> One-page Architecture Decision Record. Required before any project > 2 files (axis 4 of the Counterpart Doctrine). Filename convention: `docs/adr/NNNN-kebab-title.md`. NNNN is monotonically increasing, never reused, never rewritten in place.

**Status**: Proposed | Accepted | Superseded by ADR-XXXX
**Date**: YYYY-MM-DD
**Authors**: <name(s)>

## Context

What is the situation that calls for a decision? What constraints, what existing state, what's broken or about to break, what's the deadline. Two to four short paragraphs. No reasoning yet — just the facts of the world that surround the decision.

## Decision

In one sentence: what is being decided. Then in three to five sentences: how it will be implemented (key files, key migrations, key wirings). Concrete enough that a reader six months from now can reconstruct what was done without reading the code.

## Alternatives discarded

For each serious alternative considered:

- **Alternative A** — what it was, why it was discarded. One short paragraph.
- **Alternative B** — same.

If there were no serious alternatives, write *"No alternative considered serious enough to discard explicitly"* and explain in one sentence why this was the only viable path. Don't fake alternatives — a fake alternative is worse than admitting there wasn't one.

## Consequences

What this decision locks in (positive consequences, negative consequences, side effects). Be honest about the negative ones — the ADR is the record where future-you finds out *why* the codebase is the way it is. Hiding the cost makes the record less useful.

- **Positive**: <what becomes possible / cheaper / safer>
- **Negative**: <what becomes constrained / more expensive / more brittle>
- **Open questions**: <what we know we don't know yet, and when we'll revisit>

## References

- Code paths most affected (e.g., `lib/finance/`, `app/crm/[id]/`)
- Related ADRs (decisions this one builds on or replaces)
- External docs, tickets, or specifications cited
- Source feedback memory file(s) that triggered the ADR, if any

---

## Discipline notes

- **Write the ADR before the first commit**, not after. ADRs written retroactively rationalize decisions instead of constraining them.
- **One page max**. If the decision needs more, split it into multiple ADRs (one per axis of the choice) or write a separate design doc that the ADR references.
- **Don't rewrite an ADR after it's accepted**. Supersede it with a new ADR that references the original. The trail of supersedings is the audit trail.
- **Reference the ADR from the code** in commits ("Implements ADR-0007") or in code comments where the decision is non-obvious. The ADR is useless if no one finds it again.
