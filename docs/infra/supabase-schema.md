---
title: Schema Supabase
dominio: supabase
estado: activo
actualizado: 2026-05-22
tags: [supabase, schema, db]
---

# Supabase Schema — TheNucleo

Reescrito al 100% contra el schema real (auditoría 2026-04-25, purga de refs `maw` 2026-05-07).

**Proyecto único:** `cbixhqjsnpuhcrcjppah` (cbi · eu-west-1) — espejo Bubble + chats co-creativos + cache operativo + comunidad pública.

> El proyecto histórico `mawpgbtdvskmneqqcqag` (maw, eu-central-1) está **INACTIVE** desde mayo 2026. Toda la lógica activa apunta a cbi. Las menciones a maw que queden en este doc son histórico, no operación viva.

---

## Listado de tablas `bub_*` (40 tablas — espejo Bubble)

Escritas exclusivamente por el workflow `FGxG67I24POOUeHW` (SYNC ESPEJO — Bubble → Supabase) vía webhook reactivo desde DB Triggers Bubble. Read-only para todos los demás flujos.

### Core (23)

```
bub_actividad_diaria_log                   ← creada 2026-05-07 (Google Chat → log por cliente)
gchat_subscriptions                         ← creada 2026-05-08 (tracking Workspace Events Subscriptions)
bub_addons_agencia
bub_addons_catalogo
bub_addons_codigos_descuento
bub_agencia
bub_clientes
bub_dashboardmedia_alertas_operativas
bub_dashboardmedia_cuentas_ads
bub_integraciones                          ⚠️ deprecada — vacía, se eliminará en F7 del plan addons
bub_invitacion
bub_notificacion                            ← creada 2026-05-16 (módulo Notificaciones del Portal)
bub_notificacion_receptor                   ← creada 2026-05-16 (1 fila por destinatario)
bub_pagos_agencia_tarifa
bub_pagos_tarifa_catalogo
bub_plantillas_areas
bub_plantillas_subtareas_notion
bub_plantillas_tareas_notion
bub_rrhh_dpt_funcion
bub_rrhh_empleado_perfil
bub_rrhh_nps_registro
bub_tareas_notion
bub_triggers_catalogo
bub_user
```

### Catálogos / Option Sets (17 — `bub_os_*`)

```
bub_os_estado_facturacion          bub_os_periodo_facturas
bub_os_estado_incidencias          bub_os_periodo_suscripcion
bub_os_estado_propuesta            bub_os_prioridad_plantillas
bub_os_estado_tarifa               bub_os_rol_usuario
bub_os_estados_cliente             bub_os_rrhh_departamento
bub_os_niveles                     bub_os_rrhh_status_carga
bub_os_secciones                   bub_os_rrhh_tipo_contrato
bub_os_sector                      bub_os_tipo_propuesta
bub_os_tipo_tarifa
```

### Tablas Bubble eliminadas (histórico)

- `bub_servicios_productos_agencia` + `bub_servicios_productos_clientes` — DROP 2026-05-22. Espejos vacíos en Supabase (0 filas cada uno). Los Data Types Bubble homónimos nunca se usaron. Catálogo de servicios y junction cliente↔servicio viven ahora en tablas nativas `fichas_categorias` (12), `fichas_de_producto` (57) y `playbook_cliente_servicios` (199), editor en `work.thenucleo.com/fichas-de-producto/` y `/playbook/`. Bubble los lee como Data Types con el **mismo nombre** (`fichas_categorias` + `fichas_de_producto` + `playbook_cliente_servicios`) — bulk inicial 12+57+199 records hecho 2026-05-22 a Bubble LIVE vía workflow `ewu5A5E05T4tz5CD` (SYNC FICHAS — Supabase → Bubble). Quitadas también del `ALLOWED_TABLES` del workflow `FGxG67I24POOUeHW` (SYNC ESPEJO — Bubble → Supabase). Nomenclatura unificada Supabase↔Bubble.
- `bub_miembro_notion` — DROP 2026-05-02. IDs migrados a `bub_user` (campos `notion_id` + `clickup_user_id`). RPCs Clockify joinean ahora contra `bub_user.email`.
- `bub_comunidad_propuestas` + `bub_comunidad_comentarios` + `bub_comunidad_votos_propuesta` + `bub_comunidad_votos_comentario` — DROP 2026-04-28. Migración a comunidad pública nativa (`comunidad_*`, ver sección abajo).
- `bub_incidencias` — DROP 2026-04-27. Reemplazada por `n8n_incidencias` (operativa nativa, ver sección abajo).

⚠️ **Nombres correctos del schema real:** `bub_tareas_notion`, `bub_clientes`, `bub_user`, `bub_plantillas_tareas_notion`, `bub_plantillas_subtareas_notion`. **NO existen** `bub_tarea`, `bub_empresa`, `bub_miembro`, `bub_plantilla`, `bub_chat_mensaje`, `bub_newsletter_email`.

---

## Sistema de Addons (creado 2026-05-04)

- `bub_addons_catalogo` — 34 filas (6 nativos + 28 de pago). Catálogo de integraciones disponibles para los clientes. Campo `stripe_price_id` poblado en 7 filas tras 2026-05-11 (ActiveCampaign, HubSpot, Clientify, Odoo, Google Sheets, Monday, OneDrive); 21 restantes pendientes.
- `bub_addons_agencia` — Compras de addons por agencia.
- `bub_addons_codigos_descuento` — Cupones (sync con Stripe Coupons API en F2). 1 fila activa: `CodigoZenyx` (100% off, `stripe_coupon_id=codigozenyx`).

**Vistas públicas (lectura anon, alimentan build-time del onboarding `/onboarding/`):**
- `v_addons_catalogo_publico` — proyección sin campos sensibles del catálogo. `_data/addons.js` la consume.
- `v_tarifas_catalogo_publico` — Plan Base TheNucleo con 3 `stripe_price_id_{mensual,trimestral,anual}`. `_data/tarifas.js` la consume.

Plan completo en `~/.claude/plans/thenucleo-addons-onboarding-master-plan.md`. Estado por fase en [[addons/README|docs/addons/README]].

**`bub_integraciones` queda deprecada** (vacía, se eliminará en F7 del plan addons). Las credenciales operativas viven en `agencia_integraciones_config` (Supabase nativo, pgcrypto cifrado).

---

## Actividad Diaria Log (creado 2026-05-07)

Captura natural de logs operativos por cliente desde Google Chat. Detalle funcional en [[google-chat-log|docs/google-chat-log]].

### `bub_actividad_diaria_log`
Espejo de Bubble Data Type `actividad_diaria_log`. Escrito por `FGxG67I24POOUeHW` cuando el workflow `xzNDkDNiUOYOA2Ku` (`OPS LOG — Captura desde Google Chat`) crea una entrada en Bubble.

| Columna | Tipo | Notas |
|---|---|---|
| `bubble_id` | text PK | bubble unique id (renombrado desde `id` 2026-05-08 para machear convención SYNC ESPEJO) |
| `agencia_id` | text | |
| `cliente` | text | bubble id de bub_clientes (renombrado desde `cliente_id` 2026-05-08 para machear field Bubble) |
| `notion_id` | text | denormalizado para joins rápidos |
| `creator_id` | text | mantenido por SYNC ESPEJO desde Bubble `Created By` |
| `slug` | text | mantenido por SYNC ESPEJO desde Bubble `Slug` |
| `mensaje` | text | raw del chat |
| `mensaje_resumen` | text | 1 frase generada por Claude Haiku |
| `autor_email` | text | |
| `autor_nombre` | text | |
| `gchat_space_id` | text | espacio Google Chat origen |
| `gchat_message_id` | text UNIQUE | defensa anti-duplicado en reintentos Pub/Sub |
| `gchat_thread_id` | text | nullable |
| `clasificacion` | text | `status` \| `decision` \| `incidencia` \| `configuracion` \| `entrega` \| `otro` |
| `fecha_chat` | timestamptz | timestamp del mensaje original |
| `created_date` | timestamptz | |
| `modified_date` | timestamptz | |
| `oculto` | boolean NOT NULL DEFAULT false | añadido 2026-05-11. Soft-hide manual desde UI Bubble (checkbox por fila + botón "Limpiar todo"). RG del frontend filtra `oculto is no`. Reversible solo desde Bubble admin |
| `_synced_at` | timestamptz | mantenido por trigger `trg_set_synced_at` |

Índices: `cliente_id`, `agencia_id`, `fecha_chat DESC`, `(agencia_id, oculto, fecha_chat DESC)`. RLS enabled (sin policies, mismo patrón que el resto de `bub_*`).

> **Nota de naming:** se llama `actividad_diaria_log` (no `log_tareas`) para evitar confusión con `bub_tareas_notion` y las tareas de ClickUp. "Tarea" en TheNucleo es siempre del gestor; "actividad" es contexto humano libre escrito en chat.

### Campo nuevo en `bub_clientes`
- `gchat_space_id` (text, nullable) — formato `spaces/AAAA…`. Mapping manual al añadir el bot a cada espacio cliente. Indice parcial `bub_clientes_gchat_idx WHERE gchat_space_id IS NOT NULL`.

### `gchat_subscriptions` (creada 2026-05-08, Fase 2 v2)
Tracking de Workspace Events Subscriptions activas para renewal y auditoría. Una fila por (space, cliente).

| Columna | Tipo | Notas |
|---|---|---|
| `id` | text PK | name de la subscription Workspace Events. Formato `subscriptions/chat-spaces-XXX` |
| `space_id` | text NOT NULL | `spaces/AAAA…` |
| `cliente_bubble_id` | text | bubble unique id del cliente mapeado |
| `status` | text NOT NULL | `active` \| `suspended` \| `error` |
| `expire_time` | timestamptz | vence ~24h después de creación/renewal sin DWD |
| `last_renewed_at` | timestamptz | |
| `last_error` | text | |
| `created_at` | timestamptz NOT NULL | |
| `updated_at` | timestamptz NOT NULL | |

Sin RLS. Acceso solo desde n8n con service_role.

> **Source de verdad:** la subscription real vive en Google Workspace Events API. Esta tabla es solo tracking local para el cron de renewal (Fase 3) y auditoría.

---

## Columnas multi-provider (F0 plan v3 ClickUp — 2026-05-02 → 2026-05-07)

Añadidas para soportar coexistencia Notion + ClickUp en las mismas tablas polimórficas. Migration `f0_multiprovider_discriminator_columns`.

