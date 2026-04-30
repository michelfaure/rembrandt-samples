/**
 * lead-pipeline.ts
 *
 * Hub-and-spoke fan-out for lead creation. Postgres is the only source of
 * truth — every external system is downstream. The pipeline is invoked
 * AFTER the lead row is committed, never inside the request critical path.
 *
 * Replace each `notifyXxx` / `syncXxx` with your actual integration —
 * the only contract is that each one returns a Promise and either resolves
 * (logged as success) or rejects (logged as failure, doesn't block the
 * others).
 */

import { createClient } from '@supabase/supabase-js'

const admin = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
)

export type Lead = {
  id: string
  email: string
  name?: string
  source: 'meta_ads' | 'formidable' | 'stripe' | 'manual'
  created_at: string
}

type Integration = {
  name: string
  run: (lead: Lead) => Promise<unknown>
}

const integrations: Integration[] = [
  { name: 'mailchimp', run: syncMailchimp },
  { name: 'slack',     run: notifySlack },
  { name: 'gmail',     run: notifyGmail },
  { name: 'meta_capi', run: sendMetaCapi },
  { name: 'crm_inbox', run: postToCrmInbox },
]

export async function runLeadPipeline(lead: Lead): Promise<void> {
  const results = await Promise.allSettled(
    integrations.map((integration) =>
      integration.run(lead).then(
        () => ({ name: integration.name, status: 'ok' as const }),
        (error) => ({
          name: integration.name,
          status: 'error' as const,
          message: error instanceof Error ? error.message : String(error),
        }),
      ),
    ),
  )

  const rows = results
    .filter((r) => r.status === 'fulfilled')
    .map((r) => (r as PromiseFulfilledResult<unknown>).value)
    .map((outcome: any) => ({
      lead_id: lead.id,
      integration: outcome.name,
      status: outcome.status,
      error_message: outcome.message ?? null,
      ran_at: new Date().toISOString(),
    }))

  if (rows.length > 0) {
    await admin.from('automation_logs').insert(rows)
  }
}

// ---------------------------------------------------------------------------
// Replace these stubs with your actual integrations. Each MUST return a
// Promise. Reject = logged as error in automation_logs. Resolve = logged ok.
// ---------------------------------------------------------------------------

async function syncMailchimp(lead: Lead): Promise<void> {
  // POST to Mailchimp / Brevo / your ESP here
}

async function notifySlack(lead: Lead): Promise<void> {
  // POST to Slack webhook here
}

async function notifyGmail(lead: Lead): Promise<void> {
  // Send an internal email via SMTP / Gmail API here
}

async function sendMetaCapi(lead: Lead): Promise<void> {
  // POST to Meta Conversions API here
}

async function postToCrmInbox(lead: Lead): Promise<void> {
  // POST to your CRM webhook (HubSpot, Pipedrive, etc.) here
}
