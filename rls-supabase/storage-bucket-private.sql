-- storage-bucket-private.sql — Trap #4 fix
--
-- Supabase Storage buckets are public by default. If you store sensitive
-- documents (signatures, ID photos, training contracts), the URLs are
-- accessible to anyone who knows them — and URLs are sometimes
-- guessable, traceable, or stored as plain-text paths in your DB.
--
-- The fix is two-step: flip the bucket to private (this file), then
-- replace getPublicUrl() with createSignedUrl() in application code.

-- ============================================================================
-- Step 1: list public buckets to know what you're dealing with
-- ============================================================================

SELECT name, public, file_size_limit, allowed_mime_types
  FROM storage.buckets
 WHERE public = true
 ORDER BY name;

-- Read this list. Any bucket containing user-supplied or sensitive data
-- (signatures, supporting documents, ID photos, training contracts) must
-- become private. A bucket of public branding assets (logos, marketing
-- images) can legitimately stay public.

-- ============================================================================
-- Step 2: flip the chosen buckets to private
-- ============================================================================

UPDATE storage.buckets
   SET public = false
 WHERE name IN ('signatures', 'supporting_docs', 'identity_photos');

-- ============================================================================
-- Step 3: write storage policies that restrict per-user access
-- ============================================================================
-- Once the bucket is private, getPublicUrl() returns 404 for everyone.
-- You access files through createSignedUrl() in your API routes, but
-- you also want RLS-style policies on storage.objects so the SDK can
-- be used directly when needed (e.g. an admin tool).
--
-- Pattern: only the owner (the user who uploaded) and admins can read.

CREATE POLICY "owner_or_admin_read" ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'signatures'
    AND (
      auth.uid() = owner
      OR EXISTS (
        SELECT 1 FROM user_roles
        WHERE email = auth.email()
          AND role IN ('admin', 'super_admin')
      )
    )
  );

CREATE POLICY "owner_upload" ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'signatures'
    AND auth.uid() = owner
  );

-- ============================================================================
-- Step 4: in application code, switch getPublicUrl → createSignedUrl
-- ============================================================================
-- This is the part outside SQL. Search for `getPublicUrl` in your codebase:
--
--   rg --type ts 'getPublicUrl'
--
-- Replace each call with createSignedUrl from a server-side route, after
-- a permission check. Example handler in TypeScript:
--
--   // app/api/signatures/[id]/route.ts
--   export async function GET(req, { params }) {
--     const profile = await requireAuth()
--     const { data: signature } = await supabaseAdmin
--       .from('signatures')
--       .select('storage_path, contact_id')
--       .eq('id', params.id)
--       .single()
--     if (!canAccess(profile, signature.contact_id)) {
--       return new Response('Forbidden', { status: 403 })
--     }
--     const { data } = await supabaseAdmin.storage
--       .from('signatures')
--       .createSignedUrl(signature.storage_path, 60 * 5)  // 5 min
--     return Response.redirect(data.signedUrl)
--   }
--
-- The signed URL expires; the path stays in the DB; the access check
-- runs on every request.

-- ============================================================================
-- Verification: try to access a file from the public URL
-- ============================================================================
-- After flipping public = false, https://YOUR_PROJECT.supabase.co/storage/v1/
--   object/public/signatures/<path> returns 404. That's the symptom of
-- the fix working. If it still returns the file, the bucket is still
-- public — re-run Step 2.