| Tabla | Columna | Tipo | Default | Significado |
|---|---|---|---|---|
| `bub_tareas_notion` | `provider` | text | `'notion'` | Discriminador. `'notion'` o `'clickup'`. |
| `bub_tareas_notion` | `external_id` | text | NULL | ID en el provider externo. Para Notion = `notion_id`. Para CU = `task_id`. |
| `bub_tareas_notion` | `external_url` | text | NULL | URL canónica al recurso. |
| `bub_tareas_notion` | `last_edit_source` | text | NULL | `'notion'`/`'clickup'`/`'bubble'`/`'user'`/`'cron'`. Marker anti-rebote multi-provider. |
| `bub_tareas_notion` | `metadata` | text | NULL | JSON-encoded. Campos provider-specific: `space_id`, `list_id`, `status_id`, `parent_external_id`, `dependencies[]`, etc. (CU). Vacío para Notion en MVP. |
| `bub_clientes` | `provider` | text | `'notion'` | Discriminador. |
| `bub_clientes` | `external_id` | text | NULL | Para CU = `folder_id` principal. Para Notion = `notion_id`. |
| `bub_clientes` | `last_edit_source` | text | NULL | Marker anti-rebote. |
| `bub_clientes` | `metadata` | text | NULL | JSON-encoded. Para CU: `lists_by_area` (mapa list_id ↔ área) cuando F2/F3 las pueble. |
| `bub_agencia` | `proveedor_tareas` | text | NULL | Provider XOR de la agencia. Espejo del Option Set Bubble `Proveedor de Tareas` (Display lowercase `notion`/`clickup`). Determina branch en routers Bubble→Provider. Migrado desde legacy `task_provider` el 2026-05-07. |
| `bub_agencia` | `metadata` | text | NULL | JSON-encoded. Para CU: keys `clickup_workspace_id`, `clickup_default_spaces[]`, `clickup_sync_lists[]`. Pobladas en F2.F al onboardear la agencia. |
| `bub_user` | `clickup_user_id` | text | NULL | ID del usuario en ClickUp API. Para mapeo de assignees bidireccional. |
| `bub_user` | `notion_id` | text | NULL | ID del usuario en Notion. Migrado desde `bub_miembro_notion` (DROP 2026-05-02). |

**Sentinel `cu_<folder_id>` en `notion_id`** (clientes ClickUp): el campo `notion_id` se mantiene como nombre histórico polimórfico. Para clientes CU se rellena con `cu_<folder_principal_id>`. Razón: ≥8 features (Cerebro IA, RAG stores, Newsletter, Análisis) filtran por `cliente_notion_id`. Renombrar la columna habría roto todo.

**Backfill ejecutado** (2026-05-02): 1.412/1.412 tareas + 74/74 clientes + 1/1 agencia con `provider='notion'` + `external_id=notion_id`.

⚠️ **Deuda técnica detectada (pendiente cleanup):** 231 grupos de `notion_id` duplicados en `bub_tareas_notion` (472 filas). Mezcla de filas test + live de Bubble. Documentado en `docs/log-cambios.md` 2026-05-02. No afecta a F1/F2 — los discriminadores están correctamente populados.

---

## Tablas operativas no-`bub_*` en cbi

### Chat IA (3)

#### `chat_conversations`
| Columna | Tipo | Notas |
|---|---|---|
| id | uuid (PK) | |
| agencia_id | uuid | |
| user_bubble_id | text | |
| tipo | text | ver patrones |
| estado | text | |
| metadata | jsonb | |
| created_at | timestamptz | |
| updated_at | timestamptz | |

⚠️ NO hay columna `empresa_id`. El cliente se guarda en `tipo` (ej: `cerebro_<notion_id>`) o en `metadata`.

**Patrón `tipo` por sector:**

| Sector | Patrón |
|---|---|
| Cerebro IA | `cerebro_<notion_id>` |
| Newsletter IA | `newsletter_<notion_id>` |
| Análisis Estratégico | `analisis_<bubble_id>` |

**UNIQUE constraint** sobre `(agencia_id, tipo)`.

#### `chat_messages` — FIFO 100 por conversación
| Columna | Tipo |
|---|---|
| id | uuid (PK) |
| conversation_id | uuid (FK) |
| role | text — `user`/`assistant` |
| content | text |
| metadata | jsonb |
| created_at | timestamptz |

**Trigger:** `trigger_cleanup_messages` (AFTER INSERT) — mantiene máximo 100 mensajes por conversation.

#### ~~`tarea_en_progreso`~~ 🗑 DROPPEADA 2026-05-14
WIP del Chat Tareas legacy (obsoleto desde 2026-04-25). Tabla droppeada con `CASCADE` el 2026-05-14 — 0 filas, 0 consumidores activos. Migration `drop_tarea_en_progreso_legacy`. Los 2 workflows n8n huérfanos (`RPdNg5ZNXK0VrOhG` + `aGML9yyMsoAQ6ZGL`) estaban ya archivados. API Connector Bubble `chat_creacion_mensajes` borrada el mismo día (0 usos en Search Tool).

### WIP de chats co-creativos

#### `analisis_wip` — Análisis Estratégico Cliente (sector 7)
Briefing 12 secciones fijas + array `segmentos` con 4 objetos `{nombre, descripcion, problematica, oportunidad, empatia, buyer_persona, angulos}`. RLS habilitada. Trigger `analisis_wip_updated_at` BEFORE UPDATE.

#### `newsletter_wip` — Newsletter IA (antes `newsletter_emails_wip`)
Estado WIP completo del Newsletter IA por conversación: estrategia, array `emails[]`, `doc_url` del Word generado en Drive. **Renombrada de `newsletter_emails_wip` → `newsletter_wip`** durante refactor 2026-04-29. Trigger `newsletter_wip_updated_at`.

### RAG y Drive

#### `rag_stores`
fileSearchStores Gemini por cliente/tipo (`cerebro`, `newsletter`, `analisis`). Solo guarda `store_id` + `indexed_at`, NO la lista de archivos. Auditoría de archivos fuente pendiente (memoria `project_rag_archivos_pendiente.md`). Trigger `rag_stores_updated_at`.

### Blog

#### `blog_videos` — Cola y archivo del CRON BLOG Zenyx Diario 18:00 (~75 filas)
| Columna | Tipo |
|---|---|
| id | uuid (PK) |
| orden | integer |
| video_id, video_url, video_title | text |
| estado | text — `pendiente`/`publicado`/`error` |
| title, slug, excerpt, markdown_body | text |
| transcript_length, transcript_source | text |
| github_commit_sha, github_path | text |
| error_msg | text |
| agencia_id | uuid |
| created_at, updated_at, published_at | timestamptz |

**Workflow productor:** `CNlBtiFCwY69I6Wl` (CRON BLOG — Zenyx Diario 18:00). **Vista consumidora:** `v_blog_videos_pendientes`. Trigger `tg_bv_updated_at`.

### Time tracking (Clockify)

- `clockify_time_entries` — sync activo vía workflow `ccPQuZmH7DGYRRbe` (CRON 23:00 Madrid, ventana 35 días).
- `clockify_tarifas` — tarifas miembro (PK `email`, columna `tarifa_mensual`). ⚠️ workflow de sync pendiente reactivar.

### Finanzas (Holded)

- `holded_facturas`, `holded_metricas`, `holded_sync_log` — sync vía workflow `vI3TbyxtFM6wjhBS` (FINANZAS Holded → cbi, ACTIVADO 2026-04-25).

### Multi-provider (creadas F1 plan v3 ClickUp)

#### `provider_webhooks` — Registry de webhooks ClickUp por agencia
PK compuesta `(agencia_id, provider, webhook_id)`. Registra `webhook_secret`, `status`, `last_event_at`. RLS deshabilitado (operativa n8n con service_role).

#### `sync_suppress` — Anti-rebote ventana 30s
PK `(external_id, provider)`. Suprime actualizaciones de un external_id/provider hasta `until_ts`. Workflow CRON `ek5veFfwbeSB0bW3` (cada 5 min) borra expiradas.

#### `cliente_external_links` — Cliente:Folder es 1:N
PK uuid + UNIQUE `(provider, external_id)`. Modela la relación. Un Cliente Bubble = N folders en N Spaces de CU.

### Operativos varios

- ~~`workflow_executions`~~ 🗑 DROPPEADA 2026-05-14. Tabla del Ops Monitor abandonado al 80% — 1 fila zombie de hace 23 días en estado `cancelando`, 0 escrituras n8n recientes, 3/4 calls Bubble con 0 usos. Migration `drop_workflow_executions_legacy`. Trigger + policies RLS eliminados en cascada.
- `activity_log` — Auditoría global. RLS desactivado.
- `cliente_external_links` (ver arriba).

### Playbook compartido — `playbook_onboarding` (desde 2026-05-11)

Single-row table (slug PK) que persiste la escaleta operativa editable de onboarding TheNucleo. Consumida por `work.thenucleo.com/playbook` — Ben + Alex editan vía Google OAuth, resto del equipo lee.

```
slug          text PK              -- siempre 'default' por ahora; preparado para multi-playbook
data          jsonb NOT NULL       -- array de tareas {id, day, dayKey, phase, title, owners[], client, reg, notas, est, ...}
updated_at    timestamptz NOT NULL DEFAULT now()
updated_by    text                 -- email del editor que hizo el último PATCH
```

**RLS activado**, 2 policies:
- `playbook_read_all` (SELECT, `USING true`) — lectura pública via anon. Sin login se ve la escaleta.
- `playbook_update_editors` (UPDATE) — `USING lower(auth.jwt() ->> 'email') = ANY(ARRAY['benjamin.sanchis@thenucleo.com','alejandro.lopez@thenucleo.com','marketing.thenucleo@gmail.com','mel.dalmazo@thenucleo.com'])`. Sin INSERT/DELETE policies → solo se edita la fila default.

**Trigger:** `playbook_onboarding_updated_at` BEFORE UPDATE reusa `public.update_updated_at`.

**Sin FKs ni triggers cross-table.** Aislada del resto del schema. Frontend hace `PATCH /rest/v1/playbook_onboarding?slug=eq.default` con debounce 600ms; auth Google compartida con `/comunidad/entrar/` (mismo `storageKey thenucleo-comunidad-auth`).

**Editores actuales (2026-05-15):** Ben + Alex + marketing.thenucleo@gmail.com + Mel.

**Para añadir editores:** DROP+CREATE las **4** policies que comparten allowlist (`playbook_update_editors`, `playbook_progreso_write`, `pcs_editor_all`, `ptf_editor_all`) + añadir email al `Set EDITOR_EMAILS` en `thenucleo-landing/playbook/index.html`. Si crece a 5+, migrar a tabla `playbook_editors(email)` con policy `IN (SELECT email FROM playbook_editors)` para evitar la duplicación en 4 sitios. Síntoma de allowlist desincronizada (frontend SÍ, RLS NO): el editor pulsa el control, no ve error, pero al recargar el cambio no está. Detalle en [playbook.md](../work/playbook.md).

