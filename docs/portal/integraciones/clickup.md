---
title: Integración ClickUp
dominio: integracion
estado: en-construccion
actualizado: 2026-05-08
tags: [clickup, multi-provider, n8n, integracion]
---

# ClickUp Integration — TheNucleo Portal multi-provider

> **Estado 2026-05-07:** Plan v3 opción C híbrida en ejecución. **F0 + F1 cerradas** (smoke test 200 OK ejec `109950`). **F2.A/B/C/D/E.1/E.2/E.2b cerradas — UI Kanban CU completa y validada con dummies, NO en campo real.** F2.F (onboarding Zenyx + E2E con tareas reales) y F3 (routers Bubble→Provider) **pendientes**.

## Por qué este documento existe

Documento de **handoff completo** para reanudar el proyecto multi-provider en cualquier momento (otro chat, otro día, otra persona). Cualquiera que retome desde aquí debe poder continuar sin re-leer toda la sesión histórica.

## Plan de referencia

`C:\Users\Benjamin\.claude\plans\perfecto-vamos-a-ello-steady-tome.md` — plan v3 aprobado por el usuario el 2026-05-02. Reemplaza al v2 (`tengo-que-integrar-una-zazzy-storm.md`, en pausa por banner WARNING).

## Decisiones arquitectónicas cerradas (no abrir sin causa)

1. **Una agencia = un proveedor** (`bub_agencia.proveedor_tareas` = `'notion'` | `'clickup'`). Backed por Option Set Bubble `Proveedor de Tareas` (Display lowercase). Migrado desde campo legacy `task_provider` (text) el 2026-05-07.
2. **Tablas polimórficas** `bub_tareas_notion` y `bub_clientes` con discriminadores `provider` + `external_id`. NO se renombra ninguna tabla — `notion_id` es nombre histórico, polimórfico.
3. **Sentinel `cu_<folder_principal_id>`** en `notion_id` para clientes ClickUp. Razón: ≥8 features (Cerebro IA, RAG stores, Newsletter, Análisis) filtran por `cliente_notion_id`.
4. **Cliente:Folder es 1:N** — tabla `cliente_external_links` modela la relación. Un Cliente Bubble = N folders en N Spaces.
5. **Default Spaces para Bubble→CU al crear cliente**: configurable en `bub_agencia.metadata.clickup_default_spaces[]`.
6. **Bubble es solo lectura** para tareas y clientes. Mutaciones = botón → webhook → n8n → provider → vuelta. No drag-drop, no edición inline.
7. **MVP sin `bub_integraciones` ni wizard.** Credenciales manuales en n8n. Wizard se mueve a F4.
8. **Auth Personal Token `pk_*` MVP.** OAuth en F4 (≥3 agencias CU).
9. **Whitelist de Lists por agencia** en `bub_agencia.metadata.clickup_sync_lists[]` evita contaminar `bub_tareas_notion` con CRM/eventos/hitos plantilla/consultoría CU.
10. **`v_tareas_panel` no se toca.** Se crea `v_tareas_panel_clickup` separada (Ben la construye a mano).
11. **`area_tarea` queda como option set Notion.** Para CU se muestra `metadata.list_name` directo.
12. **`bub_user` master de identidades.** `clickup_user_id` se añade ahí.
13. **Anti-rebote doble**: marker `last_edit_source` + ventana 30s en `sync_suppress`. Empate <30s gana provider.
14. **Webhook ClickUp registry**: tabla `provider_webhooks` mapea `webhook_id → agencia_id`.
15. **Drive subworkflow `d0B4LokmPhHWdg6g`** agnóstico — reutilizable.

## Lo que se invalida del plan v2 (no resucitar)

- ❌ Kanban dinámico **unificado** con columnas variables. Reemplazado por dos Kanbans separados (Notion intacto + page nueva `/operaciones-cu`).
- ❌ Tabla `kanban_columns`. Statuses CU se leen directos via `INTEGRACIONES — Obtener Estados Espacio ClickUp [SUB]`.
- ❌ Refactor `area_tarea` a text libre.
- ❌ Sync inverso por edits inline desde Bubble.

## Auditoría real Zenyx Workspace (2026-05-01)

- **Workspace ID:** `9008203585` ("Zenyx Workspace")
- **Token validado:** `pk_99714283_BRQ4SRULGHFECRBII0U224EKQC2T4VP5` (owner Benjamin Sanchis)
- **6 Spaces:**
  - `90080425524` Wikipedia A1M (9 statuses)
  - `90127153555` Plantilla Wikipedia Nivel 1 (3 statuses)
  - `90127153580` Plantilla Operaciones Nivel 1 (7 statuses)
  - `90127153591` Plantilla Operaciones Nivel 2 (3 statuses)
  - `90125984063` Consultoría Nivel 3 (3 statuses)
  - `90124170149` Equipo A1M (3 statuses)
