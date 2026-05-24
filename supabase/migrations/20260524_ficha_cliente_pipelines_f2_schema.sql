-- ============================================================
-- F2 backend: Ficha de Cliente — Pipelines y Campañas (schema + seed)
-- Vision:        docs/portal/ficha-cliente.md
-- Handoff:       docs/portal/ficha-cliente-pipelines-handoff-landing.md
-- Frontend F1:   ficha-cliente/index.html:1677-2100 (SEED hardcoded)
--
-- Decisiones (sesion 2026-05-24):
--   - Plantillas por agencia (agencia_id NOT NULL, slug unico por agencia).
--   - FK a clientes via bubble_id text (patron playbook_cliente_servicios).
--   - Gate auth via public.is_comunidad_admin() en RLS (mismo patron que
--     disponibilidad_* y fichas_categorias / fichas_de_producto).
--   - triggers_aplicables text[] de subcodigos ('FM1','FW1'). Regla .docx
--     §3.4-6 (codigos no se reutilizan ni caducan) garantiza integridad
--     sin FK formal. Cero JOINs adicionales en la RPC _get.
--   - Estados finos por capa (visión §2 original, no los 3 unificados
--     del SEED actual). Impacto frontend documentado.
-- ============================================================


-- ---------- 1. cliente_campania_plantillas (catalogo, por agencia) ----------
CREATE TABLE public.cliente_campania_plantillas (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agencia_id          text NOT NULL,
  slug                text NOT NULL,
  nombre              text NOT NULL,
  descripcion         text,
  triggers_tipicos    jsonb NOT NULL DEFAULT '[]'::jsonb,
  emails_tipicos      jsonb NOT NULL DEFAULT '[]'::jsonb,
  campos_briefing     jsonb NOT NULL DEFAULT '[]'::jsonb,
  roles_default       jsonb NOT NULL DEFAULT '{}'::jsonb,
  briefing_master_url text,
  kpi_default         text,
  presupuesto_default numeric,
  estado              text NOT NULL DEFAULT 'activa'
                      CHECK (estado IN ('activa', 'archivada')),
  orden               int  NOT NULL DEFAULT 0,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          text DEFAULT auth.email(),
  UNIQUE (agencia_id, slug)
);
CREATE INDEX cliente_campania_plantillas_agencia_estado_idx
  ON public.cliente_campania_plantillas (agencia_id, estado);


-- ---------- 2. cliente_pipelines -------------------------------------------
CREATE TABLE public.cliente_pipelines (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_bubble_id   text NOT NULL
                      REFERENCES public.bub_clientes(bubble_id) ON DELETE CASCADE,
  codigo              text NOT NULL,                       -- 'P1','P2'... secuencial por cliente
  nombre              text NOT NULL,
  objetivo_negocio    text,
  estado              text NOT NULL DEFAULT 'activo'
                      CHECK (estado IN ('activo', 'archivado')),
  responsable_account text,                                -- bubble_id de bub_user
  notas               text,
  orden               int  NOT NULL DEFAULT 0,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          text DEFAULT auth.email(),
  UNIQUE (cliente_bubble_id, codigo)
);
CREATE INDEX cliente_pipelines_cliente_idx
  ON public.cliente_pipelines (cliente_bubble_id);


-- ---------- 3. cliente_campanias -------------------------------------------
CREATE TABLE public.cliente_campanias (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pipeline_id         uuid NOT NULL
                      REFERENCES public.cliente_pipelines(id) ON DELETE CASCADE,
  codigo              text NOT NULL,                       -- denormalizado: 'P1C1'
  nombre              text NOT NULL,
  plantilla_id        uuid
                      REFERENCES public.cliente_campania_plantillas(id) ON DELETE SET NULL,
  estado              text NOT NULL DEFAULT 'declarada'
                      CHECK (estado IN ('declarada', 'en-produccion', 'archivada')),
  fecha_inicio        date,
  fecha_fin           date,                                -- NULL = recurrente
  presupuesto_eur     numeric,
  canal_principal     text,                                -- Meta/Google/Email/Organico/Mixto
  kpi_objetivo        text,
  link_briefing_drive text,
  briefing_nombre     text,
  responsable_pm      text,                                -- bubble_id de bub_user
  notas_account       text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          text DEFAULT auth.email(),
  UNIQUE (pipeline_id, codigo)
);
CREATE INDEX cliente_campanias_pipeline_idx
  ON public.cliente_campanias (pipeline_id);


