// sync_theme_to_bubble — PATCH bub_user.theme → Bubble Data API User.theme
//
// Llamada desde work.thenucleo.com después de un toggle de theme.
// Patrón: cliente JS → RPC work_set_my_theme (UPDATE Supabase) → invoke esta EF (PATCH Bubble).
// La RPC ya valida allowlist; esta EF la replica como defensa en profundidad.
//
// Env vars requeridas (Supabase Dashboard → Edge Functions → Secrets):
//   BUBBLE_API_TOKEN  — admin token de Bubble Data API (el mismo que usa n8n cred bubble_data_api)
//   BUBBLE_APP_DOMAIN — opcional, default 'app-the-nucleo-agency.bubbleapps.io'

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'npm:@supabase/supabase-js@2';

const CORS_HEADERS: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Max-Age': '86400'
};

const ALLOWED_EMAILS = [
  'benjamin.sanchis@thenucleo.com',
  'alejandro.salgado@thenucleo.com',
  'maria.zorrilla@thenucleo.com',
  'rosa.escobar@thenucleo.com',
  'valentina.ramirez@thenucleo.com'
];

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' }
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }
  if (req.method !== 'POST') {
    return json(405, { ok: false, error: 'method_not_allowed' });
  }

  // 1) Auth: validar JWT vía Supabase (verify_jwt:true ya filtra inválidos).
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
  if (!supabaseUrl || !supabaseAnonKey) {
    return json(500, { ok: false, error: 'config_missing', detail: 'SUPABASE_URL or SUPABASE_ANON_KEY missing' });
  }
  const authHeader = req.headers.get('Authorization') ?? '';
  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } }
  });

  const { data: userData, error: userErr } = await supabase.auth.getUser();
  if (userErr || !userData?.user?.email) {
    return json(401, { ok: false, error: 'unauthenticated' });
  }
  const email = userData.user.email.toLowerCase();
  if (!ALLOWED_EMAILS.includes(email)) {
    return json(403, { ok: false, error: 'forbidden' });
  }

  // 2) Body: { bubble_id: string, theme: boolean }
  let payload: { bubble_id?: unknown; theme?: unknown };
  try {
    payload = await req.json();
  } catch {
    return json(400, { ok: false, error: 'invalid_json' });
  }
  const bubble_id = payload?.bubble_id;
  const theme = payload?.theme;
  if (typeof bubble_id !== 'string' || bubble_id.length === 0) {
    return json(400, { ok: false, error: 'bad_request', detail: 'bubble_id missing' });
  }
  if (typeof theme !== 'boolean') {
    return json(400, { ok: false, error: 'bad_request', detail: 'theme must be boolean' });
  }

  // 3) PATCH Bubble Data API
  const bubbleToken = Deno.env.get('BUBBLE_API_TOKEN');
  const bubbleDomain = Deno.env.get('BUBBLE_APP_DOMAIN') ?? 'app-the-nucleo-agency.bubbleapps.io';
  if (!bubbleToken) {
    return json(500, { ok: false, error: 'config_missing', detail: 'BUBBLE_API_TOKEN not set' });
  }

  const url = `https://${bubbleDomain}/api/1.1/obj/user/${encodeURIComponent(bubble_id)}`;
  let bubbleRes: Response;
  try {
    bubbleRes = await fetch(url, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${bubbleToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ theme })
    });
  } catch (e) {
    return json(502, { ok: false, error: 'bubble_unreachable', detail: String(e) });
  }

  if (!bubbleRes.ok) {
    const text = await bubbleRes.text();
    return json(502, {
      ok: false,
      error: 'bubble_patch_failed',
      status: bubbleRes.status,
      detail: text.slice(0, 500)
    });
  }

  return json(200, { ok: true, bubble_id, theme });
});