- **Folder = Cliente** ✓ (validado en folders `Miguel`, `Ej. Cliente`, `Miguel`).
- **List = Servicio/Área** ✓.
- Statuses Space "Plantilla Operaciones N1": `contrato firmado` → `onboarding hecho` → `primer entregable` → `segundo entregable` → `tercer entregable` → `mantenimiento` → `complete`.
- **5+ tipos de "task" coexisten** en el workspace (tareas operativas, sprints, CRM Pipeline `+1.000€`/`onboarding`/`cancelado`, eventos calendario, hitos plantilla, consultoría por bloques R1-R6). Por eso la **whitelist de Lists** es defensa intencional contra contaminación.

---

## Estado de ejecución (2026-05-02)

### F0 — Discriminadores schema ✅ COMPLETA

**Bubble Data Types (Ben añadió en editor):**
- `tareas_notion`: `provider` (default `'notion'`), `external_id`, `external_url`, `last_edit_source`, `metadata` (text JSON-encoded).
- `clientes`: `provider`, `external_id`, `last_edit_source`, `metadata`.
- `Agencia`: `proveedor_tareas` (Option Set `Proveedor de Tareas`, Display `notion`/`clickup`), `metadata`. Campo legacy text `task_provider` eliminado 2026-05-07.
- `User`: `clickup_user_id`.

**cbi migration aplicada:** `f0_multiprovider_discriminator_columns` — `ALTER TABLE ADD COLUMN IF NOT EXISTS` para 12 columnas en 4 tablas `bub_*`.

**Backfill cbi ejecutado** (UPDATE COALESCE):
- `bub_tareas_notion`: 1.412/1.412 con `provider='notion'`, `external_id=notion_id`, `external_url=url`, `last_edit_source=updated_by`.
- `bub_clientes`: 74/74 con `provider='notion'`, `external_id=notion_id`, `last_edit_source='notion'`.
- `bub_agencia`: 1/1 con `proveedor_tareas='notion'` (campo migrado desde `task_provider` el 2026-05-07).

**Backfill Bubble ejecutado** vía workflow backend `f0_backfill_provider` (3 steps `Make changes to a list of things`).

**Verificación pasiva regresión Notion:** `v_tareas_panel` (830), `v_tareas_contexto_ia` (503), `v_tareas_cerebro_ia` (1.412), `v_clientes_opciones` (74) — todas responden OK tras schema change.

### F1.1 — Tablas operativas cbi ✅ COMPLETA

**Migration aplicada:** `f1_multiprovider_operational_tables`.

**Tablas creadas:**

```sql
-- provider_webhooks: registry webhooks ClickUp por agencia
CREATE TABLE provider_webhooks (
  agencia_id uuid, provider text, workspace_id text,
  webhook_id text, webhook_secret text,
  status text DEFAULT 'active', last_event_at timestamptz,
  created_at timestamptz, updated_at timestamptz,
  PRIMARY KEY (agencia_id, provider, webhook_id)
);

-- sync_suppress: anti-rebote ventana 30s
CREATE TABLE sync_suppress (
  external_id text, provider text,
  until_ts timestamptz, source text, created_at timestamptz,
  PRIMARY KEY (external_id, provider)
);

-- cliente_external_links: cliente:folder 1:N
CREATE TABLE cliente_external_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cliente_bubble_id text, cliente_notion_id text, agencia_id uuid,
  provider text, external_type text,
  external_id text, external_name text,
  external_space_id text, external_space_name text,
  is_primary boolean, archived boolean,
  created_at timestamptz, updated_at timestamptz,
  UNIQUE (provider, external_id)
);
```

**Backfill `cliente_external_links` ejecutado:** 74 links 1:1 para los 73 clientes Notion existentes (`is_primary=true`, `provider='notion'`).

### F1.2 — Workflows auxiliares n8n ✅ COMPLETA (código)