### Playbook por cliente — `playbook_progreso` + `v_playbook_clientes` (desde 2026-05-12)

Capa de progreso por cliente sobre el playbook maestro. Permite que el admin marque qué tareas de la escaleta están realmente ejecutadas para cada cliente, sin duplicar la plantilla. El frontend `work.thenucleo.com/playbook/` añade un dropdown de cliente que pinta la barra de progreso teórico (`(hoy − fecha_onboarding) / 95 días`) sobre el `timeline-track` y los checkboxes leen/escriben aquí.

#### `playbook_progreso`
```
cliente_bubble_id  text NOT NULL       -- bubble_id de bub_clientes
task_id            integer NOT NULL    -- t.id dentro del jsonb playbook_onboarding.data
done               boolean NOT NULL DEFAULT false
done_at            timestamptz
done_by            text                -- email del editor que marcó
updated_at         timestamptz NOT NULL DEFAULT now()
PRIMARY KEY (cliente_bubble_id, task_id)
```

**RLS activado**, 2 policies:
- `playbook_progreso_read` (SELECT) — `USING true` a `authenticated`. Cualquier logueado puede ver progreso.
- `playbook_progreso_write` (ALL) — solo allowlist por email JWT (mismo array que el master playbook). Sin sesión no se puede leer ni escribir. **2026-05-15:** normalizada con `lower()` (antes match case-sensitive — bug latente) y añadida Mel.

**Índice:** `playbook_progreso_cliente_idx` sobre `cliente_bubble_id` (filtro habitual del frontend).

**Sin trigger `updated_at`** — el frontend manda `updated_at: new Date().toISOString()` explícito en cada upsert. Si crece la concurrencia, añadir `BEFORE UPDATE` con `public.update_updated_at`.

**Patrón de write:** `POST /rest/v1/playbook_progreso?on_conflict=cliente_bubble_id,task_id` con `Prefer: resolution=merge-duplicates,return=minimal`. Upsert atómico.

#### `v_playbook_clientes`
```sql
SELECT bubble_id, nombre_empresas, fecha_onboarding, agencia_id, estado, sector
FROM public.bub_clientes
WHERE fecha_onboarding IS NOT NULL
  AND COALESCE(estado, '') <> 'No Activo'
ORDER BY nombre_empresas;
```

**`GRANT SELECT TO authenticated`** + **`ALTER VIEW ... SET (security_invoker = off)`** (aplicado 2026-05-12 tras detectar que `bub_clientes` no tiene policies `authenticated` → la vista heredaba RLS y devolvía 0 filas). Con `security_invoker=off` la vista corre con los privilegios del owner (bypass de RLS de `bub_clientes`). Seguro porque la vista limita columnas (4) y filas (`fecha_onboarding IS NOT NULL`).

**Estado actual (2026-05-15):** 15 clientes elegibles (estado `Activo` + `fecha_onboarding` poblada). Total `bub_clientes`: 34 Activo + 42 No Activo. Excluidos del playbook: 42 `No Activo` + 19 `Activo` con `fecha_onboarding` NULL. Para incluir más: cambiar `estado` a `Activo` y/o rellenar `fecha_onboarding` en Bubble (sync via SYNC ABSOLUTO `FGxG67I24POOUeHW`). Filtro simplificado de `NOT IN ('Pausado','Antiguo')` a `<> 'No Activo'` el 2026-05-15 tras migración OS Bubble 6→2 estados.

#### `playbook_publico(p_bubble_id text)` — RPC pública (desde 2026-05-12)

```
RETURNS jsonb { cliente: {bubble_id, nombre_empresas, fecha_onboarding, sector}, progreso: [task_id...], tasks: [...] }
SECURITY DEFINER · STABLE · search_path = public
GRANT EXECUTE TO anon, authenticated
```

Combina en una sola llamada lo que necesita `/playbook/<bubble_id>` en modo anon: lee `bub_clientes` con los mismos filtros que `v_playbook_clientes`, agrega los `task_id` con `done=true` de `playbook_progreso` y la `data` jsonb de `playbook_onboarding.slug='default'`. Devuelve `NULL` si el `bubble_id` no existe / no cumple filtros — el frontend renderiza `showAnonError()` ("Enlace privado o no disponible").

**Anon-safe por diseño:** solo devuelve la fila cuyo `bubble_id` ya conoces. No hay endpoint de enumeración. El `bubble_id` actúa como handle opaco no enumerable (≈ 32 chars alfanuméricos). Consumida desde `thenucleo-landing/playbook/index.html` función `fetchPlaybookPublico()`.

#### `playbook_cliente_servicios` — relación cliente ↔ ficha de producto (desde 2026-05-14)

```
id                 uuid PK DEFAULT gen_random_uuid()
cliente_bubble_id  text NOT NULL
ficha_id           uuid REFERENCES fichas_de_producto(id) ON DELETE SET NULL
ficha_titulo       text NOT NULL         -- denormalizado, resiliente a borrado de ficha
categoria_nombre   text                  -- denormalizado
categoria_color    text                  -- denormalizado (hex)
precio             numeric               -- €/mes acordado con el cliente
unidades           text                  -- "3 posts/mes", "1 campaña/trimestre", etc.
periodo            text NOT NULL DEFAULT 'mensual'  -- mensual|trimestral|anual|único
notas              text
orden              integer NOT NULL DEFAULT 0
created_at         timestamptz NOT NULL DEFAULT now()
INDEX (cliente_bubble_id, orden)
```

**RLS:** habilitada. Policy `pcs_editor_all` (ALL) — allowlist de emails de editor (misma que `playbook_onboarding`). Solo `authenticated` puede leer/escribir. `GRANT SELECT, INSERT, UPDATE, DELETE TO authenticated`.

**Consumidor:** panel lateral de `work.thenucleo.com/playbook/` en modo editor con cliente seleccionado. CRUD directo vía REST (`/rest/v1/playbook_cliente_servicios`). No consume n8n ni Bubble.

#### `playbook_cliente_detalle(p_bubble_id text)` — RPC editor-gated (desde 2026-05-14)

```
RETURNS jsonb { cliente: {19 campos de bub_clientes}, servicios: [...] }
SECURITY DEFINER · STABLE · search_path = public
GRANT EXECUTE TO authenticated
```

Comprueba internamente que `lower(auth.jwt() ->> 'email')` esté en la allowlist de editores (hardcoded en el body, **no usa RLS** porque SECURITY DEFINER la bypasea). Si no, devuelve `NULL`. Devuelve el perfil completo del cliente (identidad, estado, facturación, contacto, fechas) más el array de servicios de `playbook_cliente_servicios`. Anon-safe por construcción (anon no tiene token válido para la allowlist). Consumida desde `thenucleo-landing/playbook/index.html` función `fetchClienteDetalle()`.

⚠️ Esta RPC es el **5º sitio** server-side donde vive la allowlist (las otras 4 son policies RLS). Si añades un editor a las policies pero olvidas la RPC, la UI muestra el panel "Ficha del cliente" pero queda vacío sin error visible. Caso 2026-05-15 con Mel.

**Diferencia con `playbook_publico`:** esta RPC expone datos internos (facturación, contacto, NPS, etc.) y está restringida a editores. `playbook_publico` es pública (anon) y solo expone datos seguros para el cliente final.

#### `playbook_task_feedback` — dudas y notas de tarea por cliente (desde 2026-05-14)

```
id                 uuid PK DEFAULT gen_random_uuid()
cliente_bubble_id  text NOT NULL
task_id            integer NOT NULL
es_duda            boolean NOT NULL DEFAULT false
nota               text
updated_at         timestamptz NOT NULL DEFAULT now()
UNIQUE(cliente_bubble_id, task_id)
```

**RLS:** habilitada. Policy `ptf_editor_all` (ALL) — misma allowlist email de editores. `GRANT SELECT, INSERT, UPDATE, DELETE TO authenticated`.

**Consumidor:** botones ⚠ Duda y + Nota en cada task card del timeline de `work.thenucleo.com/playbook/` (modo editor con cliente seleccionado). UPSERT directo vía REST con `Prefer: resolution=merge-duplicates`. Cargado en paralelo con `playbook_progreso` al seleccionar cliente. Invisible en anon-mode.

### Fichas de Producto — `fichas_categorias` + `fichas_de_producto` (desde 2026-05-13)

Catálogo editable inline del catálogo de servicios de la agencia. Admin-only en lectura **y** edición — reusa `comunidad_admins` + `is_comunidad_admin()` como gate único. Consumido por `work.thenucleo.com/fichas-de-producto/`. Detalle funcional en [[fichas-de-producto]].

#### `fichas_categorias`
```
id           uuid PK DEFAULT gen_random_uuid()
nombre       text NOT NULL
slug         text NOT NULL UNIQUE
orden        int NOT NULL DEFAULT 0
icono        text                              -- hint, no usado en UI todavía
color        text                              -- hex para dot + bar visual
created_at   timestamptz NOT NULL DEFAULT now()
updated_at   timestamptz NOT NULL DEFAULT now()
INDEX fichas_categorias_orden_idx (orden)
```

**Seed (12 filas):** Onboarding · Google Ads · Meta Ads · CRM · Google My Business · Redes Sociales · Producción Audiovisual · Soporte · Consultoría · Canales Externos · Materiales · Desarrollo.

#### `fichas_de_producto`
```
id             uuid PK DEFAULT gen_random_uuid()
categoria_id   uuid NOT NULL FK → fichas_categorias ON DELETE RESTRICT
titulo         text NOT NULL
slug           text NOT NULL                    -- UNIQUE(categoria_id, slug)
orden          int NOT NULL DEFAULT 0
estado         text NOT NULL DEFAULT 'borrador' CHECK (estado IN ('borrador','publicada','archivada'))
unidad         text NOT NULL DEFAULT ''
alcance        text NOT NULL DEFAULT ''
herramientas   text NOT NULL DEFAULT ''
no_incluye     text NOT NULL DEFAULT ''
flexibilidad   text NOT NULL DEFAULT ''
sop_url        text NOT NULL DEFAULT ''           -- URL al SOP. Añadido 2026-05-16.
created_at     timestamptz NOT NULL DEFAULT now()
updated_at     timestamptz NOT NULL DEFAULT now()
INDEX fichas_de_producto_categoria_orden_idx (categoria_id, orden)
```

**Seed (63 filas):** parseadas del `.md` que Ben envió (5 bloques fijos por ficha según plantilla Unidad / Alcance / Herramientas / NO incluye / Flexibilidad). Los huecos `[???]` del documento original quedan como texto literal editable. Todas en `borrador`.

**Triggers:** `BEFORE UPDATE` en ambas tablas reusa función `trg_comunidad_set_updated_at()`.

