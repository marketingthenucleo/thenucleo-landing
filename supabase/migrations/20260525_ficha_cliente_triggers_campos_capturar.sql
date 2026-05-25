-- ============================================================
-- F2.3 — Campos a capturar en triggers FM/FW (2026-05-25)
-- ============================================================
-- Account declara qué campos pide el formulario (defaults nombre/email/
-- telefono + extras editables). Sirve de spec para Media Buyer (FM) o
-- Dev/CRM (FW). En BD no aplica (la lista ya viene hecha).
--
-- Cambios:
--   1) ALTER TABLE cliente_triggers ADD campos_capturar jsonb.
--   2) Reemplazar ficha_trigger_upsert para aceptar p_campos_capturar.
--   3) ficha_pipelines_get incluye camposCapturar en cada trigger.
--
-- Iniciador: feedback Ben 2026-05-25 — "cuando elija FW quizá Account
-- rellena inputs personalizados (nombre+tel+email + extras). FM también
-- conviene porque Account define qué pide el cliente, aunque Media
-- Buyer lo monte en Meta Ads Manager."
-- ============================================================

-- ---------- 1. Columna campos_capturar -------------------------------
ALTER TABLE public.cliente_triggers
  ADD COLUMN IF NOT EXISTS campos_capturar jsonb NOT NULL
    DEFAULT '{"defaults":["nombre","email","telefono"],"extras":[]}'::jsonb;

COMMENT ON COLUMN public.cliente_triggers.campos_capturar IS
  'Spec de campos a capturar en formularios FM/FW. Forma: {"defaults":["nombre","email","telefono"], "extras":["edad","ciudad",...]}. En tipo BD se ignora (la lista ya viene hecha).';


-- ---------- 2. ficha_trigger_upsert: añadir p_campos_capturar ---------
DROP FUNCTION IF EXISTS public.ficha_trigger_upsert(uuid, uuid, text, text, text, date, text, text);

CREATE OR REPLACE FUNCTION public.ficha_trigger_upsert(
  p_id                uuid,
  p_campania_id       uuid,
  p_tipo              text,
  p_descripcion       text  DEFAULT NULL,
  p_link_externo      text  DEFAULT NULL,
  p_fecha_lanzamiento date  DEFAULT NULL,
  p_estado            text  DEFAULT 'declarado',
  p_codigo_override   text  DEFAULT NULL,
  p_campos_capturar   jsonb DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_camp_codigo text;
  v_codigo      text;
  v_row         public.cliente_triggers%ROWTYPE;
BEGIN
  IF p_id IS NULL THEN
    IF p_campania_id IS NULL THEN
      RAISE EXCEPTION 'p_campania_id requerido en INSERT' USING ERRCODE = '22023';
    END IF;
    IF p_tipo NOT IN ('FM','FW','BD') THEN
      RAISE EXCEPTION 'tipo invalido (%) — usar FM/FW/BD', p_tipo USING ERRCODE = '22023';
    END IF;

    SELECT codigo INTO v_camp_codigo
    FROM public.cliente_campanias
    WHERE id = p_campania_id;

    IF v_camp_codigo IS NULL THEN
      RAISE EXCEPTION 'campania % no existe', p_campania_id USING ERRCODE = '02000';
    END IF;

    IF p_codigo_override IS NOT NULL AND p_codigo_override <> '' THEN
      v_codigo := p_codigo_override;
    ELSE
      SELECT v_camp_codigo || p_tipo || (COALESCE(MAX(
        NULLIF(regexp_replace(codigo, '^' || v_camp_codigo || p_tipo, ''), '')::int
      ), 0) + 1)::text
      INTO v_codigo
      FROM public.cliente_triggers
      WHERE campania_id = p_campania_id AND tipo = p_tipo;
    END IF;

    INSERT INTO public.cliente_triggers
      (campania_id, codigo, tipo, descripcion, link_externo,
       fecha_lanzamiento, estado, campos_capturar)
    VALUES
      (p_campania_id, v_codigo, p_tipo, p_descripcion, p_link_externo,
       p_fecha_lanzamiento, COALESCE(p_estado, 'declarado'),
       COALESCE(p_campos_capturar,
                '{"defaults":["nombre","email","telefono"],"extras":[]}'::jsonb))
    RETURNING * INTO v_row;
  ELSE
    -- UPDATE — codigo + tipo NO se tocan
    UPDATE public.cliente_triggers SET
      descripcion       = COALESCE(p_descripcion, descripcion),
      link_externo      = COALESCE(p_link_externo, link_externo),
      fecha_lanzamiento = COALESCE(p_fecha_lanzamiento, fecha_lanzamiento),
      estado            = COALESCE(p_estado, estado),
      campos_capturar   = COALESCE(p_campos_capturar, campos_capturar)
    WHERE id = p_id
    RETURNING * INTO v_row;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'trigger % no existe', p_id USING ERRCODE = '02000';
    END IF;
  END IF;

  RETURN to_jsonb(v_row);
END;
$$;

GRANT EXECUTE ON FUNCTION public.ficha_trigger_upsert(
  uuid, uuid, text, text, text, date, text, text, jsonb
) TO authenticated;


-- ---------- 3. ficha_pipelines_get: incluir camposCapturar -----------
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