| # | Workflow | n8n ID | Carpeta | Función |
|---|---|---|---|---|
| F1.2a | `CRON ANTI-REBOTE — Limpiar Sync Suppress (5min)` | `ek5veFfwbeSB0bW3` | (raíz, mover a SYNC Otros) | Schedule cada 5min → DELETE `sync_suppress WHERE until_ts < now()`. |
| F1.2b | `INTEGRACIONES — Probar Conexión Provider [SUB]` | `o32vrctYqibCA5C2` | (raíz, mover a SYNC Otros) | Subworkflow `(agencia_id, provider, token)` → smoke test API CU/Notion. Token llega como param, NO usa cred. |
| F1.2c | `INTEGRACIONES — Registrar Webhooks Provider [SUB]` | `QBLy4DWZ7mUPsfpg` | SYNC Otros ✅ | Subworkflow `(agencia_id, workspace_id, token)` → genera 2 secrets HMAC random + POST CU webhooks tasks/folders + INSERT `provider_webhooks`. |
| F1.2d | `INTEGRACIONES — Rotar Token Provider [SUB]` | `4e9s6FpYlWiYlcI9` | SYNC Otros ✅ | Subworkflow `(agencia_id)` → marca webhooks viejos `status='deprecated'` (NO DELETE en CU). Tras esto Ben llama `INTEGRACIONES — Registrar Webhooks Provider [SUB]` con nuevo token. |
| F1.2e | `INTEGRACIONES — Descubrir Clientes Provider [SUB]` | `SMOKYPAzGAYrgpLK` | SYNC Clientes ✅ | Subworkflow `(agencia_uuid, agencia_bubble_id, workspace_id, space_id, space_name)` → GET CU folders + POST Bubble cliente + INSERT `cliente_external_links`. MVP 1 space/exec, sin lookup match. |
| F1.2f | `INTEGRACIONES — Obtener Estados Espacio ClickUp [SUB]` | `jsAnENkkzfTs6Kzu` | (raíz, mover a SYNC Otros) | Subworkflow `(agencia_id, space_id)` → GET `/v2/space/{id}` + extract statuses[] normalizado. Lo consume API Connector Bubble `cu_get_space_statuses`. |

### F1.3 — ✅ COMPLETA (2026-05-02 18:34)

**Acciones manuales Ben:**
1. ✅ 3 workflows movidos a `SYNC Otros` vía drag-and-drop UI.
2. ✅ 7 credenciales asignadas en UI tras update_workflow vía MCP (que las borró):
   - **`Espejo Supabase`** (5 nodos Supabase): CRON ANTI-REBOTE — Limpiar Sync Suppress (5min) → DELETE; INTEGRACIONES — Registrar Webhooks Provider [SUB] → 2× INSERT; INTEGRACIONES — Rotar Token Provider [SUB] → UPDATE; INTEGRACIONES — Descubrir Clientes Provider [SUB] → INSERT cliente_external_links.
   - **`ClickUp App The Nucleo`** (clickUpApi nativa, 1 nodo): INTEGRACIONES — Obtener Estados Espacio ClickUp [SUB] → CU GET /v2/space/{id} (con `predefinedCredentialType: clickUpApi`).
   - **`Bubble Data API`** (httpHeaderAuth, 1 nodo): INTEGRACIONES — Descubrir Clientes Provider [SUB] → POST Bubble cliente.
3. ✅ 6 workflows activados (publish).
4. ✅ Smoke test `INTEGRACIONES — Probar Conexión Provider [SUB]` ejecución `109950` → 200 OK, user CU 99714283 (Benjamin Sanchis), 154ms.

**Cambios estructurales aplicados durante F1.3:**
- `INTEGRACIONES — Descubrir Clientes Provider [SUB]`: migrado `CU GET /v2/space/{id}/folder` HTTP a nodo nativo `n8n-nodes-base.clickUp` resource `folder` operation `getAll`. Eliminado el `Split folders[]` (innecesario con nativo). 5 nodos.
- `INTEGRACIONES — Obtener Estados Espacio ClickUp [SUB]`: `CU GET /v2/space/{id}` cambiado de `genericCredentialType: httpHeaderAuth` a `predefinedCredentialType: clickUpApi`.
- Cred CU nativa real descubierta: **`ClickUp App The Nucleo`** (no `ClickUp Zenyx` como decía la doc previa).

**Anti-patrón nuevo descubierto:** `update_workflow` MCP **borra el campo `credentials` de TODOS los nodos** al ejecutarse, sin importar si el código SDK incluye `newCredential()`. Solo `create_workflow_from_code` auto-asigna. Excepción: nodos nativos (clickUp folder.getAll) sí auto-asignan por matching de tipo. Documentado en memoria `feedback_n8n_update_borra_creds.md`.

### F2 — Backend ✅ + UI Bubble con dummies ✅ — campo real PENDIENTE F2.F

**Sub-fases:**