-- ---------- 4. cliente_triggers --------------------------------------------
CREATE TABLE public.cliente_triggers (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campania_id         uuid NOT NULL
                      REFERENCES public.cliente_campanias(id) ON DELETE CASCADE,
  codigo              text NOT NULL,                       -- denormalizado: 'P1C1FM1'
  tipo                text NOT NULL CHECK (tipo IN ('FM', 'FW', 'BD')),
  descripcion         text,
  link_externo        text,                                -- form id Meta, URL FW, segmento GHL
  fecha_lanzamiento   date,                                -- obligatoria si tipo='BD'
  estado              text NOT NULL DEFAULT 'declarado'
                      CHECK (estado IN ('declarado', 'creado', 'monitorizando', 'archivado')),
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          text DEFAULT auth.email(),
  UNIQUE (campania_id, codigo),
  CHECK (tipo <> 'BD' OR fecha_lanzamiento IS NOT NULL)    -- regla .docx caso 4
);
CREATE INDEX cliente_triggers_campania_idx
  ON public.cliente_triggers (campania_id);


-- ---------- 5. cliente_emails ----------------------------------------------
CREATE TABLE public.cliente_emails (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campania_id           uuid NOT NULL
                        REFERENCES public.cliente_campanias(id) ON DELETE CASCADE,
  orden                 int  NOT NULL,                     -- 1, 2, 3...
  nombre                text NOT NULL,
  espera_desde_anterior text,                              -- 'Día 0', 'Día +1', '+2d'
  objetivo              text,
  triggers_aplicables   text[] NOT NULL DEFAULT '{}',      -- subcodigos: 'FM1','FW1'. Vacio = todos
  link_copy_drive       text,
  link_diseno_drive     text,
  link_ghl_workflow     text,
  estado                text NOT NULL DEFAULT 'declarado'
                        CHECK (estado IN ('declarado', 'copy-listo', 'diseno-listo',
                                          'montado-ghl', 'activo', 'archivado')),
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  created_by            text DEFAULT auth.email(),
  UNIQUE (campania_id, orden)
);
CREATE INDEX cliente_emails_campania_idx
  ON public.cliente_emails (campania_id);


-- ---------- 6. updated_at triggers (reusa public.update_updated_at) --------
CREATE TRIGGER cliente_campania_plantillas_updated_at
  BEFORE UPDATE ON public.cliente_campania_plantillas
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER cliente_pipelines_updated_at
  BEFORE UPDATE ON public.cliente_pipelines
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER cliente_campanias_updated_at
  BEFORE UPDATE ON public.cliente_campanias
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER cliente_triggers_updated_at
  BEFORE UPDATE ON public.cliente_triggers
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER cliente_emails_updated_at
  BEFORE UPDATE ON public.cliente_emails
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


-- ---------- 7. RLS + GRANTs (patron fichas_categorias/fichas_de_producto) --
-- 4 policies por tabla (select/insert/update/delete) todas gated por
-- public.is_comunidad_admin(). GRANTs explicitos (rollout 2026-10-30).

-- cliente_campania_plantillas
ALTER TABLE public.cliente_campania_plantillas ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cliente_campania_plantillas TO authenticated;
GRANT ALL                          ON public.cliente_campania_plantillas TO service_role;
CREATE POLICY ccp_select_admin ON public.cliente_campania_plantillas
  FOR SELECT TO authenticated USING (public.is_comunidad_admin());
CREATE POLICY ccp_insert_admin ON public.cliente_campania_plantillas
  FOR INSERT TO authenticated WITH CHECK (public.is_comunidad_admin());
CREATE POLICY ccp_update_admin ON public.cliente_campania_plantillas
  FOR UPDATE TO authenticated USING (public.is_comunidad_admin())
                              WITH CHECK (public.is_comunidad_admin());
CREATE POLICY ccp_delete_admin ON public.cliente_campania_plantillas
  FOR DELETE TO authenticated USING (public.is_comunidad_admin());

-- cliente_pipelines
ALTER TABLE public.cliente_pipelines ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cliente_pipelines TO authenticated;
GRANT ALL                          ON public.cliente_pipelines TO service_role;
CREATE POLICY cp_select_admin ON public.cliente_pipelines
  FOR SELECT TO authenticated USING (public.is_comunidad_admin());
CREATE POLICY cp_insert_admin ON public.cliente_pipelines
  FOR INSERT TO authenticated WITH CHECK (public.is_comunidad_admin());
CREATE POLICY cp_update_admin ON public.cliente_pipelines
  FOR UPDATE TO authenticated USING (public.is_comunidad_admin())
                              WITH CHECK (public.is_comunidad_admin());
CREATE POLICY cp_delete_admin ON public.cliente_pipelines
  FOR DELETE TO authenticated USING (public.is_comunidad_admin());

