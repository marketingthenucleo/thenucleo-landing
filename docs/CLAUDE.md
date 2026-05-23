---
title: TheNucleo — Hub Principal
dominio: hub
estado: vivo
actualizado: 2026-05-22
tags: [hub, portal, claude]
---

# TheNucleo — Portal de Gestión de Agencia de Marketing

## Qué es
App interna (portal.thenucleo.com) para gestionar clientes, tareas, facturación, RRHH y operaciones de una agencia de marketing digital. Desarrollada y mantenida por Benjamin Sanchis.

## Stack tecnológico
- **Frontend:** Bubble (no-code). Mismo app en 2 URLs: `portal.thenucleo.com` (custom domain) y `app-the-nucleo-agency.bubbleapps.io` (URL por defecto de Bubble). Ambas sirven la misma versión. Distinción dev/live por **path**: `/api/1.1/obj/...` = live, `/version-test/api/1.1/obj/...` = dev/test.
- **Base de datos:** Supabase (proyecto único `cbixhqjsnpuhcrcjppah`, región eu-west-1) — espejo Bubble + cache operativo + chat
- **Automatizaciones:** n8n (self-hosted en `n8n-n8n.irzhad.easypanel.host`)
- **IA:** Claude API (Anthropic) para chats IA + Gemini API para RAG (fileSearchStores)
- **Integraciones:** Notion (gestor de tareas — polling 1 min → Bubble; también aloja clientes con sync bidireccional), Clockify (tiempo), Holded (facturación), GHL (CRM), Google Drive, Meta Ads, Google Ads, Evolution API (WhatsApp), ClickUp (gestor de tareas alternativo)

## Arquitectura de datos
**Gestor de tareas:** Notion (TAREAS db `b67f8416-322f-4761-ba36-40b938ae9387`) o ClickUp (workspace `9008203585`), según el cliente. Ambos con workflows de sync propios (Notion activos; ClickUp en construcción en paralelo).

Flujo real:
```
Notion (tareas) ──[polling 1 min]──▶ Bubble (frontend + datos)
                                              │
                                              └─[webhook reactivo]─▶ Supabase (espejo bub_*)
```

**Clientes y users:** Bubble es la fuente activa hoy. Notion también aloja clientes (sync bidireccional Bubble↔Notion) y Clickup tambien los alojara (y tambien habrá bidireccionalidad).


- Bubble es la capa que sirve al frontend y la fuente para Supabase.
- Supabase es espejo posterior de Bubble (no paso intermedio).
- Relaciones entre tablas: arrays de IDs lógicos, sin FKs formales.
- Integridad referencial confiada a Notion (para tareas) y a Bubble (resto).

✅ **Resuelto 2026-04-27 → 2026-05-02:** los 3 syncs legacy de clientes y miembros se rehicieron o archivaron. `wvHcgVqqjkWJcJDu` (Bubble→Notion+Drive) y `FcTmv78nLjbCb2Ea08qbt` (Notion→Bubble) reescritos y activos. `cXewmXMQ8xhKmN8f` (Miembros Notion→Supabase legacy) archivado. `bub_miembro_notion` eliminada (DROP 2026-05-02): IDs de miembro migrados a `bub_user` (campos `notion_id` + `clickup_user_id`). Arquitectura actual: Bubble es fuente de clientes y miembros, vía SYNC ABSOLUTO `FGxG67I24POOUeHW` disparado por DB Triggers Bubble.

## Secciones de la app (8 internas + 1 pública)
1. **Dashboard** (`/dashboard`) — KPIs globales: tareas vencidas, incidencias, clientes críticos.
2. **Clientes** (`/clientes`) — Kanban/Lista de clientes. Modal crear cliente. Subpáginas: Ficha cliente, Chat Cerebro IA, Newsletter IA.
3. **Operaciones** (`/operaciones`) — Kanban de tareas (8 estados). Plantillas de tareas. Control de Tiempo (Clockify dashboard). Control de campañas Ads como sub-funcionalidad interna.
4. **Finanzas** — Facturas y métricas desde Holded.
5. ~~**Comunidad** (interno Bubble)~~ → **MIGRADA 2026-04-28** a `work.thenucleo.com/comunidad` (público, Eleventy SSG + Supabase nativo + Auth Google + crowdfunding). Detalle en `docs/portal/secciones-app.md` y `thenucleo-landing/CLAUDE.md`.
6. ~~**Incidencias**~~ — Eliminada como sección independiente.
7. **Ajustes** — Config agencia, miembros, onboarding, integración GHL.
8. **Recursos Humanos** — Perfiles empleados, NPS, departamentos. (antes "RRHH / Liderazgo")
9. **Notificaciones** — Sistema interno (1 emisor → N destinatarios, respuesta inline por destinatario via autobinding). 2 Data Types (`Notificacion` + `Notificacion_Receptor`), 4 Option Sets, 2 backend workflows (`api_crear_notificacion` + `_crear_receptor_notif`), popup en Header + RG dashboard. Detalle en `docs/portal/notificaciones.md`.
10. **Soporte** — (pendiente documentar)

## Supabase — Proyecto único (cbixhqjsnpuhcrcjppah, eu-west-1)

