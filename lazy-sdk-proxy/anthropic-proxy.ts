/**
 * anthropic-proxy.ts
 *
 * Same lazy-Proxy pattern adapted to the Anthropic Claude SDK. Useful when
 * you ship an AI feature behind a feature flag or a single endpoint that
 * isn't called during build.
 *
 * Note: as of late 2025 the Anthropic SDK does NOT throw on a missing key
 * at constructor time — it throws at first call. This pattern is therefore
 * defensive: it future-proofs against a behavior change, and it gives
 * exactly one place where the credential is read (easier to mock in tests).
 */

import Anthropic from '@anthropic-ai/sdk'

let _anthropic: Anthropic | null = null

function getAnthropic(): Anthropic {
  if (_anthropic) return _anthropic
  const key = process.env.ANTHROPIC_API_KEY
  if (!key) throw new Error('ANTHROPIC_API_KEY missing')
  _anthropic = new Anthropic({ apiKey: key })
  return _anthropic
}

export const anthropic = new Proxy({} as Anthropic, {
  get(_target, prop, receiver) {
    const client = getAnthropic()
    const value = Reflect.get(client, prop, receiver)
    return typeof value === 'function' ? value.bind(client) : value
  },
})
