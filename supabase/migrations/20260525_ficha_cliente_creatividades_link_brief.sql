-- ============================================================
-- F2.5b — Link al brief de cada creatividad (2026-05-25)
-- ============================================================
-- Cada declaración de creatividad (estatico ×3, reel ×2…) puede llevar
-- su propio brief en Drive: mood boards, guion, referencias, copy ideas.
-- Mejor por-row que por-campaña porque tipos distintos llevan briefs
-- distintos. El brief macro de la Campaña sigue en cliente_campanias.link_briefing_drive.
-- ============================================================

ALTER TABLE public.cliente_creatividades
  ADD COLUMN IF NOT EXISTS link_brief_drive text;

COMMENT ON COLUMN public.cliente_creatividades.link_brief_drive IS
  'URL del brief específico de esta declaración en Drive (mood board, guion, referencias). Opcional. Distinto del briefing macro de la Campaña.';

-- Update RPC para aceptar el nuevo param
CREATE OR REPLACE FUNCTION public.ficha_creatividad_upsert(
  p_id              uuid,
  p_campania_id     uuid,
  p_tipo            text,
  p_cantidad        int  DEFAULT 1,
  p_notas           text DEFAULT NULL,
  p_estado          text DEFAULT 'declarada',
  p_orden           int  DEFAULT NULL,
  p_link_brief_drive text DEFAULT NULL
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
      (campania_id, tipo, cantidad, notas, estado, orden, link_brief_drive)
    VALUES
      (p_campania_id, p_tipo, COALESCE(p_cantidad, 1), p_notas,
       COALESCE(p_estado, 'declarada'), v_orden, p_link_brief_drive)
    RETURNING * INTO v_row;
  ELSE
    UPDATE public.cliente_creatividades SET
      tipo             = COALESCE(p_tipo, tipo),
      cantidad         = COALESCE(p_cantidad, cantidad),
      notas            = COALESCE(p_notas, notas),
      estado           = COALESCE(p_estado, estado),
      orden            = COALESCE(p_orden, orden),
      link_brief_drive = COALESCE(p_link_brief_drive, link_brief_drive)
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
  uuid, uuid, text, int, text, text, int, text
) TO authenticated;

-- ficha_pipelines_get: añadir linkBrief al jsonb de creatividades.
-- (Body completo no se repite aquí — la migration de F2.5 ya tiene el shape;
-- esta migration solo añade 'linkBrief', cr.link_brief_drive.)
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
        'id', p.id, 'code', p.codigo, 'name', p.nombre, 'obj', p.objetivo_negocio,
        'estado', p.estado, 'account', p.responsable_account, 'notas', p.notas, 'orden', p.orden,
        'camps', COALESCE((
          SELECT jsonb_agg(
            jsonb_build_object(
              'id', c.id, 'code', c.codigo, 'name', c.nombre,
              'plantillaId', c.plantilla_id, 'plantillaSlug', pl.slug,
              'estado', c.estado, 'desde', c.fecha_inicio, 'hasta', c.fecha_fin,
              'presup', c.presupuesto_eur, 'canal', c.canal_principal,
              'kpi', c.kpi_objetivo, 'briefingUrl', c.link_briefing_drive,
              'briefingName', c.briefing_nombre, 'responsablePm', c.responsable_pm,
              'notas', c.notas_account,
              'triggers', COALESCE((
                SELECT jsonb_agg(jsonb_build_object(
                  'id', t.id, 'code', t.codigo, 'tipo', t.tipo,
                  'name', t.descripcion, 'estado', t.estado,
                  'ext', t.link_externo, 'fechaLanzamiento', t.fecha_lanzamiento,
                  'camposCapturar', t.campos_capturar
                ) ORDER BY t.codigo)
                FROM public.cliente_triggers t WHERE t.campania_id = c.id
              ), '[]'::jsonb),
              'emails', COALESCE((
                SELECT jsonb_agg(jsonb_build_object(
                  'id', e.id, 'name', e.nombre, 'orden', e.orden,
                  'espera', e.espera_desde_anterior, 'estado', e.estado,
                  'objetivo', e.objetivo, 'triggersAplicables', e.triggers_aplicables,
                  'linkCopy', e.link_copy_drive, 'linkDiseno', e.link_diseno_drive,
                  'linkGhl', e.link_ghl_workflow
                ) ORDER BY e.orden)
                FROM public.cliente_emails e WHERE e.campania_id = c.id
              ), '[]'::jsonb),
              'whatsapps', COALESCE((
                SELECT jsonb_agg(jsonb_build_object(
                  'id', w.id, 'name', w.nombre, 'orden', w.orden,
                  'espera', w.espera_desde_anterior, 'estado', w.estado,
                  'objetivo', w.objetivo, 'triggersAplicables', w.triggers_aplicables,
                  'linkCopy', w.link_copy_drive, 'linkWorkflow', w.link_workflow
                ) ORDER BY w.orden)
                FROM public.cliente_mensajes_whatsapp w WHERE w.campania_id = c.id
              ), '[]'::jsonb),
              'creatividades', COALESCE((
                SELECT jsonb_agg(jsonb_build_object(
                  'id', cr.id, 'tipo', cr.tipo, 'cantidad', cr.cantidad,
                  'notas', cr.notas, 'estado', cr.estado, 'orden', cr.orden,
                  'linkBrief', cr.link_brief_drive
                ) ORDER BY cr.orden, cr.created_at)
                FROM public.cliente_creatividades cr WHERE cr.campania_id = c.id
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
