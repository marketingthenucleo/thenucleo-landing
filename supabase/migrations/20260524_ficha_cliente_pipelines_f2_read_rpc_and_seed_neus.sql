-- ============================================================
-- F2.2.1: read RPC ficha_pipelines_get + migrar SEED Dra Neuss a DB
-- Aplicado: 2026-05-24
-- Migration name (Supabase): ficha_cliente_pipelines_f2_read_rpc_and_seed_neus
--
-- Cierra parte de F2.2 de la Ficha de Cliente (módulo Pipelines y
-- Campañas). Esta parte cubre LECTURAS end-to-end: RPC que devuelve el
-- árbol con la forma que el frontend ya espera + sembrar los 4 pipelines
-- de Dra Neuss que vivían hardcoded en ficha-cliente/index.html como
-- SEED, para que al cablear el frontend Melina siga viéndolos.
--
-- Decisiones:
--   - SECURITY INVOKER (no SECURITY DEFINER) → RLS via is_comunidad_admin
--     gate-ea el acceso a las 5 tablas. NO suma al contador "7 sitios"
--     de allowlist hardcoded. Coherente con la decisión §F2 de la sesión
--     2026-05-24 (ver docs/log-cambios.md entrada de hoy).
--   - El frontend espera claves cortas (code/name/obj/camps/triggers/
--     emails) → la RPC mapea explícitamente columna → key JSON-friendly.
--   - Datos extra (orden, plantillaId, canal, responsablePm, linkCopy/
--     Diseno/Ghl) se devuelven aunque el frontend actual no los lea —
--     serán útiles cuando F2.2.2 cablee escritura. No rompen.
--   - Seed Neus es idempotente (ON CONFLICT en pares únicos) — se puede
--     re-aplicar sin duplicar.
-- ============================================================

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
                    'fechaLanzamiento',  t.fecha_lanzamiento
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


-- ============================================================
-- Seed: 4 pipelines Dra Neuss (bubble_id 1773847038522x983519237604638700)
-- Mismo set que vivía en ficha-cliente/index.html lines 1694-1756 (commit
-- 67f3d21 era la versión previa). Idempotente.
-- ============================================================

-- P1 Venta directa Curso Suplementación
WITH p1 AS (
  INSERT INTO public.cliente_pipelines
    (cliente_bubble_id, codigo, nombre, objetivo_negocio, estado, responsable_account, orden)
  VALUES
    ('1773847038522x983519237604638700', 'P1',
     'Venta directa Curso Suplementación',
     'Monetizar el infoproducto Curso Suplementación 75€ a tráfico frío.',
     'activo', 'Melina Dalmazo', 1)
  ON CONFLICT (cliente_bubble_id, codigo) DO UPDATE SET nombre = EXCLUDED.nombre
  RETURNING id
),
p1c1 AS (
  INSERT INTO public.cliente_campanias
    (pipeline_id, codigo, nombre, plantilla_id, estado, fecha_inicio, presupuesto_eur, kpi_objetivo,
     link_briefing_drive, briefing_nombre, notas_account)
  SELECT
    p1.id, 'P1C1', 'Curso Suplementación 75€',
    (SELECT id FROM public.cliente_campania_plantillas WHERE slug='venta-meta'),
    'en-produccion', '2026-05-15', 500, '30 ventas/mes',
    'drive://Dra-Neuss/Campañas/P1C1 — Curso Suplementación/briefing.pdf',
    'Briefing Curso Suplementación.pdf',
    'Producto en GHL · vincular píxel ahí · funnel.neusmunozgost.com'
  FROM p1
  ON CONFLICT (pipeline_id, codigo) DO UPDATE SET nombre = EXCLUDED.nombre
  RETURNING id
)
INSERT INTO public.cliente_triggers
  (campania_id, codigo, tipo, descripcion, estado, link_externo)
SELECT p1c1.id, 'P1C1FM1', 'FM', 'Anuncio Meta → checkout', 'creado',
       'funnel.neusmunozgost.com/curso-suplementacion-clinica-40'
FROM p1c1
ON CONFLICT (campania_id, codigo) DO NOTHING;