### Tablas operativas
- `chat_conversations` — Conversaciones IA. Unique(agencia_id, tipo)
- `chat_messages` — Mensajes chat. FIFO 100 por conversación (trigger)
- `newsletter_wip` — WIP completo newsletter por conversación: estrategia + array emails + doc_url (antes `newsletter_emails_wip`)
- `activity_log` — Auditoría
- `analisis_wip` — WIP del chat co-creativo Análisis Estratégico Cliente (sector 7). briefing=12 secciones fijas; segmentos=array 4 objetos `{nombre, descripcion, problematica, oportunidad, empatia, buyer_persona, angulos}`
- `blog_videos` — Backlog de vídeos Blog Zenyx + estado de generación de posts (pendiente/publicado/error)
- `n8n_incidencias` — Errores de workflows n8n enriquecidos por Claude. Visualizables en `work.thenucleo.com/incidencias`
- `cliente_external_links` — Links cliente ↔ sistemas externos (ClickUp, etc.): provider + external_id + external_type + is_primary
- `provider_webhooks` — Registro de webhooks activos por provider con secret y status
- `sync_suppress` — Anti-rebote de sync: suprime actualizaciones de un external_id/provider hasta until_ts
- `comunidad_propuestas`, `comunidad_comentarios`, `comunidad_votos_propuesta`, `comunidad_votos_comentario`, `comunidad_admins` — Comunidad pública nativa (work.thenucleo.com/comunidad). RLS público read-only para aprobadas, write authenticated, moderación por allowlist. Edge Function `comunidad_admin_action` modera y dispara Vercel Deploy Hook. Vista `v_comunidad_propuestas_publicas` para SSG build-time.
- `casuisticas_board` — Tablero kanban single-row (`id='global'`) para `work.thenucleo.com/casuisticas/`. Columna `data jsonb` con `{bolsa, newsletter, hibrido, dudas}` + `updated_by` (email). RLS por allowlist `auth.email()` (4 emails admin). Migrada desde localStorage 2026-05-15.
- `disponibilidad_franjas_base`, `disponibilidad_overrides`, `festivos_es` — Calendario disponibilidad laboral equipo para `work.thenucleo.com/disponibilidades/` (vivo desde 2026-05-20). 6 miembros (Benjamin Sanchis, Valentina, Camilo, Damian, Joaquin, Valeria Diez) con 14 franjas L–V. Frontend carga miembros dinámicamente vía RPC `disponibilidad_miembros()` (`SECURITY DEFINER`, JOIN bub_user + franjas) — para añadir/retirar a alguien basta INSERT/DELETE en `disponibilidad_franjas_base`. Overrides time-series con tipos `medico|enfermo|llega_tarde|sale_antes|vacaciones|avatar_no_responde|otro` (7 tipos — `avatar_no_responde` = "no disponible para IA / chat automatizado"). Festivos nacionales España (10 filas 2026, sin CCAA). RLS vía `is_comunidad_admin()` (distinto del patrón Casuísticas/Playbook que usa allowlist hardcoded). FK `bub_user(bubble_id)`. Detalle en `docs/work/disponibilidades.md`.
- `rag_stores` — Gemini fileSearchStores por cliente/tipo (cerebro, newsletter, análisis)
- ✅ `clockify_time_entries` — sync activo vía workflow `ccPQuZmH7DGYRRbe` (CRON 23:00 Madrid, ventana 35 días). ⚠️ `clockify_tarifas` — pendiente reactivar workflow.
- ✅ `holded_facturas`, `holded_metricas`, `holded_sync_log` — sync activo vía workflow `vI3TbyxtFM6wjhBS` (CRON nocturno + webhook `Sync Manual`). El workflow único cubre las 3 tablas: INSERT/UPDATE en `holded_sync_log`, Upsert en `holded_metricas` y Upsert en `holded_facturas` (con borrado previo de facturas antiguas).
- `agencia_integraciones_config` — Credenciales cifradas (pgcrypto) por (agencia_id, addon_slug) para todas las integraciones (nativas + addons). RLS service_role only. Funciones `aic_set` / `aic_get` / `aic_set_test_result` + wrappers `aic_set_with_key` / `aic_get_with_key` (consumidos desde n8n sin acceso a `app.aic_key`). Clave en `app.aic_key` (set por sesión n8n) y variable env `AIC_KEY` en EasyPanel. Creada 2026-05-04.

**Ads — Control de Campañas v2 (Meta, en producción 2026-05-12):** schema multi-provider nativo `ads_*` (no `bub_*`). 7 tablas:
- `ads_cuentas` (cuentas publicitarias multi-provider Meta+Google con auto-discovery, `cliente_id` NULLABLE hasta asignar, `estado_interno IN ('pendiente_asignar','activa','archivada','sin_acceso')`, ownership owned/partner)
- `ads_campanias`, `ads_adsets`, `ads_anuncios` (jerarquía + snapshot KPIs preset `last_7d` + scoring `winner/scalable/ontarget/fatigue/loser/nodata` portado de OptiMetrics)
- `ads_insights_diario` (time-series UPSERT por `(cuenta_id, entity_type, entity_external_id, fecha)` con conv/revenue/roas/cpa)
- `ads_notas` (audit trail acciones desde Bubble — manual/accion/sistema)
- `ads_alertas` (alertas operativas derivadas — UNIQUE `(entity_external_id, reason)`)

⚠️ `bub_dashboardmedia_*` (legacy Meta+Google Ads) sigue viva durante convivencia. Plan: archivar workflow Gmail listener `4gN3uGhH8NZX2BDU` tras 2 semanas smoke verde + DROP tablas viejas. Detalle handoff completo en `docs/portal/integraciones/control-de-campanias.md`.

### Tablas espejo Bubble (`bub_*`) — 40 tablas

**Catálogos / option sets (`bub_os_*`, 17):**
`bub_os_estado_facturacion`, `bub_os_estado_incidencias`, `bub_os_estado_propuesta`, `bub_os_estados_cliente`, `bub_os_estado_tarifa`, `bub_os_niveles`, `bub_os_prioridad_plantillas`, `bub_os_rol_usuario`, `bub_os_secciones`, `bub_os_sector`, `bub_os_tipo_propuesta`, `bub_os_tipo_tarifa`, `bub_os_periodo_facturas`, `bub_os_periodo_suscripcion`, `bub_os_rrhh_tipo_contrato`, `bub_os_rrhh_departamento`, `bub_os_rrhh_status_carga`

**Core:**
`bub_agencia`, `bub_user`, `bub_clientes` (73), `bub_invitacion`, `bub_integraciones`

**Tareas:**
`bub_tareas_notion` (1.093), `bub_triggers_catalogo`

**Plantillas:**
`bub_plantillas_areas`, `bub_plantillas_tareas_notion`, `bub_plantillas_subtareas_notion`

**Servicios / Pagos:**
`bub_pagos_tarifa_catalogo`, `bub_pagos_agencia_tarifa`