-- cliente_campanias
ALTER TABLE public.cliente_campanias ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cliente_campanias TO authenticated;
GRANT ALL                          ON public.cliente_campanias TO service_role;
CREATE POLICY cc_select_admin ON public.cliente_campanias
  FOR SELECT TO authenticated USING (public.is_comunidad_admin());
CREATE POLICY cc_insert_admin ON public.cliente_campanias
  FOR INSERT TO authenticated WITH CHECK (public.is_comunidad_admin());
CREATE POLICY cc_update_admin ON public.cliente_campanias
  FOR UPDATE TO authenticated USING (public.is_comunidad_admin())
                              WITH CHECK (public.is_comunidad_admin());
CREATE POLICY cc_delete_admin ON public.cliente_campanias
  FOR DELETE TO authenticated USING (public.is_comunidad_admin());

-- cliente_triggers
ALTER TABLE public.cliente_triggers ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cliente_triggers TO authenticated;
GRANT ALL                          ON public.cliente_triggers TO service_role;
CREATE POLICY ct_select_admin ON public.cliente_triggers
  FOR SELECT TO authenticated USING (public.is_comunidad_admin());
CREATE POLICY ct_insert_admin ON public.cliente_triggers
  FOR INSERT TO authenticated WITH CHECK (public.is_comunidad_admin());
CREATE POLICY ct_update_admin ON public.cliente_triggers
  FOR UPDATE TO authenticated USING (public.is_comunidad_admin())
                              WITH CHECK (public.is_comunidad_admin());
CREATE POLICY ct_delete_admin ON public.cliente_triggers
  FOR DELETE TO authenticated USING (public.is_comunidad_admin());

-- cliente_emails
ALTER TABLE public.cliente_emails ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cliente_emails TO authenticated;
GRANT ALL                          ON public.cliente_emails TO service_role;
CREATE POLICY ce_select_admin ON public.cliente_emails
  FOR SELECT TO authenticated USING (public.is_comunidad_admin());
CREATE POLICY ce_insert_admin ON public.cliente_emails
  FOR INSERT TO authenticated WITH CHECK (public.is_comunidad_admin());
CREATE POLICY ce_update_admin ON public.cliente_emails
  FOR UPDATE TO authenticated USING (public.is_comunidad_admin())
                              WITH CHECK (public.is_comunidad_admin());
CREATE POLICY ce_delete_admin ON public.cliente_emails
  FOR DELETE TO authenticated USING (public.is_comunidad_admin());


-- ---------- 8. Seed: 7 plantillas TheNucleo --------------------------------
-- agencia_id = bubble_id de la unica agencia activa (ver docs/CLAUDE.md
-- workflow FcTmv78nLjbCb2Ea08qbt). Mismo set que ficha-cliente/index.html
-- PIPELINES_MODULE.PLANTILLAS (lineas 1684-1692) y portal/ficha-cliente.md §4.
INSERT INTO public.cliente_campania_plantillas
  (agencia_id, slug, nombre, descripcion, triggers_tipicos, emails_tipicos,
   campos_briefing, roles_default, briefing_master_url, kpi_default,
   presupuesto_default, orden)