- **F2.A — Backend n8n (4 días):**
  - `SYNC TAREAS — ClickUp → Bubble` (webhook `/clickup_tasks_inbound` + Schedule polling fallback 15min). Validar HMAC `X-Signature` con `webhook_secret` resuelto por `webhook_id` desde `provider_webhooks`. Filtro evento ∈ {taskCreated, taskUpdated, taskMoved, taskAssigneeUpdated, taskStatusUpdated}; taskDeleted → rama DELETE. Whitelist `task.list.id` ∈ `agencia.metadata.clickup_sync_lists` o skip. Anti-rebote `sync_suppress`. GET `/api/v2/task/{id}` para datos completos. Normalizar (parseInt dates ms, status.status, String(team_id), assignees[].email). Auto-discovery cliente: si `task.folder.id` no existe en `cliente_external_links`, INSERT link. CREATE/UPDATE/DELETE Bubble con `last_edit_source='clickup'`, `notion_id=task_id`, `cliente_notion_id=cu_<folder.id>`. Activity log. Carpeta n8n: `SYNC Tareas`.
  - `SYNC CLIENTES — ClickUp → Bubble` (webhook `/clickup_folders_inbound` con `folderCreated/Updated/Deleted`). Anti-rebote comparación contenido (Opción D, idéntica a `FcTmv78nLjbCb2Ea08qbt`). NO escribe a Supabase (espejo lo mantiene SYNC ESPEJO — Bubble → Supabase). Carpeta n8n: `SYNC Clientes`.
  - ✅ `CRON TAREAS — Reconciliar Huérfanas ClickUp` `kbUqzdSOrV7e2lS0` (activo 2026-05-05). Schedule 1h → SB get tasks `provider=eq.clickup` → SplitInBatches(10) → CU GET `/api/v2/task/{external_id}` con `neverError+fullResponse` → IF `statusCode===404` → SB get bub_agencia uuid → Bubble delete tarea (`onError: continueRegularOutput`) → SB delete cbi row (`onError: continueRegularOutput`) → SB log `clase='clickup_sync', accion='eliminada_huerfana_clickup'`. Carpeta n8n: `SYNC Otros`.

- **F2.B — Vista cbi (1 día):** ✅ `v_tareas_panel_clickup` creada 2026-05-05 vía MCP (`feedback_v_tareas_panel.md` aplica solo a la vista Notion existente). SELECT directo de `bub_tareas_notion WHERE provider='clickup' AND last_edited_time >= CURRENT_DATE - 20 days`. CTE `parsed` con cast seguro `metadata::jsonb` (NULL si vacío). Expone `status_id, status_name, list_id, list_name, space_id, space_name, parent_external_id` decoded. **Sin JOINs**: `cliente_nombre` + `responsable_nombres` ya precalculados por SYNC ESPEJO — Bubble → Supabase. 0 filas hasta onboarding Zenyx F2.F.

