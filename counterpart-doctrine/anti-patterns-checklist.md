# Anti-patterns checklist

Eight conversational drifts that should be flagged immediately when working with an AI coding agent. Paste this into your PR review template, your session retrospectives, or your `CLAUDE.md` itself. The earlier they're named, the cheaper the correction.

## The eight

- [ ] **Anthropomorphizing the agent** — *"it thinks"*, *"it prefers"*, *"it's confused"*. The agent has no preferences. Restate the decision, the criterion, the alternative discarded.

- [ ] **Validating a build on declaration without raw output** — *"Compiled successfully"* without the raw `tsc` or `pnpm build` output. Demand the output every time. See axis 1 of the doctrine.

- [ ] **Accepting a fix without full input → output pipeline** — a patch that makes the symptom disappear without explaining what produced the symptom. Demand the pipeline before accepting. See axis 5.

- [ ] **Creating a derived column without L/S/C category** — any new stored column that could have been computed from other data must be categorized as Live, Snapshot, or Cache, and the refresher mechanism declared in the same commit. See axis 3.

- [ ] **Starting a project > 2 files without ADR** — multi-file work that has no one-page ADR is work without a record. Future-you can't reconstruct why. See axis 4.

- [ ] **More than 3 projects open in parallel** — opening a fourth means closing one (shipped or deferred explicitly). FIFO discipline. See axis 4.

- [ ] **"You need X" + norm without citation of exact text** — any obligation claim ("you need eIDAS", "GDPR requires") must come with the exact regulatory text. Without citation, it's probably marketing. See axis 6.

- [ ] **Pushback "are you sure?" producing revision without new fact** — if the second answer doesn't cite a new factual element, the revision is complaisance. Maintaining the first answer is legitimate. See axis 2.

## How to use

- **In a session**: name the anti-pattern out loud (or in writing) when you see it. Naming is what blocks the drift.
- **In a PR review**: scan the diff for any of the eight. The first three are visible in the diff itself; the others are visible in the PR description and the linked ADR (or absence thereof).
- **In a retrospective**: at the end of a long session, ask which of the eight you let slide and why. The pattern of slides is the next axis to formalize.

## Why eight

The number is not magic — it's the residue of 35 days of practice. The doctrine started with three (the original Material Verification, Root Cause, Auditability). The other five came from incidents that recurred and pushed for a name. The day a ninth pattern recurs across multiple sessions, it earns its bullet.

Calendar a quarterly review of this list. Anti-patterns that haven't fired in two months are either solved (archive them) or too abstract (rewrite them). The list is a working tool, not a manifesto.