**RLS:** habilitada en ambas. 8 policies (4 por tabla — `fc_select_admin`, `fc_insert_admin`, `fc_update_admin`, `fc_delete_admin` + equivalentes `fp_*`), todas con `USING/WITH CHECK public.is_comunidad_admin()` a `authenticated`.

**GRANTs:** `authenticated` SELECT+INSERT+UPDATE+DELETE (RLS filtra), `service_role` ALL. Sin GRANT explícito a `anon` — los grants default de PostgREST sumados a la RLS dan `200 + []` para anon (no leak).

**Frontend:** `thenucleo-landing/fichas-de-producto/index.html` (792 líneas, standalone HTML+CSS+JS inline, clon del Playbook). Lectura: GET `/rest/v1/fichas_categorias?select=*&order=orden.asc` + GET `/rest/v1/fichas_de_producto?select=*&order=categoria_id.asc,orden.asc` con `Authorization: Bearer <jwt-user>`. Escritura: PATCH por `(id, field)` con debounce 500ms; POST para crear (`Prefer: return=representation`); DELETE para borrar; reordenar = 2 PATCHes en serie con rollback.

**Admins actuales (4 cuentas, sincronizados con `comunidad_admins`):** Ben + marketing.thenucleo + Alex López + Mel Dalmazo. Si añades a alguien: INSERT en `comunidad_admins` + actualizar `Set EDITOR_EMAILS` en `fichas-de-producto/index.html`.

### Ficha de Cliente — RPCs sobre `bub_clientes` (desde 2026-05-22)