- **F2.E — UI Bubble (3-4 días):** ✅ **CERRADA 2026-05-07 con dummies.** Decisión arquitectónica: page Bubble independiente `tareas_clickup` (no redirect desde `/operaciones`); acceso vía botón "Tareas" desde la lista de clientes con redirect condicional al `agencia.proveedor_tareas`. La page Notion existente se moverá después a otra página independiente.
  - **Tree:** `Group_KanbanViewport > RG_Columnas > Group_Column > RG_Cards > Group Card_Tarea`.
  - **Custom states activos** en `Group_KanbanViewport` (4): `selected_space_id (text)`, `selected_space_name (text)`, `kanban_cu_columns (cu_get_space_statuses list)`, `cu_tasks_all (cu_get_kanban_tasks list)`. Los 6 states obsoletos (`current_task`, `modal_open`, `filter_clientes/areas/responsables/prioridad`) eliminados 2026-05-07.
  - **`RG_Columnas`**: Type=`cu_get_space_statuses`, Data source=`kanban_cu_columns`, Rows Fixed 1 / Columns **Fit content** / Min col 300px, Height Fixed 750.
  - **`Group_Column`** (cell-group): Type+Data source=`Current cell's cu_get_space_statuses`. Container Column / Width Fill / Height Fill.
  - **`RG_Cards`**: Type=`cu_get_kanban_tasks`. **List filter (1 sola `:filtered` con 5 constraints + Ignore empty constraints ON)**:
    - `status_id = Parent group's Group_Column's cu_get_space_statuses's id`
    - `cliente_nombre = DD Lista clientes's value`
    - `list_name = DD area's value` ⚠️ **NO `area_tarea`** (es null para CU)
    - `responsable_nombres = DD responsable's value`
    - `prioridad = DD prioridad's value`
  - **`Group Card_Tarea`** (sin modal): cliente_nombre uppercase 10pt, prioridad badge 4 colors (urgent #ef4444 / high #f59e0b / normal #475569 / low #334155, hide if empty), título 14pt 2 lines, list_name + dias_hasta_entrega con 4 conditionals (vencida red / hoy amber / ≤3d amber / default gray), responsable_nombres (default "Sin asignar"). **Click card → `Open external website Current cell's url` new tab.**
  - **4 DDs filtros + botón Limpiar:** Type=text, Choices source=`cu_tasks_all's <field> :unique elements :filtered (not empty)`. Botón "Limpiar" → `Reset inputs` con visibility conditional por `value is not empty` OR encadenado.
  - **Page Loaded workflow** (6 steps): set `selected_space_id`/`name` con default `90080425524`/"Wikipedia A1M" → call `cu_get_space_statuses` → set `kanban_cu_columns` → call `cu_get_kanban_tasks` → set `cu_tasks_all`. Steps 1-2 leen `Get data from page URL: parameter "space"/"space_name" :defaulting to ...`.
  - **Botón "Tareas" en `/clientes`** (Card_Cliente footer): workflow click con 3 conditionals — `proveedor_tareas is Proveedor de Tareas clickup` → `tareas_clickup`, `is notion` → `operaciones`, `is empty` → `operaciones` (safe default).
  - **2 API Connector calls Bubble** (grupo "ClickUp"):
    - `cu_get_space_statuses` → POST wrapper `wHuKjIisVripuobE` → subworkflow `jsAnENkkzfTs6Kzu`. ⚠️ Wrapper webhook con `Response Data: All Entries` (fix 2026-05-07 — sin esto devolvía solo el primer status como single object).
    - `cu_get_kanban_tasks` → GET vista `v_tareas_panel_clickup`.
  - **Sintaxis URL:** `[placeholder]` corchetes Bubble, no `<placeholder>`.
  - **Filtro vista:** `agencia_id` filtra por **bubble_id** Bubble UID (no UUID Supabase).
  - **5 dummies en `bub_tareas_notion`** (`bubble_id LIKE 'dummy-cu-init-%'`) cubren 4 statuses + 4 prioridades + null + vencida/hoy/futuras + con/sin responsables. Permanecen hasta F2.F.
  - **⚠️ NO probado en campo real.** Validación end-to-end requiere F2.F (onboarding Zenyx con webhooks CU activos + tareas sincronizadas reales).

- **F2.F — Onboarding manual Zenyx + E2E (1-2 días):** PENDIENTE
  1. **Cleanup dummies F2.E:** `DELETE FROM bub_tareas_notion WHERE bubble_id LIKE 'dummy-cu-init-%'`. Vista `v_tareas_panel_clickup` vuelve a 0 filas.
  2. ~~**Eliminar custom states obsoletos** del `Group_KanbanViewport` Bubble: `current_task`, `modal_open`, `filter_clientes`, `filter_areas`, `filter_responsables`, `filter_prioridad`.~~ ✅ **Eliminados 2026-05-07.**
  3. **Crear Agencia Zenyx en Bubble** con `proveedor_tareas = Proveedor de Tareas clickup` + `metadata` keys `clickup_workspace_id='9008203585'`, `clickup_default_spaces=[<list_ids>]`, `clickup_sync_lists=[<list_ids whitelist>]`.
  4. **Cred `clickup_zenyx`** ya creada en n8n (id `Eq9YFJvJi97v9o44`).
  5. Execute `INTEGRACIONES — Probar Conexión Provider [SUB]` → 200 OK.
  6. Execute `INTEGRACIONES — Registrar Webhooks Provider [SUB]` con `(zenyx_uuid, '9008203585', token)` → fila viva en `provider_webhooks`.
  7. Execute `INTEGRACIONES — Descubrir Clientes Provider [SUB]` por cada Space activo → folders en `bub_clientes` + filas `cliente_external_links`.
  8. Polling inicial bulk del workflow `SYNC TAREAS — ClickUp → Bubble` (fallback Schedule cada 15min, F2.A) para traer tasks existentes.
  9. **Refactor `cu_get_kanban_tasks`** API Connector Bubble: añadir param `cliente_notion_id` opcional → URL `?cliente_notion_id=eq.[cliente_notion_id]`. Hoy carga TODAS las tareas del space; con N clientes reales eso es Kanban global, no por cliente.
  10. **Refactor botón "Tareas" en `/clientes`**: pasar `cliente_id` por URL → `tareas_clickup?cliente_id=cu_<folder_id>`. Page Loaded lee param y pasa al call. Si está vacío → fallback Kanban global del space.
  11. **(Opcional) Selector de Space** dropdown arriba del Kanban si Zenyx quiere ver más de uno. Default desde `agencia.metadata.clickup_default_spaces[0]`.
  12. Validar T-CU1 a T-CU8 (matriz en plan v3) con tareas reales sincronizadas.

### F3 — PENDIENTE

- Refactor 3 routers Bubble→Provider:
  - `wvHcgVqqjkWJcJDu` (SYNC CLIENTES — Bubble → Notion + Drive) → switch `proveedor_tareas`. Branch CU: itera `clickup_default_spaces[]` → POST CU folders → INSERT N filas `cliente_external_links` → Drive sub `d0B4LokmPhHWdg6g` SIEMPRE → PATCH Bubble cliente → INSERT `sync_suppress` por folder.
  - `eHyXBETcaGSNXqLk` (OPS TAREAS — Crear desde Formulario Bubble) → branch CU: resolver list_id desde `(cliente_notion_id, area_tarea)` → POST `/api/v2/list/{id}/task` → INSERT `sync_suppress`.
  - `KSBwigoSEpHl5OG1` (OPS TAREAS — Aplicar Plantilla a Cliente) → branch CU en bucle subtareas + `onError: continueRegularOutput`.
- Re-Initialize 3 API Connectors Bubble tras añadir `proveedor_tareas` al body.
- `CRON TAREAS — Reconciliar Huérfanas ClickUp` si quedó pendiente F2.
- Documentación final: `n8n-workflows.md`, `bubble-api-connectors.md`, `supabase-schema.md`, `sectores/01-tareas.md`, `secciones-app.md`, `CLAUDE.md`.

### F4 — Fuera de alcance MVP

- Wizard SaaS `/onboarding` Bubble.
- Migración credenciales manuales n8n → `bub_integraciones`.
- OAuth si ≥3 agencias CU.
- Cliente lookup match en `INTEGRACIONES — Descubrir Clientes Provider [SUB]` (consolida duplicados).

---

## Schema cbi — Estado actual relevante para multi-provider

### Columnas multi-provider en tablas `bub_*`

| Tabla | Columna | Tipo | Default | Significado |
|---|---|---|---|---|
| `bub_tareas_notion` | `provider` | text | `'notion'` | `'notion'` o `'clickup'`. |
| `bub_tareas_notion` | `external_id` | text | NULL | Para Notion = `notion_id`. Para CU = `task_id`. |
| `bub_tareas_notion` | `external_url` | text | NULL | URL canónica al recurso. |
| `bub_tareas_notion` | `last_edit_source` | text | NULL | `'notion'`/`'clickup'`/`'bubble'`/`'user'`/`'cron'`. Anti-rebote. |
| `bub_tareas_notion` | `metadata` | text | NULL | JSON-encoded. CU: `{space_id, list_id, status_id, parent_external_id, dependencies[], ...}`. |
| `bub_clientes` | `provider` | text | `'notion'` | Discriminador. |
| `bub_clientes` | `external_id` | text | NULL | Para CU = folder_id principal. |
| `bub_clientes` | `last_edit_source` | text | NULL | Anti-rebote. |
| `bub_clientes` | `metadata` | text | NULL | JSON-encoded. CU: `{lists_by_area, ...}`. |
| `bub_agencia` | `proveedor_tareas` | text | NULL | XOR provider. Espejo del Option Set Bubble `Proveedor de Tareas` (Display lowercase). Migrado desde legacy `task_provider` el 2026-05-07. |
| `bub_agencia` | `metadata` | text | NULL | JSON-encoded. CU: `{clickup_workspace_id, clickup_default_spaces[], clickup_sync_lists[]}`. |
| `bub_user` | `clickup_user_id` | text | NULL | Mapeo assignees CU. |

### Tablas operativas nuevas (sin prefijo `bub_`)

`provider_webhooks` (PK `agencia_id+provider+webhook_id`), `sync_suppress` (PK `external_id+provider`), `cliente_external_links` (UUID PK, UNIQUE `provider+external_id`). Todas con RLS deshabilitado (operativas n8n con service_role).

### Vistas y RPCs

- `v_tareas_panel`, `v_tareas_contexto_ia`, `v_tareas_cerebro_ia`, `v_clientes_opciones` — **NO TOCADAS**, siguen funcionando idénticas a pre-F0.
- `v_tareas_panel_clickup` — **PENDIENTE F2.B** (Ben la construirá a mano).

---

## Inventario credenciales n8n usadas

| Credencial | n8n credentialId | Type | Uso |
|---|---|---|---|
| `Espejo Supabase` | `13dKSjEd2XZCYpJa` | supabaseApi | Cualquier nodo Supabase que toque cbi (DELETE sync_suppress, INSERT provider_webhooks, UPDATE provider_webhooks, INSERT cliente_external_links). |
| `ClickUp Zenyx (header Authorization)` | `Eq9YFJvJi97v9o44` | httpHeaderAuth | HTTP Request a `api.clickup.com/api/v2/*` con `genericCredentialType: httpHeaderAuth`. Header `Authorization: pk_99714283_BRQ4SRULGHFECRBII0U224EKQC2T4VP5` (sin `Bearer `). |
| `ClickUp App The Nucleo` | (n8n UI) | clickUpApi | Nodos nativos `n8n-nodes-base.clickUp` (ej. INTEGRACIONES — Descubrir Clientes Provider [SUB] > CU folder.getAll) y HTTP Request con `predefinedCredentialType: clickUpApi` (INTEGRACIONES — Obtener Estados Espacio ClickUp [SUB]). Mismo token que httpHeaderAuth. |
| `Bubble Data API` | `i8UMJM5KZOGBRf5z` | httpHeaderAuth | HTTP Request a `app-the-nucleo-agency.bubbleapps.io/api/1.1/obj/*`. Header `Authorization: Bearer 088a20b5465b6fa2cb8fbba67f250a79`. |
| `Supabase account - Rag Clientes` | (legacy) | supabaseApi | NO usar para multi-provider — Ben lo cambió por `Espejo Supabase`. Se auto-asignaba erróneamente al crear via SDK. |
| `IFAeIvEVDbrPBZIW` (Header Auth Bubble) | `IFAeIvEVDbrPBZIW` | httpHeaderAuth | Credencial Bubble pre-existente (la usa `wvHcgVqqjkWJcJDu` SYNC CLIENTES — Bubble → Notion + Drive). Equivalente a `i8UMJM5KZOGBRf5z`. |

---

## Carpetas n8n usadas

```
The Nucleo Agency
└── App TheNucleo Agency (id 6NKOF15ZtIVs52l2)
    ├── AutoSYNC (id q3rr4KiKriY4bcfi)
    │   ├── SYNC Tareas (id ssWdt6XeqVPONq9i) ← F2 SYNC TAREAS CU→Bubble irá aquí
    │   ├── SYNC Clientes (id kvmzEDLMrWrFEW9J) ← INTEGRACIONES — Descubrir Clientes Provider [SUB] + F2 SYNC Cliente CU→Bubble
    │   └── SYNC Otros (id 1hjN7TvawJZkXqdu) ← CRON ANTI-REBOTE — Limpiar Sync Suppress (5min) + INTEGRACIONES — Probar Conexión Provider [SUB] + INTEGRACIONES — Obtener Estados Espacio ClickUp [SUB] + INTEGRACIONES — Registrar Webhooks Provider [SUB] + INTEGRACIONES — Rotar Token Provider [SUB] + F2 cron huérfanas
    ├── CHAT_Bubble (id UWoO4e8UcbtxrsvN)
    ├── Dashboard Ads - Media Buyer (id 7385fgdwtPtzx4hR)
    └── Analisis Cliente Final (id HagpPx2csHyH7Dao)
```

Project ID n8n: `cehv5Dib1J6eKwYQ` (Personal de Ben).

---

## Deuda técnica conocida

### 1. Duplicados test/live en `bub_tareas_notion` (descubierto F0)

**Magnitud:** 1.412 filas totales en cbi, 1.412 bubble_ids únicos, 1.171 notion_ids únicos → **241 filas con notion_id duplicado** (472 grupos cubriendo 231 notion_ids con 2-3 filas cada uno).

**Causa:** tareas creadas en Bubble version-test desde ~2026-04-06 que coexisten con sus gemelas live (mismo `notion_id`, distintos `bubble_id`). El bulk modify F0 reveló duplicación pre-existente al sincronizar todo a cbi.

**Distribución:**
- 256 filas duplicadas con `_synced_at < 16:50` → seguro test antiguo.
- 216 con `_synced_at ≥ 17:00` → versión live legítima.
- 940 únicas → live activas (650 con `_synced_at` reciente + 276 latentes).

**Cleanup propuesto** (sesión específica futura):
1. Ben exporta bubble_ids vivos desde Bubble Live (App Data → Tareas_notion → CSV).
2. SQL: `DELETE FROM bub_tareas_notion WHERE bubble_id NOT IN (<lista live>)`.
3. Resultado esperado: cbi pasa de 1.412 → ~1.171 filas, todos `notion_id` únicos.

**No bloquea F1/F2** porque los discriminadores están correctamente populados en todas las filas. `v_tareas_panel` filtra a 830 (probablemente por agencia/estado), no muestra el ruido.

### 2. `INTEGRACIONES — Descubrir Clientes Provider [SUB]` MVP sin lookup

Crea Cliente Bubble nuevo por cada folder CU. Si un cliente real ya existe en `bub_clientes` y le añades folder en otro Space, te duplica el cliente. Consolidación manual o se reabre en F4.

### 3. `INTEGRACIONES — Rotar Token Provider [SUB]` simplificado

Solo marca webhooks viejos como `deprecated` en cbi. NO hace DELETE en CU automático. Tras correrlo, Ben llama `INTEGRACIONES — Registrar Webhooks Provider [SUB]` con nuevo token y borra los CU viejos a mano cuando confirme que los nuevos funcionan.

---

## Cómo retomar este proyecto en otro chat

### Si solo necesitas contexto:
Lee este archivo + el plan `~/.claude/plans/perfecto-vamos-a-ello-steady-tome.md`. Entre los dos cubren todo.

### Si vas a continuar con F2:
1. Confirmar que F1.3 está hecho (las 5 acciones manuales Ben). Smoke test `INTEGRACIONES — Probar Conexión Provider [SUB]` debe haber devuelto 200 OK con su user CU.
2. Empezar por F2.A backend (3 workflows). El más complejo es `SYNC TAREAS — ClickUp → Bubble` — usa el SDK n8n native MCP `mcp__claude_ai_n8n-native__*` siguiendo el patrón de los F1 (validate → create con folderId).
3. La spec detallada de cada workflow está en el plan v3 sección "Workflows n8n".

### Si vas a continuar con F3:
1. Confirmar F2 cerrada (Zenyx onboardada, T-CU1 a T-CU8 verdes).
2. Refactor de los 3 routers Notion existentes (no crear nuevos):
   - `wvHcgVqqjkWJcJDu` (SYNC CLIENTES — Bubble → Notion + Drive)
   - `eHyXBETcaGSNXqLk` (OPS TAREAS — Crear desde Formulario Bubble)
   - `KSBwigoSEpHl5OG1` (OPS TAREAS — Aplicar Plantilla a Cliente)
3. Añadir switch `proveedor_tareas` interno tras Normalize. Branch Notion intacta (cero regresión). Branch CU nueva.
4. Re-Initialize los 3 API Connectors Bubble tras añadir `proveedor_tareas` al body.

### Aprendizajes clave de la sesión

1. **n8n SDK no permite `.join('\n')`** por seguridad — usar template literals con backticks.
2. **n8n `create_workflow_from_code` con `newCredential('NombreExacto')`** auto-asigna credencial existente con ese nombre. Si no encuentra match, deja vacío. Útil para evitar pasos manuales.
3. **n8n `update_workflow` NO acepta `folderId`** — para mover workflow entre carpetas, hacerlo manual desde UI.
4. **n8n `create_workflow_from_code` permite `folderId`** — usarlo desde el inicio para no tener que mover después.
5. **SYNC ESPEJO — Bubble → Supabase `FGxG67I24POOUeHW` solo crea columna en cbi cuando recibe valor en algún registro** (memoria `feedback_bubble_data_api_conventions.md`). Por eso F0 hizo `ALTER TABLE ADD COLUMN IF NOT EXISTS` en cbi para anticiparse.
6. **Bulk modify Bubble con `Make changes to a list of things`** dispara DB Trigger por cada fila → SYNC ESPEJO upsertea cada una a cbi. Para 1.412 tareas tarda ~5-15 min según plan Bubble.
7. **Anti-patrón de auto-asignación cred**: el SDK auto-asigna a la primera credencial que matchea el tipo. En tablas `bub_*` tocó "Supabase account - Rag Clientes" (la primera por orden) en lugar de `Espejo Supabase`. Solución: usar `newCredential('Espejo Supabase')` con el nombre exacto.
8. **n8n MCP es flaky**: 502 errors periódicos. Reintenta tras 60s.
9. **`update_workflow` BORRA credenciales** (descubierto F1.3): el MCP `update_workflow` vacía el campo `credentials` de **todos los nodos** al ejecutarse, sin importar si el código SDK incluye `newCredential()`. Solo `create_workflow_from_code` auto-asigna. Excepción: nodos nativos como `n8n-nodes-base.clickUp` sí auto-asignan por matching de tipo. Implicación: tras cualquier `update_workflow` con creds previamente asignadas, hay que reasignar manualmente. Memoria `feedback_n8n_update_borra_creds.md`.
10. **Subworkflows no ejecutables vía MCP** (descubierto F1.3): workflows con trigger `executeWorkflowTrigger` no se pueden ejecutar con `execute_workflow` MCP (necesita Schedule/Webhook/Form/Chat/Manual). Smoke test debe ejecutarse desde la UI de n8n manualmente o desde otro workflow con `executeWorkflow` node.

---

## Tests T-CU1 a T-CU16 (ver plan v3 para detalles completos)

T-CU1 a T-CU8 deben pasar al cierre F2. T-CU9 a T-CU16 al cierre F3. Los 4 T1-T4 Notion (`docs/sectores/01-tareas.md:207-248`) deben pasar al cierre de **cada** fase F0/F1/F2/F3.
