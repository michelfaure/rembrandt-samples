# silent-failure-modes/

Five named patterns that fail silently when you ship code with an AI coding agent on the long run. Code passes, tests are green, the agent announces *OK* — yet something has slipped. This folder ships the two most copy-pastable countermeasures.

**Source article**: *Five silent failure modes I codified after 35 effective days of solo ERP coding* ([DEV.to](https://dev.to/michelfaure))

## The five modes

| # | Mode | Countermeasure |
|---|---|---|
| 1 | The fix that doesn't fix (silent workaround) | Demand the full input → output pipeline before accepting. Workaround legitimate only if explicitly assumed in commit AND in a feedback file. |
| 2 | The test that passes by construction | Negative case `expect(...).rejects.toThrow()` mandatory in every contract suite — see `negative-contract-test.test.ts`. |
| 3 | The memory that confabulates | Memory is a point of entry, not a point of arrival. *"Do you remember..."* is a signal to `Read`, not to confirm. |
| 4 | The count that lies | Quarterly DB ↔ code audit of shared enums — see `quarterly-enum-audit.sh`. |
| 5 | The scope that creeps | Strict fix scope. Adjacent refactor = separate ticket, never under cover of a fix. |

## Files

| File | Role |
|---|---|
| [`negative-contract-test.test.ts`](./negative-contract-test.test.ts) | Vitest contract test with the mandatory negative case that prevents tautological green tests. |
| [`quarterly-enum-audit.sh`](./quarterly-enum-audit.sh) | Audit script that compares declared TypeScript enum constants against the actual `SELECT DISTINCT` from Postgres. Run quarterly, calendar it. |

For the feedback file template referenced in modes 1 and 3 (the rituel that turns one-off corrections into opposable rules), see [`../claude-md/feedback-template.md`](../claude-md/feedback-template.md).

## How to adapt it

- Replace the table list and column names in `quarterly-enum-audit.sh` with your own enum-bearing columns
- The negative test assumes a `assertEnumStable` helper — rename to your own helper if you already have one, the structure of the negative case is what matters
- The five modes themselves don't need code, they need a feedback file each. The article gives the formulation; the repo gives the two enforcement primitives

## Why this matters

The visible failures (red builds, white pages, uncaught exceptions) are easier — they trigger something. The silent ones don't trigger anything: code passes, the agent announces *Compiled successfully*, production runs. Drift accumulates in the gray zone where no monitoring fires because no error is raised. Names matter here. *« The count that lies »* spotted in the wild three months from now is a thirty-second diagnosis instead of a three-hour investigation. That's the entire bet of formalizing the modes.
