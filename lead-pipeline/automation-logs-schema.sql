-- automation-logs-schema.sql
--
-- One row per (lead, integration) tentative. Read every morning to
-- check what failed overnight and on what frequency. Indexed for
-- recent-window queries on a single integration.

CREATE TABLE automation_logs (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id         uuid NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
  integration     text NOT NULL,             -- mailchimp | slack | gmail | meta_capi | ...
  status          text NOT NULL,             -- ok | error
  error_message   text,                      -- null on success
  ran_at          timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT automation_logs_status_check
    CHECK (status IN ('ok', 'error'))
);

CREATE INDEX automation_logs_recent_idx
  ON automation_logs (ran_at DESC);

CREATE INDEX automation_logs_integration_recent_idx
  ON automation_logs (integration, ran_at DESC);

CREATE INDEX automation_logs_errors_idx
  ON automation_logs (integration, ran_at DESC)
  WHERE status = 'error';

COMMENT ON TABLE automation_logs IS
  'One row per (lead, integration) tentative. Used to spot failed integrations before they affect business — Slack down shouldn''t silence email overnight.';

-- ---------------------------------------------------------------------------
-- Morning dashboard query — paste in your morning Slack/email digest
-- ---------------------------------------------------------------------------

-- SELECT integration,
--        COUNT(*) FILTER (WHERE status = 'ok')                              AS ok_count,
--        COUNT(*) FILTER (WHERE status = 'error')                           AS error_count,
--        COUNT(DISTINCT lead_id)                                            AS leads_touched,
--        ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'error') / NULLIF(COUNT(*), 0), 1) AS error_pct
-- FROM automation_logs
-- WHERE ran_at >= now() - interval '24 hours'
-- GROUP BY integration
-- ORDER BY error_pct DESC NULLS LAST;