Consumidas por `work.thenucleo.com/ficha-cliente/` (admin allowlist). Resuelve que `bub_clientes` no tiene policies para `authenticated` (0 policies, RLS activa → 0 filas para clientes JWT) sin tener que añadirlas — mismo patrón que `playbook_publico` / `playbook_cliente_detalle`. Detalle funcional en [[ficha-cliente|docs/portal/secciones-app#ficha-cliente]].

#### `ficha_cliente_listar()` — selector de clientes

```sql
RETURNS TABLE(bubble_id text, nombre_empresas text, sector text, estado text, fecha_onboarding timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
```

Allowlist hardcoded en el body (`benjamin.sanchis`, `alejandro.lopez`, `marketing.thenucleo`, `mel.dalmazo`). `RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501'` si el email no está. Devuelve clientes con `COALESCE(estado,'') <> 'No Activo'` ordenados alfabéticamente. `GRANT EXECUTE TO authenticated`. Consumida desde `init()` para poblar el sheet del selector.

#### `ficha_cliente_get(p_bubble_id text)` — detalle del cliente

```sql
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
```

Misma allowlist. Devuelve `to_jsonb(c.*)` del cliente con TODAS las columnas de `bub_clientes` **+ array `servicios`** (desde 2026-05-22, migration `ficha_cliente_get_incluir_servicios`): `jsonb_agg(pcs.*)` de `playbook_cliente_servicios` JOIN-ed por `cliente_bubble_id`, ordenado por `orden NULLS LAST, created_at`. Cada objeto del array trae `ficha_titulo`, `categoria_nombre`, `categoria_color`, `unidades`, `periodo`, `notas`, `orden`. El frontend filtra qué muestra: identificación, contacto, presencia web, operaciones internas (Drive, análisis, gchat_space_id, NPS, facturación). Los campos que no están en el espejo (Instagram, Meta BM, GHL, DNS, etc.) se renderizan con badge `MOCKUP` visible. `GRANT EXECUTE TO authenticated`.

> El campo `bb_servicios_contratados` fue **eliminado de `bub_clientes` el 2026-05-22** (legacy huérfano, 78 clientes con array vacío). La RPC nunca lo devolvió porque la columna ya no existía cuando el frontend intentaba leerla — síntoma: el panel "Servicios contratados" mostraba "Sin servicios" aunque el cliente tuviera 32 en `playbook_cliente_servicios`. Fix: ampliar la RPC con el `jsonb_agg` arriba descrito.

⚠️ **Allowlist en 7 sitios ahora** (antes 6 con playbook): frontend `playbook`, `fichas-de-producto`, `ficha-cliente` + RLS policies de `playbook_progreso`/`playbook_task_feedback`/`playbook_cliente_servicios` + RPC `playbook_cliente_detalle` + RPCs `ficha_cliente_listar` y `ficha_cliente_get`. Si añades editor: actualizar los 7.

### Pipelines y Campañas — 5 tablas nativas (F2, desde 2026-05-24)

Backend del módulo "Pipelines y Campañas" de `work.thenucleo.com/ficha-cliente/` (frontend F1 vivo desde 2026-05-23 con SEED hardcoded en `ficha-cliente/index.html:1677-2100`). Visión operacional completa en [[../portal/ficha-cliente]] (modelo PxCx, 7 reglas, casuísticas). Migration `ficha_cliente_pipelines_f2_schema`, también vive en `supabase/migrations/20260524_ficha_cliente_pipelines_f2_schema.sql` del repo landing.

**Decisiones de schema (sesión 2026-05-24):**
- Plantillas por agencia (`agencia_id` NOT NULL, no global) — coherente con `bub_plantillas_tareas_notion`.
- FK a clientes via `bubble_id text` (patrón `playbook_cliente_servicios`, no `cliente_id uuid`).
- `triggers_aplicables text[]` de subcódigos (`'FM1','FW1'`) en vez de uuid[]: la regla `.docx` "los códigos no caducan ni se reutilizan" (caso 6) garantiza integridad sin FK formal y evita JOIN extra en la RPC `_get`.
- Estados finos por capa (visión §2 original, **NO** los 3 unificados `declarada/en-produccion/archivada` del SEED actual del frontend — impacto en `stateBadge()` del frontend documentado abajo).

#### `cliente_campania_plantillas` — catálogo abierto de plantillas, por agencia
```
id                  uuid PK DEFAULT gen_random_uuid()
agencia_id          text NOT NULL
slug                text NOT NULL                          -- 'venta-meta','capt-fm'...
nombre              text NOT NULL
descripcion         text
triggers_tipicos    jsonb NOT NULL DEFAULT '[]'            -- array {tipo, nombre}
emails_tipicos      jsonb NOT NULL DEFAULT '[]'            -- array {nombre, espera, objetivo}
campos_briefing     jsonb NOT NULL DEFAULT '[]'            -- array strings
roles_default       jsonb NOT NULL DEFAULT '{}'            -- {copy, diseno, meta, ghl,...}
briefing_master_url text
kpi_default         text
presupuesto_default numeric
estado              text NOT NULL DEFAULT 'activa' CHECK (estado IN ('activa','archivada'))
orden               int  NOT NULL DEFAULT 0
created_at, updated_at timestamptz                          -- updated_at via trigger reusa update_updated_at()
created_by          text DEFAULT auth.email()
UNIQUE (agencia_id, slug)
INDEX cliente_campania_plantillas_agencia_estado_idx (agencia_id, estado)
```
**Seed (7 filas, agencia TheNucleo `1769513105728x555492736219132700`):** Venta Directa con anuncio Meta · Captación leads FM · Captación leads FW · Reactivación BBDD · Newsletter recurrente · Lanzamiento multicanal · Evento. Mismo set que `PIPELINES_MODULE.PLANTILLAS` del frontend.

#### `cliente_pipelines` — líneas estratégicas por cliente
```
id                  uuid PK
cliente_bubble_id   text NOT NULL REFERENCES bub_clientes(bubble_id) ON DELETE CASCADE
codigo              text NOT NULL                          -- 'P1','P2'... secuencial por cliente
nombre              text NOT NULL
objetivo_negocio    text
estado              text NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','archivado'))
responsable_account text                                   -- bubble_id de bub_user
notas               text
orden               int NOT NULL DEFAULT 0
created_at, updated_at, created_by
UNIQUE (cliente_bubble_id, codigo)
INDEX cliente_pipelines_cliente_idx (cliente_bubble_id)
```

#### `cliente_campanias` — acción concreta dentro de un pipeline
```
id                  uuid PK
pipeline_id         uuid NOT NULL REFERENCES cliente_pipelines(id) ON DELETE CASCADE
codigo              text NOT NULL                          -- 'P1C1' (denormalizado)
nombre              text NOT NULL
plantilla_id        uuid REFERENCES cliente_campania_plantillas(id) ON DELETE SET NULL
estado              text NOT NULL DEFAULT 'declarada' CHECK (estado IN ('declarada','en-produccion','archivada'))
fecha_inicio, fecha_fin date                               -- NULL fin = recurrente
presupuesto_eur     numeric
canal_principal     text                                   -- Meta/Google/Email/Organico/Mixto
kpi_objetivo        text
link_briefing_drive text
briefing_nombre     text
responsable_pm      text                                   -- bubble_id de bub_user
notas_account       text
created_at, updated_at, created_by
UNIQUE (pipeline_id, codigo)
INDEX cliente_campanias_pipeline_idx (pipeline_id)
```

#### `cliente_triggers` — FM / FW / BD por campaña
```
id                  uuid PK
campania_id         uuid NOT NULL REFERENCES cliente_campanias(id) ON DELETE CASCADE
codigo              text NOT NULL                          -- 'P1C1FM1' (denormalizado)
tipo                text NOT NULL CHECK (tipo IN ('FM','FW','BD'))
descripcion         text
link_externo        text                                   -- form id Meta, URL FW, segmento GHL
fecha_lanzamiento   date                                   -- obligatoria si tipo='BD' (CHECK)
estado              text NOT NULL DEFAULT 'declarado' CHECK (estado IN ('declarado','creado','monitorizando','archivado'))
created_at, updated_at, created_by
UNIQUE (campania_id, codigo)
CHECK (tipo <> 'BD' OR fecha_lanzamiento IS NOT NULL)      -- regla .docx caso 4
INDEX cliente_triggers_campania_idx (campania_id)
```

#### `cliente_emails` — emails de la secuencia por campaña
```
id                    uuid PK
campania_id           uuid NOT NULL REFERENCES cliente_campanias(id) ON DELETE CASCADE
orden                 int NOT NULL
nombre                text NOT NULL
espera_desde_anterior text                                 -- 'Día 0','+2d','cadencia'
objetivo              text
triggers_aplicables   text[] NOT NULL DEFAULT '{}'         -- subcódigos: 'FM1','FW1'. Vacío = todos
link_copy_drive       text
link_diseno_drive     text
link_ghl_workflow     text
estado                text NOT NULL DEFAULT 'declarado'
                      CHECK (estado IN ('declarado','copy-listo','diseno-listo','montado-ghl','activo','archivado'))
created_at, updated_at, created_by
UNIQUE (campania_id, orden)
INDEX cliente_emails_campania_idx (campania_id)
```

**Triggers:** `BEFORE UPDATE` en las 5 reusa `public.update_updated_at()`.

**RLS:** habilitada en las 5 tablas. **20 policies** (4 por tabla — `select/insert/update/delete`, prefijos `ccp_`, `cp_`, `cc_`, `ct_`, `ce_`), todas con `USING/WITH CHECK public.is_comunidad_admin()` a `authenticated`. Mismo patrón que `fichas_categorias`/`fichas_de_producto`/`disponibilidad_*`. **Sale 1 de los 7 sitios de allowlist hardcoded** (estas 5 tablas NO suman al contador).

**GRANTs:** `authenticated` SELECT+INSERT+UPDATE+DELETE (RLS filtra), `service_role` ALL.

⚠️ **Impacto frontend pendiente (F2.1):** el SEED del frontend usa solo `declarada/en-produccion/archivada` para los 4 niveles (unificado). Con los estados finos del backend, `stateBadge()` en `ficha-cliente/index.html:1792` necesita ampliar labels + clases CSS para los nuevos valores (`copy-listo`, `diseno-listo`, `montado-ghl`, `creado`, `monitorizando`, etc.). Se hará al cablear writes.

**Pendiente F2.2 (siguiente paso):** crear 7 RPCs (`ficha_pipelines_get`, `ficha_codigos_catalogo`, `ficha_pipeline_upsert`, `ficha_campania_upsert`, `ficha_trigger_upsert`, `ficha_email_upsert`, `ficha_archivar_codigo`) + ampliar `ficha_cliente_get` para incluir `pipelines: ficha_pipelines_get(p_bubble_id)` en el jsonb (mismo patrón que `servicios`).

### `agencia_integraciones_config` — Credenciales cifradas (desde 2026-05-04)

Master nativo de credenciales de TODAS las integraciones (nativas + addons de pago). RLS service_role only — Bubble nunca lee credenciales en claro.

```
id                     uuid PK default gen_random_uuid()
agencia_id             uuid NOT NULL
addon_slug             text NOT NULL                -- coincide con bub_addons_catalogo.slug
provider               text NOT NULL                -- 'hubspot', 'clickup', 'pipedrive'…
credentials_encrypted  bytea NOT NULL               -- pgp_sym_encrypt(json::text, app.aic_key)
metadata               jsonb DEFAULT '{}'::jsonb    -- workspace_id, default_pipeline, etc.
status                 text NOT NULL DEFAULT 'pending'   -- pending | active | error | revoked
last_test_at           timestamptz
last_test_result       text
created_at, updated_at timestamptz
UNIQUE (agencia_id, addon_slug)
```

**Funciones helpers** (SECURITY DEFINER, `search_path = public, extensions, pg_temp`, EXECUTE solo a service_role):
- `aic_set(p_agencia uuid, p_slug text, p_provider text, p_creds jsonb, p_meta jsonb DEFAULT '{}')` → upsert credenciales cifradas. Lee `current_setting('app.aic_key')`.
- `aic_get(p_agencia uuid, p_slug text)` → JSONB descifrado o null.
- `aic_set_test_result(p_agencia uuid, p_slug text, p_ok boolean, p_message text)` → marca resultado de test_connection.
- **Wrappers para n8n** (desde 2026-05-12): `aic_set_with_key(p_agencia, p_slug, p_provider, p_creds, p_key, p_meta)` y `aic_get_with_key(p_agencia, p_slug, p_key)`. Reciben la clave como parámetro, hacen `set_config('app.aic_key', p_key, true)` dentro de la misma transacción y delegan en `aic_set` / `aic_get`. Permite llamar desde n8n vía PostgREST normal (HTTP Request a `/rest/v1/rpc/...`) sin conexión PostgreSQL directa. La clave llega cifrada por TLS en el body y no queda persistente en ningún `SET`.

**Clave de cifrado** en variable de entorno **`AIC_KEY`** del container n8n (EasyPanel). Mínimo 16 chars (recomendado 32+ random). n8n la pasa como `{{ $env.AIC_KEY }}` en cada llamada a `aic_*_with_key`. Nunca se almacena en BD ni en `workflows.json`. Si se pierde → credenciales cifradas existentes son irrecuperables.

**Bugfix 2026-05-12:** las funciones originales `aic_set`/`aic_get` (creadas 2026-05-04) tenían `search_path` por defecto y fallaban con `pgp_sym_encrypt does not exist` porque `pgcrypto` está en schema `extensions`. Detectado al hacer el primer uso real del sistema (tabla estaba vacía desde su creación). Resuelto añadiendo `SET search_path = public, extensions, pg_temp` a las 3 funciones base + a los 2 nuevos wrappers. Smoke test ciclo set/get/decrypt + rechazo con clave incorrecta → OK.

### `n8n_incidencias` — Errores de workflows (desde 2026-04-27)

Reemplaza al antiguo `bub_incidencias` (eliminado para descargar Bubble). Lo alimenta el workflow `HRDQ9Ju4NAIUV0qyhKzlz` (ERRORES — Capturar y Registrar Plataforma) tras enriquecer el error con Claude. Lo lee la Edge Function `incidencias_api` que sirve el panel cerrado `work.thenucleo.com/incidencias`.

```
id                uuid PK default gen_random_uuid()
agencia_id        uuid NOT NULL
workflow_id, workflow_name, execution_id, execution_url   text
node_name, node_type, node_function                       text
error_title, error_summary, error_description             text   -- generado por Claude
error_message, error_stack                                text   -- original del Error Trigger
raw_payload       jsonb DEFAULT '{}'
status            text NOT NULL DEFAULT 'open'   -- 'open' | 'resolved'
resolved_at       timestamptz
created_at        timestamptz NOT NULL DEFAULT now()

Indexes: created_at desc, status, workflow_id
RLS: enabled, sin policies → solo service_role accede.
```

---

## Vistas (6)

| Vista | Uso |
|---|---|
| `v_tareas_panel` | Kanban Bubble (Notion). ⚠️ Ben la reconstruye a mano — NO modificar sin confirmación |
| `v_tareas_panel_clickup` | Kanban Bubble (ClickUp, F2.B 2026-05-05). Filtra `provider='clickup'` + decode `metadata::jsonb`. Sin JOINs |
| `v_tareas_contexto_ia` | Tareas últimos 10 días para prompt Chat IA |
| `v_tareas_cerebro_ia` | Versión extendida con `dias_hasta_entrega` para Cerebro IA |
| `v_plantillas_catalogo` | Plantillas activas con conteo de subtareas |
| `v_blog_videos_pendientes` | Siguiente vídeo a publicar (CRON BLOG Zenyx Diario 18:00) |

⚠️ `v_responsables_opciones` eliminada 2026-05-02. Reemplazada por RPC `responsables_opciones(p_agencia_id uuid)`.

⚠️ `v_clientes_opciones` eliminada 2026-05-08. Vista huérfana (filtraba `estado <> 'Archivado'`, valor inexistente). Sin consumidores en Bubble API Connector, RPCs ni n8n.

⚠️ `v_blog_techstars_pendientes` no existe en cbi (era solo en maw, deprecado).

---

## RPCs / Functions

### Clockify (10) — todos `RETURNS TABLE`
- `clockify_resumen(p_agencia_id, p_fecha_inicio, p_fecha_fin)` → total_horas, entries, promedio_diario, pct_facturable, horas_facturables/no_facturables, clientes_activos, miembros_activos
- `clockify_por_cliente(..., p_limit)` → cliente_nombre, horas, entries, horas_facturables, miembros, color, pct, coste
- `clockify_por_miembro(...)` → usuario_email, nombre, horas, entries, clientes, promedio_diario, color, pct, coste_hora, tarifa_mensual
- `clockify_trending(...)` → semana, horas, entries, miembros, clientes, horas_facturables
- `clockify_por_tarea(...)` → descripcion, cliente_nombre, usuario, horas, entries, primera/ultima_entrada
- `clockify_cliente_miembro(...)` → cliente_nombre, miembro, horas
- `clockify_coste_por_cliente(..., p_limit)` → cliente_nombre, horas, coste, miembros, color, pct_horas, pct_coste
- `clockify_chart_donut(...)` → labels, valores, colores (text concatenado para split en Bubble)
- `clockify_chart_trending(...)` → x_labels, y_valores
- `clockify_dashboard(...)` → jsonb. **Sin consumidores activos** — mantenida por compatibilidad.

⚠️ `clockify_por_miembro`, `clockify_chart_donut`, `clockify_cliente_miembro`, `clockify_por_tarea`, `clockify_dashboard` joinean contra **`bub_user`** (no `bub_miembro_notion`) desde 2026-05-02 para resolver `nombre`. Match por `email` lowercase.

⚠️ Params reales: `p_fecha_inicio` / `p_fecha_fin` (NO `p_fecha_desde`/`p_fecha_hasta`).

### Responsables (1, nuevo 2026-05-02)
- `responsables_opciones(p_agencia_id uuid)` → `nombre, email`. Reemplaza a la vista `v_responsables_opciones` (eliminada). Filtra `bub_user` por agencia mapeando UUID supabase → bubble_id via JOIN con `bub_agencia`.

### Finanzas (4) — `finanzas_*`, NO `holded_*`
- `finanzas_metricas_mes(p_agencia_id, p_mes)` → mrr, ingresos, gastos, margen, clientes_activos, ticket_medio, churn_mrr, pct_impagos, total_impagado, num_facturas_impagadas
- `finanzas_facturas(p_agencia_id, p_tipo_vista, p_dias)` → id, holded_id, contacto_nombre, concepto, total, fecha, fecha_vencimiento, estado, numero_factura, dias_retraso, cliente_notion_id
- `finanzas_desgloses(p_agencia_id, p_mes)` → categoria, nombre, monto, pct
- `finanzas_evolucion_mrr(p_agencia_id)` → mes, mes_label, mrr, ingresos, pct_max

### Chat IA (2)
- `cerebro_consulta_ia(query text)` → jsonb
- `get_or_create_conversation(p_agencia_id, p_tipo, p_user_bubble_id, p_estado)` → composite type. Crea o devuelve conv (UNIQUE por agencia_id+tipo).

### Análisis Estratégico (8 + 2 helpers)
- `analisis_get_briefing(p_conversation_id)` — devuelve briefing completo (12 secciones)
- `analisis_get_segmento_meta(p_conversation_id, p_segmento_idx)` — meta del segmento
- `analisis_get_segmento_buyer(p_conversation_id, p_segmento_idx)` — buyer persona
- `analisis_get_segmento_empatia(p_conversation_id, p_segmento_idx)` — mapa empatía
- `analisis_get_segmento_angulos(p_conversation_id, p_segmento_idx)` — ángulos creativos
- `analisis_merge_update(...)` → jsonb — merge incremental de patches al WIP
- `analisis_reset_stuck_analyzing(p_ttl_minutes)` — libera filas atascadas (CRON `V60MieFkQzOszxhh`)
- `analisis_reset_wip(...)` → json
- `_briefing_as_bullets()`, `_briefing_as_text()` — helpers de renderizado markdown

### Newsletter IA (7)
- `newsletter_get_email(p_conversation_id, p_idx)` → 1 fila tipada (idx, numero, asunto, preheader, from_name, contenido_html, contenido_md, estado_aprobacion).
- `newsletter_get_emails(p_conversation_id)` → N filas tipadas.
- `newsletter_get_estrategia(p_conversation_id)` → 1 fila (estrategia_texto, estado, cantidad_emails).
- `newsletter_get_parametros(p_conversation_id)` → 1 fila (objetivo_secuencia, etapa_leads, segmento, cantidad_emails, estado).
- `newsletter_update_email(p_conversation_id, p_idx, p_asunto, p_contenido_html)` → `{ok, idx}`.
- `newsletter_reset_stuck()` — libera filas atascadas.
- `newsletter_reset_wip(p_conversation_id)` → `{ok:true}`. Borra `chat_messages` + resetea fila WIP.

---

## Ads — Control de Campañas v2 (creadas 2026-05-12)

Schema nativo multi-provider Meta+Google. Reemplaza al pattern legacy `bub_dashboardmedia_*` (que sigue vivo en convivencia hasta 2 semanas de smoke verde). Detalle de uso, decisiones técnicas y handoff completo en `docs/portal/integraciones/control-de-campanias.md`.

### Tablas (7, todas con prefijo `ads_*`)

#### `ads_cuentas` — Cuentas publicitarias multi-provider
Columnas clave: `id uuid PK`, `agencia_id uuid NOT NULL`, `cliente_id text` (notion_id canónico, NULLABLE hasta asignar), `provider text CHECK IN ('meta','google')`, `external_account_id text` (`act_xxx` Meta o `customers/xxx` Google), `nombre`, `currency`, `timezone`, `business_id`, `ownership text CHECK IN ('owned','partner','client_relationship')`, `account_status int`, `disable_reason int`, `spend_cap numeric`, `amount_spent numeric`, `balance numeric`, `funding_source_details jsonb`, `discovered_at`, `last_seen_at`, `estado_interno text CHECK IN ('pendiente_asignar','activa','archivada','sin_acceso')`, `last_sync_at`, `created_at`, `updated_at`. **UNIQUE `(provider, external_account_id)`** + índice parcial `idx_ads_cuentas_pendientes WHERE cliente_id IS NULL`.

#### `ads_campanias` / `ads_adsets` / `ads_anuncios` — Jerarquía + snapshot KPIs
Las 3 comparten estructura común: `cuenta_id uuid FK ads_cuentas ON DELETE CASCADE`, `external_id text NOT NULL`, `nombre`, `status`, `effective_status`, KPIs (`spend`, `impressions`, `clicks`, `reach`, `ctr`, `cpc`, `cpm`, `freq`, `conv`, `revenue`, `roas`, `cpa`, `cvr`), `preset_actual text DEFAULT 'last_7d'`, `score text CHECK IN ('winner','scalable','ontarget','fatigue','loser','nodata')`, `diagnostic_state/reading/action`, `last_sync_at`, `created_at`, `updated_at`. **UNIQUE `(cuenta_id, external_id)`** en cada una.

Extras por nivel:
- `ads_campanias`: `objective`, `buying_type`, `bid_strategy`, `daily_budget`, `lifetime_budget`, `budget_remaining`.
- `ads_adsets`: `campania_id uuid FK ads_campanias`, `optimization_goal`, `billing_event`, `bid_strategy`, budgets, `targeting jsonb`.
- `ads_anuncios`: `campania_id` + `adset_id` FKs, `creative_id`, `creative_summary jsonb`.

#### `ads_insights_diario` — Time-series por entidad
`cuenta_id uuid`, `entity_type text CHECK IN ('account','campaign','adset','ad')`, `entity_external_id text`, `fecha date`, KPIs + `acciones jsonb` + `action_values jsonb`, `fetched_at`. **UNIQUE `(cuenta_id, entity_type, entity_external_id, fecha)`** + índice `idx_insights_fecha`.

#### `ads_notas` — Audit trail + notas manuales (INSERT-only)
`agencia_id`, `cuenta_id FK ads_cuentas`, `entity_type`, `entity_external_id` (opcional para nota a nivel cuenta), `autor_user_id text NOT NULL` (email Bubble user), `titulo`, `contenido text NOT NULL`, `tipo text DEFAULT 'manual'` (`manual`/`accion`/`sistema`), `metadata jsonb` (status_anterior/nuevo si tipo=accion), `created_at`.

#### `ads_alertas` — Alertas operativas derivadas
`agencia_id`, `cuenta_id FK ads_cuentas`, `entity_type`, `entity_external_id`, `source text CHECK IN ('meta_api','google_ads_api','manual') DEFAULT 'meta_api'`, `severity text CHECK IN ('payment','critical','warning','success')`, `reason text` (ej. `UNSETTLED`, `ACCOUNT_DISABLED`, `PENDING_RISK_REVIEW`), `titulo`, `descripcion`, `metadata jsonb`, `detected_at`, `resolved_at`. **UNIQUE `(entity_external_id, reason)`** (constraint completo, NO partial — fix bug 42P10 PostgREST on_conflict).

### RPCs (16, todas multi-provider)

**Panel/lectura (consumidas por Bubble via API Connector, GRANT a authenticated):**
- `ads_cuentas_panel(p_agencia_id uuid, p_periodo text DEFAULT 'last_7d')` → cuentas activas con KPIs agregados (SUM sobre `ads_campanias`) + alertas count + cliente_nombre via JOIN.
- `ads_cuentas_pendientes(p_agencia_id uuid)` → cuentas con `cliente_id IS NULL` + sugerencia fuzzy match `extensions.similarity(unaccent(...))` > 0.3 sobre `bub_clientes.nombre_empresas`.
- `ads_campanias_panel(p_cuenta_id, p_periodo)`, `ads_adsets_panel(p_campania_id)`, `ads_anuncios_panel(p_adset_id)`.
- `ads_insights_serie(p_entity_external_id, p_entity_type, p_dias DEFAULT 30)` → time-series para charts.
- `ads_notas_listar(p_entity_external_id, p_limit DEFAULT 50)`.

**Acciones (consumidas via webhook n8n, GRANT solo service_role):**
- `ads_asignar_cliente(p_cuenta_id, p_cliente_id text, p_autor_email)` — UPDATE `cliente_id` + `estado_interno='activa'` + INSERT audit `ads_notas`.
- `ads_notas_crear(p_agencia_id, p_cuenta_id, p_entity_type, p_entity_external_id, p_autor_user_id, p_titulo, p_contenido, p_tipo DEFAULT 'manual', p_metadata jsonb DEFAULT NULL)` → `jsonb {ok, nota_id}` (cambió de `RETURNS uuid` a `RETURNS jsonb` el 2026-05-12 para evitar text/plain en PostgREST scalar).
- `ads_aplicar_status_toggle(p_agencia_id, p_cuenta_id, p_entity_type, p_entity_external_id, p_new_status, p_autor_email)` → UPDATE status en tabla correspondiente + INSERT `ads_notas` tipo='accion' + INSERT `activity_log` clase='ads'. Validación entity_type ∈ {campaign,adset,ad}, new_status ∈ {ACTIVE,PAUSED,DELETED,ARCHIVED,ENABLED,REMOVED} (enum ampliado 2026-05-13 vía migration `ads_aplicar_status_toggle_google_aware` para aceptar Meta + Google nativos; BD guarda formato nativo del provider, consistente con workflows Estructura/Daily/Intra-día).

**Sync (consumidas por workflows n8n, GRANT solo service_role):**
- `ads_meta_creds_listas(p_agencia uuid, p_key text)` → `jsonb {access_token, appsecret_proof, app_id, business_id, system_user_id}`. Descifra creds Meta de `agencia_integraciones_config` + calcula HMAC-SHA256 `appsecret_proof` via `extensions.hmac()` en una sola transacción. Workaround anti-patrón task runner n8n que bloquea `crypto.subtle`/`require('crypto')`.
- `ads_upsert_estructura(p_cuenta_id, p_campanias, p_adsets, p_anuncios jsonb)` → 3 UPSERTs atómicos con FK resolution interna por `external_id` (JOIN contra `ads_campanias`/`ads_adsets`).
- `ads_insertar_insights_diario(p_cuenta_id, p_fecha date, p_rows jsonb)` → UPSERT `ads_insights_diario` con `LATERAL ads_extract_conversion(...)` para derivar conv/revenue + roas/cpa con protección división por cero.
- `ads_actualizar_kpis_snapshot(p_cuenta_id, p_preset, p_campanias, p_adsets, p_anuncios jsonb)` → UPDATE (no UPSERT) de KPIs snapshot en las 3 tablas de entidad, match por `external_id`. Aplica conv/revenue/roas/cpa/cvr.

**Helpers internos (portados de OptiMetrics, GRANT solo service_role):**
- `ads_extract_conversion(p_actions jsonb, p_action_values jsonb)` → `TABLE(conv, revenue, atc, ic, lpv)`. Parsea los 16 action_types de Meta para extraer conv y revenue.
- `ads_calcular_scoring(p_cuenta_id uuid)` → void. Recalcula `score` y `diagnostic_*` en `ads_campanias`/`adsets`/`anuncios` usando percentiles `percent_rank()` sobre CPA y CTR.

### `aic_*` — Wrappers para n8n (creados 2026-05-12)

- `aic_set_with_key(p_agencia, p_slug, p_provider, p_creds jsonb, p_key text, p_meta jsonb)` → `uuid`. Setea `app.aic_key` por sesión y delega a `aic_set`.
- `aic_get_with_key(p_agencia, p_slug, p_key text)` → `jsonb`. Idem para descifrar.

Permite a n8n llamar via PostgREST HTTP simple (sin conexión PostgreSQL directa con `SET LOCAL`).

### Realtime + RLS
Publication `supabase_realtime` ON para las 7 tablas. RLS service_role only en todas. Bubble lee via RPCs panel (GRANT authenticated solo en panels/list).

### Triggers
5 triggers `*_updated_at` (BEFORE UPDATE en `ads_cuentas`/`ads_campanias`/`ads_adsets`/`ads_anuncios`/`ads_alertas`). `ads_insights_diario` y `ads_notas` son INSERT-only sin trigger.

### Trigger functions
- `cleanup_old_messages()` → trigger (FIFO 100 chat_messages)
- `update_updated_at()` → trigger genérico (operativas)
- `set_synced_at()` → trigger (BEFORE INSERT/UPDATE en `bub_*` para marcar `_synced_at`)
- `tg_bv_updated_at()` → trigger (blog_videos)
- `trg_comunidad_set_slug()` → trigger BEFORE INSERT (auto-slug en propuesta comunidad)
- `trg_comunidad_set_updated_at()` → trigger BEFORE UPDATE (comunidad)
- `comunidad_propuestas_rate_limit()` → trigger BEFORE INSERT (rate limit propuestas)
- `is_comunidad_admin()` → boolean (SECURITY DEFINER)
- `comunidad_slugify(p_input text)` → text (IMMUTABLE, usa `extensions.unaccent`)
- `rls_auto_enable()` → event_trigger (activa RLS automáticamente al crear tablas nuevas)

---

## Triggers

| Trigger | Tabla | Evento |
|---|---|---|
| `trigger_cleanup_messages` | chat_messages | AFTER INSERT — FIFO 100 |
| `trg_set_synced_at` | 18 tablas `bub_*` sincronizadas | BEFORE INSERT/UPDATE |
| `analisis_wip_updated_at` | analisis_wip | BEFORE UPDATE |
| `bv_updated_at` / `tg_bv_updated_at` | blog_videos | BEFORE UPDATE |
| `clockify_tarifas_updated_at` | clockify_tarifas | BEFORE UPDATE |
| `newsletter_wip_updated_at` | newsletter_wip | BEFORE UPDATE |
| `rag_stores_updated_at` | rag_stores | BEFORE UPDATE |
| `trg_comunidad_set_slug` | comunidad_propuestas | BEFORE INSERT |
| `trg_comunidad_set_updated_at` | comunidad_propuestas, comunidad_comentarios | BEFORE UPDATE |
| `trg_comunidad_propuestas_rate_limit` | comunidad_propuestas | BEFORE INSERT |
| `trg_fichas_categorias_updated_at` | fichas_categorias | BEFORE UPDATE (reusa `trg_comunidad_set_updated_at`) |
| `trg_fichas_de_producto_updated_at` | fichas_de_producto | BEFORE UPDATE (reusa `trg_comunidad_set_updated_at`) |

---

## RLS — Estado real

⚠️ El doc anterior simplificaba a "anon SELECT, service_role ALL" — **falso**. RLS real es heterogéneo. Resumen:

| Tabla | Política real |
|---|---|
| `bub_*` (todas) | RLS habilitada con policies por agencia. n8n usa `service_role` (bypass). Bubble usa `anon` (sujeto a RLS) |
| `analisis_wip`, `rag_stores`, `newsletter_wip`, `clockify_*`, `holded_*`, `n8n_incidencias`, `comunidad_*` | RLS habilitada con policies |
| `fichas_categorias`, `fichas_de_producto` | RLS habilitada con policies gated por `is_comunidad_admin()` en las 4 operaciones (SELECT/INSERT/UPDATE/DELETE). Acceso admin-only en lectura y edición (no anon, no authenticated genérico) |
| `provider_webhooks`, `sync_suppress`, `cliente_external_links`, `activity_log`, `blog_videos` | RLS habilitada **sin policies** (deny-all anon/auth, service_role bypass) — hardening 2026-05-13 |
| `chat_conversations`, `chat_messages` | RLS desactivada (bloqueado por Bubble API Connector consumiendo `chat_messages` directo — pendiente D3: envolver CRUD en RPCs DEFINER, ver log 2026-05-13) |

**Conclusión práctica:** si un PATCH desde Bubble falla **silenciosamente**, primer check sigue siendo RLS. Pero el problema más habitual no es "falta SELECT" sino mismatch de columnas/tipos contra el schema real (Bubble manda string `"null"` para vacíos, etc.).

---

## GRANTs explícitos en tablas nuevas (rollout Supabase 2026-10-30)

A partir del **30 octubre 2026** Supabase aplica en todos los proyectos existentes (incluido `cbixhqjsnpuhcrcjppah`) el cambio que ya rige desde el **30 mayo 2026** para proyectos nuevos: las tablas creadas en `public` **NO se exponen automáticamente a la Data API**. Sin un `GRANT` explícito, PostgREST devuelve `42501` con el statement exacto que falta.

**Tablas actuales:** conservan sus grants. No se rompe nada de lo que está en producción hoy.

**Tablas nuevas (creadas a partir de 2026-10-30):** todo migration que cree una tabla en `public` consumida por Data API debe incluir GRANTs explícitos en el mismo migration.

### Quién consume la Data API en TheNucleo

| Consumidor | Endpoint | Rol |
|---|---|---|
| Bubble (API Connector) | `/rest/v1/...` (cbi) | `anon` (con `apikey` Bubble) |
| n8n (HTTP Request) | `/rest/v1/...` | `service_role` |
| `work.thenucleo.com` (supabase-js cliente) | `/rest/v1/...` + `/auth/v1/...` | `anon` / `authenticated` |
| Edge Functions (incidencias_api, comunidad_admin_action) | `/rest/v1/...` interno | `service_role` |

**No afectado:** conexiones directas por connection string (no se usan en producción TheNucleo). RPCs (`GRANT EXECUTE`) tampoco — modelo propio sin cambios.

### Plantilla para tabla nueva tipo `bub_*` (espejo Bubble)

```sql
create table public.bub_nueva_tabla (
  bubble_id text primary key,
  agencia_id text not null,
  -- ... campos ...
  _synced_at timestamptz default now()
);

grant select, insert, update, delete on public.bub_nueva_tabla to service_role;
-- anon solo si Bubble la lee directo (raro; lo normal es vía RPC):
-- grant select on public.bub_nueva_tabla to anon;

alter table public.bub_nueva_tabla enable row level security;

create policy "service_role full access"
  on public.bub_nueva_tabla
  for all to service_role
  using (true) with check (true);

-- Trigger _synced_at + entrada en ALLOWED_TABLES de FGxG67I24POOUeHW
```

### Plantilla para tabla operativa consumida desde `work.thenucleo.com`

```sql
create table public.nueva_tabla (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  -- ... campos ...
  created_at timestamptz default now()
);

grant select on public.nueva_tabla to anon;                          -- si SSG público
grant select, insert, update, delete on public.nueva_tabla to authenticated;
grant all on public.nueva_tabla to service_role;

alter table public.nueva_tabla enable row level security;

create policy "users read own rows"
  on public.nueva_tabla for select to authenticated
  using (auth.uid() = user_id);

create policy "users insert own rows"
  on public.nueva_tabla for insert to authenticated
  with check (auth.uid() = user_id);
```

### Checklist antes de cerrar un migration nuevo

- [ ] `GRANT` por rol (`anon` si aplica, `authenticated` si aplica, `service_role` siempre que escriba n8n/Edge Functions)
- [ ] `ENABLE ROW LEVEL SECURITY`
- [ ] Policies (al menos una por operación que necesite cada rol)
- [ ] Si la tabla la lee Bubble vía API Connector: probar con curl + `apikey` anon ANTES de cablear el call
- [ ] Si la escribe el SYNC ESPEJO: añadir a `ALLOWED_TABLES` del workflow `FGxG67I24POOUeHW`

### Fuente

Email Supabase 2026-05-13. Dashboard → Security Advisor lista tablas en riesgo. Error en runtime: PostgREST `42501` con el statement exacto a aplicar.

---

## Comunidad pública (cbi) — Tablas nativas (2026-04-28)

Stack: `work.thenucleo.com/comunidad` (Eleventy SSG + supabase-js cliente + Edge Function `comunidad_admin_action`).
Sustituye a las 4 tablas espejo `bub_comunidad_*` (DROP 2026-04-28).

### `comunidad_propuestas`
```
id uuid PK default gen_random_uuid()
slug text UNIQUE NOT NULL                      -- generado por trigger BEFORE INSERT
titulo text NOT NULL                            -- CHECK char_length BETWEEN 1 AND 200
descripcion text NOT NULL                       -- CHECK char_length BETWEEN 1 AND 5000
problema text · beneficio text                  -- CHECK char_length <= 2000 cada uno
modo text NOT NULL CHECK ('pool','referidos')   -- antes `tipo_propuesta` (renombrado 2026-04-28)
estado text NOT NULL DEFAULT 'pendiente' CHECK ('pendiente','aprobada','rechazada','financiada','archivada')
cotizacion_precio numeric · umbral_financiacion_pool numeric · recaudado_pool numeric DEFAULT 0 · precio_adhoc numeric
fecha_publicacion timestamptz                   -- se setea al aprobar (Edge Function)
autor_id uuid NOT NULL FK auth.users(id) ON DELETE SET NULL
moderado_por uuid · moderado_at timestamptz · moderacion_nota text
created_at · updated_at timestamptz DEFAULT now()
Indexes: (estado, fecha_publicacion DESC NULLS LAST), (autor_id)
```

**Rate limit (trigger `trg_comunidad_propuestas_rate_limit`, BEFORE INSERT):** máximo 3 propuestas/hora y 10/día por `autor_id`. Admins exentos. Levanta `RAISE EXCEPTION 'rate_limit_propuestas_hora'` o `'rate_limit_propuestas_dia'` con `ERRCODE='check_violation'`. El cliente (`comunidad-nueva.js`) detecta el sentinel y muestra mensaje amistoso.

### `comunidad_comentarios`
```
id uuid PK · propuesta_id uuid FK comunidad_propuestas ON DELETE CASCADE · autor_id uuid FK auth.users
texto text NOT NULL
estado text DEFAULT 'pendiente' CHECK ('pendiente','aprobado','rechazado')
moderado_por · moderado_at · created_at · updated_at
Index: (propuesta_id, estado)
```

### `comunidad_votos_propuesta` y `comunidad_votos_comentario`
N:N con PK compuesta. Toggle vote = INSERT/DELETE desde cliente authenticated.

### `comunidad_admins` — allowlist moderadores
```
user_id uuid PK FK auth.users ON DELETE CASCADE · added_at timestamptz
```
RLS habilitada **sin policies** → solo `service_role` accede directo. La función `is_comunidad_admin()` SECURITY DEFINER bypassa RLS.

### Vista `v_comunidad_propuestas_publicas`
`security_invoker = true`. Solo `estado IN ('aprobada','financiada')`. Añade `votos` y `comentarios_count` calculados. `GRANT SELECT TO anon, authenticated`. Consumida en build-time SSG por `_data/comunidad.js` de la landing.

### RLS (18 policies)
- **Propuestas:** SELECT público para aprobadas/financiadas + autor sus propias + admin todas. INSERT authenticated con CHECK duro (`autor_id=auth.uid()`, `estado='pendiente'`, `recaudado_pool=0`, sin moderación). UPDATE/DELETE solo admin.
- **Comentarios:** SELECT público para aprobado + propuesta visible. INSERT authenticated con CHECK estado='pendiente'. UPDATE/DELETE solo admin.
- **Votos (ambos):** SELECT público (`true`). INSERT/DELETE solo `usuario_id=auth.uid()` (toggle).

### Edge Function `comunidad_admin_action` (verify_jwt=true)
POST `{ tipo: 'propuesta'|'comentario', id, accion: 'aprobar'|'rechazar', nota? }`. Verifica admin via `comunidad_admins`, hace UPDATE con service_role, dispara `VERCEL_DEPLOY_HOOK_URL` al aprobar propuesta.

---

## Casuísticas (cbi) — Tabla operativa single-row (2026-05-15)

Stack: `work.thenucleo.com/casuisticas/` (HTML standalone + supabase-js cliente vía CDN).
Reemplaza la persistencia `localStorage` previa (clave `nucleo_casuisticas_v1`, por dispositivo).

### `casuisticas_board`
```
id          text PK DEFAULT 'global'          -- single-row, siempre 'global'
data        jsonb NOT NULL DEFAULT '{}'       -- {bolsa, newsletter, hibrido, dudas}: arrays de {t,d,flag,nota}
updated_at  timestamptz NOT NULL DEFAULT now()
updated_by  text                              -- email del último editor, 'seed' en INSERT inicial
```

**Trigger:** `casuisticas_board_updated_at` (BEFORE UPDATE) → `update_updated_at()`.

### GRANTs
```sql
GRANT SELECT, INSERT, UPDATE ON public.casuisticas_board TO authenticated;
GRANT ALL ON public.casuisticas_board TO service_role;
```

### RLS (3 policies)
Todas: `auth.email() IN (allowlist 4 emails)` — `benjamin.sanchis@thenucleo.com`, `alejandro.lopez@thenucleo.com`, `marketing.thenucleo@gmail.com`, `mel.dalmazo@thenucleo.com`.
- `casuisticas_board_admin_select` (SELECT)
- `casuisticas_board_admin_update` (UPDATE, USING + WITH CHECK)
- `casuisticas_board_admin_insert` (INSERT, WITH CHECK)

Mismo allowlist que `EDITOR_EMAILS` del frontend. Si añades un editor, actualizar **ambos** sitios (HTML + policies).

### Patrón cliente
- **Load:** `SELECT data, updated_at, updated_by FROM casuisticas_board WHERE id='global'` al pasar el gate de auth.
- **Save:** `UPSERT { id:'global', data, updated_by:auth.email(), updated_at:now() } ON CONFLICT (id)` debounced 600 ms.
- **Cache local:** `localStorage[nucleo_casuisticas_v1]` se mantiene como fallback offline (lectura si Supabase falla).
- **Last-writer-wins:** sin realtime, sin OT/CRDT. Aceptable porque ≤4 editores con baja frecuencia.

---

## Disponibilidades (cbi) — Calendario laboral equipo (2026-05-20)

Stack: `work.thenucleo.com/disponibilidades/` (HTML standalone + supabase-js cliente vía CDN). 3 capas UI (AHORA / HOY timeline / SEMANA grid) sobre franjas base por miembro + overrides puntuales + festivos nacionales.

Migrations: `disponibilidades_init` (schema + RLS + GRANTs) + `disponibilidades_seed` (9 franjas + 10 festivos) + `disponibilidades_add_joaquin_damian_valeria` (3 miembros nuevos + RPC `disponibilidad_miembros`).

### `disponibilidad_franjas_base`
Franjas L–V por miembro+tramo. Una fila por (miembro, tramo) — el día de la semana se infiere (todas L–V iguales). 14 filas seed (3+3+3+1+3+1 = 14: Benja/Valentina/Camilo con 3 tramos, Damian/Valeria con 1 solo activo, Joaquin con los 3 completos).
```
id           uuid PK DEFAULT gen_random_uuid()
miembro_id   text NOT NULL REFERENCES bub_user(bubble_id) ON DELETE CASCADE
tramo        text NOT NULL CHECK (tramo IN ('activo_am','comida','activo_pm'))
hora_inicio  time NOT NULL
hora_fin     time NOT NULL
updated_at   timestamptz NOT NULL DEFAULT now()
UNIQUE(miembro_id, tramo)
```

Seed actual 2026-05-20 (6 miembros del equipo):

| Miembro | bubble_id | activo_am | comida | activo_pm |
|---|---|---|---|---|
| Benjamin Sanchis | `1772728038513x480671187100790300` | 08:30–14:30 | 14:30–16:00 | 16:00–18:00 |
| Valentina | `1772798993384x712884450325125900` | 09:00–14:00 | 14:00–15:00 | 15:00–18:00 |
| Camilo | `1773165777528x565611358129485950` | 10:30–15:00 | 15:00–16:00 | 16:00–19:00 |
| Damian | `1773057357337x468860004761055800` | 13:00–18:00 | — | — |
| Joaquin | `1773165270743x407759088346369540` | 13:00–17:00 | 17:00–18:00 | 18:00–21:00 |
| Valeria Diez | `1778497476044x261105595193495740` | 13:00–16:00 | — | — |

Damian y Valeria sólo tienen `activo_am` (tramo único sin comida modelada). Joaquin cubre hasta 21:00 → el frontend amplía el timeline visible a 08:00–21:00.

### RPC `disponibilidad_miembros()` — descubrimiento dinámico del equipo

```sql
CREATE OR REPLACE FUNCTION public.disponibilidad_miembros()
RETURNS TABLE(bubble_id text, nombre text, color text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT DISTINCT u.bubble_id,
         COALESCE(u.nombre, u.email) AS nombre,
         COALESCE(u.color, '#6b7280') AS color
  FROM bub_user u
  INNER JOIN disponibilidad_franjas_base f ON f.miembro_id = u.bubble_id
  ORDER BY 2;
$$;
GRANT EXECUTE ON FUNCTION public.disponibilidad_miembros() TO authenticated;
```

`SECURITY DEFINER` necesario porque `bub_user` tiene RLS y los admins de Comunidad no tienen policy de lectura ahí. La RPC sólo expone `bubble_id + nombre + color`. El frontend la llama en boot y para añadir o retirar a alguien del calendario basta INSERT/DELETE en `disponibilidad_franjas_base`.

### `disponibilidad_overrides`
Circunstancias puntuales (time-series). Solo crea/borra desde frontend admin; no se editan in-place.
```
id           uuid PK DEFAULT gen_random_uuid()
miembro_id   text NOT NULL REFERENCES bub_user(bubble_id) ON DELETE CASCADE
tipo         text NOT NULL CHECK (tipo IN ('medico','enfermo','llega_tarde','sale_antes','vacaciones','otro'))
desde        timestamptz NOT NULL
hasta        timestamptz NOT NULL
nota         text
creado_por   text NOT NULL                    -- auth.email() del admin
creado_en    timestamptz NOT NULL DEFAULT now()
CHECK (hasta > desde)
```

Índices:
- `idx_disp_overrides_miembro_fecha (miembro_id, desde)` — query por miembro ordenado por inicio.
- `idx_disp_overrides_rango (desde, hasta)` — query por rango (semana visible).

⚠️ **Set de tipos NO incluye `teletrabajo` ni `foco`** (decisión cerrada 2026-05-20). El equipo es 100% remoto, "teletrabajo" es la norma; "foco" se descartó del set inicial.

### `festivos_es`
Festivos nacionales España (sin CCAA). Carga manual cada año.
```
fecha    date PK
nombre   text NOT NULL
```

10 filas seed 2026: `2026-01-01` Año Nuevo · `2026-01-06` Epifanía · `2026-04-03` Viernes Santo · `2026-05-01` Día del Trabajo · `2026-08-15` Asunción · `2026-10-12` Fiesta Nacional · `2026-11-01` Todos los Santos · `2026-12-06` Constitución · `2026-12-08` Inmaculada · `2026-12-25` Navidad.

### GRANTs
```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON public.disponibilidad_franjas_base TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.disponibilidad_overrides    TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.festivos_es                 TO authenticated;
GRANT ALL ON public.disponibilidad_franjas_base TO service_role;
GRANT ALL ON public.disponibilidad_overrides    TO service_role;
GRANT ALL ON public.festivos_es                 TO service_role;
```

### RLS (3 policies — una por tabla)
Las 3 con la misma política: `FOR ALL TO authenticated USING (is_comunidad_admin()) WITH CHECK (is_comunidad_admin())`.

- `disp_franjas_admin_all` sobre `disponibilidad_franjas_base`
- `disp_overrides_admin_all` sobre `disponibilidad_overrides`
- `festivos_es_admin_all` sobre `festivos_es`

⚠️ **Patrón distinto al de Casuísticas/Playbook** (que usan allowlist `auth.email() IN (...)` hardcoded en SQL). Aquí gate es vía RPC `is_comunidad_admin()` que mira la tabla `comunidad_admins`. Ventaja: añadir un admin = INSERT en `comunidad_admins`, sin tocar policies. Desventaja: para que un email funcione, debe estar **tanto** en `comunidad_admins` (Supabase) como en `EDITOR_EMAILS` (frontend `disponibilidades/index.html`). Si solo está en uno, fallo silencioso.

### Patrón cliente
- **Boot:** primero `SUPABASE.rpc('disponibilidad_miembros')` para derivar el array `MIEMBROS` (no array hardcoded, refleja la realidad de `disponibilidad_franjas_base` en cada carga). Después, en paralelo: `SELECT * FROM disponibilidad_franjas_base` + `SELECT * FROM disponibilidad_overrides WHERE hasta >= <lunes> AND desde <= <lunes+8>` (ventana de la semana visible) + `SELECT * FROM festivos_es WHERE fecha BETWEEN <año>-01-01 AND <año+1>-12-31`.
- **Insert override:** modal frontend → `INSERT INTO disponibilidad_overrides (...)` con `creado_por = auth.email()`.
- **Delete override:** click en banda timeline → confirm → `DELETE FROM disponibilidad_overrides WHERE id = $1`.
- **Refresco UI:** `setInterval(tick, 60000)` recalcula estado AHORA y reposiciona la línea "AHORA" en el timeline cada minuto, sin volver a consultar Supabase.

### Pendientes (v2, no desplegados)
- Editor de franjas base por UI (hoy solo SQL directo si un miembro cambia horario).
- Enlace Notion Calendar usuario + Google Calendar usuario en perfil de cada miembro.
- Self-service: cada miembro marca su propio override + push notification al PM.
- Carga manual festivos 2027 al inicio de año.
