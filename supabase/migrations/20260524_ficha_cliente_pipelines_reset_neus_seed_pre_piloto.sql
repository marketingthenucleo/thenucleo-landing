-- ============================================================
-- Reset: vaciar pipelines/campañas/triggers/emails de Dra Neuss
-- Aplicado: 2026-05-24
-- Migration name (Supabase): ficha_cliente_pipelines_reset_neus_seed_pre_piloto
--
-- Motivo: el SEED migrado en F2.2.1 (los 4 pipelines de Neus) venía
-- del frontend, que a su vez era una reconstrucción post-hoc de 60
-- tareas observadas en Notion entre marzo→mayo 2026
-- (docs/portal/ficha-cliente.md §8). Esa dirección es la INVERSA del
-- modelo correcto:
--
--   ficha (Account declara) → tarea Notion → equipo ejecuta en
--   Meta/GHL/Drive → link_externo capturado en la ficha
--
-- La ficha es UPSTREAM (declara intent), Notion/Meta/GHL son
-- DOWNSTREAM (ejecutan). Sembrar datos "inferidos del downstream"
-- rompe el sentido del modelo y enseña la herramienta al revés.
--
-- Solución limpia: borrar los 4 pipelines de Neus. ON DELETE CASCADE
-- en las FKs (cliente_campanias.pipeline_id, cliente_triggers.campania_id,
-- cliente_emails.campania_id) nukea las 4 tablas hijas en una sola
-- operación.
--
-- Lo que se queda intacto:
--   - cliente_campania_plantillas: 7 filas (catálogo TheNucleo).
--   - Las 5 tablas + RLS + 6 RPCs write + 1 RPC read.
--   - El frontend cableado (todos los drawers y archivar).
--
-- Siguiente paso: piloto Mel sobre Neus en
-- work.thenucleo.com/ficha-cliente/?id=1773847038522x983519237604638700
-- — declarar pipelines desde cero, en la dirección correcta.
-- ============================================================

DELETE FROM public.cliente_pipelines
 WHERE cliente_bubble_id = '1773847038522x983519237604638700';

-- Verificación inline (idempotente, falla si quedó algo)
DO $$
DECLARE
  v_p int; v_c int; v_t int; v_e int;
BEGIN
  SELECT COUNT(*) INTO v_p FROM public.cliente_pipelines
   WHERE cliente_bubble_id = '1773847038522x983519237604638700';
  SELECT COUNT(*) INTO v_c FROM public.cliente_campanias c
   JOIN public.cliente_pipelines p ON p.id = c.pipeline_id
   WHERE p.cliente_bubble_id = '1773847038522x983519237604638700';
  SELECT COUNT(*) INTO v_t FROM public.cliente_triggers t
   JOIN public.cliente_campanias c ON c.id = t.campania_id
   JOIN public.cliente_pipelines p ON p.id = c.pipeline_id
   WHERE p.cliente_bubble_id = '1773847038522x983519237604638700';
  SELECT COUNT(*) INTO v_e FROM public.cliente_emails e
   JOIN public.cliente_campanias c ON c.id = e.campania_id
   JOIN public.cliente_pipelines p ON p.id = c.pipeline_id
   WHERE p.cliente_bubble_id = '1773847038522x983519237604638700';
  IF v_p + v_c + v_t + v_e <> 0 THEN
    RAISE EXCEPTION 'Reset incompleto: p=% c=% t=% e=%', v_p, v_c, v_t, v_e;
  END IF;
END $$;
