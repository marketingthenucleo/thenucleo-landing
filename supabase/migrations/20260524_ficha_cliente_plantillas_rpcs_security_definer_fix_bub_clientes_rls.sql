-- ============================================================
-- Fix: SECURITY DEFINER en RPCs de plantillas que leen bub_clientes
-- Aplicado: 2026-05-24
-- Migration name (Supabase): ficha_cliente_plantillas_rpcs_security_definer_fix_bub_clientes_rls
--
-- Bug detectado en piloto: el picker no mostraba ninguna plantilla.
-- Causa: ficha_plantillas_listar y ficha_plantilla_create_from_campania
-- eran SECURITY INVOKER, pero internamente leen bub_clientes para
-- derivar agencia_id desde el cliente_bubble_id. bub_clientes tiene
-- RLS activo con 0 policies para authenticated → la SELECT desde
-- INVOKER devuelve NULL → agencia_id queda NULL → listar devuelve
-- '[]', create lanza "no se pudo derivar agencia_id".
--
-- Fix: pasar las 2 RPCs a SECURITY DEFINER + gate por
-- is_comunidad_admin() al inicio. Mismo patrón que ya usa el resto
-- de RPCs admin (ficha_cliente_listar/get). No añade al contador de
-- "allowlist hardcoded" porque is_comunidad_admin lee de la tabla
-- comunidad_admins — el gate es por tabla, no hardcoded en el body.
--
-- ficha_plantilla_archivar NO necesita el cambio (solo toca
-- cliente_campania_plantillas, cuyas policies ya permiten admin).
-- ============================================================

CREATE OR REPLACE FUNCTION public.ficha_plantillas_listar(p_bubble_id text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_agencia_id text;
BEGIN
  IF NOT public.is_comunidad_admin() THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;
  IF p_bubble_id IS NULL OR p_bubble_id = '' THEN
    RAISE EXCEPTION 'p_bubble_id requerido' USING ERRCODE = '22023';
  END IF;

  SELECT agencia_id INTO v_agencia_id
  FROM public.bub_clientes
  WHERE bubble_id = p_bubble_id;

  IF v_agencia_id IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  RETURN COALESCE((
    SELECT jsonb_agg(
      jsonb_build_object(
        'id',                  plt.id,
        'slug',                plt.slug,
        'nombre',              plt.nombre,
        'descripcion',         plt.descripcion,
        'triggers_tipicos',    plt.triggers_tipicos,
        'emails_tipicos',      plt.emails_tipicos,
        'briefing_master_url', plt.briefing_master_url,
        'kpi_default',         plt.kpi_default,
        'presupuesto_default', plt.presupuesto_default,
        'roles_default',       plt.roles_default,
        'estado',              plt.estado,
        'orden',               plt.orden
      ) ORDER BY plt.orden, plt.slug
    )
    FROM public.cliente_campania_plantillas plt
    WHERE plt.agencia_id = v_agencia_id
      AND plt.estado = 'activa'
  ), '[]'::jsonb);
END;
$$;


CREATE OR REPLACE FUNCTION public.ficha_plantilla_create_from_campania(
  p_campania_id uuid
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_camp           public.cliente_campanias%ROWTYPE;
  v_cliente_bid    text;
  v_agencia_id     text;
  v_slug_base      text;
  v_slug           text;
  v_attempt        int := 0;
  v_plantilla_id   uuid;
  v_plantilla      jsonb;
BEGIN
  IF NOT public.is_comunidad_admin() THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;
  IF p_campania_id IS NULL THEN
    RAISE EXCEPTION 'p_campania_id requerido' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_camp
  FROM public.cliente_campanias
  WHERE id = p_campania_id;

  IF v_camp.id IS NULL THEN
    RAISE EXCEPTION 'campania % no existe', p_campania_id USING ERRCODE = '02000';
  END IF;

  SELECT p.cliente_bubble_id INTO v_cliente_bid
  FROM public.cliente_pipelines p
  WHERE p.id = v_camp.pipeline_id;

  SELECT agencia_id INTO v_agencia_id
  FROM public.bub_clientes
  WHERE bubble_id = v_cliente_bid;

  IF v_agencia_id IS NULL THEN
    RAISE EXCEPTION 'no se pudo derivar agencia_id desde cliente %', v_cliente_bid USING ERRCODE = '02000';
  END IF;

  v_slug_base := lower(translate(
    COALESCE(v_camp.nombre, ''),
    'áéíóúÁÉÍÓÚñÑüÜ',
    'aeiouAEIOUnNuU'
  ));
  v_slug_base := regexp_replace(v_slug_base, '[^a-z0-9]+', '-', 'g');
  v_slug_base := regexp_replace(v_slug_base, '(^-+|-+$)', '', 'g');
  IF v_slug_base = '' THEN v_slug_base := 'plantilla'; END IF;
  v_slug := v_slug_base;

  WHILE EXISTS (
    SELECT 1 FROM public.cliente_campania_plantillas
    WHERE agencia_id = v_agencia_id AND slug = v_slug
  ) LOOP
    v_attempt := v_attempt + 1;
    v_slug := v_slug_base || '-' || v_attempt::text;
    EXIT WHEN v_attempt > 100;
  END LOOP;

  INSERT INTO public.cliente_campania_plantillas
    (agencia_id, slug, nombre, descripcion,
     kpi_default, presupuesto_default, briefing_master_url,
     estado, orden)
  VALUES
    (v_agencia_id, v_slug, v_camp.nombre,
     'Plantilla auto-creada desde campaña ' || v_camp.codigo,
     v_camp.kpi_objetivo, v_camp.presupuesto_eur, v_camp.link_briefing_drive,
     'activa',
     (SELECT COALESCE(MAX(orden), 0) + 1
        FROM public.cliente_campania_plantillas
       WHERE agencia_id = v_agencia_id))
  RETURNING id INTO v_plantilla_id;

  UPDATE public.cliente_campanias
     SET plantilla_id = v_plantilla_id
   WHERE id = p_campania_id;

  SELECT to_jsonb(plt.*) INTO v_plantilla
  FROM public.cliente_campania_plantillas plt
  WHERE plt.id = v_plantilla_id;

  RETURN v_plantilla;
END;
$$;
