# glue-ratio/

Measure the glue / business logic ratio in `lib/` and wire a CI gate against regression.

**Source article**: *The glue/business ratio: a CI gate against silent code bloat* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

What isn't measured drifts. A rule in a constraints file is read then forgotten; a numbered metric that blocks a PR is seen. LLMs are no exception — they happily produce adapters, because adapters are easy to generate.

## Files

| File | Role |
|---|---|
| [`glue-ratio.sh`](./glue-ratio.sh) | Main script: two hardcoded lists (glue / business), global and types-excluded ratio, short verdict |
| [`glue-ratio-check.sh`](./glue-ratio-check.sh) | Compares HEAD vs base ref (default `origin/main`), fails on regression beyond a tolerance (default 0) |
| [`ci-workflow.yml`](./ci-workflow.yml) | GitHub Actions excerpt: log on push to main, blocking check on PR |

## Why non-regression and not an absolute threshold

A mature project at 35% glue that holds steady can be healthy. A project at 18% climbing to 22% in a week is drifting. An absolute threshold doesn't see the drift, it only sees the arrival. Non-regression sees the drift on the very first PR.

Secondary safety net at 40%: above that, a textual alert. It's a guardrail for pathological cases, not the main metric.

## How to adapt it

- Copy `glue-ratio.sh`, empty both lists, fill them with your own files
- Exclude auto-generated files (ORM types, generated schemas) from the denominator
- Add the CI workflow, tolerance 0 to start
- Watch for 2-3 weeks to see where regression actually comes from in practice before tightening
