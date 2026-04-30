/**
 * stripe-proxy.ts
 *
 * Lazy instantiation of the Stripe SDK behind a Proxy. The Stripe constructor
 * throws on a missing key, which crashes `next build` even when no real
 * request is ever made. The Proxy defers the constructor to the first
 * property access, so the credential error only surfaces at runtime.
 *
 * Drop-in replacement for `export const stripe = new Stripe(...)`.
 */

import Stripe from 'stripe'

let _stripe: Stripe | null = null

function getStripe(): Stripe {
  if (_stripe) return _stripe
  const key = process.env.STRIPE_SECRET_KEY
  if (!key) throw new Error('STRIPE_SECRET_KEY missing')
  _stripe = new Stripe(key, { apiVersion: '2026-03-25.dahlia' })
  return _stripe
}

// Public API preserved: callers keep doing `stripe.checkout.sessions.create(...)`
// with no change. The Proxy intercepts every property access, lazily
// instantiates the real client, and forwards the call.
export const stripe = new Proxy({} as Stripe, {
  get(_target, prop, receiver) {
    const client = getStripe()
    const value = Reflect.get(client, prop, receiver)
    return typeof value === 'function' ? value.bind(client) : value
  },
})
