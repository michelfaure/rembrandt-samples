-- agent-runs-schema.sql
--
-- Minimal schema for an `agent_runs` table that records each query run
-- by an SQL-generating AI agent. The column `result_row_count` is the
-- silent-zero detector — it lets you spot drift retroactively without
-- having to wait for a user complaint.
--
-- Companion: see `semantic-drift.test.ts` for the upstream contract test.

CREATE TABLE agent_runs (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at      timestamptz NOT NULL DEFAULT now(),

  -- Question and answer trail
  user_question   text NOT NULL,
  generated_sql   text,                    -- SQL produced by the planner LLM
  validator_pass  boolean NOT NULL DEFAULT false,

  -- Execution outcome
  result_row_count int,                    -- the silent-zero canary
  exec_duration_ms int,
  error_message   text,                    -- null on success

  -- Routing / cost trail
  model_plan      text,                    -- e.g. 'sonnet-4.6'
  model_comment   text,                    -- e.g. 'haiku-4.5'
  cache_hit       boolean,

  -- Tenant filter (whatever you use in your JWT claim)
  tenant_filter   text[] NOT NULL
);

CREATE INDEX agent_runs_zero_rows_idx
  ON agent_runs (created_at DESC)
  WHERE result_row_count = 0;

CREATE INDEX agent_runs_recent_idx
  ON agent_runs (created_at DESC);

COMMENT ON COLUMN agent_runs.result_row_count IS
  'Number of rows returned to the agent. Zero on a business-reasonable question is a drift smell — surface in admin dashboard with a 7-day rolling filter.';

-- The query you run weekly to spot drift retroactively:
--
-- SELECT date_trunc('day', created_at)::date AS day,
--        COUNT(*)                                            AS total_runs,
--        COUNT(*) FILTER (WHERE result_row_count = 0)        AS zero_runs,
--        ROUND(100.0 * COUNT(*) FILTER (WHERE result_row_count = 0) / COUNT(*), 1) AS zero_pct
-- FROM agent_runs
-- WHERE created_at >= now() - interval '7 days'
-- GROUP BY 1
-- ORDER BY 1 DESC;
