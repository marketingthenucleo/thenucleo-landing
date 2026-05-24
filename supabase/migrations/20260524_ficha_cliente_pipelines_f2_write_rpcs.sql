-- ============================================================
-- F2.2.2.A: 5 upsert + 1 archivar para Pipelines y Campañas
-- Aplicado: 2026-05-24
-- Migration name (Supabase): ficha_cliente_pipelines_f2_write_rpcs
--
-- Cierra la mitad write de F2.2 (queda F2.2.2.B: cableo drawers
-- frontend + refactor stateBadge).
--
-- Decisiones:
--   - SECURITY INVOKER en las 6 → RLS is_comunidad_admin() gate-ea.
--   - "Servidor propone, usuario valida": cada upsert acepta
--     p_codigo_override; si NULL/'' autocompone via regex sobre max
--     actual. Si pasa, valida unicidad via UNIQUE constraint.
--   - Regla .docx §3.4 (codes never reused) — UPDATE NO toca codigo.
--   - Regla .docx §3.6 + caso 9 — ficha_archivar_codigo cubre los 4
--     tipos. Genders: pipelines/triggers/emails 'archivado', campañas
--     'archivada' (CHECK constraints obligan).
--   - Auto-orden en pipelines (orden int per cliente) y emails (orden
--     int per campaña). Triggers ordenan por código alfabético.
--   - Frontend hará loadFor(bubbleId) tras cada save para refrescar
--     (decisión "como sea mejor" — más limpio que merge selectivo).
--
-- Smoke test (2026-05-24): DO block insertó P5 + P5C1 + P5C1FM1 +
-- P5C1BD1 (con fecha) + email + UPDATE estado → 'copy-listo' +
-- archivar pipeline + cleanup. Todo verde. RPC count = 5 nuevas
-- (ficha_archivar_codigo cuenta como las 5).
-- ============================================================