> `bub_servicios_productos_agencia` y `bub_servicios_productos_clientes` ELIMINADAS 2026-05-22 (Data Types Bubble nunca usados, espejos vacíos en Supabase). Catálogo de servicios y junction cliente↔servicio viven ahora en tablas nativas Supabase `fichas_categorias` + `fichas_de_producto` + `playbook_cliente_servicios` (editor en `work.thenucleo.com/fichas-de-producto/` y `/playbook/`). Bubble los lee como Data Types con el mismo nombre (`fichas_categorias` + `fichas_de_producto` + `playbook_cliente_servicios`) vía workflow `ewu5A5E05T4tz5CD` (SYNC FICHAS — Supabase → Bubble). Bulk inicial 12+57+199 records ejecutado 2026-05-22 a Bubble LIVE.

**Addons (sistema de integraciones de pago único, F1 cerrada 2026-05-04):**
`bub_addons_catalogo` (34 filas — 6 nativos + 28 de pago), `bub_addons_agencia` (compras por agencia), `bub_addons_codigos_descuento` (cupones, sync con Stripe Coupons API en F2). Plan maestro en `~/.claude/plans/thenucleo-addons-onboarding-master-plan.md`, estado por fase en `docs/addons/README.md`.

**Comunidad (interna Bubble):** ELIMINADAS 2026-04-28. Sustituidas por tablas nativas `comunidad_*` (público en `work.thenucleo.com/comunidad`). Ver `docs/infra/supabase-schema.md` sección "Comunidad pública".

**RRHH:**
`bub_rrhh_empleado_perfil`, `bub_rrhh_nps_registro`, `bub_rrhh_dpt_funcion`

**Ads (control de campañas) — LEGACY en convivencia:**
`bub_dashboardmedia_alertas_operativas` (686), `bub_dashboardmedia_cuentas_ads` (5). Pendiente archivar tras 2 semanas smoke verde del schema nativo `ads_*` (ver bloque "Ads — Control de Campañas v2" arriba).

