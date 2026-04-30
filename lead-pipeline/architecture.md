# Architecture — hub-and-spoke lead pipeline

## The shape

```
Meta Ads    ──┐
Formidable  ──┤
Stripe      ──┤──► Webhooks ──► Postgres (source of truth) ──► fan-out
Manual      ──┘                                                 │
                                                                ├── Mailchimp / Brevo
                                                                ├── Slack (#leads)
                                                                ├── Gmail (internal email)
                                                                ├── Meta CAPI
                                                                └── CRM inbox (HubSpot / Pipedrive)
```

One entry point per source, one storage table, one fan-out function in TypeScript. Compare with a typical Zapier graph: 21 zaps + 9 Make scenarios, each one a tiny black box, no central state, no joint dashboard.

## Why the fan-out runs OUTSIDE the request

The webhook that creates the lead writes to Postgres and returns immediately. The fan-out runs in `waitUntil` (Vercel/Next.js) or a queue worker — never inside the request critical path.

Two reasons:

1. **Latency**: Slack APIs occasionally take three to five seconds. If the lead-creation HTTP request waits for Slack, it times out. The lead never gets stored.
2. **Failure isolation**: Slack being down should never block lead capture. Postgres commits, the fan-out runs best-effort, the user sees a `200 OK` response.

```ts
// In your Next.js route handler
import { waitUntil } from '@vercel/functions'

export async function POST(req: Request) {
  const lead = await req.json()
  const { data } = await admin.from('contacts').insert(lead).select().single()

  // Returns 200 OK immediately. The pipeline runs in the background.
  waitUntil(runLeadPipeline(data))

  return Response.json({ ok: true })
}
```

## Why one Postgres table is the central trick

Without a central source of truth, you can't ask "how many leads on Tuesday" without querying every tool. Each tool has its own view, and they disagree. With Postgres central, the question becomes a single SQL query. With Postgres central plus `automation_logs`, you also know which tools were notified about which lead and which failed — without having to log into Slack, Mailchimp, and HubSpot to triangulate.

## What you give up

- A Zap "if X then Y" rule that bypasses Postgres entirely (e.g. Stripe → Slack directly) becomes one more line in `runLeadPipeline`. You can't have an integration that lives outside the central pipeline.
- Visual workflow editing (Zapier UI) — you edit code now. For a small team comfortable with TypeScript, this is a net positive (versioned, reviewable, tested). For a non-technical operator, this is a regression.

## What you gain

- One file to read to see every outbound integration.
- One table to query to know what fired and what didn't.
- One pricing line to cancel ($30-200/month of Zapier+Make depending on volume) instead of a recurring SaaS spread across two vendors.
- Cold-path execution: a flaky integration doesn't slow down lead capture.
