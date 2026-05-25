-- ============================================================
-- Bridge Portal Bubble → Work — tabla de auditoría (2026-05-25)
-- ============================================================
-- Soporta la Edge Function `bridge_from_portal` que recibe peticiones
-- HMAC-firmadas desde Bubble y devuelve un magic link single-use de
-- Supabase para deep-link autenticado a /ficha-cliente/?id=<bubble_id>.
--
-- Cada llamada se registra aquí (success + failure_reason) para detectar
-- abuso del shared secret y para debug.
--
-- Lectura restringida a la misma allowlist hardcoded de 5 admins que
-- usan las RPCs `ficha_cliente_listar` / `ficha_cliente_get`.
-- Escritura solo SERVICE_ROLE (la Edge Function), por tanto no necesita
-- policy de INSERT.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.bridge_audit_log (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email           text,
  bubble_id       text,
  ip              text,
  user_agent      text,
  success         boolean NOT NULL,
  failure_reason  text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS bridge_audit_log_created_at_idx
  ON public.bridge_audit_log (created_at DESC);
CREATE INDEX IF NOT EXISTS bridge_audit_log_email_idx
  ON public.bridge_audit_log (email);
CREATE INDEX IF NOT EXISTS bridge_audit_log_success_idx
  ON public.bridge_audit_log (success) WHERE success = false;

ALTER TABLE public.bridge_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admins_read_audit" ON public.bridge_audit_log;
CREATE POLICY "admins_read_audit" ON public.bridge_audit_log FOR SELECT
  USING (
    (auth.jwt() ->> 'email') IN (
      'benjamin.sanchis@thenucleo.com',
      'alejandro.lopez@thenucleo.com',
      'marketing.thenucleo@gmail.com',
      'mel.dalmazo@thenucleo.com',
      'valentina.ramirez@thenucleo.com'
    )
  );

COMMENT ON TABLE public.bridge_audit_log IS
  'Auditoría de la Edge Function bridge_from_portal (deep-link Bubble→Work). Allowlist hardcoded x5 admins.';
