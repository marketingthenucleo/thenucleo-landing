-- ============================================================
-- Backfill plantillas + RPCs listar + archivar
-- Aplicado: 2026-05-24
-- Migration name (Supabase): ficha_cliente_plantillas_backfill_y_rpcs_listar_archivar
--
-- Cierra deuda del picker JS const → catálogo DB live + habilita
-- opción A del piloto: X en cada card de plantilla con confirm.
--
-- A. UPDATE las 5 plantillas existentes con datos completos
--    (triggers_tipicos, emails_tipicos, kpi_default, presupuesto_default,
--    briefing_master_url, roles_default) que vivían hardcoded en
--    ficha-cliente/index.html const PLANTILLAS. Frontend deja de
--    leer ese const tras este commit y carga todo desde DB via la
--    nueva RPC ficha_plantillas_listar.
--
-- B. RPC ficha_plantillas_listar(p_bubble_id text) RETURNS jsonb.
--    Devuelve plantillas estado='activa' para la agencia del cliente.
--    Resuelve agencia_id desde bub_clientes. SECURITY INVOKER + RLS.
--
-- C. RPC ficha_plantilla_archivar(p_id uuid) RETURNS jsonb.
--    Soft delete vía estado='archivada'. La plantilla queda en DB
--    (compatibilidad histórica con campañas que la referencien) pero
--    deja de aparecer en el picker. Mismo patrón conceptual que
--    ficha_archivar_codigo pero separado porque plantilla no es un
--    código del flujo PxCx, es catálogo.
-- ============================================================

UPDATE public.cliente_campania_plantillas SET
  triggers_tipicos    = '[{"tipo":"FM","nombre":"Anuncio Meta → checkout"}]'::jsonb,
  emails_tipicos      = '[]'::jsonb,
  briefing_master_url = 'drive://templates/briefing-venta-directa.docx',
  kpi_default         = 'Ventas',
  presupuesto_default = 500,
  roles_default       = '{"estaticos":"Valentin Arias","video":"Joaquin Rojo","meta":"Damian"}'::jsonb
WHERE agencia_id='1769513105728x555492736219132700' AND slug='venta-meta';

UPDATE public.cliente_campania_plantillas SET
  triggers_tipicos    = '[{"tipo":"FM","nombre":"Formulario Meta"}]'::jsonb,
  emails_tipicos      = '[{"nombre":"Bienvenida","espera":"Día 0"},{"nombre":"Valor","espera":"Día +2"},{"nombre":"Oferta","espera":"Día +5"}]'::jsonb,
  briefing_master_url = 'drive://templates/briefing-captacion-fm.docx',
  kpi_default         = 'Leads · CPL',
  presupuesto_default = 300,
  roles_default       = '{"copy":"Valentin Arias","diseno":"Valentin Arias","formulario":"Damian","ghl":"Camilo Balanta"}'::jsonb
WHERE agencia_id='1769513105728x555492736219132700' AND slug='capt-fm';

UPDATE public.cliente_campania_plantillas SET
  triggers_tipicos    = '[{"tipo":"FW","nombre":"Form en web"}]'::jsonb,
  emails_tipicos      = '[{"nombre":"Bienvenida","espera":"Día 0"},{"nombre":"Valor","espera":"Día +2"},{"nombre":"Oferta","espera":"Día +5"}]'::jsonb,
  briefing_master_url = 'drive://templates/briefing-captacion-fw.docx',
  kpi_default         = 'Leads · CPL',
  presupuesto_default = 200,
  roles_default       = '{"copy":"Valentin Arias","diseno":"Valentin Arias","form":"Dev/CRM","ghl":"Camilo Balanta"}'::jsonb
WHERE agencia_id='1769513105728x555492736219132700' AND slug='capt-fw';

UPDATE public.cliente_campania_plantillas SET
  triggers_tipicos    = '[{"tipo":"BD","nombre":"Segmento BBDD"}]'::jsonb,
  emails_tipicos      = '[{"nombre":"Reactivación","espera":"Día 0"},{"nombre":"Oferta","espera":"Día +2"},{"nombre":"Cierre","espera":"Día +5"}]'::jsonb,
  briefing_master_url = 'drive://templates/briefing-react-bd.docx',
  kpi_default         = 'Conversiones',
  presupuesto_default = 0,
  roles_default       = '{"copy":"Valentin Arias","diseno":"Valentin Arias","ghl":"Camilo Balanta"}'::jsonb
WHERE agencia_id='1769513105728x555492736219132700' AND slug='react-bd';

UPDATE public.cliente_campania_plantillas SET
  triggers_tipicos    = '[{"tipo":"BD","nombre":"BBDD activa"}]'::jsonb,
  emails_tipicos      = '[{"nombre":"Edición única","espera":"cadencia"}]'::jsonb,
  briefing_master_url = 'drive://templates/briefing-newsletter.docx',
  kpi_default         = 'Apertura · Clicks',
  presupuesto_default = 0,
  roles_default       = '{"copy":"Valentin Arias","diseno":"Valentin Arias","ghl":"Camilo Balanta"}'::jsonb
WHERE agencia_id='1769513105728x555492736219132700' AND slug='news';


CREATE OR REPLACE FUNCTION public.ficha_plantillas_listar(p_bubble_id text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_agencia_id text;
BEGIN
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

GRANT EXECUTE ON FUNCTION public.ficha_plantillas_listar(text) TO authenticated;


CREATE OR REPLACE FUNCTION public.ficha_plantilla_archivar(p_id uuid)
RETURNS jsonb
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

  UPDATE public.cliente_campania_plantillas
     SET estado = 'archivada'
   WHERE id = p_id
  RETURNING to_jsonb(cliente_campania_plantillas.*) INTO v_row;

  IF v_row IS NULL THEN
    RAISE EXCEPTION 'plantilla % no existe', p_id USING ERRCODE = '02000';
  END IF;

  RETURN v_row;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ficha_plantilla_archivar(uuid) TO authenticated;