VALUES
  ('1769513105728x555492736219132700', 'venta-meta',
   'Venta Directa con anuncio Meta',
   'Anuncio Meta → checkout. Sin secuencia post-compra obligatoria.',
   '[{"tipo":"FM","nombre":"Anuncio Meta → checkout"}]'::jsonb,
   '[]'::jsonb,
   '["Producto","Precio","Link checkout","Presupuesto Meta","Ángulos","Guión vídeo","Briefing estáticos","Info producto"]'::jsonb,
   '{"estaticos":"Valentin Arias","video":"Joaquin Rojo","meta":"Damian"}'::jsonb,
   'drive://templates/briefing-venta-directa.docx', 'Ventas', 500, 1),

  ('1769513105728x555492736219132700', 'capt-fm',
   'Captación de leads vía formulario Meta',
   'Form Meta + secuencia de 3 emails de nutrición.',
   '[{"tipo":"FM","nombre":"Formulario Meta"}]'::jsonb,
   '[{"nombre":"Bienvenida","espera":"Día 0","objetivo":"Romper el hielo"},
     {"nombre":"Valor","espera":"Día +2","objetivo":"Aportar contenido educativo"},
     {"nombre":"Oferta","espera":"Día +5","objetivo":"Presentar producto con urgencia"}]'::jsonb,
   '["Producto/oferta","Lead magnet","Presupuesto Meta","Ángulos","Briefing estáticos"]'::jsonb,
   '{"copy":"Valentin Arias","diseno":"Valentin Arias","formulario":"Damian","ghl":"Camilo Balanta"}'::jsonb,
   'drive://templates/briefing-captacion-fm.docx', 'Leads · CPL', 300, 2),

  ('1769513105728x555492736219132700', 'capt-fw',
   'Captación de leads vía formulario Web',
   'Form en la web del cliente + secuencia de 3 emails.',
   '[{"tipo":"FW","nombre":"Form en web"}]'::jsonb,
   '[{"nombre":"Bienvenida","espera":"Día 0","objetivo":"Romper el hielo"},
     {"nombre":"Valor","espera":"Día +2","objetivo":"Aportar contenido educativo"},
     {"nombre":"Oferta","espera":"Día +5","objetivo":"Presentar producto con urgencia"}]'::jsonb,
   '["Producto/oferta","URL form","Presupuesto Google u orgánico","Copy form"]'::jsonb,
   '{"copy":"Valentin Arias","diseno":"Valentin Arias","form":"Dev/CRM","ghl":"Camilo Balanta"}'::jsonb,
   'drive://templates/briefing-captacion-fw.docx', 'Leads · CPL', 200, 3),

  ('1769513105728x555492736219132700', 'react-bd',
   'Reactivación BBDD (con fecha)',
   'Envío a segmento existente en fecha programada. Secuencia reactivación → oferta → cierre.',
   '[{"tipo":"BD","nombre":"Segmento BBDD"}]'::jsonb,
   '[{"nombre":"Reactivación","espera":"Día 0","objetivo":"Recordar valor"},
     {"nombre":"Oferta","espera":"Día +2","objetivo":"Gancho de reactivación"},
     {"nombre":"Cierre","espera":"Día +5","objetivo":"Última llamada"}]'::jsonb,
   '["Segmento BBDD","Fecha envío","Asunto","Oferta de reactivación"]'::jsonb,
   '{"copy":"Valentin Arias","diseno":"Valentin Arias","ghl":"Camilo Balanta"}'::jsonb,
   'drive://templates/briefing-react-bd.docx', 'Conversiones', 0, 4),

  ('1769513105728x555492736219132700', 'news',
   'Newsletter recurrente',
   'Envío periódico a BBDD activa. Una edición por ciclo.',
   '[{"tipo":"BD","nombre":"BBDD activa"}]'::jsonb,
   '[{"nombre":"Edición única","espera":"cadencia","objetivo":"Edición del ciclo"}]'::jsonb,
   '["Cadencia","Segmento","Línea editorial","Briefing por edición"]'::jsonb,
   '{"copy":"Valentin Arias","diseno":"Valentin Arias","ghl":"Camilo Balanta"}'::jsonb,
   'drive://templates/briefing-newsletter.docx', 'Apertura · Clicks', 0, 5),

  ('1769513105728x555492736219132700', 'lanz',
   'Lanzamiento multicanal',
   'FM + FW + BD coordinados. Secuencia 5 emails (pre/lanzamiento/post).',
   '[{"tipo":"FM","nombre":"Anuncio Meta"},{"tipo":"FW","nombre":"Form web"},{"tipo":"BD","nombre":"BBDD"}]'::jsonb,
   '[{"nombre":"Pre-aviso","espera":"-3d","objetivo":"Calentar"},
     {"nombre":"Anuncio","espera":"D0","objetivo":"Lanzar"},
     {"nombre":"Recordatorio","espera":"+2d","objetivo":"Recordar"},
     {"nombre":"Última llamada","espera":"+5d","objetivo":"Urgir"},
     {"nombre":"Cierre","espera":"+7d","objetivo":"Cerrar"}]'::jsonb,
   '["Producto","Fecha lanzamiento","Fases","Presupuesto total","Mensaje por fase"]'::jsonb,
   '{"copy":"Valentin Arias","diseno":"Valentin Arias","meta":"Damian","ghl":"Camilo Balanta"}'::jsonb,
   'drive://templates/briefing-lanzamiento.docx', 'Ventas', 1500, 6),

  ('1769513105728x555492736219132700', 'evento',
   'Evento (formulario + recordatorios)',
   'Form web + 2 emails de gestión del evento.',
   '[{"tipo":"FW","nombre":"Inscripción evento"}]'::jsonb,
   '[{"nombre":"Confirmación","espera":"Día 0","objetivo":"Confirmar inscripción"},
     {"nombre":"Recordatorio","espera":"-1d","objetivo":"Recordar evento"}]'::jsonb,
   '["Producto/evento","Fecha","Formato","Capacidad"]'::jsonb,
   '{"copy":"Valentin Arias","diseno":"Valentin Arias","ghl":"Camilo Balanta"}'::jsonb,
   'drive://templates/briefing-evento.docx', 'Inscripciones', 100, 7);
