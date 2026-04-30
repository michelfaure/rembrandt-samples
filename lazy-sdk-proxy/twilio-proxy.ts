/**
 * twilio-proxy.ts
 *
 * Same lazy-Proxy pattern adapted to Twilio, which takes two credentials
 * (account SID + auth token) in its constructor. Both must be present
 * before instantiation; the Proxy defers the check to first call.
 */

import twilio from 'twilio'

type TwilioClient = ReturnType<typeof twilio>

let _client: TwilioClient | null = null

function getClient(): TwilioClient {
  if (_client) return _client
  const sid = process.env.TWILIO_ACCOUNT_SID
  const token = process.env.TWILIO_AUTH_TOKEN
  if (!sid || !token) throw new Error('TWILIO credentials missing')
  _client = twilio(sid, token)
  return _client
}

export const twilioClient = new Proxy({} as TwilioClient, {
  get(_target, prop, receiver) {
    const client = getClient()
    const value = Reflect.get(client, prop, receiver)
    return typeof value === 'function' ? value.bind(client) : value
  },
})