**Log Google chat** ( no definido en ux Bubble todavia)
**Actividad Diaria Log (Google Chat → Bubble, Fase 2 v2 cerrada 2026-05-08, rollout multi-espacio 2026-05-09):**
`bub_actividad_diaria_log` (capturado por workflow `8snJvdNsmRM2yI2y` Pub/Sub vía Workspace Events API, classifier Haiku 4.5 filtra ruido). `bub_clientes.gchat_space_id` como mapping (23 clientes mapeados). `gchat_subscriptions` tracking (24 subs activas; columna extra `cliente_bubble_id`). Lifecycle workflow `xzNDkDNiUOYOA2Ku` (Fase 3 #2 auto-match) **activado 2026-05-09**. Detalle completo en `docs/portal/integraciones/google-chat-log.md`.

**Notificaciones (espejo creado 2026-05-16):**
`bub_notificacion` (mensaje original, `destinatarios text[]` denormalizado incluye al remitente para que vea sus enviadas; `archivada boolean NOT NULL DEFAULT false` global desde 2026-05-21), `bub_notificacion_receptor` (1 fila por destinatario con `mensaje_respuesta`, `leida_en`, `archivada boolean NOT NULL DEFAULT false` por receptor desde 2026-05-21, `archivado_en` queda solo como timestamp histórico). Sync vía `FGxG67I24POOUeHW` (DB Triggers Bubble pendientes que cree Ben). Detalle en `docs/portal/notificaciones.md`.

### Vistas (6)
- `v_tareas_panel` — Kanban Bubble (JOINs: clientes_nombres, responsables)
- `v_tareas_contexto_ia` — Últimos 10 días para prompt IA
- `v_tareas_cerebro_ia` — Extendida con días hasta entrega
- ~~`v_clientes_opciones`~~ → eliminada 2026-05-08 (huérfana, sin consumidores)
- ~~`v_responsables_opciones`~~ → eliminada 2026-05-02. Reemplazada por RPC `responsables_opciones(p_agencia_id uuid)`
- `v_plantillas_catalogo` — Plantillas activas + conteo subtareas
- `v_blog_videos_pendientes` — Usada por workflow Blog Zenyx

### RPCs — Portal (portal.thenucleo.com)
**Clockify (10):** `clockify_resumen`, `clockify_por_cliente`, `clockify_por_miembro`, `clockify_trending`, `clockify_por_tarea`, `clockify_cliente_miembro`, `clockify_coste_por_cliente`, `clockify_chart_donut`, `clockify_chart_trending`, `clockify_dashboard` (sin consumidores activos; mantenida por compatibilidad). Joinean `nombre` contra `bub_user` desde 2026-05-02.

**Responsables (1):** `responsables_opciones(p_agencia_id uuid)` → `nombre, email`. Sustituye a `v_responsables_opciones` (eliminada 2026-05-02). Mapea UUID supabase → bubble_id via `bub_agencia` para filtrar `bub_user`.

**Finanzas (4):** `finanzas_metricas_mes`, `finanzas_facturas`, `finanzas_desgloses`, `finanzas_evolucion_mrr`

**Chat / Cerebro IA (2):** `get_or_create_conversation`, `cerebro_consulta_ia`

**Análisis Estratégico (8):** `analisis_get_briefing`, `analisis_get_segmento_angulos`, `analisis_get_segmento_buyer`, `analisis_get_segmento_empatia`, `analisis_get_segmento_meta`, `analisis_merge_update`, `analisis_reset_stuck_analyzing`, `analisis_reset_wip`

**Helpers Análisis (2, internas):** `_briefing_as_bullets`, `_briefing_as_text`

**Newsletter IA (7):** `newsletter_get_email`, `newsletter_get_emails`, `newsletter_get_estrategia`, `newsletter_get_parametros`, `newsletter_update_email`, `newsletter_reset_stuck`, `newsletter_reset_wip`

**Ads — Control de Campañas (16, todas multi-provider Meta+Google):**
- Panel (lectura Bubble): `ads_cuentas_panel`, `ads_cuentas_pendientes`, `ads_campanias_panel`, `ads_adsets_panel`, `ads_anuncios_panel`, `ads_insights_serie`, `ads_notas_listar`
- Acciones (escritura desde webhooks): `ads_asignar_cliente`, `ads_notas_crear` (RETURNS jsonb desde 2026-05-12), `ads_aplicar_status_toggle`
- Sync (consumidas por n8n): `ads_meta_creds_listas` (descifra creds Meta + HMAC appsecret_proof), `ads_upsert_estructura`, `ads_insertar_insights_diario`, `ads_actualizar_kpis_snapshot`
- Helpers internos: `ads_extract_conversion` (portado de OptiMetrics `parseIns`), `ads_calcular_scoring` (percentiles CPA/CTR, portado de `scoreAll`)
GRANT EXECUTE a `authenticated` solo en panels/list. Writes/helpers + sync solo `service_role`.

**Trigger functions Portal:**
- `cleanup_old_messages` — FIFO 100 mensajes (`chat_messages`)
- `update_updated_at` — Auto-timestamp UPDATE (tablas operativas portal)
- `set_synced_at` — Marca `_synced_at` en upsert desde Bubble (`bub_*`)
- `rls_auto_enable` — ⚠️ Pendiente confirmar uso

### RPCs — Work (work.thenucleo.com)
**Comunidad (3):** `is_comunidad_admin`, `comunidad_propuestas_rate_limit`, `comunidad_slugify`

**Playbook público (1):** `playbook_publico(p_bubble_id text)` → jsonb `{cliente, progreso, tasks}`. SECURITY DEFINER. GRANT EXECUTE a `anon, authenticated`. Anon-safe: solo devuelve la fila cuyo `bubble_id` conoces (no enumera). Consumido por `work.thenucleo.com/playbook/<bubble_id>` en modo anon (timeline only, sin responsables/estimaciones/notas internas).

**Ficha de Cliente — RPCs admin-allowlist (2, desde 2026-05-22):** consumidas por `work.thenucleo.com/ficha-cliente/`. Resuelven que `bub_clientes` no tiene policies para `authenticated` sin necesidad de añadirlas (mismo patrón que `playbook_cliente_detalle`).
- `ficha_cliente_listar()` RETURNS TABLE → selector dropdown de clientes activos. Filtra `COALESCE(estado,'') <> 'No Activo'` orden alfabético.
- `ficha_cliente_get(p_bubble_id text)` RETURNS jsonb → `to_jsonb(c.*)` con todas las columnas de `bub_clientes` **+ array `servicios`** (ampliación 2026-05-22, migration `ficha_cliente_get_incluir_servicios`): `jsonb_agg(pcs.*)` de `playbook_cliente_servicios` ordenado por `orden NULLS LAST, created_at`. Cada elemento trae `ficha_titulo`, `categoria_nombre`, `categoria_color`, `unidades`, `periodo`, `notas`.

Ambas SECURITY DEFINER + allowlist hardcoded en body (4 emails TheNucleo) + `RAISE EXCEPTION 'forbidden'` ERRCODE `42501` si email no autorizado. `GRANT EXECUTE TO authenticated`. ⚠️ **Allowlist en 7 sitios ahora** (frontend playbook/fichas-de-producto/ficha-cliente + RLS policies playbook_progreso/playbook_task_feedback/playbook_cliente_servicios + RPC playbook_cliente_detalle + estas 2 RPCs).

**Trigger functions Work:**
- `tg_bv_updated_at` — Auto-timestamp UPDATE (`blog_videos`)
- `trg_comunidad_set_slug` — Auto-slug en insert de propuesta comunidad
- `trg_comunidad_set_updated_at` — Auto-timestamp UPDATE (tablas comunidad)

### Triggers (3 patrones)
- `trg_set_synced_at` (BEFORE INSERT/UPDATE) → 18 tablas `bub_*` sincronizadas desde Bubble.
- `*_updated_at` (BEFORE UPDATE) → tablas operativas: `analisis_wip`, `blog_videos`, `clockify_tarifas`, `newsletter_wip`, `rag_stores`, `comunidad_comentarios`, `comunidad_propuestas`.
- `trigger_cleanup_messages` (AFTER INSERT en `chat_messages`) → FIFO 100 mensajes por conversación.

### Reglas clave
- n8n usa `service_role` (bypass RLS). Bubble usa `anon` (sujeto a RLS).
- RLS activo: todas las `bub_*` + `analisis_wip` + `rag_stores` + `newsletter_wip` + `clockify_*` + `holded_*` + `n8n_incidencias` + `comunidad_*` + `casuisticas_board`.
- Sin RLS: `chat_*`, `activity_log`, `blog_videos`, `cliente_external_links`, `provider_webhooks`, `sync_suppress`.
- Fallos silenciosos de PATCH Bubble → primer check = RLS policies.
- PostgreSQL function params: siempre prefijo `p_` para evitar error 42702.
- `DROP VIEW IF EXISTS` antes de cualquier rename/type change en columnas de vistas.
- **GRANTs explícitos obligatorios en tablas nuevas (rollout Supabase 2026-10-30):** toda tabla nueva en `public` consumida por Data API (Bubble API Connector, n8n HTTP `/rest/v1/`, supabase-js en `work.thenucleo.com`) requiere `GRANT` por rol (`anon`/`authenticated`/`service_role`) + `ENABLE ROW LEVEL SECURITY` + policies en el mismo migration. Sin GRANT → PostgREST devuelve `42501`. Tablas actuales conservan grants y no se rompen. RPCs no se ven afectados (siguen con `GRANT EXECUTE`).

## Bubble — Patrones clave
- **API Connector calls** — 59 calls en 12 grupos activos (todas auditadas 2026-05-14, tras cleanups "estados flujos" + "Gestion plantillas" + `POST_MESSAGE`).
- **SIEMPRE Action, NUNCA Data source** — Bubble cachea Data sources
- **RPCs tipados (RETURNS TABLE)** para Bubble — Las funciones RETURNS jsonb llegan como texto plano
- **Helpers pre-formateados** para plugins de charts (split by separador)
- Paleta colores: Fondo `#0c0d12`, Card `#13151c`, Borde `#1e2130`, Texto `#edeef3`, Acento verde `#22c55e`
- Font: New Black

## n8n — Workflows

> **Nomenclatura (2026-05-06):** todos los workflows del Portal renombrados a esquema `[TIPO] [DOMINIO] — [Detalle] [→ Dirección si SYNC]`. Tipos: SYNC | CRON | OPS | IA | INTEGRACIONES | ERRORES | SUB. Dominios: TAREAS | CLIENTES | FINANZAS | TIEMPO | ESPEJO | ADDONS | ADS | CRM | BLOG | ANTI-REBOTE.
>
> **Tag obligatorio `portal` (id `8JEzIL3gJwyclObr`):** todo workflow del Portal debe tener este tag. Lo usa el workflow `Background GitHub` (`7OhqK68gIkHQilSlYDZlW`) para filtrar qué subir al repo backup `marketingthenucleo/n8nthenucleo`. Sin tag → no entra al backup. Workflows de OTROS clientes (Iruelas, Freexday, Roes & Co, etc.) NO se etiquetan.  — `PUT /api/v1/workflows/{id}/tags` directo. Detalle en skill `n8n`.

### SYNC — Sincronizaciones bidireccionales
- ✅ `GjijIDEUyiH05Mg0` — **SYNC TAREAS — Notion → Bubble**. Polling Notion cada minuto. Soporta N responsables.
- ⚠️ `eR5SWFkxJmjMT1VI` — **SYNC TAREAS — ClickUp → Bubble** (rename pendiente UI: bloqueo validación operadores unarios pre-existente). Webhook /clickup_tasks_inbound + HMAC + whitelist + anti-rebote.
- ✅ `FcTmv78nLjbCb2Ea08qbt` — **SYNC CLIENTES — Notion → Bubble**. 2 Notion Triggers (pageAdded + pageUpdated). Anti-rebote por comparación de contenido. Flujo: Get full page → Build payload → GET Bubble por notion_id → Compare & Decide → POST/PATCH Bubble → Activity Log. ⚠️ `agencia_id` usa `unique id` Bubble (`1769513105728x555492736219132700`), NO `uuid_supabase`.
- ✅ `wvHcgVqqjkWJcJDu` — **SYNC CLIENTES — Bubble → Notion + Drive**. Webhook desde Bubble → alta: crea carpeta raíz Drive + invoca sub `d0B4LokmPhHWdg6g` (subcarpetas L1/L2/L3) + actualiza Doc Maestro + crea página Notion DB Empresas + PATCH Bubble portal con `notion_id`/`link_drive`. Update: solo PATCH Notion. Logs en `activity_log`.
- ⚠️ `SjqnIOJYPAkFMFfW` — **SYNC CLIENTES — ClickUp → Bubble** (rename pendiente UI: bloqueo validación operadores unarios). Handles folderCreated/Updated/Deleted vía HMAC webhook.
- ✅ `FGxG67I24POOUeHW` — **SYNC ESPEJO — Bubble → Supabase**. Webhook reactivo `/webhook/espejo_a_supabase`. `ALLOWED_TABLES` con 23 entradas (incluye `bub_addons_*` desde 2026-05-04, `bub_actividad_diaria_log` desde 2026-05-07, `bub_notificacion` + `bub_notificacion_receptor` desde 2026-05-16; `bub_servicios_productos_agencia` + `bub_servicios_productos_clientes` quitadas 2026-05-22). URL Bubble Data API hardcoded a LIVE.
- ⏸ `ewu5A5E05T4tz5CD` — **SYNC FICHAS — Supabase → Bubble** (creado 2026-05-22, INACTIVO, pendiente tag `portal` UI). 18 nodos. Triggers: webhook `/sync_fichas_supabase_bubble` + Schedule cron 03:15 Madrid. 3 bloques secuenciales (Categorías → Fichas → Junction) con patrón `GET Supabase → GET Bubble → Compute Ops (Code) → Apply Op (HTTP dinámico)`. Resuelve refs `categoria_id` UUID → Bubble uid usando mapa initial + IDs nuevos del POST. Upsert por `id_externo`. URLs apuntando a LIVE (`/api/1.1/obj/`) desde 2026-05-22. **Bulk inicial 2026-05-22:** 12+57+199 records ya en Bubble LIVE vía script Python one-shot — próximas corridas del workflow harán PATCH idempotente. Reemplaza al patrón Bubble→Supabase: aquí Bubble es destino, no fuente.
- ✅ `vI3TbyxtFM6wjhBS` — **SYNC FINANZAS — Holded → Supabase** (activado 2026-04-25)
- ✅ `ccPQuZmH7DGYRRbe` — **SYNC TIEMPO — Clockify → Supabase (CRON 23:00)** (reactivado 2026-04-27)
- ⏸ `bDYIpOSZ7Ge01Fqt` — **SYNC ADDONS — Bubble → Stripe (Cupones)** (F2, INACTIVO: pendiente creds Stripe + Bubble + Supabase)

### CRON — Tareas programadas
- ✅ `ZqccS38F2Lz8WFwX` — **CRON TAREAS — Reconciliar Huérfanas Notion** (huérfanas Notion→Bubble→Supabase)
- ✅ `kbUqzdSOrV7e2lS0` — **CRON TAREAS — Reconciliar Huérfanas ClickUp** (cada 1h)
- ✅ `ek5veFfwbeSB0bW3` — **CRON ANTI-REBOTE — Limpiar Sync Suppress (5min)** (purga `sync_suppress` expiradas)
- ✅ `V60MieFkQzOszxhh` — **CRON IA Análisis — Reset Stuck (15min)** (libera análisis colgados via `analisis_reset_stuck_analyzing`)
- ✅ `ZnJSkoWlSusmEjhO` — **CRON IA Cerebro — Reindexar RAG (3:00)**
- ✅ `kZE3W2ae0upyGt2E` — **CRON IA Newsletter — Reindexar RAG (3:30)**
- ✅ `CNlBtiFCwY69I6Wl` — **CRON BLOG — Zenyx Diario 18:00** (ver sección Blog Zenyx)
- ✅ `1f6IGS3cGPMVhQInlG7nX` — **CRON TIEMPO — Calcular Horas Reales** (Clockify)
- ✅ `NMZA404s1agKcHau` — **CRON LOG — Renovar Subscriptions Google Chat (3h)** (activo 2026-05-08, intervalo bajado de 6h→3h el 2026-05-14 tras gap de captura observado). Filtro `status=active AND expire_time < now()` (solo subs en SUSPENDED en Google). POST CREATE idempotente sobre `/v1/subscriptions` con cred Google SA `chat-token-thenucleo` (refactor 2026-05-09 desde `:reactivate`, que falla sobre subs ya borradas). Tag `portal` pendiente UI.

### OPS — Operaciones (tareas, plantillas, ads, CRM)
- ✅ `eHyXBETcaGSNXqLk` — **OPS TAREAS — Crear desde Formulario Bubble**
- ✅ `KSBwigoSEpHl5OG1` — **OPS TAREAS — Aplicar Plantilla a Cliente**
- ⏸ `rONvzi9sdbFvgYYo` — **OPS TAREAS — Backfill cliente_nombre [MANUAL]**. Manual Trigger reutilizable. RPC Supabase `backfill_cliente_nombre_pendientes()` → PATCH Bubble. Tag `portal` pendiente UI. Usado 2026-05-08 para repoblar 300 tareas afectadas por bug 2026-04-21→2026-05-08 del sync `GjijIDEUyiH05Mg0`.
- ⏸ `2Rt6xK2jQfh7VhA5` — **OPS TAREAS — Backfill agencia_id [MANUAL]**. Sibling del anterior. RPC `backfill_agencia_id_pendientes()` → PATCH Bubble (`agencia_id = e748c7d4-5823-413d-8cb3-532896f6e41d`). Tag `portal` pendiente UI. Pendiente disparar para repoblar 303 tareas con `agencia_id` NULL.
- ⏸ `FqWqBN2NzWGCpB2w` — **OPS TAREAS — Backfill url [MANUAL]**. Mismo patrón. RPC `backfill_url_pendientes()` reconstruye URL Notion como `https://www.notion.so/<notion_id sin guiones>` para 303 tareas con `url` NULL. Tag `portal` pendiente UI.
- ✅ `xzNDkDNiUOYOA2Ku` — **OPS LOG — Lifecycle Google Chat (Auto-Match Cliente)** (activo desde 2026-05-09, Fase 3 #2). Webhook `/gchat_log_inbound`. 10 nodos: JWT dual-issuer (`chat@system.gserviceaccount.com` + SA `gcp-sa-gsuiteaddons` que firma JWT en apps Marketplace SDK) → parser moderno `body.chat.{addedToSpacePayload|removedFromSpacePayload|messagePayload}.space` + fallback legacy → solo ADDED_TO_SPACE → GET clientes agencia → fuzzy-match local (lowercase + sin diacritics + alfanum, exact-then-contains) `displayName` vs `nombre_empresas` → PATCH `gchat_space_id` si match único. REMOVED diferido a Fase 4.
- ✅ `8snJvdNsmRM2yI2y` — **OPS LOG — Mensajes Google Chat (Pub/Sub)** (activo desde 2026-05-08, rollout multi-espacio 2026-05-09). Webhook `/gchat_pubsub_push` ← Pub/Sub topic `gchat-events-thenucleo`. 14 nodos: Validar JWT vía `tokeninfo` Google (sin crypto local — task runner bloquea `require('crypto')`/`require('https')`) → Decode envelope → Validar Evento → GET Cliente Bubble → pre-check anti-dup → Anthropic Classify Haiku 4.5 → GET Admin User (DWD) → POST Bubble `actividad_diaria_log`. Anti-duplicado doble (pre-check n8n + UNIQUE `gchat_message_id` Supabase). **24 subs Workspace Events activas** sobre `gchat_subscriptions` (rollout 2026-05-09). Detalle en `docs/portal/integraciones/google-chat-log.md`.
- ✅ `gJfDb3Gwrf7fJ8Li` — **OPS LOG — Crear Subscription Google Chat por Cliente** (activo desde 2026-05-08). Webhook `/gchat_subscription_create`. Crea subscription Workspace Events API para el space indicado. INSERT en `gchat_subscriptions`. Invocado desde API Connector Bubble `obtener_id_gspace` (ficha cliente → botón "Vincular Google Chat").
- ✅ `4gN3uGhH8NZX2BDU` — **OPS ADS — Oyente Meta Ads (Gmail)** (LEGACY, sustituido por workflow Discovery + alertas derivadas del polling; archivar tras 2 semanas smoke verde). Trigger Gmail cada minuto. NO extrae métricas. Escribe en `bub_dashboardmedia_alertas_operativas`.
- ✅ `fdmkhBOua6pbZh6P` — **OPS ADS — Receptor Google Ads Script** (LEGACY Google Apps Script push). Pendiente migrar a polling Google Ads API con OAuth (estructura paralela Meta).
- ⏸ `Ik2Tt3Dw5ivL8qk7` — **OPS CRM — Oyente GHL [PAUSADO]**

### Ads — Control de Campañas v2 (Meta, activos desde 2026-05-12)
- ✅ `hwKBGC6QWP2dFObT` — **SYNC ADS — Meta Discovery Cuentas** (cron `*/30 8-21` Madrid). 6 nodos: RPC `ads_meta_creds_listas` → GET `/me/adaccounts` → mapear cuentas + derivar alertas (account_status 2/3/7/8/9, disable_reason) → fan-out UPSERT `ads_cuentas` + UPSERT `ads_alertas`. Tags `portal`+`ads`.
- ✅ `VhlqAQ1vH9HldpH5` — **SYNC ADS — Meta Estructura** (cron `30 5` daily Madrid). 9 nodos con loop SplitInBatches: itera `ads_cuentas` activas → 3 GETs Meta (campaigns/adsets/ads) → Code armar payload → RPC `ads_upsert_estructura` (UPSERT atómico FK-resolved). Tags `portal`+`ads`.
- ✅ `pIxC6RNqHISWvpoU` — **CRON ADS — Meta Daily 06:00**. 11 nodos: time_range día anterior → 4 GETs Meta level=account/campaign/adset/ad → RPC `ads_insertar_insights_diario` (UPSERT + extract_conversion + roas/cpa div-zero protección). Tags `portal`+`ads`.
- ✅ `Uqv3R3txzcg8GI1B` — **CRON ADS — Google Y Meta Intra-día 30min** (cron `*/30 8-21` Madrid, unificado 2026-05-21). 20 nodos, 2 ramas paralelas desde el mismo cron: **Google** (Descifrar Creds Google → Refresh OAuth Access Token → GET Cuentas eq.google → Iterar → 3 GAQL Snapshot campaign/ad_group/ad_group_ad LAST_7_DAYS → Armar Payload Google → RPC `ads_actualizar_kpis_snapshot` → RPC `ads_calcular_scoring`) y **Meta** (Descifrar Creds Meta → GET Cuentas eq.meta → Iterar → 3 GET Insights `date_preset=last_7d` level=campaign/adset/ad → Armar Payload → RPC `ads_actualizar_kpis_snapshot` → RPC `ads_calcular_scoring`). Tags `portal`+`ads`.
- ⏸ `BCgSCKjzryYaFYMC` — **CRON ADS — Meta Intra-día 30min** (LEGACY, INACTIVO desde 2026-05-21, sustituido por `Uqv3R3txzcg8GI1B` unificado Google+Meta). Tags `portal`+`ads`.
- ✅ `sNpVWEkinc4g0KfA` — **OPS ADS — Acciones Bubble [WEBHOOK]** (endpoint POST `/webhook/ads_action`). 17 nodos. Switch v3.4 mode expression por `body.action` → 3 branches: **refresh** (re-poll Meta + UPSERT KPIs + scoring), **status_toggle** (POST Meta `<entity_id>` con status + RPC `ads_aplicar_status_toggle` que UPDATE+INSERT notas+activity_log), **nota_crear** (RPC `ads_notas_crear`). Cada branch su propio Respond to Webhook. Tags `portal`+`ads`.

### IA Cerebro
- ✅ `JI5Tr7IogqXgaI7a` — **IA Cerebro — Chat por Cliente**
- ✅ `7yjLwl4cEJa7XAYY` — **IA Cerebro — Tool Loop [SUB]**
- ✅ `NI1oUwIY99TGk496` — **IA Cerebro — Indexar Drive [SUB]**
- ✅ `BqNTrwoQ2iJIcAB4` — **IA Cerebro — Reindexar RAG Manual [WEBHOOK]**

### IA Newsletter
- ✅ `inWFSAEDLCH1kx5P` — **IA Newsletter — Entrada**
- ✅ `SfwR7gqs1hBIOV7i` — **IA Newsletter — Tool Loop [SUB]**
- ✅ `9wnB9NI8Capa4b8s` — **IA Newsletter — Entrega [SUB]**
- ✅ `w6Gqo8B6Sqp6Mq9x` — **IA Newsletter — KB Fetch [SUB]**
- ✅ `UBYXNKZ1HHFTZyDX` — **IA Newsletter — Init**
- ✅ `u9DsFadbpb7QiLaP` — **IA Newsletter — Trigger Entrega**

### IA Análisis Estratégico (sector 7)
- ✅ `dtgF0G35aeJQVVfn` — **IA Análisis — Entrada** [Webhook]
- ✅ `FFhkdTFCjTtfyvhP` — **IA Análisis — Tool Loop [SUB]**
- ✅ `QW8VZ9cV5ECsSKvZ` — **IA Análisis — Entrega [SUB]**
- ✅ `JtXdkXHm6RyGOJft` — **IA Análisis — Trigger Entrega** [Webhook]
- ✅ `Cfs3NFEE1enu1jTx` — **IA Análisis — KB Fetch [SUB]**
- ✅ `8hAokf6zfQl0dMlR` — **IA Análisis — Init**

### INTEGRACIONES — Multi-provider F1
- ✅ `QBLy4DWZ7mUPsfpg` — **INTEGRACIONES — Registrar Webhooks Provider [SUB]**
- ✅ `4e9s6FpYlWiYlcI9` — **INTEGRACIONES — Rotar Token Provider [SUB]**
- ✅ `SMOKYPAzGAYrgpLK` — **INTEGRACIONES — Descubrir Clientes Provider [SUB]**
- ✅ `o32vrctYqibCA5C2` — **INTEGRACIONES — Probar Conexión Provider [SUB]**
- ⏸ `jsAnENkkzfTs6Kzu` — **INTEGRACIONES — Obtener Estados Espacio ClickUp [SUB]**

### SUB — Subworkflows compartidos
- ✅ `d0B4LokmPhHWdg6g` — **SUB — Carpetas Cliente Drive** (invocado por `wvHcgVqqjkWJcJDu`. `active: false` por diseño)

### ERRORES
- ✅ `HRDQ9Ju4NAIUV0qyhKzlz` — **ERRORES — Capturar y Registrar Plataforma**. Captura errores de cualquier workflow, los enriquece con Claude y los inserta en `n8n_incidencias`. Visualizables en panel cerrado `work.thenucleo.com/incidencias` (Edge Function `incidencias_api`).

## Reglas de trabajo
- No inventar datos. Preguntar antes de asumir.
- Ser conciso y esquemático.
- No lanzar opcionales. Dar resolución directa.
- No ampliar a "siguientes pasos" no solicitados.
- Notion/clickup es master de tareas. Para clientes y miembros, ver estado actual de syncs en sección Arquitectura de datos.
- **Si modificas un workflow n8n (nodo, trigger, schedule, onError, etc.), actualiza su entrada en `docs/infra/n8n-workflows.md` antes de cerrar la sesión.** Si el cambio encaja con un anti-patrón conocido o introduce uno nuevo, reflejarlo también en la sección "Lecciones aprendidas". Incidencias resueltas van al "Historial de fixes críticos" del mismo doc y a la tabla de `docs/README.md`.
- **Si CREAS un workflow nuevo del Portal en n8n, asígnale el tag `portal` antes de activar.** Sin tag, el workflow no entra al backup automático en `marketingthenucleo/n8nthenucleo` (filtrado por tag desde 2026-05-06). Vía `PUT /api/v1/workflows/{id}/tags. Detalle en skill `n8n`.

## Documentación detallada
**Empezar por [[README|docs/README]]** — índice + troubleshooting + historial de incidencias.

Estructura `docs/` reorganizada por dominio (revisada 2026-05-20):

**Hubs:**
- `docs/README.md` — Índice maestro
- `docs/log-cambios.md` — Historial cronológico inverso
- `MOC.md` (raíz) — Mapa de contenido Obsidian

**`docs/infra/`** — Plataforma técnica (transversal):
- `ids-referencias.md` — IDs, tokens, credenciales
- `supabase-schema.md` — Schema completo con columnas, tipos, RLS
- `n8n-workflows.md` — Mapa workflows + **anti-patrones** (revisar siempre)
- `bubble-api-connectors.md` — 59 API Connector calls (12 grupos activos)

**`docs/portal/`** — Portal interno Bubble (portal.thenucleo.com):
- `README.md` — Hub del dominio + las 9 secciones
- `secciones-app.md` — Detalle funcional de las secciones
- `flujo-registro-saas.md` — Flujo registro/onboarding SaaS (en construcción)
- `chat-cocreativo-blueprint.md` — Blueprint chats IA co-creativos
- `notificaciones.md` — Módulo Notificaciones (sección 9)
- `sectores/` — Auditoría por área funcional (Tareas, Clientes, Reconciliaciones, Chats IA, Análisis)
- `integraciones/` — Sistemas externos que solo alimentan al Portal:
  - `clickup.md` — Multi-provider Notion+ClickUp
  - `google-chat-log.md` — Captura actividad desde Google Chat
  - `google-chat-dm-urgentes.md` — Plan DM privado a @mencionados
  - `control-de-campanias.md` — Meta Ads + Google Ads

**`docs/work/`** — Cara pública (work.thenucleo.com):
- `README.md` — Hub del dominio + Landing/Pricing/Blog/Comunidad/Playbook/Fichas/Casuísticas/Disponibilidades
- `blog-zenyx.md` — Blog SEO `/conocimiento-zenyx`
- `comunidad.md` — Comunidad pública (Eleventy + Supabase)
- `playbook.md` — Playbook onboarding cuarentena
- `fichas-de-producto.md` — Editor admin fichas de servicios
- `casuisticas.md` — Tablero kanban clasificación peticiones cliente
- `disponibilidades.md` — Calendario disponibilidad laboral equipo (AHORA/HOY/SEMANA, admin-only)

**`docs/addons/`** — Sistema de addons (cross-domain Portal + Work signup):
- `README.md` — Plan maestro + estado por fase (F1 ✅, F2/F3 pendientes)
- `bubble-spec-f1.md` — Spec Bubble F1
- `n8n-pendientes-f2.md` — Pendientes Stripe Coupons F2
- `f3-deploy-checklist.md` — Checklist deploy F3
- `bubble-import-addons-catalogo.csv` — Catálogo importable

**Cambio 2026-05-20:** la carpeta antigua `docs/integraciones/` se eliminó. Sus contenidos se redistribuyeron: ClickUp/GChat/Meta Ads → `docs/portal/integraciones/` (porque solo alimentan al Portal); Addons → `docs/addons/` (cross-domain).

## Estructura del workspace ⚠️ [REVISAR — Ben pasará lista actualizada]
- `docs/` — Documentación técnica (schema, workflows, API connectors, IDs)
- `Design/` — Assets de marca, mockups, auditoría UX, referencias (`screenshots-app/`, `assets/`, `referencias/`)
- `my-video/` — Proyecto Remotion para generación de vídeos (repo git independiente, uso futuro)
- `thenucleo-landing/` — Landing page work.thenucleo.com (repo git independiente, Vercel)

## Landing page — work.thenucleo.com
Proyecto en `thenucleo-landing/` (subcarpeta de este proyecto)
Stack: HTML + CSS + Three.js (SPA) + **Eleventy v3** (static site generator para el blog). Deploy en Vercel.

**Estado SEO (2026-04-19) — 4 de 5 críticos cerrados:**
- ✅ robots.txt + sitemap.xml apuntan a `work.thenucleo.com` (sitemap ahora dinámico vía `sitemap.njk`)
- ✅ Páginas legales: `privacidad.html` + `aviso-legal.html`
- ✅ JSON-LD completo: SoftwareApplication + Organization + WebSite en `index.html`
- ✅ OG image 1200×630 en `Media/og-image.png` (marcada como mejorable: fondo blanco sin tagline)
- ✅ Google Search Console verificado (URL prefix property) + sitemap enviado
- ⏸ **Stripe TEST → PROD pendiente intencional** — no tocar hasta que Ben finalice cuenta Stripe de producción

**Pendientes opcionales no críticos:**
- CSP header en `vercel.json` (ya hay HSTS)
- Self-host Google Fonts (eliminar bloqueo render externo — Space Grotesk + JetBrains Mono en línea 36-38 de index.html)
- Rehacer OG image v2 (fondo `#171717` + tagline)

## Blog Zenyx — work.thenucleo.com/conocimiento-zenyx
Blog público SEO generado automáticamente desde los vídeos del canal de Miguel Villamil (@soymiguelvillamil). 1 post/día a las 18:00 Madrid, orden cronológico (EP01 → EP41). Backlog de 75 vídeos precargados en Supabase.

- **Workflow n8n:** `CNlBtiFCwY69I6Wl` (BLOG Zenyx — DIARIO 18:00 Madrid)
- **Tabla Supabase:** `blog_videos` + vista `v_blog_videos_pendientes`
- **Repo destino:** `marketingthenucleo/thenucleo-landing` → `content/conocimiento-zenyx/*.md`
- **Stack frontend:** Eleventy v3 (markdown → HTML) sobre el `index.html` Three.js existente
- **Docs detalladas:** [[blog-zenyx|docs/work/blog-zenyx]]

⚠️ **NO confundir con el módulo Newsletter IA** (`newsletter_emails_wip` + workflows `inWFSAEDLCH1kx5P`+). El blog es público SEO, la Newsletter IA es interna por cliente.
