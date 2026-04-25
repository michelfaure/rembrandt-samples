// client-selection.ts — Trap #1 fix
//
// Supabase exposes three distinct clients. The trap is that
// createSupabaseServer() — the SSR client with the anon key + auth cookie
// — silently falls back to anon if the cookie doesn't transit correctly
// (misconfigured middleware, expired refresh token, proxy reshape).
// Queries return [] with no error, which is the worst kind of bug.
//
// The rule: in a Server Component, use createSupabaseAdmin().
// Authentication is verified upstream by the route-guarding middleware;
// the service_role never reaches the browser; queries return what you
// expect.

import { createBrowserClient, createServerClient } from '@supabase/ssr'
import { createClient } from '@supabase/supabase-js'
import { cookies } from 'next/headers'

const SUPABASE_URL      = process.env.NEXT_PUBLIC_SUPABASE_URL!
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!

// ============================================================================
// 1. Browser client — for Client Components only
// ============================================================================
// Uses the anon key. Never a fallback. RLS policies apply. Auth comes
// from the cookie that Supabase manages in the browser.

export function createSupabaseBrowser() {
  return createBrowserClient(SUPABASE_URL, SUPABASE_ANON_KEY)
}

// ============================================================================
// 2. Server client — RARELY what you want in a Server Component
// ============================================================================
// Uses the anon key + the auth cookie passed via the request. RLS applies.
// Falls back to anon if the cookie is missing or the JWT can't be refreshed.
//
// Use this only for code that genuinely needs to run as the requesting user
// (e.g. a Server Action that records who triggered it via auth.uid()).
// For most reads in a Server Component, prefer createSupabaseAdmin() below.

export function createSupabaseServer() {
  const cookieStore = cookies()
  return createServerClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    cookies: {
      getAll() {
        return cookieStore.getAll()
      },
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options),
          )
        } catch {
          // Server Component — setAll fails silently, that's OK
        }
      },
    },
  })
}

// ============================================================================
// 3. Admin client — RECOMMENDED in Server Components
// ============================================================================
// Uses the service_role key. Bypasses RLS. Never reaches the browser
// (the env var is server-only). The auth check is your responsibility,
// but in a Server Component it's already been done by the route-guarding
// middleware before this code runs.

export function createSupabaseAdmin() {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  })
}

// ============================================================================
// Decision tree
// ============================================================================
//
// Where am I writing this code?
//
//   Browser (Client Component, useEffect, event handler):
//     → createSupabaseBrowser()
//
//   Server Component (default in App Router):
//     → createSupabaseAdmin()  in 95% of cases
//     → createSupabaseServer() only if you need auth.uid() in RLS policies
//
//   Server Action (form submission, mutation):
//     → createSupabaseAdmin() with a manual auth check before the mutation
//
//   API Route Handler (app/api/.../route.ts):
//     → createSupabaseAdmin() with a manual auth check before the work
//
//   Cron job, background task, migration script:
//     → createSupabaseAdmin() — there's no user to authenticate

// ============================================================================
// Anti-pattern in a Server Component
// ============================================================================
//
//   // ❌ Returns [] with no error if the cookie didn't transit
//   const supabase = createSupabaseServer()
//   const { data } = await supabase.from('inscriptions').select('*')
//
//   // ✅ Auth verified upstream by middleware, RLS bypassed
//   const supabase = createSupabaseAdmin()
//   const { data } = await supabase.from('inscriptions').select('*')
