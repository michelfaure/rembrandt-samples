-- ---------------------------------------------------------------------------
-- Pattern alternatif : DELETE multi-étapes en RPC SECURITY DEFINER transactionnelle
-- ---------------------------------------------------------------------------
-- When you have a cascade that must happen in a specific order (delete
-- children first, then parent) and any step can violate a constraint, do NOT
-- chain it in the application layer. The Supabase JS client can mask the
-- real error at the first step (silent await + unchecked { error }) and
-- surface a misleading FK violation at the second step.
--
-- Wrap the whole sequence in a `SECURITY DEFINER` function and call it as
-- a single RPC. The transaction fails atomically with the real error code
-- and the real error message — no intermediate applicative step exists to
-- swallow it.
--
-- This complements the lint rule in 02-eslint-rule.mjs:
--   - lint catches bare awaits at write time
--   - the RPC pattern eliminates the multi-step applicative chain entirely

CREATE OR REPLACE FUNCTION public.delete_event_with_children(
  p_event_id text
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Step 1: delete dependent rows. If this fails (CHECK violation, FK from
  -- another table, RLS denial), the transaction aborts here with the real
  -- error code surfacing back to the client as a PostgrestError.
  DELETE FROM event_attachments WHERE event_id = p_event_id;

  -- Step 2: delete the parent row. If a dependent table we forgot still
  -- references this event, this fails atomically and step 1 rolls back.
  DELETE FROM events WHERE id = p_event_id;

  -- Optional explicit raise for "not found" — useful when the caller
  -- expects to distinguish "deleted" from "wasn't there".
  IF NOT FOUND THEN
    RAISE EXCEPTION 'event % not found', p_event_id
      USING ERRCODE = 'P0002';
  END IF;
END;
$$;

-- Grant execution to authenticated callers only. The function runs as the
-- definer (typically a service role), so it bypasses RLS — make sure the
-- function body is the only authorization boundary you trust.
GRANT EXECUTE ON FUNCTION public.delete_event_with_children(text) TO authenticated;

-- ---------------------------------------------------------------------------
-- Calling from the application:
--
--   const { error } = await supabase.rpc('delete_event_with_children', {
--     p_event_id: id,
--   })
--   if (error) {
--     // error.code is the real ERRCODE (23503, 23514, P0002, ...)
--     // error.message is the real Postgres error message
--     throw new Error(`${error.code}: ${error.message}`)
--   }
--
-- ---------------------------------------------------------------------------
