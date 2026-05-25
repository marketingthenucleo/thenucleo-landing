// Bridge Portal Bubble → Work (/ficha-cliente/) via Supabase magic link.
//
// Bubble calls this Edge Function with HMAC-signed payload. If valid, we
// generate a single-use magic link for the requesting admin email and
// return the action_link. Bubble redirects the user there; Supabase
// consumes the link, drops the JWT in localStorage on work.thenucleo.com,
// and the user lands at /ficha-cliente/?id=<bubble_id> already signed in.
//
// Config in Supabase Dashboard → Edge Functions → bridge_from_portal:
//   - verify_jwt: false       (caller is Bubble, auth is via HMAC)
//   - Secret BRIDGE_SHARED_SECRET (openssl rand -hex 32, mirrored in Bubble)
//   - Secret SUPABASE_SERVICE_ROLE_KEY (already provisioned by Supabase)
//
// See docs/work/bridge-portal-ficha.md for arch + rotation steps.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ALLOWLIST = new Set([
  "benjamin.sanchis@thenucleo.com",
  "alejandro.lopez@thenucleo.com",
  "marketing.thenucleo@gmail.com",
  "mel.dalmazo@thenucleo.com",
  "valentina.ramirez@thenucleo.com",
]);

const TIMESTAMP_WINDOW_SECONDS = 300;
const WORK_BASE = "https://work.thenucleo.com";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const BRIDGE_SHARED_SECRET = Deno.env.get("BRIDGE_SHARED_SECRET")!;

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

async function hmacSha256Hex(secret: string, message: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));
  return Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function timingSafeEqualHex(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

type AuditEntry = {
  email?: string;
  bubble_id?: string;
  ip?: string;
  user_agent?: string;
  success: boolean;
  failure_reason?: string;
};

async function logAudit(entry: AuditEntry): Promise<void> {
  try {
    await admin.from("bridge_audit_log").insert(entry);
  } catch (err) {
    console.error("[bridge_from_portal] audit insert failed", err);
  }
}

function forbidden(): Response {
  return new Response(JSON.stringify({ error: "forbidden" }), {
    status: 403,
    headers: { "content-type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: { "content-type": "application/json" },
    });
  }

  const ip = req.headers.get("x-forwarded-for") ?? "";
  const ua = req.headers.get("user-agent") ?? "";

  let body: { email?: unknown; bubble_id?: unknown; timestamp?: unknown; signature?: unknown };
  try {
    body = await req.json();
  } catch {
    await logAudit({ ip, user_agent: ua, success: false, failure_reason: "invalid_json" });
    return forbidden();
  }

  const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
  const bubble_id = typeof body.bubble_id === "string" ? body.bubble_id.trim() : "";
  const timestamp = typeof body.timestamp === "number" ? body.timestamp : NaN;
  const signature = typeof body.signature === "string" ? body.signature.trim().toLowerCase() : "";

  if (!email || !bubble_id || !Number.isFinite(timestamp) || !signature) {
    await logAudit({ email, bubble_id, ip, user_agent: ua, success: false, failure_reason: "missing_fields" });
    return forbidden();
  }

  const expected = await hmacSha256Hex(BRIDGE_SHARED_SECRET, `${email}|${bubble_id}|${timestamp}`);
  if (!timingSafeEqualHex(expected, signature)) {
    await logAudit({ email, bubble_id, ip, user_agent: ua, success: false, failure_reason: "bad_signature" });
    return forbidden();
  }

  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - timestamp) > TIMESTAMP_WINDOW_SECONDS) {
    await logAudit({ email, bubble_id, ip, user_agent: ua, success: false, failure_reason: "stale_timestamp" });
    return forbidden();
  }

  if (!ALLOWLIST.has(email)) {
    await logAudit({ email, bubble_id, ip, user_agent: ua, success: false, failure_reason: "not_in_allowlist" });
    return forbidden();
  }

  const next = `/ficha-cliente/?id=${encodeURIComponent(bubble_id)}`;
  const redirectTo = `${WORK_BASE}/comunidad/entrar/?next=${encodeURIComponent(next)}`;

  const { data, error } = await admin.auth.admin.generateLink({
    type: "magiclink",
    email,
    options: { redirectTo },
  });

  const action_link = data?.properties?.action_link;
  if (error || !action_link) {
    await logAudit({
      email,
      bubble_id,
      ip,
      user_agent: ua,
      success: false,
      failure_reason: `magiclink_failed:${error?.message ?? "no_link"}`,
    });
    return forbidden();
  }

  await logAudit({ email, bubble_id, ip, user_agent: ua, success: true });

  return new Response(JSON.stringify({ action_link }), {
    status: 200,
    headers: { "content-type": "application/json" },
  });
});