-- P2 Captación de clientes potenciales (FM + 3 emails)
WITH p2 AS (
  INSERT INTO public.cliente_pipelines
    (cliente_bubble_id, codigo, nombre, objetivo_negocio, estado, responsable_account, orden)
  VALUES
    ('1773847038522x983519237604638700', 'P2',
     'Captación de clientes potenciales',
     'Nutrir BBDD con leads cualificados para futuras ofertas.',
     'activo', 'Melina Dalmazo', 2)
  ON CONFLICT (cliente_bubble_id, codigo) DO UPDATE SET nombre = EXCLUDED.nombre
  RETURNING id
),
p2c1 AS (
  INSERT INTO public.cliente_campanias
    (pipeline_id, codigo, nombre, plantilla_id, estado, fecha_inicio, presupuesto_eur, kpi_objetivo,
     link_briefing_drive, briefing_nombre)
  SELECT
    p2.id, 'P2C1', 'Captación leads',
    (SELECT id FROM public.cliente_campania_plantillas WHERE slug='capt-fm'),
    'en-produccion', '2026-05-20', 300, '50 leads/mes',
    'drive://Dra-Neuss/Campañas/P2C1 — Captación leads/briefing-mayo.docx',
    'Briefing captación mayo.docx'
  FROM p2
  ON CONFLICT (pipeline_id, codigo) DO UPDATE SET nombre = EXCLUDED.nombre
  RETURNING id
)
INSERT INTO public.cliente_triggers
  (campania_id, codigo, tipo, descripcion, estado, link_externo)
SELECT p2c1.id, 'P2C1FM1', 'FM', 'Formulario Meta clientes potenciales', 'creado',
       'Form ID Meta 12345'
FROM p2c1
ON CONFLICT (campania_id, codigo) DO NOTHING;

INSERT INTO public.cliente_emails (campania_id, orden, nombre, espera_desde_anterior, objetivo, estado, triggers_aplicables)
SELECT id, 1, 'Bienvenida + valor', 'Día 0',
       'Romper el hielo, dar contexto del problema.', 'activo', '{}'
FROM public.cliente_campanias WHERE codigo='P2C1' AND pipeline_id IN (
  SELECT id FROM public.cliente_pipelines
  WHERE cliente_bubble_id='1773847038522x983519237604638700' AND codigo='P2'
)
ON CONFLICT (campania_id, orden) DO NOTHING;

INSERT INTO public.cliente_emails (campania_id, orden, nombre, espera_desde_anterior, objetivo, estado, triggers_aplicables)
SELECT id, 2, 'Educación / hábitos', 'Día +2',
       'Educar sobre suplementación con evidencia.', 'declarado', '{}'
FROM public.cliente_campanias WHERE codigo='P2C1' AND pipeline_id IN (
  SELECT id FROM public.cliente_pipelines
  WHERE cliente_bubble_id='1773847038522x983519237604638700' AND codigo='P2'
)
ON CONFLICT (campania_id, orden) DO NOTHING;

INSERT INTO public.cliente_emails (campania_id, orden, nombre, espera_desde_anterior, objetivo, estado, triggers_aplicables)
SELECT id, 3, 'Oferta curso', 'Día +5',
       'Presentar curso 75€ con urgencia controlada.', 'declarado', '{}'
FROM public.cliente_campanias WHERE codigo='P2C1' AND pipeline_id IN (
  SELECT id FROM public.cliente_pipelines
  WHERE cliente_bubble_id='1773847038522x983519237604638700' AND codigo='P2'
)
ON CONFLICT (campania_id, orden) DO NOTHING;

