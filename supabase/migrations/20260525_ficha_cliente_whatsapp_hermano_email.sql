-- ============================================================
-- F2.4 — WhatsApp como hermano de Email (2026-05-25)
-- ============================================================
-- Nueva tabla cliente_mensajes_whatsapp paralela a cliente_emails.
-- Misma forma + scope (triggers_aplicables) + numeración independiente
-- por scope (mismo modelo que emails).
-- Códigos display: P1C1WA1 (shared), P1C1FM1WA1 (específico para FM1).
--
-- Decisión: NO unificar como cliente_mensajes con `canal`. Razones:
--   - El copy del email no aplica al copy de WhatsApp (longitud, tono,
--     formato distintos). Las secuencias son independientes por canal.
--   - Mantener tablas separadas evita el doble índice (UNIQUE por orden
--     se confunde si compartes filas).
--   - Permite añadir columnas específicas de WhatsApp (link_workflow
--     en vez de link_ghl_workflow) sin contaminar emails.
-- ============================================================

-- ---------- 1. Tabla cliente_mensajes_whatsapp -----------------------
CREATE TABLE IF NOT EXISTS public.cliente_mensajes_whatsapp (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campania_id           uuid NOT NULL REFERENCES public.cliente_campanias(id) ON DELETE CASCADE,
  orden                 int NOT NULL,
  nombre                text NOT NULL,
  espera_desde_anterior text,
  objetivo              text,
  triggers_aplicables   text[] NOT NULL DEFAULT '{}',
  link_copy_drive       text,
  link_workflow         text,
  estado                text NOT NULL DEFAULT 'declarado'
    CHECK (estado IN ('declarado','copy-listo','montado-ghl','activo','archivado')),
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  created_by            text DEFAULT auth.email(),
  UNIQUE (campania_id, orden)
);

CREATE INDEX IF NOT EXISTS cliente_mensajes_whatsapp_campania_idx
  ON public.cliente_mensajes_whatsapp(campania_id);

COMMENT ON TABLE public.cliente_mensajes_whatsapp IS
  'Mensajes WhatsApp como secuencia hermana de cliente_emails. Códigos display PxCxWAn (shared) o PxCxFMnWAn (específico).';


-- ---------- 2. Trigger updated_at -----------------------------------
DROP TRIGGER IF EXISTS cliente_mensajes_whatsapp_updated_at ON public.cliente_mensajes_whatsapp;
CREATE TRIGGER cliente_mensajes_whatsapp_updated_at
  BEFORE UPDATE ON public.cliente_mensajes_whatsapp
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


-- ---------- 3. RLS + GRANTs ----------------------------------------
ALTER TABLE public.cliente_mensajes_whatsapp ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cmw_select ON public.cliente_mensajes_whatsapp;
DROP POLICY IF EXISTS cmw_insert ON public.cliente_mensajes_whatsapp;
DROP POLICY IF EXISTS cmw_update ON public.cliente_mensajes_whatsapp;
DROP POLICY IF EXISTS cmw_delete ON public.cliente_mensajes_whatsapp;

CREATE POLICY cmw_select ON public.cliente_mensajes_whatsapp
  FOR SELECT TO authenticated
  USING (public.is_comunidad_admin());
CREATE POLICY cmw_insert ON public.cliente_mensajes_whatsapp
  FOR INSERT TO authenticated
  WITH CHECK (public.is_comunidad_admin());
CREATE POLICY cmw_update ON public.cliente_mensajes_whatsapp
  FOR UPDATE TO authenticated
  USING (public.is_comunidad_admin())
  WITH CHECK (public.is_comunidad_admin());
CREATE POLICY cmw_delete ON public.cliente_mensajes_whatsapp
  FOR DELETE TO authenticated
  USING (public.is_comunidad_admin());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.cliente_mensajes_whatsapp TO authenticated;
GRANT ALL ON public.cliente_mensajes_whatsapp TO service_role;


