# lazy-sdk-proxy/

Wrap an SDK client in a Proxy so that `next build` doesn't crash when the SDK secret isn't in the build environment. Fifteen lines that move the credential check from module-load time to first-call time.

**Source article**: *Fifteen lines of Proxy to keep an SDK from breaking my CI* ([DEV.to](https://dev.to/michelfaure))

## Invariant rule

Any SDK that validates its credentials in its constructor and is imported by an API route will crash `next build` if the secret is absent from the build env. Wrap it in a Proxy plus lazy getter, and the credential error only surfaces at first real call — exactly where you want it.

## Files

| File | Role |
|---|---|
| [`stripe-proxy.ts`](./stripe-proxy.ts) | The canonical pattern on the Stripe SDK — fifteen lines, public API preserved |
| [`twilio-proxy.ts`](./twilio-proxy.ts) | Variant on Twilio (two-credential constructor) |
| [`anthropic-proxy.ts`](./anthropic-proxy.ts) | Variant on `@anthropic-ai/sdk` for Claude API consumers |

## When to apply, and when not to

The pattern pays off whenever an SDK is consumed by a rarely-exercised route — webhooks, admin endpoints, scheduled cron jobs — and the secret isn't systematically present in every build environment.

If the SDK is consumed everywhere in the app, the Proxy only protects symbolically — it shifts the crash from `next build` to first-render. In that case, put the secret everywhere instead.

A middle ground: if the SDK has a *dry-run* or mock client, instantiate that when the secret is missing rather than throwing. More surgical, but not all SDKs support it.

## Three subtle bits in the code

1. **Why Proxy and not an exported `getStripe()` function**: the Proxy preserves the public API (`stripe.checkout.sessions.create(...)`) that all callers already use. Moving to a getter would force you to update 30+ call sites.
2. **Why the `bind(client)` on methods**: SDK methods use `this` internally. Without `bind`, the Proxy hop loses context and you get `TypeError: Cannot read properties of undefined`.
3. **Why the cache (`_stripe`)**: not just performance — it's a consistency guarantee. Without it, every property access creates a new client, breaking stateful behaviors (rate limiters, keep-alive pools).
