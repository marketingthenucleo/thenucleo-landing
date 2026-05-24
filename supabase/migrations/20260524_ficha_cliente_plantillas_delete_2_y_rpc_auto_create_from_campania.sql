-- ============================================================
-- DELETE 2 plantillas + RPC ficha_plantilla_create_from_campania
-- Aplicado: 2026-05-24
-- Migration name (Supabase): ficha_cliente_plantillas_delete_2_y_rpc_auto_create_from_campania
--
-- A. DELETE las 2 plantillas que no encajan con el workflow TheNucleo:
--    'lanz' (Lanzamiento multicanal) y 'evento' (Evento). Quedan 5:
--    venta-meta, capt-fm, capt-fw, react-bd, news.
--
-- B. RPC ficha_plantilla_create_from_campania(p_campania_id uuid):
--    crea automáticamente una plantilla SHELL en cliente_campania_plantillas
--    a partir de una campaña custom recién creada. Frontend llama a esta
--    RPC tras ficha_campania_upsert cuando state.custom===true. La
--    plantilla captura metadata (nombre, kpi_default, presupuesto_default,
--    briefing_master_url) pero NO triggers_tipicos ni emails_tipicos
--    (la campaña aún no los tiene). Luego linka la campaña a la
--    plantilla recién creada via UPDATE cliente_campanias.plantilla_id.
--
-- Slug = lowercase + translate acentos + replace no-alfanum por '-'
-- + collision handling con sufijo -N (hasta 100 intentos).
-- ============================================================

DELETE FROM public.cliente_campania_plantillas
 WHERE agencia_id = '1769513105728x555492736219132700'
   AND slug IN ('lanz', 'evento');


CREATE OR REPLACE FUNCTION public.ficha_plantilla_create_from_campania(
  p_campania_id uuid
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
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

GRANT EXECUTE ON FUNCTION public.ficha_plantilla_create_from_campania(uuid) TO authenticated;