-- ---------- 4. RPC ficha_whatsapp_upsert ----------------------------
CREATE OR REPLACE FUNCTION public.ficha_whatsapp_upsert(
  p_id                    uuid,
  p_campania_id           uuid,
  p_nombre                text,
  p_orden                 int     DEFAULT NULL,
  p_espera_desde_anterior text    DEFAULT NULL,
  p_objetivo              text    DEFAULT NULL,
  p_triggers_aplicables   text[]  DEFAULT '{}',
  p_link_copy_drive       text    DEFAULT NULL,
  p_link_workflow         text    DEFAULT NULL,
  p_estado                text    DEFAULT 'declarado'
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_orden int;
  v_row   public.cliente_mensajes_whatsapp%ROWTYPE;
BEGIN
  IF p_id IS NULL THEN
    IF p_campania_id IS NULL THEN
      RAISE EXCEPTION 'p_campania_id requerido en INSERT' USING ERRCODE = '22023';
    END IF;
    v_orden := COALESCE(p_orden, (
      SELECT COALESCE(MAX(orden), 0) + 1
      FROM public.cliente_mensajes_whatsapp
      WHERE campania_id = p_campania_id
    ));
    INSERT INTO public.cliente_mensajes_whatsapp
      (campania_id, orden, nombre, espera_desde_anterior, objetivo,
       triggers_aplicables, link_copy_drive, link_workflow, estado)
    VALUES
      (p_campania_id, v_orden, p_nombre, p_espera_desde_anterior, p_objetivo,
       COALESCE(p_triggers_aplicables, '{}'), p_link_copy_drive, p_link_workflow,
       COALESCE(p_estado, 'declarado'))
    RETURNING * INTO v_row;
  ELSE
    UPDATE public.cliente_mensajes_whatsapp SET
      nombre                = COALESCE(p_nombre, nombre),
      orden                 = COALESCE(p_orden, orden),
      espera_desde_anterior = COALESCE(p_espera_desde_anterior, espera_desde_anterior),
      objetivo              = COALESCE(p_objetivo, objetivo),
      triggers_aplicables   = COALESCE(p_triggers_aplicables, triggers_aplicables),
      link_copy_drive       = COALESCE(p_link_copy_drive, link_copy_drive),
      link_workflow         = COALESCE(p_link_workflow, link_workflow),
      estado                = COALESCE(p_estado, estado)
    WHERE id = p_id
    RETURNING * INTO v_row;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'whatsapp % no existe', p_id USING ERRCODE = '02000';
    END IF;
  END IF;
  RETURN to_jsonb(v_row);
END;
$$;

GRANT EXECUTE ON FUNCTION public.ficha_whatsapp_upsert(
  uuid, uuid, text, int, text, text, text[], text, text, text
) TO authenticated;


-- ---------- 5. ficha_archivar_codigo: kind 'whatsapp' ---------------
CREATE OR REPLACE FUNCTION public.ficha_archivar_codigo(
  p_kind text,
  p_id   uuid
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_row jsonb;
BEGIN
  IF p_id IS NULL THEN
    RAISE EXCEPTION 'p_id requerido' USING ERRCODE = '22023';
  END IF;

  CASE p_kind
    WHEN 'pipeline' THEN
      UPDATE public.cliente_pipelines SET estado = 'archivado'
       WHERE id = p_id
      RETURNING to_jsonb(cliente_pipelines.*) INTO v_row;
    WHEN 'campania' THEN
      UPDATE public.cliente_campanias SET estado = 'archivada'
       WHERE id = p_id
      RETURNING to_jsonb(cliente_campanias.*) INTO v_row;
    WHEN 'trigger' THEN
      UPDATE public.cliente_triggers SET estado = 'archivado'
       WHERE id = p_id
      RETURNING to_jsonb(cliente_triggers.*) INTO v_row;
    WHEN 'email' THEN
      UPDATE public.cliente_emails SET estado = 'archivado'
       WHERE id = p_id
      RETURNING to_jsonb(cliente_emails.*) INTO v_row;
    WHEN 'whatsapp' THEN
      UPDATE public.cliente_mensajes_whatsapp SET estado = 'archivado'
       WHERE id = p_id
      RETURNING to_jsonb(cliente_mensajes_whatsapp.*) INTO v_row;
    ELSE
      RAISE EXCEPTION 'p_kind invalido (%) — usar pipeline|campania|trigger|email|whatsapp', p_kind
        USING ERRCODE = '22023';
  END CASE;

  IF v_row IS NULL THEN
    RAISE EXCEPTION '% % no existe', p_kind, p_id USING ERRCODE = '02000';
  END IF;

  RETURN v_row;
END;
$$;
GRANT EXECUTE ON FUNCTION public.ficha_archivar_codigo(text, uuid) TO authenticated;


-- ---------- 6. ficha_pipelines_get: incluir whatsapps por campaña ----
CREATE OR REPLACE FUNCTION public.ficha_pipelines_get(p_bubble_id text)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id',      p.id,
        'code',    p.codigo,
        'name',    p.nombre,
        'obj',     p.objetivo_negocio,
        'estado',  p.estado,
        'account', p.responsable_account,
        'notas',   p.notas,
        'orden',   p.orden,
        'camps', COALESCE((
          SELECT jsonb_agg(
            jsonb_build_object(
              'id',            c.id,
              'code',          c.codigo,
              'name',          c.nombre,
              'plantillaId',   c.plantilla_id,
              'plantillaSlug', pl.slug,
              'estado',        c.estado,
              'desde',         c.fecha_inicio,
              'hasta',         c.fecha_fin,
              'presup',        c.presupuesto_eur,
              'canal',         c.canal_principal,
              'kpi',           c.kpi_objetivo,
              'briefingUrl',   c.link_briefing_drive,
              'briefingName',  c.briefing_nombre,
              'responsablePm', c.responsable_pm,
              'notas',         c.notas_account,
              'triggers', COALESCE((
                SELECT jsonb_agg(
                  jsonb_build_object(
                    'id',                t.id,
                    'code',              t.codigo,
                    'tipo',              t.tipo,
                    'name',              t.descripcion,
                    'estado',            t.estado,
                    'ext',               t.link_externo,
                    'fechaLanzamiento',  t.fecha_lanzamiento,
                    'camposCapturar',    t.campos_capturar
                  ) ORDER BY t.codigo
                )
                FROM public.cliente_triggers t
                WHERE t.campania_id = c.id
              ), '[]'::jsonb),
              'emails', COALESCE((
                SELECT jsonb_agg(
                  jsonb_build_object(
                    'id',                  e.id,
                    'name',                e.nombre,
                    'orden',               e.orden,
                    'espera',              e.espera_desde_anterior,
                    'estado',              e.estado,
                    'objetivo',            e.objetivo,
                    'triggersAplicables',  e.triggers_aplicables,
                    'linkCopy',            e.link_copy_drive,
                    'linkDiseno',          e.link_diseno_drive,
                    'linkGhl',             e.link_ghl_workflow
                  ) ORDER BY e.orden
                )
                FROM public.cliente_emails e
                WHERE e.campania_id = c.id
              ), '[]'::jsonb),
              'whatsapps', COALESCE((
                SELECT jsonb_agg(
                  jsonb_build_object(
                    'id',                  w.id,
                    'name',                w.nombre,
                    'orden',               w.orden,
                    'espera',              w.espera_desde_anterior,
                    'estado',              w.estado,
                    'objetivo',            w.objetivo,
                    'triggersAplicables',  w.triggers_aplicables,
                    'linkCopy',            w.link_copy_drive,
                    'linkWorkflow',        w.link_workflow
                  ) ORDER BY w.orden
                )
                FROM public.cliente_mensajes_whatsapp w
                WHERE w.campania_id = c.id
              ), '[]'::jsonb)
            ) ORDER BY c.codigo
          )
          FROM public.cliente_campanias c
          LEFT JOIN public.cliente_campania_plantillas pl ON pl.id = c.plantilla_id
          WHERE c.pipeline_id = p.id
        ), '[]'::jsonb)
      ) ORDER BY p.orden, p.codigo
    ), '[]'::jsonb
  )
  FROM public.cliente_pipelines p
  WHERE p.cliente_bubble_id = p_bubble_id;
$$;

GRANT EXECUTE ON FUNCTION public.ficha_pipelines_get(text) TO authenticated;
