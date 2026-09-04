import { createClient } from 'npm:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const corsHeaders = {
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-share-token',
  'Access-Control-Allow-Methods': 'POST, GET, DELETE, OPTIONS',
  'Access-Control-Allow-Origin': '*',
  'Content-Type': 'application/json',
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { headers: corsHeaders, status });

const tokenHash = async (token: string) => {
  const bytes = new TextEncoder().encode(token);
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
};

const newToken = () => {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return btoa(String.fromCharCode(...bytes))
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '');
};

const findLink = async (request: Request) => {
  const shareId = new URL(request.url).searchParams.get('shareId');
  const token = request.headers.get('x-share-token') ??
    new URL(request.url).searchParams.get('token');
  if (!shareId || !token) return null;

  const { data } = await supabase
    .from('shared_run_links')
    .select('id, run_payload, expires_at, revoked_at')
    .eq('id', shareId)
    .eq('token_hash', await tokenHash(token))
    .maybeSingle();

  if (!data || data.revoked_at || new Date(data.expires_at) <= new Date()) return null;
  return data;
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  if (request.method === 'POST') {
    if (request.headers.get('content-type')?.startsWith('multipart/form-data')) {
      const link = await findLink(request);
      if (!link) return json({ error: 'Share link is invalid or expired' }, 404);

      const form = await request.formData();
      const file = form.get('image');
      const evidence = JSON.parse(String(form.get('evidence') ?? '{}'));
      if (!(file instanceof File) || file.size === 0 || file.size > 10 * 1024 * 1024) {
        return json({ error: 'Image must be between 1 byte and 10 MB' }, 400);
      }
      if (!evidence.id || !evidence.questId) {
        return json({ error: 'Evidence metadata is required' }, 400);
      }

      const storagePath = `${link.id}/${crypto.randomUUID()}`;
      const { error: uploadError } = await supabase.storage
        .from('shared-run-images')
        .upload(storagePath, await file.arrayBuffer(), {
          contentType: file.type || 'application/octet-stream',
          upsert: false,
        });
      if (uploadError) return json({ error: 'Could not upload image' }, 500);

      const existingEvidence = Array.isArray(link.run_payload.evidence)
        ? link.run_payload.evidence
        : [];
      const { error: updateError } = await supabase
        .from('shared_run_links')
        .update({
          run_payload: {
            ...link.run_payload,
            evidence: [...existingEvidence, {...evidence, storagePath}],
          },
        })
        .eq('id', link.id);
      if (updateError) {
        await supabase.storage.from('shared-run-images').remove([storagePath]);
        return json({ error: 'Could not save image metadata' }, 500);
      }
      return json({ uploaded: true });
    }

    const body = await request.json();
    const expiresInSeconds = Math.min(
      Math.max(Number(body.expiresInSeconds ?? 86400), 300),
      604800,
    );
    if (!body.run || typeof body.run !== 'object') {
      return json({ error: 'run is required' }, 400);
    }

    const token = newToken();
    const expiresAt = new Date(Date.now() + expiresInSeconds * 1000).toISOString();
    const { data, error } = await supabase
      .from('shared_run_links')
      .insert({
        expires_at: expiresAt,
        run_payload: body.run,
        token_hash: await tokenHash(token),
      })
      .select('id, expires_at')
      .single();

    if (error) return json({ error: 'Could not create share link' }, 500);
    const requestUrl = new URL(request.url);
    requestUrl.search = '';
    const shareUrl = `${requestUrl.toString()}?shareId=${data.id}&token=${token}`;
    return json({ shareId: data.id, token, expiresAtUtc: data.expires_at, shareUrl });
  }

  if (request.method === 'GET') {
    const link = await findLink(request);
    if (!link) return json({ error: 'Share link is invalid or expired' }, 404);
    const evidence = await Promise.all(
      (Array.isArray(link.run_payload.evidence) ? link.run_payload.evidence : [])
        .map(async (item: Record<string, unknown>) => {
          const { data } = await supabase.storage
            .from('shared-run-images')
            .createSignedUrl(String(item.storagePath), 3600);
          return {
            id: item.id,
            questId: item.questId,
            caption: item.caption ?? '',
            imageUrl: data?.signedUrl,
          };
        }),
    );
    return json({ ...link.run_payload, evidence, expiresAtUtc: link.expires_at });
  }

  if (request.method === 'DELETE') {
    const link = await findLink(request);
    if (!link) return json({ error: 'Share link is invalid or expired' }, 404);
    const { error } = await supabase
      .from('shared_run_links')
      .update({ revoked_at: new Date().toISOString() })
      .eq('id', link.id);
    if (error) return json({ error: 'Could not revoke share link' }, 500);
    return new Response(null, { headers: corsHeaders, status: 204 });
  }

  return json({ error: 'Method not allowed' }, 405);
});