-- ---------- 1. ficha_pipeline_upsert ---------------------------------------
CREATE OR REPLACE FUNCTION public.ficha_pipeline_upsert(
  p_id                  uuid,
  p_cliente_bubble_id   text,
  p_nombre              text,
  p_objetivo_negocio    text DEFAULT NULL,
  p_estado              text DEFAULT 'activo',
  p_responsable_account text DEFAULT NULL,
  p_notas               text DEFAULT NULL,
  p_orden               int  DEFAULT NULL,
  p_codigo_override     text DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_codigo text;
  v_orden  int;
  v_row    public.cliente_pipelines%ROWTYPE;
BEGIN
  IF p_id IS NULL THEN
    IF p_cliente_bubble_id IS NULL OR p_cliente_bubble_id = '' THEN
      RAISE EXCEPTION 'p_cliente_bubble_id requerido en INSERT' USING ERRCODE = '22023';
    END IF;

    IF p_codigo_override IS NOT NULL AND p_codigo_override <> '' THEN
      v_codigo := p_codigo_override;
    ELSE
      SELECT 'P' || (COALESCE(MAX(
        NULLIF(regexp_replace(codigo, '^P', ''), '')::int
      ), 0) + 1)::text
      INTO v_codigo
      FROM public.cliente_pipelines
      WHERE cliente_bubble_id = p_cliente_bubble_id;
    END IF;

    v_orden := COALESCE(p_orden, (
      SELECT COALESCE(MAX(orden), 0) + 1
      FROM public.cliente_pipelines
      WHERE cliente_bubble_id = p_cliente_bubble_id
    ));

    INSERT INTO public.cliente_pipelines
      (cliente_bubble_id, codigo, nombre, objetivo_negocio, estado,
       responsable_account, notas, orden)
    VALUES
      (p_cliente_bubble_id, v_codigo, p_nombre, p_objetivo_negocio,
       COALESCE(p_estado, 'activo'), p_responsable_account, p_notas, v_orden)
    RETURNING * INTO v_row;
  ELSE
    UPDATE public.cliente_pipelines SET
      nombre              = COALESCE(p_nombre, nombre),
      objetivo_negocio    = COALESCE(p_objetivo_negocio, objetivo_negocio),
      estado              = COALESCE(p_estado, estado),
      responsable_account = COALESCE(p_responsable_account, responsable_account),
      notas               = COALESCE(p_notas, notas),
      orden               = COALESCE(p_orden, orden)
    WHERE id = p_id
    RETURNING * INTO v_row;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'pipeline % no existe', p_id USING ERRCODE = '02000';
    END IF;
  END IF;

  RETURN to_jsonb(v_row);
END;
$$;
GRANT EXECUTE ON FUNCTION public.ficha_pipeline_upsert(uuid, text, text, text, text, text, text, int, text) TO authenticated;


-- ---------- 2. ficha_campania_upsert ---------------------------------------
CREATE OR REPLACE FUNCTION public.ficha_campania_upsert(
  p_id                  uuid,
  p_pipeline_id         uuid,
  p_nombre              text,
  p_plantilla_id        uuid    DEFAULT NULL,
  p_estado              text    DEFAULT 'declarada',
  p_fecha_inicio        date    DEFAULT NULL,
  p_fecha_fin           date    DEFAULT NULL,
  p_presupuesto_eur     numeric DEFAULT NULL,
  p_canal_principal     text    DEFAULT NULL,
  p_kpi_objetivo        text    DEFAULT NULL,
  p_link_briefing_drive text    DEFAULT NULL,
  p_briefing_nombre     text    DEFAULT NULL,
  p_responsable_pm      text    DEFAULT NULL,
  p_notas_account       text    DEFAULT NULL,
  p_codigo_override     text    DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_pipe_codigo text;
  v_codigo      text;
  v_row         public.cliente_campanias%ROWTYPE;
BEGIN
  IF p_id IS NULL THEN
    IF p_pipeline_id IS NULL THEN
      RAISE EXCEPTION 'p_pipeline_id requerido en INSERT' USING ERRCODE = '22023';
    END IF;

    SELECT codigo INTO v_pipe_codigo
    FROM public.cliente_pipelines
    WHERE id = p_pipeline_id;

    IF v_pipe_codigo IS NULL THEN
      RAISE EXCEPTION 'pipeline % no existe', p_pipeline_id USING ERRCODE = '02000';
    END IF;

    IF p_codigo_override IS NOT NULL AND p_codigo_override <> '' THEN
      v_codigo := p_codigo_override;
    ELSE
      SELECT v_pipe_codigo || 'C' || (COALESCE(MAX(
        NULLIF(regexp_replace(codigo, '^' || v_pipe_codigo || 'C', ''), '')::int
      ), 0) + 1)::text
      INTO v_codigo
      FROM public.cliente_campanias
      WHERE pipeline_id = p_pipeline_id;
    END IF;

    INSERT INTO public.cliente_campanias
      (pipeline_id, codigo, nombre, plantilla_id, estado, fecha_inicio,
       fecha_fin, presupuesto_eur, canal_principal, kpi_objetivo,
       link_briefing_drive, briefing_nombre, responsable_pm, notas_account)
    VALUES
      (p_pipeline_id, v_codigo, p_nombre, p_plantilla_id,
       COALESCE(p_estado, 'declarada'), p_fecha_inicio, p_fecha_fin,
       p_presupuesto_eur, p_canal_principal, p_kpi_objetivo,
       p_link_briefing_drive, p_briefing_nombre, p_responsable_pm, p_notas_account)
    RETURNING * INTO v_row;
  ELSE
    UPDATE public.cliente_campanias SET
      nombre              = COALESCE(p_nombre, nombre),
      plantilla_id        = COALESCE(p_plantilla_id, plantilla_id),
      estado              = COALESCE(p_estado, estado),
      fecha_inicio        = COALESCE(p_fecha_inicio, fecha_inicio),
      fecha_fin           = COALESCE(p_fecha_fin, fecha_fin),
      presupuesto_eur     = COALESCE(p_presupuesto_eur, presupuesto_eur),
      canal_principal     = COALESCE(p_canal_principal, canal_principal),
      kpi_objetivo        = COALESCE(p_kpi_objetivo, kpi_objetivo),
      link_briefing_drive = COALESCE(p_link_briefing_drive, link_briefing_drive),
      briefing_nombre     = COALESCE(p_briefing_nombre, briefing_nombre),
      responsable_pm      = COALESCE(p_responsable_pm, responsable_pm),
      notas_account       = COALESCE(p_notas_account, notas_account)
    WHERE id = p_id
    RETURNING * INTO v_row;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'campania % no existe', p_id USING ERRCODE = '02000';
    END IF;
  END IF;

  RETURN to_jsonb(v_row);
END;
$$;
GRANT EXECUTE ON FUNCTION public.ficha_campania_upsert(uuid, uuid, text, uuid, text, date, date, numeric, text, text, text, text, text, text, text) TO authenticated;


-- ---------- 3. ficha_trigger_upsert ----------------------------------------
CREATE OR REPLACE FUNCTION public.ficha_trigger_upsert(
  p_id                uuid,
  p_campania_id       uuid,
  p_tipo              text,
  p_descripcion       text DEFAULT NULL,
  p_link_externo      text DEFAULT NULL,
  p_fecha_lanzamiento date DEFAULT NULL,
  p_estado            text DEFAULT 'declarado',
  p_codigo_override   text DEFAULT NULL
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
       fecha_lanzamiento, estado)
    VALUES
      (p_campania_id, v_codigo, p_tipo, p_descripcion, p_link_externo,
       p_fecha_lanzamiento, COALESCE(p_estado, 'declarado'))
    RETURNING * INTO v_row;
  ELSE
    -- UPDATE — codigo + tipo NO se tocan
    UPDATE public.cliente_triggers SET
      descripcion       = COALESCE(p_descripcion, descripcion),
      link_externo      = COALESCE(p_link_externo, link_externo),
      fecha_lanzamiento = COALESCE(p_fecha_lanzamiento, fecha_lanzamiento),
      estado            = COALESCE(p_estado, estado)
    WHERE id = p_id
    RETURNING * INTO v_row;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'trigger % no existe', p_id USING ERRCODE = '02000';
    END IF;
  END IF;

  RETURN to_jsonb(v_row);
END;
$$;
GRANT EXECUTE ON FUNCTION public.ficha_trigger_upsert(uuid, uuid, text, text, text, date, text, text) TO authenticated;


-- ---------- 4. ficha_email_upsert ------------------------------------------
-- Emails NO tienen columna codigo — el código display se deriva en
-- frontend via emailCode(camp, email) en función de orden + triggers_aplicables.
CREATE OR REPLACE FUNCTION public.ficha_email_upsert(
  p_id                    uuid,
  p_campania_id           uuid,
  p_nombre                text,
  p_orden                 int     DEFAULT NULL,
  p_espera_desde_anterior text    DEFAULT NULL,
  p_objetivo              text    DEFAULT NULL,
  p_triggers_aplicables   text[]  DEFAULT '{}',
  p_link_copy_drive       text    DEFAULT NULL,
  p_link_diseno_drive     text    DEFAULT NULL,
  p_link_ghl_workflow     text    DEFAULT NULL,
  p_estado                text    DEFAULT 'declarado'
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_orden int;
  v_row   public.cliente_emails%ROWTYPE;
BEGIN
  IF p_id IS NULL THEN
    IF p_campania_id IS NULL THEN
      RAISE EXCEPTION 'p_campania_id requerido en INSERT' USING ERRCODE = '22023';
    END IF;

    v_orden := COALESCE(p_orden, (
      SELECT COALESCE(MAX(orden), 0) + 1
      FROM public.cliente_emails
      WHERE campania_id = p_campania_id
    ));

    INSERT INTO public.cliente_emails
      (campania_id, orden, nombre, espera_desde_anterior, objetivo,
       triggers_aplicables, link_copy_drive, link_diseno_drive,
       link_ghl_workflow, estado)
    VALUES
      (p_campania_id, v_orden, p_nombre, p_espera_desde_anterior, p_objetivo,
       COALESCE(p_triggers_aplicables, '{}'), p_link_copy_drive, p_link_diseno_drive,
       p_link_ghl_workflow, COALESCE(p_estado, 'declarado'))
    RETURNING * INTO v_row;
  ELSE
    UPDATE public.cliente_emails SET
      nombre                = COALESCE(p_nombre, nombre),
      orden                 = COALESCE(p_orden, orden),
      espera_desde_anterior = COALESCE(p_espera_desde_anterior, espera_desde_anterior),
      objetivo              = COALESCE(p_objetivo, objetivo),
      triggers_aplicables   = COALESCE(p_triggers_aplicables, triggers_aplicables),
      link_copy_drive       = COALESCE(p_link_copy_drive, link_copy_drive),
      link_diseno_drive     = COALESCE(p_link_diseno_drive, link_diseno_drive),
      link_ghl_workflow     = COALESCE(p_link_ghl_workflow, link_ghl_workflow),
      estado                = COALESCE(p_estado, estado)
    WHERE id = p_id
    RETURNING * INTO v_row;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'email % no existe', p_id USING ERRCODE = '02000';
    END IF;
  END IF;

  RETURN to_jsonb(v_row);
END;
$$;
GRANT EXECUTE ON FUNCTION public.ficha_email_upsert(uuid, uuid, text, int, text, text, text[], text, text, text, text) TO authenticated;


-- ---------- 5. ficha_archivar_codigo (genérico para los 4 tipos) -----------
-- Regla .docx §3.6 + caso 9: nada se borra, sólo archivar.
-- Genders varían: pipelines/triggers/emails 'archivado', campañas 'archivada'.
CREATE OR REPLACE FUNCTION public.ficha_archivar_codigo(
  p_kind text,    -- 'pipeline' | 'campania' | 'trigger' | 'email'
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
    ELSE
      RAISE EXCEPTION 'p_kind invalido (%) — usar pipeline|campania|trigger|email', p_kind
        USING ERRCODE = '22023';
  END CASE;

  IF v_row IS NULL THEN
    RAISE EXCEPTION '% % no existe', p_kind, p_id USING ERRCODE = '02000';
  END IF;

  RETURN v_row;
END;
$$;
GRANT EXECUTE ON FUNCTION public.ficha_archivar_codigo(text, uuid) TO authenticated;