-- P3 Reactivación de leads (BD + 1 email)
WITH p3 AS (
  INSERT INTO public.cliente_pipelines
    (cliente_bubble_id, codigo, nombre, objetivo_negocio, estado, responsable_account, orden)
  VALUES
    ('1773847038522x983519237604638700', 'P3',
     'Reactivación de leads',
     'Recuperar leads sin conversión >60d.',
     'activo', 'Melina Dalmazo', 3)
  ON CONFLICT (cliente_bubble_id, codigo) DO UPDATE SET nombre = EXCLUDED.nombre
  RETURNING id
),
p3c1 AS (
  INSERT INTO public.cliente_campanias
    (pipeline_id, codigo, nombre, plantilla_id, estado, fecha_inicio, fecha_fin, presupuesto_eur, kpi_objetivo,
     briefing_nombre, notas_account)
  SELECT
    p3.id, 'P3C1', 'Relanzamiento clientes potenciales',
    (SELECT id FROM public.cliente_campania_plantillas WHERE slug='react-bd'),
    'declarada', '2026-05-25', '2026-05-31', 0, '5% reactivación',
    'Sin briefing — Account pendiente de duplicar template',
    'Segmento: leads que no convirtieron en 60 días.'
  FROM p3
  ON CONFLICT (pipeline_id, codigo) DO UPDATE SET nombre = EXCLUDED.nombre
  RETURNING id
)
INSERT INTO public.cliente_triggers
  (campania_id, codigo, tipo, descripcion, estado, link_externo, fecha_lanzamiento)
SELECT p3c1.id, 'P3C1BD1', 'BD', 'Segmento leads sin conversión >60d', 'declarado',
       'GHL segment ID 88', '2026-05-25'
FROM p3c1
ON CONFLICT (campania_id, codigo) DO NOTHING;

INSERT INTO public.cliente_emails (campania_id, orden, nombre, espera_desde_anterior, objetivo, estado, triggers_aplicables)
SELECT id, 1, 'Reactivación', 'Día 0',
       'Recordar valor + oferta de gancho.', 'declarado', '{}'
FROM public.cliente_campanias WHERE codigo='P3C1' AND pipeline_id IN (
  SELECT id FROM public.cliente_pipelines
  WHERE cliente_bubble_id='1773847038522x983519237604638700' AND codigo='P3'
)
ON CONFLICT (campania_id, orden) DO NOTHING;

-- P4 Newsletter mensual (BD + 1 email)
WITH p4 AS (
  INSERT INTO public.cliente_pipelines
    (cliente_bubble_id, codigo, nombre, objetivo_negocio, estado, responsable_account, orden)
  VALUES
    ('1773847038522x983519237604638700', 'P4',
     'Newsletter mensual',
     'Mantener relación con BBDD activa.',
     'activo', 'Melina Dalmazo', 4)
  ON CONFLICT (cliente_bubble_id, codigo) DO UPDATE SET nombre = EXCLUDED.nombre
  RETURNING id
),
p4c1 AS (
  INSERT INTO public.cliente_campanias
    (pipeline_id, codigo, nombre, plantilla_id, estado, fecha_inicio, presupuesto_eur, kpi_objetivo,
     link_briefing_drive, briefing_nombre)
  SELECT
    p4.id, 'P4C1', 'Newsletter mayo',
    (SELECT id FROM public.cliente_campania_plantillas WHERE slug='news'),
    'en-produccion', '2026-05-20', 0, '25% apertura',
    'drive://Dra-Neuss/Campañas/P4C1 — Newsletter mayo/briefing-mayo.docx',
    'Briefing Mayo.docx'
  FROM p4
  ON CONFLICT (pipeline_id, codigo) DO UPDATE SET nombre = EXCLUDED.nombre
  RETURNING id
)
INSERT INTO public.cliente_triggers
  (campania_id, codigo, tipo, descripcion, estado, link_externo, fecha_lanzamiento)
SELECT p4c1.id, 'P4C1BD1', 'BD', 'BBDD activa', 'monitorizando',
       'Tag GHL activo', '2026-05-20'
FROM p4c1
ON CONFLICT (campania_id, codigo) DO NOTHING;

INSERT INTO public.cliente_emails (campania_id, orden, nombre, espera_desde_anterior, objetivo, estado, triggers_aplicables)
SELECT id, 1, 'Edición mayo', 'mensual',
       'Edición mensual: hábito + recurso clínico.', 'activo', '{}'
FROM public.cliente_campanias WHERE codigo='P4C1' AND pipeline_id IN (
  SELECT id FROM public.cliente_pipelines
  WHERE cliente_bubble_id='1773847038522x983519237604638700' AND codigo='P4'
)
ON CONFLICT (campania_id, orden) DO NOTHING;
