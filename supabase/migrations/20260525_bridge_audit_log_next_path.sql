-- ============================================================
-- Bridge Portal Bubble → Work — añadir columna next_path (2026-05-25)
-- ============================================================
-- Ampliación de bridge_audit_log para registrar a qué subsección de Work
-- aterriza cada deep-link autenticado: /ficha-cliente/, /estrategia/,
-- /timeline/, /catalogo/, /servicios/.
--
-- La columna es NULLABLE — registros antiguos (pre-2026-05-25) la dejan
-- vacía; nuevos registros la rellenan siempre (success + failures).
-- ============================================================

ALTER TABLE public.bridge_audit_log
  ADD COLUMN IF NOT EXISTS next_path text;

COMMENT ON COLUMN public.bridge_audit_log.next_path IS
  'Path destino del magic link tras /comunidad/entrar/?next=. Allowlist en la Edge Function (/ficha-cliente/, /estrategia/, /timeline/, /catalogo/, /servicios/). NULL en registros antes de 2026-05-25.';
