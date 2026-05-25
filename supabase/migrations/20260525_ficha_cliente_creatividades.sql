-- ============================================================
-- F2.5 — Creatividades declarativas por Campaña (2026-05-25)
-- ============================================================
-- Account declara qué piezas necesita la Campaña (estáticos, reels,
-- carruseles, copies RRSS, vídeos…) con cantidad + notas + estado.
-- Cuelgan de la Campaña (caso 10 .docx — viven en PxCx, no en E ni FM).
--
-- 1 fila = 1 declaración tipo-cantidad. Los archivos individuales (con
-- sus versiones v1, v2, v3…) viven en Drive con nomenclatura
-- PxCx_<tipo>_v<n>. La ficha solo tracksdeclaración + estado del grupo.
--
-- Iniciador: feedback Ben 2026-05-25 — "varolalo tu de tener dentro de
-- la campaña ya: Triggers, Email, Creativos para campaña, Reels,
-- Carrouseles".
-- ============================================================

-- ---------- 1. Tabla cliente_creatividades --------------------------
CREATE TABLE IF NOT EXISTS public.cliente_creatividades (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campania_id   uuid NOT NULL REFERENCES public.cliente_campanias(id) ON DELETE CASCADE,
  tipo          text NOT NULL
    CHECK (tipo IN ('estatico','reel','carrusel','copy_RRSS','video','otro')),
  cantidad      int  NOT NULL DEFAULT 1 CHECK (cantidad > 0),
  notas         text,
  estado        text NOT NULL DEFAULT 'declarada'
    CHECK (estado IN ('declarada','en-produccion','lista','aprobada','archivada')),
  orden         int NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  created_by    text DEFAULT auth.email()
);

CREATE INDEX IF NOT EXISTS cliente_creatividades_campania_idx
  ON public.cliente_creatividades(campania_id);

COMMENT ON TABLE public.cliente_creatividades IS
  'Declaración de creatividades necesarias por Campaña (estáticos, reels, etc). 1 fila = 1 grupo (tipo + cantidad). Versiones individuales viven en Drive.';


-- ---------- 2. Trigger updated_at -----------------------------------
DROP TRIGGER IF EXISTS cliente_creatividades_updated_at ON public.cliente_creatividades;
CREATE TRIGGER cliente_creatividades_updated_at
  BEFORE UPDATE ON public.cliente_creatividades
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


-- ---------- 3. RLS + GRANTs ----------------------------------------
ALTER TABLE public.cliente_creatividades ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cr_select ON public.cliente_creatividades;
DROP POLICY IF EXISTS cr_insert ON public.cliente_creatividades;
DROP POLICY IF EXISTS cr_update ON public.cliente_creatividades;
DROP POLICY IF EXISTS cr_delete ON public.cliente_creatividades;

CREATE POLICY cr_select ON public.cliente_creatividades
  FOR SELECT TO authenticated
  USING (public.is_comunidad_admin());
CREATE POLICY cr_insert ON public.cliente_creatividades
  FOR INSERT TO authenticated
  WITH CHECK (public.is_comunidad_admin());
CREATE POLICY cr_update ON public.cliente_creatividades
  FOR UPDATE TO authenticated
  USING (public.is_comunidad_admin())
  WITH CHECK (public.is_comunidad_admin());
CREATE POLICY cr_delete ON public.cliente_creatividades
  FOR DELETE TO authenticated
  USING (public.is_comunidad_admin());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.cliente_creatividades TO authenticated;
GRANT ALL ON public.cliente_creatividades TO service_role;


-- ---------- 4. RPC ficha_creatividad_upsert -------------------------
CREATE OR REPLACE FUNCTION public.ficha_creatividad_upsert(
  p_id          uuid,
  p_campania_id uuid,
  p_tipo        text,
  p_cantidad    int  DEFAULT 1,
  p_notas       text DEFAULT NULL,
  p_estado      text DEFAULT 'declarada',
  p_orden       int  DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_orden int;
  v_row   public.cliente_creatividades%ROWTYPE;
BEGIN
  IF p_id IS NULL THEN
    IF p_campania_id IS NULL THEN
      RAISE EXCEPTION 'p_campania_id requerido en INSERT' USING ERRCODE = '22023';
    END IF;
    IF p_tipo NOT IN ('estatico','reel','carrusel','copy_RRSS','video','otro') THEN
      RAISE EXCEPTION 'tipo invalido (%) — usar estatico|reel|carrusel|copy_RRSS|video|otro', p_tipo
        USING ERRCODE = '22023';
    END IF;
    v_orden := COALESCE(p_orden, (
      SELECT COALESCE(MAX(orden), 0) + 1
      FROM public.cliente_creatividades
      WHERE campania_id = p_campania_id
    ));
    INSERT INTO public.cliente_creatividades
      (campania_id, tipo, cantidad, notas, estado, orden)
    VALUES
      (p_campania_id, p_tipo, COALESCE(p_cantidad, 1), p_notas,
       COALESCE(p_estado, 'declarada'), v_orden)
    RETURNING * INTO v_row;
  ELSE
    UPDATE public.cliente_creatividades SET
      tipo     = COALESCE(p_tipo, tipo),
      cantidad = COALESCE(p_cantidad, cantidad),
      notas    = COALESCE(p_notas, notas),
      estado   = COALESCE(p_estado, estado),
      orden    = COALESCE(p_orden, orden)
    WHERE id = p_id
    RETURNING * INTO v_row;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'creatividad % no existe', p_id USING ERRCODE = '02000';
    END IF;
  END IF;
  RETURN to_jsonb(v_row);
END;
$$;

GRANT EXECUTE ON FUNCTION public.ficha_creatividad_upsert(
  uuid, uuid, text, int, text, text, int
) TO authenticated;


-- ---------- 5. ficha_archivar_codigo: kind 'creatividad' ------------
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
    WHEN 'creatividad' THEN
      UPDATE public.cliente_creatividades SET estado = 'archivada'
       WHERE id = p_id
      RETURNING to_jsonb(cliente_creatividades.*) INTO v_row;
    ELSE
      RAISE EXCEPTION 'p_kind invalido (%) — usar pipeline|campania|trigger|email|whatsapp|creatividad', p_kind
        USING ERRCODE = '22023';
  END CASE;

  IF v_row IS NULL THEN
    RAISE EXCEPTION '% % no existe', p_kind, p_id USING ERRCODE = '02000';
  END IF;

  RETURN v_row;
END;
$$;
GRANT EXECUTE ON FUNCTION public.ficha_archivar_codigo(text, uuid) TO authenticated;


-- ---------- 6. ficha_pipelines_get: incluir creatividades -----------
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
              ), '[]'::jsonb),
              'creatividades', COALESCE((
                SELECT jsonb_agg(
                  jsonb_build_object(
                    'id',       cr.id,
                    'tipo',     cr.tipo,
                    'cantidad', cr.cantidad,
                    'notas',    cr.notas,
                    'estado',   cr.estado,
                    'orden',    cr.orden
                  ) ORDER BY cr.orden, cr.created_at
                )
                FROM public.cliente_creatividades cr
                WHERE cr.campania_id = c.id
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
