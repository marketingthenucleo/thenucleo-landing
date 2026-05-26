---
title: Workflows n8n
dominio: n8n
estado: activo
actualizado: 2026-05-22
tags: [n8n, workflows, automatizacion]
---

# n8n — Mapa de Workflows TheNucleo

**Host:** `https://n8n-n8n.irzhad.easypanel.host`

> **Nomenclatura (2026-05-06):** workflows del Portal renombrados a esquema `[TIPO] [DOMINIO] — [Detalle] [→ Dirección si SYNC]` (TIPO: SYNC/CRON/OPS/IA/INTEGRACIONES/ERRORES/SUB). Mapeo viejo→nuevo en `docs/log-cambios.md` (entrada del 2026-05-06). Los headers `###` de este doc pueden mostrar el nombre viejo — el ID en negrita es la fuente de verdad. Tres workflows quedaron pendientes de rename manual UI por validaciones pre-existentes: `eR5SWFkxJmjMT1VI`, `SjqnIOJYPAkFMFfW`, `9WM__jEMrviSSC6KyJCT9`.

---

## Categorías

1. [SYNC — Sincronización Notion ↔ Supabase ↔ Bubble](#sync)
2. [CRON — Tareas programadas](#cron)
3. [Chat IA — Conversaciones inteligentes](#chat-ia)
4. [RAG — Actualización de bases de conocimiento](#rag)
5. [Operaciones — Crear tareas y plantillas](#operaciones)
6. [Infraestructura — Error handling y monitoreo](#infraestructura)
7. [Ads — Sincronización Meta Ads](#ads)
8. [Externos — Webhooks de terceros](#externos)
9. [Análisis Estratégico Cliente (chat co-creativo)](#análisis-estratégico-cliente-chat-co-creativo)
10. [Subworkflows RAG y herramientas IA](#subworkflows-rag-y-herramientas-ia)
11. [Workflow de error de bots externos](#workflow-de-error-de-bots-externos)

---

## SYNC

### Sync Tareas Notion → Bubble (v2)
**ID:** `GjijIDEUyiH05Mg0` (activo) — reemplaza al antiguo `gKhvS7eP1B169bhbtc44a` (archivado)
**Trigger:** Notion polling cada minuto (eventos `created` + `pagedUpdatedInDatabase`)

**Flujo:**
```
1. Notion Trigger (Tarea Creada / Actualizada) → Merge
2. Normalizar Tarea de Notion (extrae props: nombre, estado, fecha, prioridad,
   área, responsables emails, cliente_notion_id, estimaciones, real)
3. Buscar Tarea en Supabase (bub_tareas_notion filter notion_id, limit 1) ← anti-duplicado 2026-05-13
4. Listar Users Bubble (1 vez, executeOnce) → mapa email → bubble user _id
5. Listar Clientes Bubble (1 vez, executeOnce) → mapa cliente_notion_id → nombre_empresas
6. Decidir Acción:
   - archived + existe → delete
   - !archived + existe → update
   - !archived + !existe → create
   (resuelve cliente_nombre desde el map por cliente_notion_id)
7. Switch por outputIndex → Crear / Actualizar / Borrar en Bubble
   (incluye cliente_nombre en payload, sets updated_by='notion' como anti-rebote)
```

**Lookup contra Supabase (cambio 2026-05-13):** el paso 3 antes consultaba `tareas_notion` vía Bubble Data API. La API de Bubble tiene latencia de indexado de búsqueda (~30-60s tras un POST), lo que provocaba **falsos negativos** cuando dos pollings consecutivos del mismo notion_id corrían en ventana <1 min: la segunda ejecución no veía la fila recién creada por la primera → decidía `create` → fila duplicada en Bubble. Ahora el lookup va contra el espejo `bub_tareas_notion` (Supabase), que se sincroniza vía webhook reactivo `FGxG67I24POOUeHW` con latencia ~1-2s. La ventana de race es 30× más estrecha. El nodo Code `Decidir Acción` lee `m.bubble_id` (campo Supabase) en lugar de `m._id` (campo Bubble).

**Hardening anti-race 2026-05-18 (dedupe + retry):** dos defensas añadidas tras la incidencia de las 5 huérfanas residuales del lote 12-may:
- **Dedupe por `notion_id` en `Decidir Acción`** (paso 6). Cuando los triggers `Notion: Tarea Creada` y `Notion: Tarea Actualizada` disparan en el mismo poll para la misma página recién creada (Notion marca `last_edited_time = created_time` al nacer → ambos triggers la atrapan), `Fusionar Triggers` (Merge, append) produce 2 items con el mismo `notion_id`. Sin dedupe, ambos llegan al lookup Supabase antes de que el espejo escriba la primera creación → ambos resuelven `existsInBubble:false` → 2 creates → duplicado. Fix: agrupar `normalizeItems` por `notion_id` al inicio del Code, conservar el de `last_edited_time` más reciente. Coste 0 en happy path.
- **Retry en ambos Notion Triggers:** `retryOnFail: true, maxTries: 3, waitBetweenTries: 5000`. Notion API devuelve `Bad gateway` esporádicos (ejec `126372` del 2026-05-18 00:24 dejó el cursor `lastTimeChecked` encallado en `2026-05-16T21:17` durante 36 h porque la ejecución murió sin retry y el siguiente poll no se disparó). Misma receta que SYNC ADS Meta Discovery del 16-may.

**Nodos clientes (añadidos 2026-05-08, fix bug `cliente_nombre` NULL):**
- `Listar Clientes Bubble`: getAll typeName `clientes`, executeOnce, alwaysOutputData. Trae los ~73 clientes en una sola llamada por ejecución.
- `Decidir Acción`: construye `clienteNombreByNotionId[c.notion_id] = c.nombre_empresas` y emite `cliente_nombre`.
- `Crear` y `Actualizar Tarea en Bubble`: incluyen `cliente_nombre` en el array de properties.

**Propiedades sincronizadas (24 entries por payload Bubble, tras refactor 2026-05-08):**
`notion_id, agencia_id (constante e748c7d4-...), nombre, estado, fecha_entrega, prioridad, area_tarea, responsables (JSON.stringify bubble user IDs), responsable_nombres, cliente_notion_id, cliente_nombre, aprobador_emails (JSON.stringify), aprobador_nombres, observadores_emails (JSON.stringify), observadores_nombres, incidencia (bool), bloqueado_por_ids (JSON.stringify), bloqueando_ids (JSON.stringify), estimacion_min, estimacion_horas, duracion_real_min, real_horas, last_edited_time, updated_by`.

**Helpers Code añadidos (Normalizar Tarea de Notion):**
- `relationAllIds(p)` → array de notion_ids de una relation property (vs `relationFirstId` que solo extrae el primero).
- `checkboxVal(p)` → boolean para Notion checkbox properties.

**Anti-rebote:** escribe `updated_by='notion'` en Bubble. El sync de vuelta
(`9mEU2MzE14mGpry2` Bubble→Notion) detecta ese marker y omite la actualización.

**Propagación a Supabase:** NO escribe a Supabase. La replicación a `bub_tareas_notion`
se hace vía `FGxG67I24POOUeHW` (SYNC ABSOLUTO Bubble→Supabase) que se dispara por
webhook desde el Bubble DB Trigger al guardar el registro.

---

### Sync Cliente Notion → Bubble
**ID:** `FcTmv78nLjbCb2Ea08qbt` · ✅ Activo (reescrito y activado 2026-04-27)
**Triggers:** 2 Notion Triggers (DB Empresas `fd1652ef-2456-4b77-b44c-005b69b0e240`, polling 1min):
- `pageAdded` → dispara también la rama Clockify
- `pageUpdated` → solo flujo de sync

**Flujo:**
```
1. Notion Trigger detecta cambio en DB Empresas
2. If Recoge nombre (skip si vacío)
3. Set Meta Notion → notion_id, last_edited_time
4. Notion Get full page (properties completos)
5. Code Build Bubble Payload (mapea propiedades Notion → campos Bubble cliente)
6. HTTP GET Bubble por notion_id (constraint=equals)
7. Code Compare & Decide:
   - results[] vacío → action='create'
   - results[0] coincide campo a campo con payload → action='skip'
   - results[0] difiere → action='patch'
8. IF Skip? → noOp si action=skip
9. IF Create? →
   - TRUE: POST Bubble cliente → Activity Log Created
   - FALSE: PATCH Bubble cliente → Activity Log Updated
```

**Rama Clockify (paralelo, solo alta nueva):**
```
Notion Trigger pageAdded → Clockify Create Client → Clockify Create Project (nombre = cliente)
```

**Decisiones de diseño:**
- **Anti-rebote por comparación de contenido (Opción D).** No toca Notion ni añade campos en Bubble. Antes de PATCHear, lee Bubble y compara los 20 campos relevantes. Si todo coincide → skip. Esto rompe el loop B↔N sin markers ni timestamps.
- **NO escribe a Supabase directamente.** El espejo `bub_clientes` lo mantiene `FGxG67I24POOUeHW` (SYNC ABSOLUTO), disparado automáticamente por el DB Trigger Bubble `A Clientes is modified` tras cada POST/PATCH (en Bubble el trigger `is changed` cubre también creates). Aplicado el fix 2026-04-28: se eliminaron los nodos `POST sync mirror Created/Patched` que llamaban explícitamente al webhook con `{tabla: "clientes"}` — fallaban siempre porque el `Validar Payload` del SYNC ABSOLUTO solo acepta `bub_*`, pero el HTTP devolvía 200 enmascarando el error y el espejo se mantenía por el DB Trigger.
- **Clockify solo en alta.** Crea cliente + proyecto único con nombre = cliente. NO crea proyectos mensuales (cambio respecto al original).
- **Logs útiles:** `clase=cliente`, `accion=creado|actualizado`, `entidad_id=bubble_id`, `metadata.source="notion"`, `metadata.notion_last_edited_time` para detectar latencia Notion → Bubble. Ambos Activity Log con `onError: continueRegularOutput`.

**Notas técnicas críticas:**
- **`agencia_id` enviado a Bubble**: usa el `unique id` Bubble del objeto Agencia (`1769513105728x555492736219132700`), NO el `uuid_supabase` (`e748c7d4-...`). En Bubble Data Type `clientes`, el campo `agencia_id` es referencia al objeto Agencia y exige formato Bubble. Si se manda uuid_supabase: error 400 `Invalid data for field agencia_id: object with this id does not exist`.
- **Codes en `runOnceForEachItem`**: ambos `Code - Build Bubble Payload` y `Code - Compare & Decide` están configurados así. Sin esto, solo procesarían el primer item del trigger (perdiendo silenciosamente los demás).
- **Referencias entre nodos usan `.item.json`** (no `.first().json`) para que cada item del flujo se mapee correctamente con sus contextos paired en Activity Log.

**Estado de los datos al activar:** los 73 clientes de `bub_clientes` (cbi) tenían todos `notion_id` rellenado, por lo que cualquier edición en Notion entra por la rama PATCH (no CREATE) → cero riesgo de duplicados al activar.

**Tolerancia a 502 transitorios de Notion (2026-05-02):** ambos Notion Triggers (`Notion - Se agrega un nuevo cliente a la Database de Empresas` y `Notion - Se agrega modifica un nuevo cliente`) tienen `retryOnFail: true`, `maxTries: 3`, `waitBetweenTries: 2000ms`. Notion devuelve 502 (Cloudflare) o aborta conexión de forma esporádica (~0.17% de los polls); sin retry, cada fallo se marcaba como ejecución error y disparaba el workflow de errores. Los polls fallidos no avanzan cursor `lastTimeChecked`, así que el siguiente poll exitoso recupera los cambios pendientes (no hay pérdida de datos).

---

### Sync Cliente Bubble → Notion + Drive
**ID:** `wvHcgVqqjkWJcJDu` · ✅ Activo (reescrito y validado 2026-04-27, alineación estados unificada 2026-05-08)
**Trigger:** Webhook POST `/SYNC_clientes_bubble_notion` desde Bubble (API Connector "Cliente Sync Bubble Notion")

**Flujo CREATE** (cliente nuevo, `notion_id` vacío):
```
1. Webhook → Respond 200 OK (paralelo, asíncrono)
2. Normalize Client Payload (Code) — convierte strings "null"/"undefined" en null reales, valida bubble_id, valida `estado` contra los 2 valores del option set (desde 2026-05-15): `Activo`, `No Activo`
3. IF notion_id isEmpty → rama CREATE
4. Buscar Carpeta Raíz (HTTP Drive query por nombre cliente en parent "Clientes")
5. Resolver Raíz (Code) — alreadyExisted true/false
6. Crear Raíz si falta (HTTP Drive POST condicional)
7. Extraer rootId (Code)
8. Sub Carpetas Cliente (executeWorkflow → d0B4LokmPhHWdg6g, idempotente, ~17s)
9. Listar L1 raíz + Listar L2 Análisis (HTTP Drive)
10. Preparar datos cliente (Code) — calcula rootUrl + analisisUrl
11. Leer Doc Maestro → Insertar en índice → Actualizar Doc Maestro
12. Create Client in Notion1 (Notion API POST /v1/pages en DB Empresas) → notion_id
13. PATCH Bubble portal/clientes/{bubble_id} con { notion_id, link_drive, bb_link_drive_analisis }
14. Activity Log Creado (POST activity_log cbi, onError continueRegularOutput)
```

**Flujo UPDATE** (cliente con `notion_id`):
```
1. Webhook → Respond 200 OK
2. Normalize Client Payload
3. IF notion_id NOT empty → rama UPDATE
4. Nuevos parametros de Cliente (Code) — build properties Notion (con date guards contra fechas inválidas)
5. Update (Notion API PATCH /v1/pages/{notion_id})
6. Activity Log Actualizado (POST activity_log cbi, onError continueRegularOutput)
```

**Decisiones de diseño:**
- **NO escribe en Supabase.** El espejo `bub_clientes` lo mantiene `FGxG67I24POOUeHW` (SYNC ABSOLUTO). Evita el doble write y simplifica.
- **Drive solo en alta.** En UPDATE no se toca Drive (la estructura ya existe).
- **Idempotencia:** la creación de la carpeta raíz audita primero (búsqueda por nombre+parent) y solo crea si falta. Las subcarpetas via sub `d0B4LokmPhHWdg6g` también son idempotentes.

**Estructura de carpetas que crea el sub `d0B4LokmPhHWdg6g` (auditada 2026-05-23):**

```
/Cliente/
├── Onboarding                                ← L1
├── Analisis inicial y estrategia             ← L1
│   ├── Analisis inicial                      ← L2 (= bb_link_drive_analisis)
│   └── Estrategia                            ← L2
│       ├── Estilo comunicacion y Arquetipos  ← L3
│       └── Historico_newsletters             ← L3
├── Reuniones                                 ← L1
├── Informes                                  ← L1
└── Organizacion interna                      ← L1
    ├── CRM                                   ← L2
    └── Compartida Clientes                   ← L2
        ├── RRSS                              ← L3
        └── Anuncios                          ← L3
```

5 L1 + 4 L2 + 4 L3. Estructura **temática por tipo de activo**, no por Campaña.

⚠️ **TODO 2026-05-23 — añadir L1 `Campañas`** (decidido en sesión de documentación Ficha Cliente v2 modelo A): la nomenclatura PxCx requiere una carpeta por Campaña (`/Cliente/Campañas/PxCx — Nombre/`) donde vivan TODOS los entregables de esa Campaña juntos (briefing + copies + diseños + estáticos + reels + configs). Modificación pendiente: añadir nodo `Crear Campañas` en `Decidir L1` + `Listar L1` (que la incluya como `needed`). Coste estimado: 1 nodo HTTP + 1 fila en `Decidir L1`. La subcarpeta `PxCx — Nombre/` dentro de `Campañas/` la crea Account manualmente al declarar Pipeline/Campaña en la ficha (en F2 con backend se podría automatizar vía RPC + workflow nuevo). Referencias: [[../portal/ficha-cliente|ficha-cliente]] §7, [[../portal/equipo-manual-pipelines|equipo-manual-pipelines]] §2.bis.
- **Defensivo contra Bubble:** Bubble manda strings literales `"null"` para campos vacíos en API Connector. El nodo Normalize convierte `"null"` y `"undefined"` (strings) a `null` reales antes de procesar.
- **Token Bubble:** credencial `IFAeIvEVDbrPBZIW` (Header Auth Bubble) con token live de portal. NO usar tokens hardcoded en nodos.
- **Logs útiles:** activity_log con `clase=cliente`, `accion=creado|actualizado`, `entidad_id=bubble_id`, `metadata.execution_id`, `metadata.drive_already_existed` (distingue alta real vs retry).

**API Connector Bubble correspondiente:** "Cliente Sync Bubble Notion" en grupo "N8N - Workflows". Body con campos del Data Type clientes + `source: "bubble"` + `bubble_id` (= `This Cliente's unique id`) + `notion_id` (vacío en alta).

---

### ~~Sync Nuevos Miembros Notion → Supabase~~ (ARCHIVADO 2026-04-27)
**ID:** `cXewmXMQ8xhKmN8f` · 🗑 `isArchived: true`

**Motivo:** apuntaba a tabla `miembros_equipo` (proyecto histórico maw, hoy INACTIVE) que nunca existió en cbi. La identidad de miembros vive desde 2026-05-02 en `bub_user` (con campos `notion_id` + `clickup_user_id`). La tabla intermedia `bub_miembro_notion` se eliminó (DROP) tras la migración. Además era INSERT puro sin upsert: cambios de email en Notion no se reflejarían.

---

### ~~Sync Tarea Bubble → Notion~~ (ARCHIVADO 2026-04-27)
**ID:** `9mEU2MzE14mGpry2`
**Estado:** 🗑 Archivado (`isArchived: true`)

**Motivo del archivado:** el kanban operativo en Bubble (`/operaciones`) no estaba en uso real. La call Bubble→n8n correspondiente nunca llegó a construirse en API Connector (no aparece en la tabla de webhooks de `docs/infra/bubble-api-connectors.md`), por lo que el workflow llevaba meses esperando llamadas que nunca llegaban. Decisión: archivar y rehacer el kanban + sync desde cero cuando se retome la feature.

**Lo que se conserva intencionalmente** (no es deuda — es inversión para el rehacer futuro):
- Campo `last_edit_source` en Bubble Data Type `tareas_notion` y columna en `bub_tareas_notion` (cbi). El patrón anti-rebote multi-provider (`notion`/`clickup`/`bubble`/`user`/`cron`) introducido en F0 plan v3 ClickUp (2026-05-02) reemplaza al legacy `updated_by`. Documentado en `docs/sectores/README.md`.
- Nodo en `GjijIDEUyiH05Mg0` (Notion→Bubble) que escribe `updated_by='notion'` — necesario el día que se reactive el flujo inverso.

---

### SYNC FICHAS — Supabase → Bubble
**ID:** `ewu5A5E05T4tz5CD` · ⏸ INACTIVO (creado 2026-05-22, pendiente tag `portal` UI + smoke test)

**Triggers (2):**
- Webhook `POST /sync_fichas_supabase_bubble` (Bubble botón "Refrescar catálogo")
- Schedule cron `15 3 * * *` Europe/Madrid (respaldo nocturno)

**Dirección invertida vs el resto del sistema:** aquí Bubble es **destino**, Supabase es **fuente**. No hay tabla espejo `bub_*` — los Data Types Bubble (`fichas_categorias`, `fichas_de_producto`, `playbook_cliente_servicios`) son réplica read-only de las tablas nativas Supabase con **el mismo nombre**. Editor real vive en `work.thenucleo.com/fichas-de-producto/` + `/playbook/`. Nomenclatura unificada Supabase↔Bubble (rename Bubble 2026-05-22).

**Flujo (3 bloques secuenciales, 18 nodos):**
```
Webhook ─▶ Respond OK ──┐
Schedule 03:15 ─────────┤
                        ▼
            [CATEGORÍAS] GET Supabase → GET Bubble → Compute Cat Ops (Code) → Apply Cat Op (HTTP dinámico) → Collect
                        ▼
            [FICHAS]     GET Supabase → GET Bubble → Compute Ficha Ops → Apply Ficha Op → Collect
                        ▼
            [JUNCTION]   GET Supabase → GET Bubble → Compute Junction Ops → Apply Junction Op → Final Log
```

**Patrón Compute Ops (común a los 3 bloques):**
- Build `bubbleByExt` (Map `id_externo → _id Bubble`) desde GET Bubble inicial.
- Para cada fila Supabase: si `id_externo` ya está en Bubble → PATCH; si no → POST.
- Emite items `{ kind, ext_id, method, url, body, uid }`.
- Si `ops.length === 0` emite item `{noop: true}` para no romper el flujo siguiente.

**Patrón Apply Op (HTTP dinámico):**
- `method: ={{ $json.method }}` · `url: ={{ $json.url }}` · `jsonBody: ={{ JSON.stringify($json.body || {}) }}`.
- Header `Authorization: Bearer 088a20b5...`.
- `onError: continueRegularOutput` — un POST que falle no rompe el run.

**Resolución de referencias inter-bloque (clave):**
- Ficha tiene `categoria_id` (UUID Supabase) → debe resolverse a `_id` Bubble de la categoría.
- Junction tiene `ficha_id` (UUID Supabase) → mismo problema.
- Tras el POST de una categoría nueva, **el GET Bubble del siguiente bloque NO la verá** por delay de indexado (~30-60s, anti-patrón documentado en memoria persistente `feedback_bubble_data_api_indexado.md`).
- **Mitigación:** capturar `_id` de la respuesta del POST (Bubble devuelve `{id: "..."}` inmediato) y construir el mapa progresivamente:
  ```js
  // En Compute Ficha Ops:
  const initialCats = $('GET Bubble Categorias')...; // las que ya estaban
  const computedCatOps = $('Compute Cat Ops').all().map(i => i.json);
  const catOpResults = $('Apply Cat Op').all();
  // Por cada op kind='cat_create', tomar el response.id y meterlo en el map
  ```
  Para PATCH no hace falta — el `_id` no cambia.

**Cliente en Junction:** `cliente_bubble_id` (text Supabase) ya es el unique_id de Bubble del Cliente. Se pasa directo al field `cliente` del Data Type junction (Bubble lo trata como referencia).

**Credenciales:**
- Supabase: `13dKSjEd2XZCYpJa` (`1. Espejo Supabase`).
- Bubble: Bearer token hardcoded en headers (mismo que SYNC ESPEJO `088a20b5...`).

**URLs hardcoded:**
- Supabase: `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/`
- Bubble: `https://app-the-nucleo-agency.bubbleapps.io/api/1.1/obj/` (LIVE desde 2026-05-22). ⚠️ Bubble Data API tiene bases separadas DEV (`/version-test/`) vs LIVE (`/api/1.1/obj/`). El sync apunta a LIVE porque los 78 clientes del espejo `bub_clientes` viven en LIVE.

**Limitaciones v1 (conscientes):**
- ❌ Sin DELETE de huérfanos — borrar en Supabase no borra en Bubble.
- ❌ Sin paginación — GET Bubble `limit=100`. Junction Supabase tiene 199 filas. La primera corrida solo crea 100 en Bubble; la segunda corrida ya los ve como existentes (`id_externo` match) y completa los restantes 99. Self-healing en 2 ejecuciones.
- ❌ Sin retry específico — si Bubble devuelve 4xx por race, hay que volver a ejecutar.

**Settings:**
- `executionOrder: v1`, timezone Madrid.
- `errorWorkflow: HRDQ9Ju4NAIUV0qyhKzlz` (ERRORES — Capturar y Registrar Plataforma).
- `saveDataErrorExecution: all`, `saveDataSuccessExecution: all` (verbose, ajustar tras smoke test).

**Tag pendiente:** `portal` (id `8JEzIL3gJwyclObr`) — sin él no entra al backup `marketingthenucleo/n8nthenucleo`.

**Tras activar:** exponer botón "Refrescar catálogo" en Bubble que llame al webhook `POST /sync_fichas_supabase_bubble` (vía API Connector). El cron 03:15 cubre el caso de actualizaciones perezosas.

---

## Multi-Provider F1 (auxiliares ClickUp)

Plan v3 multi-provider, fase F1 — 6 workflows auxiliares creados 2026-05-02. **TODOS inactivos hasta que Ben los active manualmente** (acciones F1.3 documentadas en `docs/portal/integraciones/clickup.md`). Spec completa del proyecto multi-provider en `~/.claude/plans/perfecto-vamos-a-ello-steady-tome.md`.

### `cron_sync_suppress_cleanup` (`ek5veFfwbeSB0bW3`)
- **Trigger:** Schedule cada 5 minutos.
- **Hace:** `DELETE FROM sync_suppress WHERE until_ts < now()` vía nodo Supabase delete.
- **Carpeta destino:** `SYNC Otros` (raíz actualmente, pendiente mover).
- **Credencial Supabase:** `Espejo Supabase` (id `13dKSjEd2XZCYpJa`).

### `provider_test_connection` (`o32vrctYqibCA5C2`)
- **Trigger:** Execute Workflow Trigger. Inputs: `agencia_id`, `provider`, `token`.
- **Hace:** Switch por `provider`. Branch CU: `GET https://api.clickup.com/api/v2/user` con header `Authorization: {{ $json.token }}`. Branch Notion: `GET https://api.notion.com/v1/users/me` con `Authorization: Bearer` + `Notion-Version: 2022-06-28`. Devuelve `{statusCode, body}`.
- **Uso:** smoke test del token antes de configurar credencial. Ben lo dispara manualmente desde n8n UI en onboarding.
- **Carpeta destino:** `SYNC Otros` (raíz actualmente, pendiente mover).
- **Credencial:** ninguna guardada (token recibido como parámetro).

### `provider_register_webhooks` (`QBLy4DWZ7mUPsfpg`)
- **Trigger:** Execute Workflow Trigger. Inputs: `agencia_id`, `workspace_id`, `token`.
- **Hace:**
  1. Code: genera 2 secrets HMAC random (32 bytes hex) — uno para tasks, otro para folders.
  2. POST CU `/v2/team/{workspace_id}/webhook` con `endpoint=/clickup_tasks_inbound`, eventos `task* + list*`, `secret=secret_tasks`.
  3. INSERT `provider_webhooks` con webhook_id devuelto.
  4. POST CU `/v2/team/{workspace_id}/webhook` con `endpoint=/clickup_folders_inbound`, eventos `folder*`, `secret=secret_folders`.
  5. INSERT `provider_webhooks` con webhook_id devuelto.
- **Carpeta:** `SYNC Otros` ✅.
- **Credenciales:** Supabase `Espejo Supabase`. Token CU recibido como param.

### `provider_rotate_token` (`4e9s6FpYlWiYlcI9`)
- **Trigger:** Execute Workflow Trigger. Inputs: `agencia_id`.
- **Hace:** UPDATE `provider_webhooks SET status='deprecated', updated_at=now()` WHERE `agencia_id=? AND provider='clickup' AND status='active'`. Versión MVP simplificada (no DELETE en CU automático). Tras esto Ben llama `provider_register_webhooks` con el nuevo token y borra los CU viejos a mano cuando confirma que los nuevos funcionan.
- **Carpeta:** `SYNC Otros` ✅.
- **Credencial Supabase:** `Espejo Supabase`.

### `provider_discover_clients` (`SMOKYPAzGAYrgpLK`)
- **Trigger:** Execute Workflow Trigger. Inputs: `agencia_uuid`, `agencia_bubble_id`, `workspace_id`, `space_id`, `space_name`.
- **Hace:**
  1. GET CU `/v2/space/{space_id}/folder?archived=false`.
  2. SplitOut `folders[]` para iterar.
  3. Code "Enrich folder con context" (runOnceForEachItem) — añade contexto del trigger a cada folder. `cliente_notion_id = 'cu_' + folder.id`.
  4. POST Bubble `app-the-nucleo-agency.bubbleapps.io/api/1.1/obj/clientes` con `{nombre_empresas, agencia_id (bubble_id), notion_id, provider, external_id, last_edit_source}`.
  5. INSERT `cliente_external_links` con `cliente_bubble_id` (devuelto por Bubble), `cliente_notion_id`, `agencia_id` (uuid), `provider='clickup'`, `external_type='folder'`, `external_id`, `external_name`, `external_space_id`, `external_space_name`, `is_primary=true`.
- **MVP simplificado:** 1 space por ejecución (Ben llama N veces para N spaces). NO hace lookup match contra `bub_clientes` por nombre — crea cliente Bubble nuevo siempre. Si un cliente real ya existe en Bubble y le añades folder en otro Space, te crea duplicado. Consolidación manual o se reabre en F4.
- **Carpeta:** `SYNC Clientes` ✅.
- **Credenciales:** CU `Eq9YFJvJi97v9o44` + Bubble `i8UMJM5KZOGBRf5z` + Supabase `Espejo Supabase`.

### `provider_fetch_space_statuses` (`jsAnENkkzfTs6Kzu`)
- **Trigger:** Execute Workflow Trigger. Inputs: `agencia_id`, `space_id`.
- **Hace:** GET CU `/v2/space/{space_id}` + Code que extrae `statuses[]` y normaliza a `{id, status, type, color, orderindex}`.
- **Uso:** lo consume API Connector Bubble `cu_get_space_statuses` (F2.C) para poblar custom state `kanban_cu_columns` al cargar `/operaciones-cu`. Permite Kanban dinámico que refleja los statuses reales del Space activo.
- **Carpeta destino:** `SYNC Otros` (raíz actualmente, pendiente mover).
- **Credencial CU:** `Eq9YFJvJi97v9o44`.

---

## Anti-rebote multi-provider (resumen)

Doble defensa para prevenir bucles bidireccionales Bubble↔CU↔Bubble:

1. **Marker `last_edit_source`** en `bub_tareas_notion` y `bub_clientes` — quien hizo la última edición. Workflow `provider→Bubble` setea `last_edit_source='clickup'`. Workflow `Bubble→provider` lo lee; si matchea, skip.
2. **Ventana de supresión 30s en `sync_suppress`** — tras cada PATCH Bubble→Provider, INSERT `(external_id, provider, now()+30s)`. El workflow `Provider→Bubble` consulta esta tabla antes de patchear; si suprimido, skip y log.

**Regla de empate** (edición simultánea <30s en ambos lados): **gana el provider** (CU es master de tareas). Documentado en plan v3.

**Cleanup**: cron `cron_sync_suppress_cleanup` (cada 5 min) borra filas con `until_ts < now()`.

---

## CRON

### Tareas Huérfanas (Notion → Bubble + espejo)
**ID:** `ZqccS38F2Lz8WFwX`
**Nombre real:** `CRON Reconciliación Tareas — Eliminar huérfanas Notion→Bubble→Supabase espejo`
**Schedule:** Cada 3h (Europe/Madrid)
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz`

Detecta filas en el espejo `bub_tareas_notion` (Supabase `cbixhqjsnpuhcrcjppah`) cuya tarea en Notion está archivada, borrada o devuelve 404. Las elimina de Bubble (`tareas_notion`) y del espejo.

**Flujo:**
```
1. Cron cada 3h (o trigger manual)
2. GET Supabase bub_tareas_notion (notion_id not null)
3. IF hay tareas?
4. Preparar lista (notion_id + bubble_id + nombre)
5. Loop por tarea
   a. GET Notion /v1/pages/{notion_id}
   b. IF eliminada o archivada? (status=404 OR archived=true OR in_trash=true)
      NO → siguiente iteración
      SÍ → Log activity_log (accion=eliminada_huerfana, source=huerfanas_cron)
   c. IF tiene bubble_id?
      SÍ → DELETE Bubble tareas_notion (onError: continueRegularOutput)
           → DELETE espejo bub_tareas_notion (filter por notion_id)
      NO → DELETE espejo directo
6. Fin
```

**Reglas críticas:**
- `DELETE Bubble tareas_notion` DEBE tener `onError: continueRegularOutput`. Si Bubble ya no tiene el registro (404), el flujo tiene que continuar al DELETE del espejo. De lo contrario, abortar deja filas zombie en el espejo que bloquean al siguiente cron eternamente. Ver anti-patrón #15.
- El único camino legítimo de delete es Notion → este cron → Bubble + espejo. Bubble no permite delete manual de tareas, por eso la reconciliación no necesita reverse-diff desde Bubble.
- `Notion: GET pagina` configurado con `retryOnFail: true` (maxTries=3, waitBetweenTries=2000ms) y `parameters.options.timeout: 30000` (2026-05-02). Importante: NO añadir `onError: continueRegularOutput` aquí — pasaría un item vacío al `IF eliminada o archivada?` y podría disparar DELETE de tareas reales por timeout transitorio. El retry cubre los blips; si tras 3 intentos el cron aborta es preferible a un borrado falso.
- IF `cond-404` lee `$json.status` (NO `$json.statusCode`). El nodo HTTP Request con `neverError:true` y sin `fullResponse:true` devuelve solo el body de la respuesta. El error 404 de Notion tiene shape `{"object":"error","status":404,"code":"object_not_found",...}`. El campo es `status`, no `statusCode`. Ver anti-patrón #16 e historial 2026-05-04.

---

### Clockify Sync
**ID:** `ccPQuZmH7DGYRRbe`
**Estado:** ✅ Activo (reactivado 2026-04-27)
**Schedule:** Diario a las 23:00 Madrid (`triggerAtHour: 23`)
**Nota:** El nodo trigger se llama `CRON 23:00 Madrid`. La URL de Supabase apunta a `cbixhqjsnpuhcrcjppah` (cbi); previamente apuntaba al proyecto antiguo (maw, hoy INACTIVE) — corregido en la reactivación.

```
1. Clockify Get Clients (workspace 68e22513cb6c3d1db549ca50) → mapa id→nombre
2. Build Context: ventana últimos 35 días (UTC), página 1
3. Loop paginado (Fetch Page → Accumulate → IF more pages → Update Context)
   - POST reports.api.clockify.me/.../reports/detailed con pageSize=1000
   - Sigue mientras lastPageCount === 1000 y currentPage < 50
4. Normalize + Chunk: arma payload por entry y trocea en chunks de 100
5. Upsert Supabase clockify_time_entries (on_conflict=clockify_id)
6. Log Result
```

---

### Calculo horas reales — Clockify Auto
**ID:** `1f6IGS3cGPMVhQInlG7nX`
**Estado:** ✅ Activo
**Trigger:** Schedule
**Función:** automatización de cálculo de horas reales por tarea/cliente desde Clockify (no consultable vía MCP — `availableInMCP=false`).

---

### Cerebro IA — CRON Reindexar RAG Nocturno
**ID:** `ZnJSkoWlSusmEjhO`
**Estado:** ✅ Activo
**Schedule:** Diario 3:00 AM Madrid
**Función:** reindexa fileSearchStores Gemini de cada cliente activo. Detalle en sección RAG.

---

### Newsletter IA — CRON Reindexar RAG Nocturno (`newsletter_cron_reindex`)
**ID:** `kZE3W2ae0upyGt2E`
**Estado:** ❌ Inactivo (espera E2E Fase 3 Bubble — refactorizado 2026-04-29)
**Schedule:** Diario 3:30 AM Madrid
**Función:** lee `bub_clientes` con `link_drive`, cruza con `rag_stores` filtrado por `tipo='newsletter'`, dispara reindex de los stale (>24h) o nunca indexados. **Multi-tenant** (sin `agencia_id` hardcoded). Invoca subworkflow `w6Gqo8B6Sqp6Mq9x` (`newsletter_kb_fetch`). Renombrado pendiente a `newsletter_cron_reindex`.

---

### Newsletter IA — CRON reset stuck (`newsletter_cron_reset_stuck`)
**ID:** `4rGLGT37BORP3xab`
**Estado:** ✅ Activo (creado 2026-04-29)
**Schedule:** Cada 15 min
**Función:** llama RPC `newsletter_reset_stuck(p_ttl_minutes=15)` en cbi. Solo libera estados `indexing|generating|entregando` (los `waiting_*` son espera humana). Marca WIP `error` + inserta msg assistant explicativo en `chat_messages`. Auth `supabaseApi` cred `13dKSjEd2XZCYpJa` ("Espejo Supabase"). errorWorkflow `HRDQ9Ju4NAIUV0qyhKzlz`.

---

### Análisis Estratégico — CRON reset stuck
**ID:** `V60MieFkQzOszxhh` (`analisis_cron_reset_analizando`)
**Estado:** ✅ Activo
**Schedule:** Cada 15 min
**Función:** llama RPC `analisis_reset_stuck_analyzing(p_ttl_minutes=15)` en Supabase cbi para liberar filas de `analisis_wip` que quedaron en estado `analizando` más de 15 min (chats co-creativos colgados).

---

### CRON LOG — Renovar Subscriptions Google Chat (3h)
**ID:** `NMZA404s1agKcHau` · ✅ Activo (creado 2026-05-08, refactorizado 2026-05-09 — Fase 3 #1 Actividad Diaria Log, fix `last_error` ruido 2026-05-11, intervalo 6h→3h 2026-05-14)
**Schedule:** Cada 3h (`hoursInterval: 3`)
**Folder:** `App TheNucleo Agency` (id `6NKOF15ZtIVs52l2`)
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz`
**Tag `portal`:** ✅ aplicado

Recrea las Workspace Events Subscriptions de Google Chat cuando han expirado (TTL 24h sin DWD). Sin este cron el pilot de captura de mensajes deja de recibir eventos tras 24h.

```
1. Cada 3h (Schedule Trigger — nombre del nodo "Cada 6h" sin renombrar, TODO cosmético)
2. Fetch Expiring Subscriptions (Supabase getAll gchat_subscriptions
   WHERE status='active' AND expire_time < {{ $now.toISO() }})
3. Reactivate Subscription (HTTP POST workspaceevents.googleapis.com/v1/subscriptions
   con cred Google SA chat-token-thenucleo, body completo:
     targetResource: //chat.googleapis.com/{{ $json.space_id }}
     eventTypes: [google.workspace.chat.message.v1.created]
     notificationEndpoint.pubsubTopic: projects/app-thenucleo/topics/gchat-events-thenucleo
     payloadOptions.includeResource: true
     ttl: 0s
   Idempotente — Google reutiliza la sub por (target, pubsubTopic) y devuelve la misma
   con expireTime nuevo)
4. Mark Renewed (Supabase update gchat_subscriptions filter id=<id viejo>:
   status='active', last_renewed_at={{ $now.toISO() }},
   expire_time={{ $json.response?.expireTime ?? $now.plus({hours: 24}).toISO() }},
   updated_at={{ $now.toISO() }})
   — Nota: NO escribe `last_error` desde el fix 2026-05-11. El field se preserva
     intacto, así que solo lo popula quien tenga el error (rama branch-on-error
     futura). Antes escribía `last_error=''` en cada renewal exitoso, ensuciando
     auditorías.
```

> **Nota:** el nodo se llama `Reactivate Subscription` por legado (versión inicial usaba `:reactivate`). Tras el refactor 2026-05-09 hace `POST CREATE` idempotente. Renombrar a `Recreate Subscription` es TODO cosmético no crítico.

**Refactor 2026-05-09 — `:reactivate` → POST CREATE idempotente:**
- **Trigger del fix:** ejecución `117225` 2026-05-09 16:00 UTC devolvió `403 PERMISSION_DENIED — SUBSCRIPTION_ACCESS_DENIED — "(or it may not exist)"` al llamar `:reactivate` sobre la sub ya expirada. Sin fix la sub muere a las 24h y Pub/Sub deja de entregar.
- **Causa raíz:** Google elimina rápido las subs SUSPENDED, y los scopes `chat.app.*.readonly` son asimétricos — autorizan CREATE pero no `:reactivate` sobre subs perdidas (mismo patrón que la lección 5 de Fase 2 v2).
- **Fix:** cambiados 2 fields del nodo `Reactivate Subscription` vía `n8n_update_partial_workflow` (2 ops `patchNodeField`):
  1. `parameters.url`: `=https://workspaceevents.googleapis.com/v1/{{ $json.id }}:reactivate` → `https://workspaceevents.googleapis.com/v1/subscriptions`.
  2. `parameters.jsonBody`: `={}` → body completo con `targetResource` interpolado de `$json.space_id`, `eventTypes`, `notificationEndpoint.pubsubTopic`, `payloadOptions.includeResource: true`, `ttl: "0s"`.
- **Validado:** `n8n_validate_workflow` 0 errores. Patrón validado manualmente con `C:\tmp\gchat-bot-assets\create-subscription.mjs` el mismo día — Google reutilizó la sub por `(targetResource, pubsubTopic)` y devolvió mismo `name`/`uid` con `expireTime` nuevo.
- **Mark Renewed sin tocar:** el filter `id = $('Fetch Expiring Subscriptions').item.json.id` sigue funcionando porque Google preserva el `name` por idempotencia. Si en algún caso Google generara un `name` distinto, el UPDATE no encontraría fila y caería al errorWorkflow — aceptable.
- **expire_time fallback:** la expression existente `$json.response?.expireTime ?? $now.plus({hours: 24})` cae al fallback de 24h si la respuesta CREATE no viene wrappeada en `response`. Eso evita BD inconsistente sin modificar el nodo.

**Finding histórico (smoke test execution `116448`, 2026-05-08, ya superado por el refactor):**
- `subscriptions:reactivate` sobre una sub en `ACTIVE` no extiende `expireTime`. Solo opera contra `SUSPENDED`.
- Por eso el filtro Supabase es `expire_time < now()` (no `now()+6h`). Ese filtro sigue siendo correcto post-refactor: solo recreamos las que ya expiraron.

**Otras decisiones:**
- Sin rama `onError: continueErrorOutput`. Si CREATE falla, errorWorkflow externo registra en `n8n_incidencias`. Aceptable con 1 sub en pilot; refactor a rama dedicada cuando rollout a 11+ subs (un fallo aislado no debe bloquear las demás).
- Scopes readonly suficientes para CREATE (lección aprendida #5 de `docs/portal/integraciones/google-chat-log.md`).
- Trade-off aceptado: gap worst-case ~3h sin captura el día que la sub expira (entre expiración real → siguiente tick del cron). Aceptable para esta feature (log operativo, no real-time). Bajado de 6h→3h el 2026-05-14 tras observar gap real de ~4.5h (sub expiró 10:00 UTC, próximo tick estaba a 15:22 UTC — log de chat sin captura ese día).

**Cred n8n usada por este workflow:** `Bot Log Actividad - Service Acount` (id `nJOGize9nY0rINy4`, tipo `googleApi`, Service Account `chat-token-thenucleo@app-thenucleo.iam.gserviceaccount.com`, scopes `chat.app.*.readonly`, sin Impersonate). Reutilizada por `gJfDb3Gwrf7fJ8Li` (OPS LOG Crear Subscription) — comparten el mismo patrón POST CREATE.

---

### CRON DEMO — Rolling Refresh Fechas (Lunes 03:00)
**ID:** `Z9Mp78CHNeuEwtCc` · ✅ Activo (creado 2026-05-25)
**Schedule:** Weekly, lunes 03:00 Europe/Madrid (era daily al crear; cambiado a weekly mismo día por decisión Ben)
**Folder:** raíz (personal Ben)
**Error workflow:** (sin asignar)
**Tag `portal`:** ⏳ pendiente UI (necesario para entrar al backup `marketingthenucleo/n8nthenucleo`)

Mantiene las fechas seed de la agencia Demo Quasar (`bea972de-6499-4086-b8de-57e8ed2d42a7`) actualizadas al `CURRENT_DATE` para que la demo del Portal no quede "atrás en el tiempo" en filtros tipo "últimos 30 días" (Clockify), "últimos 6 meses" (Holded) o "histórico chats Análisis" al pasar el tiempo. Detalle operativo + protocolo de refresh on-demand Bubble en `docs/portal/demo-quasar.md`.

```
1. Cron lunes 03:00 Madrid (Schedule Trigger v1.3, weeks=1, triggerAtDay=[1], triggerAtHour=3, triggerAtMinute=0)
2. POST demo_rolling_refresh (HTTP Request v4.4, POST
   https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/demo_rolling_refresh
   Headers:
     apikey: ={{ $env.SUPABASE_SERVICE_ROLE_KEY }}
     Authorization: =Bearer {{ $env.SUPABASE_SERVICE_ROLE_KEY }}
     Content-Type: application/json
   Body: {}
   Timeout: 30000ms
   Returns: {status, delta_days, rows: {clockify, holded_facturas, chat_conversations,
                                       chat_messages, analisis_wip, holded_metricas}})
```

**RPC consumida:** `demo_rolling_refresh()` SECURITY DEFINER (ver `supabase-schema.md` sección "Demo Quasar"). Idempotente — si `delta_days <= 0` devuelve `{status:'skipped', reason:'already_fresh'}` sin escribir.

**Alcance del CRON automático:** solo tablas cbi (Clockify, Holded, chats, análisis). Las fechas en `bub_clientes` (`fecha_onboarding`, `ultimo_seguimiento`) son espejo desde Bubble y NO se tocan automáticamente — si entraran al CRON, cada PATCH dispararía `wvHcgVqqjkWJcJDu` que intentaría actualizar la página Notion del cliente Demo (que no existe, son UUIDs fake) → ruido semanal en `n8n_incidencias`. Decisión: refresh Bubble es on-demand manual. Ben pide "refresca fechas Bubble Demo" → operador pausa `wvHcgVqqjkWJcJDu` 30s, hace 3 PATCH a Bubble Data API, reactiva.

**Lección setup (gotcha SDK n8n):** la expresión `expr('$env.X')` del SDK genera `=$env.X` que n8n NO evalúa en headers HTTP. Hay que usar `expr('{{ $env.X }}')` para que genere `={{ $env.X }}` (sintaxis canónica). Detectado en el primer test del workflow (401 Invalid API key porque el header `apikey` se mandaba literal). Aplicable a cualquier nodo HTTP Request que lea env vars.

**Cred n8n usada:** ninguna (env var directa). `$env.SUPABASE_SERVICE_ROLE_KEY` ya existía en EasyPanel desde 2026-05-14 (ver log-cambios línea 493).

---

### BLOG Zenyx — DIARIO 18:00 Madrid
**ID:** `CNlBtiFCwY69I6Wl`
**Estado:** ✅ Activo
**Schedule:** Diario 18:00 Madrid

Coge el siguiente vídeo pendiente de la vista `v_blog_videos_pendientes` (orden ASC), oembed + Supadata transcribe + Claude genera markdown, hace commit al repo `marketingthenucleo/thenucleo-landing` (carpeta `content/conocimiento-zenyx/`), marca `publicado` en `blog_videos`. Detalle completo en [[blog-zenyx|docs/blog-zenyx-workflow]].

**Contrato Claude → parser (2026-04-26):** Claude devuelve **tags XML** (`<title>`, `<slug>`, `<excerpt>`, `<markdown_body>`), no JSON. El nodo `Parse Claude and Build Markdown` extrae con regex `<tag>([\s\S]*?)</tag>`. Razón en anti-patrón #11.

---

### FINANZAS — SYNC Holded → Supabase
**ID:** `vI3TbyxtFM6wjhBS`
**Estado:** ✅ Activo (activado 2026-04-25)
**Triggers:** Webhook `/sync_holded_finanzas` (manual desde Bubble) + CRON 4:00 AM
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz`

```
1. INSERT holded_sync_log (trigger_type, status='running')
2. GET Holded /invoicing/v1/documents/invoice
3. GET Holded /invoicing/v1/documents/purchase
4. Code Calcular Métricas: 6 meses rolling, MRR/ingresos/gastos/margen,
   desglose recurrente vs puntual, impagos, ticket medio
5. Upsert holded_metricas (on_conflict=mes,agencia_id)
6. DELETE holded_facturas WHERE agencia_id=X (limpia panel)
7. POST holded_facturas con impagadas + próximas
8. PATCH holded_sync_log (finished_at, status='ok')
```

---

### WF1 — Oyente Meta Ads Gmail
**ID:** `4gN3uGhH8NZX2BDU`
**Trigger:** Gmail Trigger cada minuto (label `Label_6002817172122686507`, no leídos)
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz`

Detector de **alertas operativas** de Meta for Business (rechazos, suspensiones, límites de gasto, fallos de pago, recibos, fatiga). **No extrae métricas** (reach/impressions/spend) — eso lo trabaja Looker/Meta API directamente.

```
1. Gmail Trigger → cada minuto, etiqueta Meta for Business, solo unread
2. Code "Extraer ad_account_id":
   - Regex sobre subject + snippet:
     · /identificador de la cuenta[:\s]+(\d{10,20})/i
     · /Account ID[:\s]+(\d{10,20})/i
     · /\((\d{14,20})\)/
   - Clasifica tipo_error por keywords del asunto:
     rechazo | suspendido | limitada_presupuesto | aprobado | recibo | frecuencia_alta | otro
   - Marca es_critica=true para rechazo/suspendido/limitada_presupuesto
   - Genera external_id = "gmail_<message_id>" (idempotencia)
3. IF — ¿Tiene ad_account_id? (skip si no extrae)
4. Lookup Bubble GET /obj/dashboardmedia_cuentas_ads
   constraint: meta_ad_account_id = "act_<id>"
   → resuelve cliente_notion_id + agencia_id
5. IF — ¿Tiene cliente? (skip si no hay match)
6. Verificar dedup en Bubble GET /obj/dashboardmedia_alertas_operativas
   constraint: external_id = gmail_<message_id>
7. IF — ¿Ya existe? (skip si count > 0)
8. Humanizar con IA: POST api.anthropic.com/v1/messages
   model=claude-haiku-4-5-20251001, max_tokens=500
   - system role anti-markdown, anti-narrativa
   - recibe METRICAS como hints literales (no aluciacion)
   - devuelve JSON {titulo, detalle} en formato COMPACTO "Etiqueta: valor | ..."
9. POST /obj/dashboardmedia_alertas_operativas con cadena de fallback:
   - titulo: IA (con strip de ```json fences```) → titulo_compacto regex → subject
   - detalle: IA → detalle_compacto regex → body_preview
   - resto: fuente=meta, tipo_error, es_critica, external_id, estado=activa,
     fecha_deteccion, cliente_notion_id, agencia_id
10. Gmail Mark As Read del mensaje
```

**Capa híbrida regex + IA (2026-04-25):**
- **Regex en Code** extrae `importe`, `umbral`, `campana`, `resultados`, `metodo_pago`, `referencia` (multi-idioma ES/EN). Datos exactos, anti-alucinación IA.
- **IA con prompt v2** recibe esas métricas como hints literales y genera formato compacto. Si Meta cambia plantilla, la IA cubre; si la IA falla parse JSON, el regex compacto cubre.
- **Parser robusto** en "Crear alerta": strip de ` ```json ... ``` ` markdown fences antes de `JSON.parse` (bug anterior: la IA devolvía fences → parse fallaba → fallback al subject crudo = "el correo tal cual").

**Tablas Bubble involucradas:**
- `dashboardmedia_cuentas_ads` (lookup) — clave `meta_ad_account_id` con prefijo `act_`
- `dashboardmedia_alertas_operativas` (escritura) — clave única `external_id`

---

## Chat IA

### Chat Tareas (entrada)
**ID:** `RPdNg5ZNXK0VrOhG`
**Trigger:** Webhook POST desde Bubble (sidebar Dashboard)

```json
{
  "agencia_id": "uuid",
  "conversation_id": "uuid",
  "mensaje": "texto del usuario",
  "contexto_adicional": {}
}
```

Pasa al workflow de proceso y devuelve response de Claude a Bubble.

### Chat Tareas (proceso IA)
**ID:** `aGML9yyMsoAQ6ZGL`
**Función:**
1. Recupera últimos 20 mensajes de `chat_messages` para la conversación
2. Consulta `v_tareas_contexto_ia` para contexto de tareas actuales
3. Si detecta intención de crear tarea → activa flujo de creación paso a paso via `tarea_en_progreso`
4. Llama a Claude API con system prompt + historial + contexto
5. Guarda respuesta en `chat_messages`
6. Si creación de tarea completada → llama workflow Crear Tarea

---

### Chat Cerebro IA (entrada)
**ID:** `JI5Tr7IogqXgaI7a`
**Trigger:** Webhook POST desde Bubble (página Ficha Cliente → tab Cerebro IA)

Recibe empresa_id y mensaje del usuario. Llama al proceso.

### Chat Cerebro IA (proceso)
**ID:** `7yjLwl4cEJa7XAYY`
**Función:**
1. Llama RPC `cerebro_consulta_ia` para obtener contexto completo del cliente
2. Busca en Gemini fileSearchStore del cliente (RAG sobre documentos)
3. Construye prompt con contexto + RAG + historial
4. Llama Claude API
5. Guarda en `chat_messages`

---

### Newsletter IA (sector 4) — Refactor 2026-04-29

Refactorizado al patrón Análisis (Pull-on-Signal). Detalles funcionales en [[04-chat-newsletter|docs/sectores/04-chat-newsletter]]. Plan de refactor: `C:\Users\Benjamin\.claude\plans\tomando-como-referencia-la-deep-curry.md`.

| Workflow | ID | Rol | Estado | Notas |
|---|---|---|---|---|
| `newsletter_init` | `UBYXNKZ1HHFTZyDX` | Webhook `/init-newsletter`. Disparado por Bubble Page Loaded cuando `count(chat_messages)=0`. Race guard → GET `rag_stores` + `bub_clientes` → 3 branches: **A** (store existe) Gemini RAG query + INSERT greeting híbrido / **B** (sin store, con `link_drive`) INSERT msg "indexando…" + UPSERT `wip.estado=indexing` + executeWorkflow `newsletter_kb_fetch` async con `init_followup=true` / **C** (sin link_drive) INSERT greeting genérico. | ✅ Activo (2026-04-30) | 18 nodos |
| `newsletter_entrada` | `inWFSAEDLCH1kx5P` | Webhook `/chat-newsletter`. get_or_create_conv (con `tipo` con sufijo timestamp UNIX desde Bubble) → UPSERT `newsletter_wip` → save user msg → executeWorkflow tool_loop async. | ❌ Inactivo (espera Bubble Fase 3) | 20 nodos |
| `newsletter_tool_loop` | `SfwR7gqs1hBIOV7i` | Agent Claude Sonnet 4.6 streaming + 7 tools (`guardar_parametros`, `cargar_contexto_cliente`, `generar_estrategia`, `confirmar_estrategia`, `generar_email`, `aprobar_email`, `completar_newsletter`) que persisten en columnas tipadas de `newsletter_wip`. Lectura fresca de WIP cada iteración. Execute Workflow Trigger typeVersion 1 (recursión). | ✅ Activo (subworkflow) | 7 nodos |
| `newsletter_kb_fetch` | `w6Gqo8B6Sqp6Mq9x` | 2 triggers: `Execute Workflow Trigger` (cron + `newsletter_init` Branch B) + Webhook `/indexar_contexto_newsletter` (tool_loop async). Crea fileSearchStore Gemini + indexa Drive del cliente + UPSERT `rag_stores` (PK `notion_id,tipo='newsletter'`, ahora con `metadata: {file_count, categories}`) + UPDATE `newsletter_wip.kb_text`. Si recibe `init_followup=true` (desde `newsletter_init`), al final emite mensaje assistant con greeting híbrido + PATCH `wip.estado=borrador`. Distinción cron vs tool_loop por prefijo `conversation_id = "cron-nl-*"`. Renombrado pendiente. | ✅ Activo (subworkflow) | 16 nodos |
| `newsletter_entrega` | `9wnB9NI8Capa4b8s` | Bajo demanda. Get `newsletter_wip` + Get cliente Drive + Render Markdown + 4 niveles Drive (Cliente/Análisis y estrategia/Estrategia/Historico_newsletters) + createFromText + PATCH `wip.estado=entregado`+`doc_url` + INSERT chat msg con link. **Sin DELETE de drafts post-entrega.** | ✅ Activo (subworkflow) | 15 nodos |
| `newsletter_trigger_entrega` | `u9DsFadbpb7QiLaP` | Webhook `/entregar-newsletter` → Respond 200 paralelo + executeWorkflow `newsletter_entrega` async. Clon de `analisis_trigger_entrega`. | ❌ Inactivo (espera UI Bubble) | 3 nodos |

**WIP unificada:** todos los workflows leen/escriben `newsletter_wip` (1 fila por conv con `parametros + estrategia_texto + emails jsonb[] + email_actual + kb_text + estado + doc_url`) en cbi. La tabla `chat_conversations.metadata` ya no se usa para Newsletter; `newsletter_emails_wip` deprecada.

**Credencial cbi:** `13dKSjEd2XZCYpJa` "Espejo Supabase" (supabaseApi). Usada por todos los nodos HTTP Supabase de los 6 workflows vía `predefinedCredentialType: supabaseApi`. **Cleanup 2026-05-24:** removida la deuda técnica del JWT inline — los outliers `SfwR7gqs1hBIOV7i` (Code, `$env.SUPABASE_SERVICE_ROLE_KEY`) y `UBYXNKZ1HHFTZyDX` (7 HTTP nodes, cred bindeada) están migrados. Detalle en lección 20 + Historial fix 2026-05-24. **Credencial Gemini para HTTP:** `fEKYLWb7Vhx4HnNs` "Gemini API Key" (httpHeaderAuth `x-goog-api-key`) — usada por `UBYXNKZ1HHFTZyDX` nodo `Gemini RAG Resumen`. Los Code nodes siguen usando `$env.GEMINI_API_KEY` (caso `SfwR7gqs1hBIOV7i` Process Tools, válido porque Code nodes leen $env sin restricción).

**Tipo conversación:** `newsletter_<notion_id>_<unix_seconds>`. Bubble construye el sufijo en Page Loaded. Permite N newsletters por cliente sin colisionar con `UNIQUE(agencia_id, tipo)` de `chat_conversations`. La tool `completar_newsletter` ya NO renombra `tipo`.

---

## RAG

### RAG Cerebro IA
**ID:** `ZnJSkoWlSusmEjhO`
**Schedule:** Diario a las 3:00 AM

```
1. Para cada empresa activa en notion_empresas:
   a. Buscar documentos en Google Drive de la empresa
      (carpeta: /Clientes/{nombre_empresa}/)
   b. Descargar archivos nuevos/modificados
   c. Actualizar fileSearchStore en Gemini API
      → createFile → addToStore (upsert por nombre)
   d. Actualizar metadata en Supabase (última sync RAG)
```

### RAG Newsletter IA (`newsletter_cron_reindex`)
**ID:** `kZE3W2ae0upyGt2E`
**Schedule:** Diario a las 3:30 AM
**Estado:** ❌ Inactivo (espera E2E Fase 3 — refactorizado 2026-04-29)

Refactorizado a multi-tenant: lee `bub_clientes` con `link_drive`, cruza con `rag_stores` filtrado por `tipo='newsletter'`, dispara reindex de stale (>24h) o nunca indexados. Invoca subworkflow `w6Gqo8B6Sqp6Mq9x` (`newsletter_kb_fetch`) que escribe en `rag_stores` con PK `(notion_id, tipo)`. Sin `agencia_id` hardcoded. Renombrar workflow pendiente.

---

## Operaciones

### Crear Tarea desde Formulario Bubble
**ID:** `eHyXBETcaGSNXqLk` · patch 2026-05-19 (fix `\n` literales en descripción Notion)
**Trigger:** Webhook POST `crear_tarea_formulario` desde Bubble (botón formulario "Crear tarea" en Operaciones).
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz`

```
1. Webhook recibe payload Bubble (nombre, cliente_notion_id, responsable, aprobador, observadores,
   prioridad, area_tarea, fecha_entrega, estimacion_min, estado, incidencia, bloqueado_por_ids,
   bloqueando_ids, descripcion, agencia_id, user_id)
2. Preparar Notion Body (Code) → mapea campos a properties Notion + arma children blocks con
   descripcion. Normaliza escapes literales (\n / \r\n / \t como 2 chars) a saltos reales,
   parte en párrafos por doble salto, y trocea cada párrafo a 2000 chars max por rich_text.
3. POST Notion /v1/pages (HTTP, cred notionApi) → crea página en TAREAS
4. Preparar Respuesta (Code) → status ok + notion_id + url
5. Respond to Webhook → JSON al caller Bubble
6. Activity Log (rama paralela) → POST cbi.activity_log con metadata completo (incluye descripcion)
```

**Nota:** la DB Notion TAREAS no tiene propiedad "Descripción"; el texto se inserta como bloques `paragraph` en el body de la página. El sync polling Notion→Bubble (`GjijIDEUyiH05Mg0`) **no espeja el body**, sólo properties — si en el futuro hay que reflejar la descripción en `bub_tareas_notion`, hay que extender ese sync.

**Patch 2026-05-19:** descripción llegaba a Notion con `\n` literales (caracteres `\` + `n`) en lugar de saltos reales, porque Bubble enviaba doble-escape cuando el `MultilineInput` contenía texto pegado desde fuentes ya escapadas (típicamente respuestas de IA). El nodo `Preparar Notion Body` ahora normaliza `\\n` → `\n` real antes de construir los blocks y, además, divide la descripción en párrafos separados por doble salto (Notion renderiza `\n` simples como soft line breaks dentro del párrafo). Fix defensivo en n8n; el lado Bubble (`MultilineInput's value:formatted as JSON-safe`) ya era correcto y se deja como está.

⚠️ El antiguo Chat Tareas IA (workflows `RPdNg5ZNXK0VrOhG` + `aGML9yyMsoAQ6ZGL`) está obsoleto desde 2026-04-25; las tareas se crean exclusivamente desde este formulario.

### Aplicar Plantilla
**ID:** `KSBwigoSEpHl5OG1` · refactor 2026-05-11 (fix ENOTFOUND MAW)
**Trigger:** Webhook desde Bubble `POST /aplicar_plantilla` (botón "Aplicar plantilla" en Operaciones).
Body: `{ bubble_id (plantilla padre), cliente_notion_id, agencia_id }`.

```
1. Webhook (responseMode: responseNode)
2. Respond 200 (paralelo, ack inmediato a Bubble: { status: 'processing', bubble_id })
3. Fetch Bubble + Crear Padre (Code, jsCode):
   a. GET Bubble Data API /plantillas_tareas_notion?_id=<bubble_id> → plantilla padre
   b. GET Bubble Data API /plantillas_subtareas_notion?Plantilla_padre=<bubble_id> sort Orden asc → subtareas
   c. GET Bubble Data API /plantillas_areas → catálogo áreas
   d. GET Bubble Data API /user?agencia_id=<plantilla.agencia_id> → users
   e. Build lookups: areaLookup[_id]=Nombre_area, userToNotion[_id]=notion_id
      (notion_id viene en bub_user directamente, sin paso por miembros_equipo legacy)
   f. POST Notion /v1/pages — crea tarea padre con Tarea/Estado/Cliente +
      Prioridad/Área/Responsable/Estimación/Aprobador/Observadores/Incidencia
   g. return items[] con datos de cada subtarea (notion_id de responsable/aprobador/observadores resueltos)
4. Loop Subtareas (SplitInBatches default 1)
   → Crear Subtarea en Notion (Code): POST /v1/pages con relation 'ítem principal' = padre.id
5. (Tras el loop) Activity Log (HTTP Supabase cbixhqjsnpuhcrcjppah/activity_log):
   clase=plantilla, accion=aplicada, entidad_id=bubble_id, metadata={bubble_id, cliente_notion_id}
```

**Fuente de datos:** **Bubble** (`plantillas_tareas_notion` + `plantillas_subtareas_notion` + `plantillas_areas` + `user`). Supabase NO se lee para datos de la plantilla — solo se escribe al final el `activity_log`. Las tablas espejo `bub_plantillas_*` se mantienen al día vía SYNC ABSOLUTO `FGxG67I24POOUeHW` (Bubble→Supabase), pero este workflow no las consume.

**Refactor 2026-05-11:** eliminadas referencias al proyecto Supabase legacy `mawpgbtdvskmneqqcqag` (host muerto que tiraba `ENOTFOUND`). Eliminados: (a) upsert padre tabla legacy `plantillas`, (b) upsert subtareas tabla legacy `plantillas_subtareas`, (c) GET `miembros_equipo`. Sustituida resolución de notion_user_id por lookup directo desde `u.notion_id` del fetch Bubble (1 hop en lugar de 2).

---

### OPS LOG — Lifecycle Google Chat (Auto-Match Cliente)
**ID:** `xzNDkDNiUOYOA2Ku` · ✅ Activo desde 2026-05-09 (Fase 3 #2). Rollout multi-espacio el mismo día — auto-match cubrió el grueso de los 23 clientes hoy mapeados con `gchat_space_id`
**Trigger:** Webhook POST `gchat_log_inbound` desde Chat App HTTP endpoint (eventos lifecycle: ADDED_TO_SPACE; resto se ignora).
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz`

```
1. Webhook GChat Inbound (POST /gchat_log_inbound, responseMode: responseNode)
2. Respond 200 (paralelo, ack inmediato a Google Chat)
3. Verify Token (HTTP GET https://oauth2.googleapis.com/tokeninfo?id_token=<JWT>)
   → Google verifica firma RSA y devuelve claims parseados
4. Validar JWT Chat App (Code, sin crypto local)
   → claims iss/email ∈ ['chat@system.gserviceaccount.com',
                         'service-817779477263@gcp-sa-gsuiteaddons.iam.gserviceaccount.com']
       (1º para Chat Apps estándar, 2º para apps publicadas vía Marketplace SDK
        — la SA gcp-sa-gsuiteaddons es la que firma JWT al HTTP endpoint
        en apps Marketplace, visible en el campo "Correo electrónico de
        la cuenta de servicio" de la pantalla Chat API config en GCP)
   → aud = https://n8n-n8n.irzhad.easypanel.host/webhook/gchat_log_inbound
   → exp no expirado
5. Decode Lifecycle Event (Code): parsea estructura moderna Chat App (Marketplace SDK):
   `body.chat.{addedToSpacePayload|removedFromSpacePayload|messagePayload}.space`,
   con fallback `body.type` + `body.space` para estructura legacy. Output: type, space.name, space.displayName.
6. IF Is ADDED (type === 'ADDED_TO_SPACE' AND has displayName) → STOP si no
7. GET Clientes Agencia (HTTP Bubble Search): all clientes con agencia_id
   = 1769513105728x555492736219132700 (limit 100)
8. Match Cliente Fuzzy (Code): normaliza lowercase + sin diacritics + alfanum.
   Match exacto primero, fallback contains bidireccional.
   Output is_unique=true sólo si exactamente 1 candidato.
9. IF Match Unico → STOP si 0 o múltiples matches (mapping manual queda al humano)
10. PATCH Cliente gchat_space_id (Bubble Data API PATCH /clientes/<id>)
    body: { gchat_space_id: spaces/AAA }
    Esto dispara DB Trigger Bubble (a configurar para Fase 3 #3) →
    webhook gchat_subscription_create → workflow gJfDb3Gwrf7fJ8Li crea la sub.
```

**Validación JWT vía tokeninfo:** mismo patrón que `8snJvdNsmRM2yI2y`. Memoria `feedback_n8n_task_runner_this.md` sigue aplicando — `require('crypto')`/`require('https')` bloqueado, por eso delegamos firma a Google.

**Auto-match algoritmo:** normalización en JS local tras GET ALL clientes. Ejemplo: `"E | LASER SPACE"` (display_name) y `"Laser Space S.L."` (nombre_empresas en Bubble) → ambos normalizan a `"laser space"` (con eliminación de `E |` siendo no-alfanumérico → un espacio + trim) → match único. Si Ben crea un cliente "Laser" y otro "Laser Space" en Bubble, la rama contains daría 2 matches y NO patcharía (correcto: humano decide).

**No se cubren en este iter (Fase 4):**
- `REMOVED_FROM_SPACE`: requeriría DELETE Workspace Events sub + PATCH cliente con `gchat_space_id=null`. Decisión política sobre el log histórico al irse el cliente.
- `MESSAGE` events en este endpoint: ignorados — los gestiona Pub/Sub `8snJvdNsmRM2yI2y`.
- DM al admin con lista de candidatos cuando match no único.
- Header secret webhook (mismo TODO que `gJfDb3Gwrf7fJ8Li`).

**Smoke test pendiente:** añadir bot a un space test cuyo `displayName` matchee con un cliente real Bubble. Validar (a) JWT pasa, (b) ADDED detectado, (c) match fuzzy único, (d) PATCH OK, (e) DB Trigger Bubble dispara webhook crear-subscription. Caso negativo: bot en space "Pruebas" sin cliente match → termina en `IF Match Unico(false)`.

---

### OPS LOG — Mensajes Google Chat (Pub/Sub)
**ID:** `8snJvdNsmRM2yI2y` · ✅ Activo desde 2026-05-08 (E2E validado, Fase 2 v2). **Rollout multi-espacio 2026-05-09:** 24 subscriptions activas en `gchat_subscriptions`, 23 clientes Bubble con `gchat_space_id` mapeado
**Trigger:** Webhook POST `gchat_pubsub_push` desde Pub/Sub topic `gchat-events-thenucleo` (push OIDC firmado por SA `push-thenucleo-log-bot`).
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz`

```
1. Webhook PubSub Push recibe push HTTPS de Google Pub/Sub
2. Respond 204 inmediato (ack a Pub/Sub para evitar retry)
3. Verify Token (HTTP GET https://oauth2.googleapis.com/tokeninfo?id_token=<JWT>)
   → Google verifica firma RSA y devuelve claims parseados
   → Si firma inválida o token expirado: tokeninfo devuelve 4xx, workflow aborta
4. Validar JWT PubSub (Code, sin crypto): valida claims (iss, aud, email, email_verified, exp)
5. Decode PubSub Envelope (Code): base64 → ChatEvent + extrae attributes['ce-type']
6. Validar Evento (Code): filtra non-MESSAGE y bot, extrae text/sender/space_id/message_id
                          + precomputa search_url (cliente by space), dup_check_url (log by
                          gchat_message_id) y author_url (Chat API spaces/AAA/members/users/<id>)
                          + detección de URL (regex) y mapeo dominio → tipo de recurso
                          (Google Doc / Sheet / Slides / Drive / Meet / Figma / Notion /
                           ClickUp / Loom / YouTube / GitHub / Portal / etc).
                          Output incluye: has_url, urls[], resource_types[], resource_summary.
7. IF Skip → STOP si no es mensaje válido
8. GET Cliente by Space (Bubble Search) por gchat_space_id
9. IF Cliente Found → STOP si el espacio no está mapeado a ningún cliente
10. GET Dup Check (Bubble Search) por gchat_message_id en actividad_diaria_log
11. IF Es Duplicado → STOP si results.length > 0 (Pub/Sub reentrego este mensaje)
12. Build Classify Body (Code): payload Anthropic con tool_use forzado
                                cliente leído de $('GET Cliente by Space').item.json.
                                System prompt incluye "REGLA URLs": si has_url=true,
                                log_worthy=true SIEMPRE, clasificación=entrega,
                                resumen formato "__AUTOR__ compartio un {tipo}".
                                User content recibe metadata has_url + tipos detectados.
13. Anthropic Classify (HTTP Claude Haiku 4.5) → { log_worthy, clasificacion, resumen }
                                                  (resumen puede contener literal __AUTOR__)
14. Parse Classify (Code)
15. IF Log-Worthy → STOP si el mensaje es ruido conversacional
16. POST Bubble actividad_diaria_log → crea entrada vinculada al cliente.
    autor_nombre = $('GET Admin User').item.json.name.fullName (DWD, resuelve nombre real
                   del autor desde Admin SDK Directory) || sender_name fallback.
    mensaje_resumen sustituye __AUTOR__ por autor_nombre vía split/join.
    (DB Trigger Bubble lo reenvía a SYNC ESPEJO → bub_actividad_diaria_log Supabase)
```

**Tratamiento de URLs (cambio 2026-05-11):** mensajes que contienen una URL siempre se loguean (decisión determinista de regex, no del LLM). El classifier solo construye la narrativa. La función `classifyResource(url)` en `Validar Evento` mapea dominios conocidos a etiquetas legibles; dominios no mapeados caen en `enlace (<hostname>)`. Placeholder de autor `__AUTOR__` (no `{{AUTOR}}`) elegido para evitar conflicto con el parser de expresiones n8n. Resultado típico en `mensaje_resumen`: `"Joaquín compartió un Google Doc"` o `"Joaquín compartió un archivo de Figma: mockups del onboarding"`.

**Clasificación `solicitud` (cambio 2026-05-11):** enum del classifier ampliado a `status|decision|incidencia|configuracion|entrega|solicitud|otro`. Mensajes con menciones (`@usuario`) que piden acción/confirmación/acceso/revisión, o peticiones operativas dirigidas al equipo con verbos de acción claros ("necesito que...", "podéis...", "me avisan", "confirmadme", "hace falta..."), entran a `solicitud` con `log_worthy=true`. Solicitudes genéricas sin acción concreta siguen siendo noise. Cambios atómicos en `Build Classify Body` (4 patches `patchNodeField`): enum schema + system prompt log-worthy ampliado + bloque "REGLA SOLICITUD" + línea noise limpiada de "preguntas sin contexto". Detonado por incidencia Membersfy 12:54 UTC donde 2 mensajes operativos quedaron clasificados como `otro/log_worthy=false`.

> **Fase 3 #5 intentada y revertida (2026-05-08):** un nodo `GET Author Membership` en posición 16 llamaba `chat.googleapis.com/v1/spaces/AAA/members/users/<id>` para resolver `member.displayName`. Devolvía 404 sistemático: el scope `chat.app.memberships.readonly` autoriza CREATE subscription y leer la propia membership del bot, no GET sobre membresías humanas arbitrarias. Adicionalmente cascadeó un fallo del POST Bubble (las expressions `$json.cliente._id` etc. resolvían contra el output del GET con error en lugar de Parse Classify). Revertido en ejecución `116690`. Para resolver `autor_nombre` realmente hay que ir vía DWD + scope `chat.memberships.readonly` (sin `.app`) o Admin SDK Directory `users.get`. Detalle en log-cambios 2026-05-08 + memoria `feedback_gcp_chat_app_marketplace.md`.

**Latencia E2E observada (smoke test 2026-05-08):** 8 s desde envío en Google Chat hasta fila en Supabase. (Mediciones tomadas antes del pre-check anti-duplicado de Fase 3 #6 — el GET extra añade ~100-300 ms en duplicados; en mensajes nuevos no afecta.)

**Anti-duplicado (doble defensa, Fase 3 #6 desde 2026-05-08):**
1. **Pre-check n8n** (paso 10-11): GET Bubble por `gchat_message_id` antes de llamar a Claude. Si existe, terminate. Cubre el coste Claude además del POST Bubble duplicado. Posicionado tras `IF Cliente Found` para no consumir GET Bubble en mensajes de espacios sin mapear.
2. **UNIQUE Supabase**: `bub_actividad_diaria_log.gchat_message_id`. Defensa de último nivel si el pre-check fallase (race condition Pub/Sub paralelo entre 2 reintentos solapados, o si alguien borra la fila en Bubble entre los 2 eventos).

**Modelo:** `claude-haiku-4-5-20251001`. Coste estimado <2 €/mes.

**Mapping cliente:** campo `gchat_space_id` (text) en `bub_clientes`. Auto-discovery activo desde 2026-05-09 vía `xzNDkDNiUOYOA2Ku` (Fase 3 #2): cuando se añade el bot a un espacio, el lifecycle ADDED_TO_SPACE dispara fuzzy-match contra `nombre_empresas` y PATCH automático si match único. Casos sin match único quedan a humano.

**Validación JWT vía tokeninfo (no crypto local):** el task runner de n8n bloquea `require('crypto')` y `require('https')` por allow-list — verificación RSA local es imposible desde Code. Se delega a Google `oauth2.googleapis.com/tokeninfo` que valida la firma por nosotros y devuelve los claims. Ver memoria `feedback_n8n_task_runner_this.md`.

**Workspace Events Subscription:** TTL 24h sin DWD. Tracking en Supabase `gchat_subscriptions` (24 filas activas tras rollout 2026-05-09; columnas: `id, space_id, cliente_bubble_id, status, expire_time, last_renewed_at, last_error, created_at, updated_at`). Renewal cron `NMZA404s1agKcHau` ✅ activo desde 2026-05-08. **Alta:** las 24 subs del rollout 2026-05-09 se crearon vía script local `create-subscription.mjs`. El workflow `gJfDb3Gwrf7fJ8Li` (alta automática desde DB Trigger Bubble) sigue inactivo — se usará cuando se den de alta nuevos clientes desde Bubble.

---

### OPS LOG — Crear Subscription Google Chat por Cliente
**ID:** `gJfDb3Gwrf7fJ8Li` · ⏳ Inactivo (Fase 3 #3, creado 2026-05-08, pendiente tag portal + activar + DB Trigger Bubble + smoke)
**Trigger:** Webhook POST `/gchat_subscription_create` desde Bubble API Connector (DB Trigger sobre Clientes cuando `gchat_space_id` cambia).
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz`

```
1. Webhook (POST gchat_subscription_create, responseMode: responseNode)
2. Respond 200 noData
3. Validar Body (Code): extrae cliente_bubble_id (obligatorio) + gchat_space_id (opcional)
                        + flag has_space
4. IF Has Space → STOP si gchat_space_id vacío (caso REMOVED_FROM_SPACE lo gestiona Fase 3 #2)
5. GET Existing Sub (Supabase getAll, alwaysOutputData=true)
   filter: status=active AND space_id=<gchat_space_id>
6. IF Already Active → STOP si ya hay sub viva para ese space (idempotente)
7. Build Subscription Body (Code): payload Workspace Events
   { targetResource: //chat.googleapis.com/<spaces/AAA>,
     eventTypes: ['google.workspace.chat.message.v1.created'],
     notificationEndpoint: { pubsubTopic: 'projects/app-thenucleo/topics/gchat-events-thenucleo' },
     payloadOptions: { includeResource: true },
     ttl: '0s' }
8. Create Subscription (HTTP POST workspaceevents.googleapis.com/v1/subscriptions)
   auth: predefinedCredentialType googleApi cred `nJOGize9nY0rINy4`
9. Parse Sub Response (Code): normaliza response.name + expireTime (Workspace Events
   devuelve LRO `{response: {name, expireTime}}` o resp directa según versión API)
10. INSERT Sub Tracking (Supabase create gchat_subscriptions)
    id = subscription.name (`subscriptions/chat-spaces-...`)
```

**Body esperado del webhook (desde Bubble):**
```json
{ "cliente_bubble_id": "1772...", "gchat_space_id": "spaces/AAA" }
```

**Idempotencia:** doble defensa contra duplicados:
1. Pre-check GET+IF Already Active termina sin llamar a Workspace Events API si ya hay sub viva.
2. `alwaysOutputData: true` en GET es imprescindible — sin esa flag, n8n termina el flujo cuando getAll devuelve `[]` y nunca alcanzaríamos el Create.

**Auth:** patrón heredado del CRON renewal `NMZA404s1agKcHau`. Cred `googleApi` `nJOGize9nY0rINy4` ("Bot Log Actividad - Service Acount" — typo en el nombre, ID es lo canónico). Misma SA que tiene los scopes `chat.app.*.readonly` y el Marketplace OAuth client autorizado por admin install.

**Sin auth en webhook (MVP):** endpoint público pero benigno. Mitigaciones: validación estricta del body, sub creada caduca a 24h sin renewal, scope SA no permite escribir en spaces. TODO Fase 4: header `X-Webhook-Secret`.

**Pendientes antes de activar:**
- Tag `portal` (id `8JEzIL3gJwyclObr`) vía UI n8n o REST PUT.
- DB Trigger Bubble sobre `Clientes` "When is modified — gchat_space_id is changed" → llama webhook con `{cliente_bubble_id, gchat_space_id}`.
- Smoke test manual: `curl -X POST -H "Content-Type: application/json" -d '{"cliente_bubble_id":"1772195822486x737945880292517000","gchat_space_id":"spaces/AAQAThLQ5ck"}' https://n8n-n8n.irzhad.easypanel.host/webhook/gchat_subscription_create`. Si la sub para ese space ya existe (caso piloto E|BENJA), debe terminar en `IF Already Active(true)` sin crear duplicado.

---

### OPS TAREAS — Backfill url [MANUAL]
**ID:** `FqWqBN2NzWGCpB2w` · ⏸ Inactivo (Manual Trigger, one-shot reutilizable)
**Tag:** `portal` (pendiente aplicar vía UI)

Mismo patrón que los siblings cliente_nombre y agencia_id. Reconstruye `url` Notion para las 303 tareas post-bug 21-04. URL derivada como `'https://www.notion.so/' || REPLACE(notion_id, '-', '')` (formato corto sin slug; Notion redirige al canónico con título al abrir).

```
1. Manual Trigger
2. Listar Pendientes (RPC) → POST /rpc/backfill_url_pendientes
   Devuelve (bubble_id, url) por cada tarea con url NULL/empty
3. Actualizar url → Bubble update typeName tareas_notion
   property [{ key: url, value: $json.url }]
```

**RPC asociada:** `public.backfill_url_pendientes()` — derivada del notion_id, sin necesidad de fetch a Notion API.

---

### OPS TAREAS — Backfill agencia_id [MANUAL]
**ID:** `2Rt6xK2jQfh7VhA5` · ⏸ Inactivo (Manual Trigger, one-shot reutilizable)
**Tag:** `portal` (pendiente aplicar vía UI)

Sibling de `rONvzi9sdbFvgYYo`. Repobla `agencia_id` constante (uuid_supabase TheNucleo `e748c7d4-5823-413d-8cb3-532896f6e41d`) en las 303 tareas que el sync `GjijIDEUyiH05Mg0` dejó NULL entre 2026-04-21 y 2026-05-08.

```
1. Manual Trigger
2. Listar Pendientes (RPC) → POST /rpc/backfill_agencia_id_pendientes
   Devuelve (bubble_id, agencia_id) por cada tarea con agencia_id NULL
3. Actualizar agencia_id → Bubble update typeName tareas_notion
   property [{ key: agencia_id, value: $json.agencia_id }]
```

**RPC asociada:** `public.backfill_agencia_id_pendientes()` — devuelve la constante `'e748c7d4-...'::text` para cada tarea con `agencia_id IS NULL AND bubble_id IS NOT NULL`. Si en el futuro TheNucleo deja de ser single-tenant, hay que reescribir la RPC para mapear `agencia_id` por workspace Notion o por responsable.

---

### OPS TAREAS — Backfill cliente_nombre [MANUAL]
**ID:** `rONvzi9sdbFvgYYo` · ⏸ Inactivo (Manual Trigger, one-shot reutilizable)
**Tag:** `portal` (pendiente aplicar vía UI — MCP `addTag` roto, sandbox bloqueó workaround REST)

Workflow one-shot creado 2026-05-08 para repoblar `cliente_nombre` en tareas existentes que quedaron NULL por el bug del sync `GjijIDEUyiH05Mg0` entre 2026-04-21 y 2026-05-08.

```
1. Manual Trigger
2. Listar Pendientes (RPC) → POST Supabase /rpc/backfill_cliente_nombre_pendientes
   (RETURNS TABLE bubble_id text, cliente_nombre text)
   PostgREST devuelve array; n8n auto-splitea en N items
3. Actualizar cliente_nombre → Bubble update typeName tareas_notion
   objectId = $json.bubble_id
   property [{ key: cliente_nombre, value: $json.cliente_nombre }]
```

**RPC asociada:** `public.backfill_cliente_nombre_pendientes()` — JOIN `bub_tareas_notion ↔ bub_clientes` filtrando `cliente_nombre IS NULL AND cliente_notion_id IS NOT NULL AND bubble_id IS NOT NULL` (solo provider=notion). SECURITY DEFINER, GRANT a service_role.

**Reutilización:** sirve para futuros backfills si se rompe otro sync similar — basta con modificar la RPC para devolver `(bubble_id, valor_correcto)` y el workflow vuelve a parchear Bubble. El sync espejo `FGxG67I24POOUeHW` propaga los cambios a Supabase automáticamente.

**No tiene anti-rebote** porque escribe directamente a Bubble (no pasa por Notion); el sync espejo Bubble→Supabase no rebota porque no escribe a Bubble.

**Histórico:** Ejecución `114871` (2026-05-08 07:29 UTC, 97 s, 300 PATCHes success). Antes: 300 NULLs con `cliente_notion_id` poblado. Después: 0.

---

## Infraestructura

### Error Handler Global
**ID:** `HRDQ9Ju4NAIUV0qyhKzlz` — *Errores Flujos Plataforma*
**Trigger:** Error en cualquier workflow (configurado como error workflow en n8n)

```
1. Error Trigger captura el fallo (workflow.id, workflow.name, execution.id, error.message, error.stack, lastNodeExecuted, ...)
2. Extraer Datos Error (Code) → normaliza payload
3. Limpiar workflow_executions (Code) → reset oportunista de runs colgados en cbi
   (status running/cancelando → completed) y reset newsletter si el workflow caído es de newsletter
4. Claude Analizar Error (HTTP Anthropic) → enriquece con título, resumen, descripción, función del nodo
5. Parsear Respuesta Claude (Code) → JSON con 10 campos
6. Insert Supabase Incidencia (HTTP PostgREST → cbi.n8n_incidencias)
   credencial: Espejo Supabase (id 13dKSjEd2XZCYpJa)
```

Tabla destino: `public.n8n_incidencias` (RLS activo, solo `service_role`). Visor: panel cerrado `work.thenucleo.com/incidencias` (Edge Function `incidencias_api` con auth HMAC propia, hardcoded user/pass). Sustituye al antiguo `bub_incidencias` (eliminado 2026-04-27 para descargar Bubble).

---

## Ads

### Control de Campañas v2 (módulo nuevo, en construcción)

Plan completo: `docs/portal/integraciones/control-de-campanias.md` · plan maestro `~/.claude/plans/whimsical-churning-shore.md`. Schema multi-provider `ads_*` (7 tablas) + RPCs Supabase + cadena de workflows polling Meta API que sustituirá al patrón legacy Gmail listener.

#### SYNC ADS — Meta Discovery Cuentas
**ID:** `hwKBGC6QWP2dFObT` · **Estado:** ✅ ACTIVO (2026-05-12)
**Trigger:** Cron `*/30 8-21 * * *` Europe/Madrid
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz` · **Tags:** `portal`, `ads`

Descubre dinámicamente todas las ad accounts accesibles por el System User Meta y deriva alertas operativas. 6 nodos:

```
1. Cron */30 8-21 Madrid
2. Descifrar Creds Meta — POST /rpc/ads_meta_creds_listas → {access_token, appsecret_proof, app_id, business_id, system_user_id}
3. GET Meta /me/adaccounts?fields=id,name,account_status,disable_reason,currency,timezone_name,business,balance,spend_cap,amount_spent,funding_source_details
4. Code "Mapear cuentas + derivar alertas" — array `cuentas` + array `alertas` según account_status (2=DISABLED, 3=UNSETTLED, 7-9=warning)
5. UPSERT /ads_cuentas?on_conflict=provider,external_account_id
6. UPSERT /ads_alertas?on_conflict=entity_external_id,reason (fan-out paralelo con 5)
```

Smoke test E2E ejec 120108 (success, 4s, 23 cuentas + 3 alertas). HMAC `appsecret_proof` calculado en Supabase via RPC `ads_meta_creds_listas` (workaround anti-patrón #15: task runner n8n bloquea `crypto.subtle`/`require('crypto')`).

**Hardening `GET Meta /me/adaccounts` (2026-05-18):** tras timeout aislado en ejec 125198 (`ECONNABORTED` a los 30s con payload 23 cuentas + funding details + coupons), el nodo HTTP sube `options.timeout` 30000 → 60000 y activa `retryOnFail: true, maxTries: 3, waitBetweenTries: 5000`. Mitiga latencia intermitente de Graph API sin abortar el cron.

#### SYNC ADS — Meta Estructura
**ID:** `VhlqAQ1vH9HldpH5` · **Estado:** ✅ ACTIVO (smoke test ejec 120121 OK, 32 campañas + 43 adsets + 87 anuncios sobre The Nucleo)
**Trigger:** Cron `30 5 * * *` Europe/Madrid (05:30 daily)
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz` · **Tags:** `portal`, `ads`

Extiende Discovery con jerarquía completa campañas/adsets/anuncios. 9 nodos en cadena con loop SplitInBatches:

```
1. Cron 05:30 daily Madrid
2. Descifrar Creds Meta — POST /rpc/ads_meta_creds_listas
3. GET Cuentas Activas — GET /ads_cuentas?provider=eq.meta&estado_interno=eq.activa&select=id,external_account_id,nombre
4. Iterar Cuentas — Split In Batches v3, size 1 (output 0 done · output 1 loop)
5. GET Meta Campaigns — /v19.0/<acc>/campaigns?fields=id,name,status,effective_status,objective,buying_type,bid_strategy,daily_budget,lifetime_budget,budget_remaining,start_time,stop_time,updated_time
6. GET Meta Adsets — /v19.0/<acc>/adsets?fields=...,campaign_id,optimization_goal,billing_event,targeting,...
7. GET Meta Ads — /v19.0/<acc>/ads?fields=...,campaign_id,adset_id,creative{id,name,object_type,thumbnail_url}
8. Code "Armar Payload RPC" — empaqueta {p_cuenta_id, p_campanias, p_adsets, p_anuncios} con normalización budgets / centavos
9. POST /rpc/ads_upsert_estructura → loop back a "Iterar Cuentas"
```

RPC `ads_upsert_estructura(uuid, jsonb, jsonb, jsonb) RETURNS jsonb` (Supabase, SECURITY DEFINER): 3 UPSERTs en una transacción con FK resolution interna por `external_id`. Devuelve contadores `{cuenta_id, campanias_upsertadas, adsets_upsertados, anuncios_upsertados}`. GRANT EXECUTE solo `service_role`.

⚠️ Filtro `estado_interno='activa'` deja la cuenta fuera mientras esté `pendiente_asignar` (estado por defecto del Discovery). Smoke test requiere `UPDATE ads_cuentas SET estado_interno='activa' WHERE external_account_id='<acc>'` antes de ejecutar.

#### CRON ADS — Meta Daily 06:00
**ID:** `pIxC6RNqHISWvpoU` · **Estado:** ⏸ INACTIVO (smoke test ejec 120124 OK, 4 filas sobre The Nucleo)
**Trigger:** Cron `0 6 * * *` Europe/Madrid (06:00 daily)
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz` · **Tags:** ⚠️ `portal` PENDIENTE UI

Archivo histórico diario de insights Meta por entidad (account/campaign/adset/ad). 11 nodos en cadena con loop:

```
1. Cron 06:00 daily Madrid
2. Descifrar Creds Meta — POST /rpc/ads_meta_creds_listas
3. Calcular Fecha Ayer (Code) — toLocaleDateString('sv-SE', {timeZone:'Europe/Madrid'}) sobre Date.now()-86400000
4. GET Cuentas Activas — provider=eq.meta&estado_interno=eq.activa
5. Iterar Cuentas — Split In Batches size 1
6. GET Insights Account — /v19.0/<acc>/insights?level=account&time_range={since:ayer,until:ayer}&fields=account_id,spend,impressions,clicks,reach,frequency,ctr,cpc,cpm,actions,action_values
7. GET Insights Campaign — idem level=campaign + campaign_id
8. GET Insights Adset — idem level=adset + adset_id
9. GET Insights Ad — idem level=ad + ad_id
10. Code "Armar Payload Insights" — merge 4 arrays con entity_type cada uno + p_cuenta_id + p_fecha
11. POST /rpc/ads_insertar_insights_diario → loop back a "Iterar Cuentas"
```

RPC `ads_insertar_insights_diario(uuid, date, jsonb) RETURNS jsonb` (Supabase, SECURITY DEFINER): UPSERT a `ads_insights_diario` aplicando `ads_extract_conversion` (LATERAL JOIN) para derivar `conv`/`revenue` desde `actions`/`action_values`. Calcula `roas = revenue/spend` y `cpa = spend/conv` con protección división por cero. GRANT EXECUTE solo `service_role`.

**Coste rate-limit Meta:** 4 calls × 4 puntos (insights es 4× más caro que reads de estructura) = **16 puntos/cuenta/día**. Standard Access permite 300+ calls/h por cuenta → margen amplio.

#### CRON ADS — Google Y Meta Intra-día 30min (unificado 2026-05-21)
**ID:** `Uqv3R3txzcg8GI1B` · **Estado:** ✅ ACTIVO
**Trigger:** Cron `*/30 8-21 * * *` Europe/Madrid
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz` · **Tags:** `portal` + `ads` ✅

Snapshot intra-día de KPIs (preset `last_7d`) en `ads_campanias` / `ads_adsets` / `ads_anuncios` + scoring inline, para **ambos providers (Google + Meta)**. 20 nodos: el Cron dispara DOS ramas paralelas independientes que terminan en sus propios loops:

```
Cron */30 8-21 Madrid
  ├──▶ Rama Google ──▶ Rama Meta ──▶ (loops independientes)
  │
  ├── RAMA GOOGLE (10 nodos):
  │   1. Descifrar Creds Google (RPC aic_get_with_key p_slug=google-ads)
  │   2. Refresh → Access Token (POST oauth2.googleapis.com/token)
  │   3. GET Cuentas Activas (provider=eq.google&estado_interno=eq.activa)
  │   4. Iterar Cuentas — Split In Batches size 1
  │   5. GAQL Snapshot Campaign — POST googleAds:search query LAST_7_DAYS campaign WHERE status != 'REMOVED'
  │   6. GAQL Snapshot AdGroup — idem ad_group
  │   7. GAQL Snapshot Ad — idem ad_group_ad
  │   8. Code "Armar Payload Snapshot Google" — mapea metrics Google (costMicros/1e6, ctr*100, conversions→actions purchase, conversionsValue→action_values)
  │   9. RPC ads_actualizar_kpis_snapshot — UPDATE match por external_id
  │   10. RPC ads_calcular_scoring — percentiles INLINE
  │   → loop back a "Iterar Cuentas"
  │
  └── RAMA META (10 nodos, idéntica al workflow legacy):
      1. Descifrar Creds Meta (RPC ads_meta_creds_listas)
      2. GET Cuentas Activas1 (provider=eq.meta&estado_interno=eq.activa)
      3. Iterar Cuentas1 — Split In Batches size 1
      4. GET Insights Campaign — date_preset=last_7d, level=campaign
      5. GET Insights Adset — level=adset
      6. GET Insights Ad — level=ad
      7. Code "Armar Payload Snapshot" — {p_cuenta_id, p_preset:'last_7d', p_campanias, p_adsets, p_anuncios}
      8. POST RPC ads_actualizar_kpis_snapshot — UPDATE match por external_id
      9. POST RPC ads_calcular_scoring — percentiles INLINE
      → loop back a "Iterar Cuentas1"
```

**Por qué fusión Google+Meta en un solo workflow:** ambas ramas comparten el mismo cron (`*/30 8-21` Madrid) y el mismo par de RPCs downstream (`ads_actualizar_kpis_snapshot` + `ads_calcular_scoring`). Mantener dos workflows separados con cron idéntico desincronizaba la ventana de snapshot vista por Bubble. Fusionando, ambas ramas escriben en la misma transacción horaria. La rama Meta replica byte-a-byte la lógica del legacy `BCgSCKjzryYaFYMC`.

**Mapping Google → schema canónico ads_* (Code "Armar Payload Snapshot Google"):** `costMicros/1e6 → spend`, `ctr*100 → ctr` (Google viene en ratio 0–1, Meta en %), `averageCpc/1e6 → cpc`, `averageCpm/1e6 → cpm`, `conversions → actions[{action_type:'purchase', value}]`, `conversionsValue → action_values[{action_type:'purchase', value}]`, `reach/frequency → null` (Google no los devuelve). El external_id es `campaign.id` / `adGroup.id` / `adGroupAd.ad.id`.

RPC `ads_actualizar_kpis_snapshot(uuid, text, jsonb, jsonb, jsonb) RETURNS jsonb` (Supabase, SECURITY DEFINER): UPDATE de KPIs match por `external_id`. Aplica `ads_extract_conversion` para conv/revenue + calcula roas/cpa/cvr con protección división por cero. GRANT EXECUTE solo `service_role`.

**Coste rate-limit Meta (rama Meta):** 3 calls × 4 puntos = **12 puntos/cuenta cada 30 min** = ~24 puntos/cuenta/h. Standard Access permite 300+ calls/h por cuenta → margen 12×.
**Coste Google Ads API (rama Google):** 3 GAQL search × ~5 ops/query = ~15 ops/cuenta/30 min. Quota basic access es 15.000 ops/día → margen >>10×.

**Reliability:** los 3 nodos GAQL Google y los 2 RPCs Google llevan `onError: continueRegularOutput` para que un fallo en una cuenta no detenga el loop sobre el resto. La rama Meta NO tiene `continueRegularOutput` (manteniendo el comportamiento legacy del workflow original — si revienta, errorWorkflow lo captura).

#### CRON ADS — Meta Intra-día 30min (LEGACY)
**ID:** `BCgSCKjzryYaFYMC` · **Estado:** ⏸ INACTIVO desde 2026-05-21 (sustituido por `Uqv3R3txzcg8GI1B` unificado Google+Meta)
**Trigger:** Cron `*/30 8-21 * * *` Europe/Madrid (desactivado)
**Tags:** `portal` + `ads` ✅

Workflow legacy Meta-only. Conservado sin archivar por si hay que rollback rápido. La rama Meta del workflow unificado `Uqv3R3txzcg8GI1B` replica byte-a-byte sus 10 nodos. No modificar — si se necesita ajustar Meta intra-día, hacerlo en el unificado.

#### OPS ADS — Acciones Bubble [WEBHOOK]
**ID:** `sNpVWEkinc4g0KfA` · **Estado:** ⏸ INACTIVO (3 smoke tests OK)
**Trigger:** Webhook `POST /ads_action` (typeVersion 2.1, responseMode: responseNode, onError: continueRegularOutput)
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz` · **Tags:** ⚠️ `portal` PENDIENTE UI

Endpoint único fusionado para las 3 acciones que Bubble dispara: refresh, status_toggle, nota_crear. 17 nodos con Switch v3.4 mode `expression` (fórmula `({refresh:0,status_toggle:1,nota_crear:2})[$json.body.action] ?? 3`).

```
Webhook /ads_action
  → Switch Action (4 outputs, último fallback)

Output 0 — Branch refresh:
  GET Cuenta Supabase (id=eq.<cuenta_id>) → Descifrar Creds Meta
  → 3 GETs Insights (level=campaign/adset/ad, date_preset=last_7d)
  → Armar Payload → POST /rpc/ads_actualizar_kpis_snapshot
  → POST /rpc/ads_calcular_scoring → Respond refresh

Output 1 — Branch status_toggle:
  Descifrar Creds Meta
  → POST https://graph.facebook.com/v19.0/<entity_id> ?status=<new>
  → POST /rpc/ads_aplicar_status_toggle → Respond status_toggle

Output 2 — Branch nota_crear:
  POST /rpc/ads_notas_crear → Respond nota_crear
```

**RPCs nuevas:**
- `ads_aplicar_status_toggle(uuid, uuid, text, text, text, text) RETURNS jsonb` — UPDATE atómico de status en `ads_campanias`/`ads_adsets`/`ads_anuncios` + INSERT `ads_notas` tipo='accion' + INSERT `activity_log` clase='ads'. Validación entity_type ∈ {campaign,adset,ad}, new_status ∈ {ACTIVE,PAUSED,DELETED,ARCHIVED}.
- `ads_notas_crear` modificada: `RETURNS uuid` → `RETURNS jsonb` (devuelve `{ok, nota_id}`). Necesario porque PostgREST con RPC `RETURNS scalar` responde `text/plain` y el nodo HTTP n8n con response format JSON rompe el parseo.

**Bugs encontrados durante smoke test (resueltos):**
- `ads_notas_crear` RETURNS uuid → respuesta text/plain → fix migration RETURNS jsonb.
- 6 referencias `$('GET Cuenta').first().json[0].external_account_id` rompían refresh con URL Meta `v19.0//insights` (doble slash). PostgREST GET con filter `id=eq.X` devuelve array de 1 elemento pero n8n auto-promociona a objeto en el siguiente nodo. Fix: patches `.json[0]` → `.json`.

**Endpoint público** (cuando se active): `POST https://n8n-n8n.irzhad.easypanel.host/webhook/ads_action`

**Ramificación Google 2026-05-13** (branch `status_toggle` ahora multi-provider): añadidos 8 nodos al output 1 del Switch. Reorganización: `Switch[1] → GET Cuenta (status_toggle) → IF Provider Meta`:
- **TRUE branch (Meta)**: flow original intacto (Descifrar Creds Meta → POST graph.facebook.com/<entity_id> {status} → POST aplicar_status_toggle → Respond).
- **FALSE branch (Google)**: 6 nodos nuevos:
  - `Descifrar Creds Google (status)` (RPC aic_get_with_key con `p_slug='google-ads'`)
  - `Refresh → Access Token (status)` (POST oauth2.googleapis.com/token)
  - `Mapear Status Google` (Code: maps ACTIVE→ENABLED / PAUSED→PAUSED / ARCHIVED|DELETED→REMOVED + construye `endpoint` y `resourceName` según `entity_type`: campaign/adset=adGroups/ad=adGroupAds con `ad_group_id~ad_id`)
  - `POST Google :mutate` (POST `googleads.googleapis.com/v20/customers/<acc>/<entity>s:mutate` body `{operations:[{update:{resourceName, status}, updateMask:'status'}]}`)
  - `POST aplicar_status_toggle (Google)` (mismo RPC pero `p_new_status = google_status` nativo ENABLED/PAUSED/REMOVED — RPC ampliado vía migration `ads_aplicar_status_toggle_google_aware`)
  - `Respond status_toggle (Google)` (RespondToWebhook)

Smoke test Google ejec `120880` 2.2s ✅ — Campaign Limón y Kiwi PAUSED→PAUSED (test neutro). Response `{ok:true, nota_id:'71193935-...', prev_status:'PAUSED', new_status:'PAUSED'}`. Nota `accion` generada en `ads_notas`.

**Bug fix durante smoke** (anti-patrón nuevo):
- GET Cuenta (status_toggle) con `Accept: application/vnd.pgrst.object+json` devolvía `{json:{data:'<stringified>'}}` porque n8n no parsea Content-Type custom de PostgREST. Fix: añadir `options.response.response.responseFormat = 'json'` al nodo HTTP. Documentado en sección PostgREST gotchas (pendiente añadir).

**Para entity_type='ad' Google**: Bubble DEBE incluir `external_adset_id` en el payload del webhook. El resourceName requiere `customers/<acc>/adGroupAds/<ad_group_id>~<ad_id>` (no solo el ad_id como en Meta). El Mapear Status Google lanza error explícito si falta.

#### SYNC ADS — Google Discovery Cuentas
**ID:** `NmJAZoRIVjggnYlT` · **Estado:** ✅ ACTIVO (smoke test ejec `120830` 2.0s, 10 cuentas mapeadas + 5 viejas actualizadas con nombres canónicos)
**Trigger:** Cron `*/30 8-21 * * *` Europe/Madrid
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz` · **Tags:** ⚠️ `portal+ads` PENDIENTE UI

Espejo Google del Discovery Meta. Descubre dinámicamente las cuentas hijas accesibles bajo el MCC `6005054046` vía GAQL `customer_client level<=1 AND manager=false AND status=ENABLED`. UPSERT en `ads_cuentas` preservando `estado_interno` en UPDATE (campo omitido del body PostgREST). 6 nodos:

```
1. Cron */30 8-21 Madrid
2. Descifrar Creds Google — RPC aic_get_with_key con $env.AIC_KEY
3. Refresh → Access Token — oauth2.googleapis.com/token form-urlencoded
4. GAQL customer_client — POST googleads.googleapis.com/v20/customers/<MCC>/googleAds:search
5. Code "Mapear Cuentas" — status map ENABLED=1 / SUSPENDED=2 / CANCELED|CLOSED=9
6. UPSERT ads_cuentas — URL query ?on_conflict=provider,external_account_id · header Prefer: resolution=merge-duplicates,return=minimal
```

⚠️ **El parámetro `on_conflict` va en URL query string, NO en header**. PostgREST lo lee exclusivamente de query. Si va en header (o se omite), el UPSERT con `Prefer: resolution=merge-duplicates` infiere el conflict target del primary key UUID (nunca tiene conflict) → cae a INSERT puro → UNIQUE violation en filas existentes → con `onError: continueRegularOutput` el nodo NO actualiza datos viejos pero NO lanza error visible. Bug fix aplicado en ejec 120703 (filas nuevas OK, viejas NO actualizadas).

API v20 obligatoria (v18/v19 dan 404 en 2026-05). Smoke test creds verde con workflow temporal `m77TBjKCZDaW1c4E` (ya borrado) — 11 cuentas (10 hijas + MCC). Discovery filtra el MCC vía `manager=false`.

#### SYNC ADS — Google Estructura
**ID:** `TMGNH1IVlthDAptX` · **Estado:** ✅ ACTIVO (smoke test ejec `120866` 2.5s, Limón y Kiwi: 2 campañas + 2 adgroups + 2 ads)
**Trigger:** Cron `30 5 * * *` Europe/Madrid (mismo schedule que Meta Estructura)
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz` · **Tags:** ⚠️ `portal+ads` PENDIENTE UI

Sync campañas + ad_groups + ads de Google a las 3 tablas Meta-named (`ads_campanias`/`ads_adsets`/`ads_anuncios`) reusando RPC `ads_upsert_estructura`. 10 nodos con loop SplitInBatches:

```
1. Cron 05:30 daily Madrid
2. Descifrar Creds Google
3. Refresh → Access Token
4. GET Cuentas Activas — provider=eq.google&estado_interno=eq.activa
5. Iterar Cuentas — Split In Batches size 1
6. GAQL Campaigns — SELECT campaign.id, name, status, advertising_channel_type, bidding_strategy_type, campaign_budget.amount_micros WHERE campaign.status != 'REMOVED'
7. GAQL Ad Groups — SELECT ad_group.id, name, status, type, campaign WHERE ad_group.status != 'REMOVED'
8. GAQL Ad Group Ads — SELECT ad_group_ad.ad.id, ad.name, status, ad_group WHERE status != 'REMOVED'
9. Code "Armar Payload Estructura Google":
   - tail() para resource names (customers/X/campaigns/Y → Y)
   - microsToUnit() para amount_micros / 1e6
   - map ad_group_id → campaign_id para resolver el campaign de cada anuncio
   - Meta-only fields (buying_type, targeting, billing_event, lifetime_budget, creative_summary, etc) → null
10. POST /rpc/ads_upsert_estructura — UPSERT campañas + ad_groups (=adsets) + ads
→ loop back
```

**Mapeos clave:**
- `campaign.advertising_channel_type` → `objective` (SEARCH/DISPLAY/VIDEO/PERFORMANCE_MAX/etc)
- `campaign.bidding_strategy_type` → `bid_strategy`
- `campaign_budget.amount_micros / 1e6` → `daily_budget`
- `ad_group.type` → `optimization_goal`

#### CRON ADS — Google Daily 06:00
**ID:** `HXPp0By7yLtEAJiD` · **Estado:** ✅ ACTIVO (smoke test ejec `120867` 3.7s, fecha=2026-05-12, 6 filas insights: 1 account + 1 campaign + 2 adsets + 2 ads · €25.15 spend / 24 clicks / 1 conv)
**Trigger:** Cron `0 6 * * *` Europe/Madrid
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz` · **Tags:** ⚠️ `portal+ads` PENDIENTE UI

Insights diarios del día anterior por 4 niveles (account/campaign/ad_group/ad) → `ads_insights_diario` reusando RPC `ads_insertar_insights_diario` con adapter Meta-like fabricado en Code. 12 nodos:

```
1. Cron 06:00 daily Madrid
2. Descifrar Creds Google
3. Refresh → Access Token
4. Code "Calcular Fecha Ayer" — Intl.DateTimeFormat('en-CA', timeZone: Madrid) + UTC arith para DST-safe
5. GET Cuentas Activas — provider=google&estado_interno=activa
6. Iterar Cuentas — Split In Batches size 1
7. GAQL Insights Account — WHERE segments.date DURING YESTERDAY · FROM customer
8. GAQL Insights Campaign — idem FROM campaign + status != REMOVED
9. GAQL Insights AdGroup — idem FROM ad_group
10. GAQL Insights Ad — idem FROM ad_group_ad
11. Code "Armar Payload Insights Google" — adapter Meta-like (ver abajo)
12. POST /rpc/ads_insertar_insights_diario
→ loop back
```

**Adapter Meta-like (clave para reusar RPC sin duplicar):**
```js
mapRow(entity_type, entity_external_id, metrics) {
  spend = costMicros / 1e6
  ctr = ctr_decimal * 100  // Google decimal → Meta %
  cpc = averageCpc / 1e6
  cpm = averageCpm / 1e6
  reach = null         // no existe Google
  frequency = null     // no existe Google
  actions = conv > 0 ? [{action_type:'purchase', value:conv}] : []          // fabricado para ads_extract_conversion
  action_values = conv_val > 0 ? [{action_type:'purchase', value:conv_val}] : []
}
```

`ads_extract_conversion` reconoce `purchase` como conversion type, así que el revenue se extrae correctamente.

#### CRON ADS — Google Intra-día 30min
**ID:** `Uqv3R3txzcg8GI1B` · **Estado:** ✅ ACTIVO (smoke test ejec `120876` 3.0s, scoring last_7d: Leads-Search `ontarget`, adset G2 `winner` CPA €22.70, adset G1 `loser` CPA €54.58, Campaign #1 `nodata`)
**Trigger:** Cron `*/30 8-21 * * *` Europe/Madrid (mismo schedule que Meta Intra-día)
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz` · **Tags:** ⚠️ `portal+ads` PENDIENTE UI

Snapshot intra-día last_7d agregado + scoring inline. 11 nodos:

```
1. Cron */30 8-21 Madrid
2. Descifrar Creds Google
3. Refresh → Access Token
4. GET Cuentas Activas — provider=google&estado_interno=activa
5. Iterar Cuentas — Split In Batches size 1
6. GAQL Snapshot Campaign — SELECT sin segments.date · WHERE segments.date DURING LAST_7_DAYS AND status != REMOVED (agrega 7d)
7. GAQL Snapshot AdGroup
8. GAQL Snapshot Ad
9. Code "Armar Payload Snapshot Google" — mismo adapter Meta-like que Daily
10. POST /rpc/ads_actualizar_kpis_snapshot — preset='last_7d'
11. POST /rpc/ads_calcular_scoring — recálculo percentiles (provider-agnóstic) INLINE
→ loop back
```

**Truco GAQL agregación**: omitir `segments.date` del SELECT con `WHERE segments.date DURING LAST_7_DAYS` agrega automáticamente las métricas de los 7 días por entidad. No hace falta GROUP BY.

**Coste rate-limit Google:** 3 GAQL × N cuentas cada 30 min. Google Ads Basic Access: 15k operations/día (no por hora). Con 10 cuentas × 3 calls × 48 ejec/día = 1440 calls/día → 9.6% cuota. Margen 10×.

### Legacy (Gmail / GHL / Google Ads Script)

### WF1 — Oyente Meta Ads Gmail
**ID:** `4gN3uGhH8NZX2BDU`
**Trigger:** Gmail Trigger cada minuto, label Meta for Business, no leídos
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz`

Detector de alertas operativas (rechazos, suspensiones, límites, fallos pago, recibos, fatiga) en correos de Meta for Business → extrae `ad_account_id` por regex → resuelve cliente vía `dashboardmedia_cuentas_ads` (Bubble) → humaniza con Claude Haiku 4.5 → crea registro en `dashboardmedia_alertas_operativas` (Bubble). Idempotente por `external_id = gmail_<message_id>`.

**No extrae métricas** (reach/impressions/spend/conversiones). Si en algún momento se quiere sync de métricas, sería un workflow nuevo distinto.

Detalle de nodos en sección [Cron y sincronizaciones programadas](#cron) (entrada "WF1 — Oyente Meta Ads Gmail").

### WF2 — Oyente GHL
**ID:** `Ik2Tt3Dw5ivL8qk7`
**Estado:** Inactivo (en desarrollo, no operativo).

### WF3 — Receptor Google Ads Script (modificado 2026-05-12 — redirige también a `ads_alertas`)
**ID:** `fdmkhBOua6pbZh6P`
**Trigger:** Webhook POST en `/webhook/google-ads-alertas`. Lo llama un Google Apps Script "TheNucleo — Ops Monitor" (en `ads.google.com` MCC TheNucleo → Scripts, programado cada hora) que itera `AdsManagerApp.accounts().get()` y empuja alertas en lote.
**Error workflow:** `HRDQ9Ju4NAIUV0qyhKzlz` · **Tags:** `portal`
**Cambio 2026-05-12:** se añadió un nodo `POST ads_upsert_alerta_google` (HTTP Request) conectado en PARALELO al "Humanizar alerta con IA" desde "Lookup Cuentas_Ads". La rama legacy (Humanizar → Crear alerta en Bubble) sigue intacta para convivencia. La nueva rama llama a la RPC `ads_upsert_alerta_google` con auto-discovery: cualquier `customer_id` que llegue del Apps Script y no exista en `ads_cuentas` se crea automáticamente como `pendiente_asignar` (provider='google'). Smoke test E2E verde 2026-05-12.

**Cambio 2026-05-13 (transparente para este workflow):** la RPC `ads_upsert_alerta_google` ahora normaliza `p_customer_id` al entrar (`regexp_replace(p_customer_id, '-', '', 'g')`). El Apps Script sigue enviando IDs con guiones (`562-486-5472`) sin cambios; la normalización ocurre en el RPC para que el matching contra `ads_cuentas.external_account_id` (formato canónico API sin guiones, `5624865472`) funcione. Las 5 filas Google ya existentes fueron normalizadas en la misma migration `ads_normalize_google_ids`.

Detector de alertas operativas Google Ads. El script externo envía un payload con `alertas[]` ya pre-formateadas:
- `tipo`: `gasto_caido | cpc_anomalo | limitada_presupuesto | quality_score | rechazo | suspendido | frecuencia_alta | flujo_roto`
- `campaign_name`, `customer_id`, `detalle` (ya compacto, ej: `"CPC hoy: 3.32 | CPC media 7d: 2.53"`)

```
1. Webhook POST → recibe body.alertas[]
2. Code "Preparar alertas con IDs":
   - genera _external_id (idempotencia, distinto según tipo)
   - genera titulo_compacto + detalle_compacto (fallback determinista)
   - marca es_critica por tipo (rechazo, suspendido, gasto_caido, flujo_roto, limitada_presupuesto)
3. GET dashboardmedia_alertas_operativas (estado=activa, limit=200) → existentes
4. Code "Filtrar solo nuevas": diff por external_id
5. IF nuevas > 0 → SplitInBatches loop:
   5a. Lookup dashboardmedia_cuentas_ads por google_customer_id
   5b. Humanizar con IA (Claude Haiku 4.5, max_tokens=400):
       - system role anti-markdown, anti-narrativa
       - mantener numeros EXACTOS del DETALLE del script
       - devuelve {titulo, detalle, tipo_error} compacto
   5c. POST dashboardmedia_alertas_operativas (cadena fallback IA → compacto)
6. Respond to Webhook { status: ok }
```

**Patrón híbrido (mismo que WF1):** datos compactos del script son source of truth. La IA solo reformatea sin alucinar números. Si IA falla, fallback a `titulo_compacto`/`detalle_compacto` del Code.

---

## Externos (Webhooks de entrada)

⚠️ **GHL sin workflow activo:** el único oyente GHL (`Ik2Tt3Dw5ivL8qk7` / WF2 GHL) está inactivo (en desarrollo).

**Evolution API (WhatsApp):** primer uso productivo en `Q99fjZWhA8tlofVr` — **OPS VENTAS — Alta Cliente WhatsApp** (ver sección [OPS VENTAS](#ops-ventas-alta-cliente-whatsapp) más abajo). Las tablas legacy `wa_conversaciones` / `wa_mensajes` / `wa_resumenes` se eliminaron (nunca llegaron a usarse); la persistencia conversacional vive ahora en la tabla nativa `alta_cliente_wip`.

### OPS VENTAS — Alta Cliente WhatsApp

- **ID:** `Q99fjZWhA8tlofVr` — INACTIVO (pendiente Evolution + credenciales).
- **Trigger:** Webhook POST `/webhook/ventas_whatsapp_inbound` (Evolution API push).
- **Allowlist hardcoded en `Filtro whitelist + fromMe`** (anti-confusión con clientes externos que pudieran mandar al mismo número):
  - `+34627755036` — Benja
  - `+34675525001` — Alex
- **Flujo (26 nodos):** Webhook → Respond 200 OK + If whitelist+fromMe=false → If audio → (rama audio) `Descargar audio Evolution` → `Upload Gemini File API` → `Transcribir Gemini` (gemini-2.5-flash) — (rama texto) directo → `Normalizar texto entrada` (Code, mapea teléfono→`{nombre,email}` del comercial) → `GET intake abierto` (alta_cliente_wip) → `UPSERT intake` (append historial) → 3 lookups paralelos en cascada: `GET fichas catalogo` + `GET categorias` + `GET clientes existentes` (bub_clientes con `agencia_id=eq.1769...`) → `Claude Sonnet 4.6` (system prompt con catálogo+clientes existentes+comercial actual, devuelve JSON `{accion:preguntar|resumir|crear|cancelar, mensaje_para_comercial, payload_actualizado, servicios_finales}`) → `Parsear y validar ficha_id` (Code, anti-alucinación: si Claude inventa un `ficha_id` que no está en catálogo, fuerza `accion=preguntar`) → `PATCH intake mensaje asistente` → `Ruta por accion` (Switch v3.4):
  - **crear** → `POST bub_clientes Bubble` (dispara `wvHcgVqqjkWJcJDu` Drive+Notion automáticamente) → `Expandir servicios` (Code, devuelve N items con un fallback `__skip:true` cuando no hay servicios) → `Loop servicios` (SplitInBatches v3, batchSize 1) → onEachBatch `INSERT playbook_cliente_servicios` (vía SYNC `ewu5A5E05T4tz5CD` se espeja a Bubble) → nextBatch → onDone `PATCH intake confirmado` (`estado=confirmado`, `cliente_bubble_id`=ID Bubble) → `sendText cliente creado` (Evolution).
  - **cancelar** → `PATCH intake rechazado` → `sendText cancelado`.
  - **preguntar/resumir** → `sendText Evolution` con `mensaje_para_comercial`.
- **Tabla destino WIP:** `alta_cliente_wip` (nativa, sin policies = solo service_role; `UNIQUE (telefono_e164) WHERE estado='abierto'` impide 2 sesiones abiertas a la vez del mismo comercial; `last_msg_in_id UNIQUE` da idempotencia anti-doble webhook Evolution).
- **Tabla destino final cliente:** `bub_clientes` vía Bubble Data API (LIVE). Campos seteados: `nombre_empresas`, `sector`, `contacto_principal`, `correo_principal`, `telefono_principal`, `estado='Activo'`, `agencia_id='1769513105728x555492736219132700'` (unique id Bubble, NO uuid Supabase).
- **Tabla destino servicios:** `playbook_cliente_servicios` (Supabase nativa, FK `cliente_bubble_id`). El SYNC `ewu5A5E05T4tz5CD` los espeja a Bubble.
- **Env vars requeridas en EasyPanel:** `GEMINI_API_KEY`, `BUBBLE_BASE_URL` (apuntando a LIVE), `EVO_URL`, `EVO_INSTANCE`.
- **Credenciales n8n requeridas:** `Supabase API` (predefined), `Anthropic API` (predefined), `Bubble HTTP Header (LIVE)` (httpHeaderAuth genérica), `Evolution API Header Auth` (httpHeaderAuth genérica).
- **Pendientes UI antes de activar:**
  1. Asignar las 4 credenciales en los 17 nodos HTTP marcados como skipped.
  2. Añadir tag `portal` (sin él, el workflow no entra al backup `n8nthenucleo`).
  3. Configurar webhook Evolution para que apunte a `/webhook/ventas_whatsapp_inbound`.
- **Bugs corregidos al continuar el draft `2026-05-23`:** (a) `agencia_id_bub` → `agencia_id` en GET + POST contra `bub_clientes`; (b) `cliente_id` → `cliente_bubble_id` en INSERT a `playbook_cliente_servicios`; (c) whitelist por env var `WHITELIST_TELEFONOS` (no existía) → hardcoded en el If; (d) nuevo nodo `Expandir servicios` que iteraba la respuesta de Bubble en vez de los servicios reales — ahora itera el array `servicios_finales` real.
- **Doc detallada:** [[../portal/integraciones/whatsapp-alta-cliente|whatsapp-alta-cliente]].

---

## Análisis Estratégico Cliente (chat co-creativo)

Bloque de 6 workflows que sostienen el chat co-creativo del módulo "Análisis Estratégico Cliente" (sector 7). Persistencia en Supabase cbi tabla `analisis_wip` (briefing 12 secciones + segmentos array + `kb_files` con inventario Drive).

### analisis_init
**ID:** `8hAokf6zfQl0dMlR` — ✅ Activo (2026-04-30)
**Trigger:** Webhook POST `/init-analisis`
Greeting inicial al abrir el chat. Race guard `count(chat_messages)=0` → lista Drive lite del `bb_link_drive_analisis` del cliente (sin descargar) → separa archivos soportados (PDF/DOCX/TXT/MD/JSON) de no soportados → llama Gemini 2.5 Flash con la lista de nombres → genera narrativa 2-3 frases → format greeting HTML (lista clicable + drive link + nota honestidad "no accedo a la web en directo") → upsert `kb_files` lite en `analisis_wip` → insert greeting en `chat_messages`. 3 branches: con drive+soportados / con drive sin soportados / sin drive. **Patch 2026-05-21 (url_analizar):** `Get Cliente` ahora consulta también `pagina_web` de `bub_clientes`. `Build Context` valida regex `^https?://` y propaga como `url_analizar`. Nuevo nodo `Upsert URL Analizar` (HTTP Request, **rama LATERAL desde `Build Context` en paralelo a `Has Drive?`**) hace UPSERT a `analisis_wip` con `Prefer: resolution=merge-duplicates` + `on_conflict=conversation_id` para escribir `url_analizar` SIEMPRE, sin depender de los 3 branches downstream. ⚠️ La rama es LATERAL no en serie: si se mete en serie entre `Build Context` y `Has Drive?`, el `Prefer: return=minimal` deja `$json = {}` vacío y `Has Drive?` evalúa `$json.hasLinkDrive = undefined` → siempre FALSE → greeting incorrecto "no tengo Drive". Bug original: `url_analizar` quedaba NULL en TODOS los WIPs → KB Fetch fallaba al hacer `https://r.jina.ai/null` con 400 → análisis sin contenido de web pública. Backfill SQL 2026-05-21 cubrió los 3 WIPs históricos afectados (Aquagames/Worknature/Rock&Climb).

### analisis_entrada
**ID:** `dtgF0G35aeJQVVfn` — ✅ Activo
**Trigger:** Webhook `chat-analisis`
Guarda mensaje del usuario, asegura fila WIP (insert con `continueOnError` por UNIQUE) y dispara `analisis_tool_loop`.

### analisis_tool_loop
**ID:** `FFhkdTFCjTtfyvhP` — ✅ Activo
Update estado=`analizando` (no create — fila ya existe). Get WIP + historial + Agent Claude streaming + merge patches al briefing/segmentos. **Resolve Citations (2026-04-30)** dentro del Code `Parse + Merge`: reemplaza `[fuente: nombre.ext]` en `assistant_message` por `<a href="<link>" class="cita-fuente">[nombre.ext]</a>` mediante lookup en `kb_files` del WIP. Si el agent inventa un nombre que no está en `kb_files`, deja `[fuente: X]` plain text. System prompt del Agent Claude incluye bloque "CITAS DE FUENTES" con la instrucción. **Hardening Parse + Merge (2026-05-12 v2):** `extractJson`/`extractFencedJson` sustituidos por `extractAllJsonCandidates` (recolecta TODOS los `{…}` balanceados, fenced y a pelo, respetando strings con llaves dentro) + `parseBestCandidate` (recorre de atrás hacia delante, descarta candidatos con `"..."` y `{ ... }` literales, devuelve el primero válido con `assistant_message` o `updates`). `stripToolTags` se mantiene. Fallback final: si nada parsea, `assistant_message` muestra "⚠️ El modelo devolvió un formato inesperado… (Diagnóstico: [primeros 400 chars del raw])" — adiós al genérico "Error procesando la respuesta del asistente." Origen: ejecución **119771** (Rock & Climb) — Sonnet 4.6 tardó 179 s y devolvió chain-of-thought en inglés + 4 bloques JSON (1 con placeholders `...`, 3 borradores, 1 final correcto). El extractFencedJson v1 cogía el primer bloque (placeholder), `JSON.parse` reventaba en line 4 col 25. La versión v2 sí encuentra el JSON correcto al final. Sustituye al hardening v1 del 2026-05-12 mañana. **Fix maxIterations (2026-05-21):** `Agent Claude.options.maxIterations` subido de `2` → `8` y `retryOnFail` desactivado. Origen: ejecución **130746** (BRIEFING_INICIAL con KB 15 212 chars) — el agente gastó iter 1 en `cargar_url`, iter 2 en otra tool y se quedó sin presupuesto para emitir el JSON final → `NodeOperationError: Max iterations (2) reached`. Con 2 iteraciones no había margen para las 3 cargas de URL que permite el system prompt + el output final. El retry de 4 s recursaba al mismo límite. Nuevo tope 8 = 3 tools + 1 output + 4 de colchón para deliberación interna del agente. WIP ya no queda colgado en `analizando` hasta que el CRON `V60MieFkQzOszxhh` lo libere a los 15 min.

### analisis_kb_fetch
**ID:** `Cfs3NFEE1enu1jTx` — ✅ Activo
Subworkflow auxiliar: recupera contexto (KB) para el agente del análisis. **Patch 2026-05-21 (límites KB subidos):** en el Code `Empaquetar KB`, `MAX=100000` (antes 75000), `PER_FILE=50000` (antes 15000), `WEB_MAX=20000` (antes 15000). El cambio cubre el caso DOCX largos (74K+ del onboarding Aquagames) que antes se cortaban al 20%. Coste extra +$1-2/análisis (Sonnet 4.6), latencia +5-10s/turno. Pendiente activar Anthropic prompt caching — requiere refactor del Agent Claude porque el nodo `@n8n/n8n-nodes-langchain.lmChatAnthropic` v1.3 no expone `cache_control`. **Patch 2026-04-30:** ahora persiste `kb_files` (inventario con `status: incluido|truncado` + `chars_used`) además del `kb_text`. Mergea con `existing_kb_files` (poblados por `analisis_init`) preservando los `no_soportado`. Nodo nuevo `Get WIP existing kb_files` antes del listado Drive para leer el inventario lite. **Fix DOCX v1 (2026-05-21, descartado):** se sustituyó el `extractFromFile`-roto-para-docx por un Code node con `require('jszip')`. En execution `130847` el Code reventó silencioso con `Module 'jszip' is disallowed [line 10]` — el task runner externo de n8n bloquea TODOS los `require()` por allow-list, incluido `jszip` (y `crypto`, `https`, `xlsx`…). El KB volvió a salir vacío. **Fix DOCX v3a (2026-05-21, descartado):** primera versión de la cadena nativa con bug en `Pick document.xml` (buscaba por nombre de key `file_<idx>` en vez de por `binary[k].fileName`). Execution `130912`. **Fix DOCX v3b (2026-05-21, descartado):** Pick corregido pero con `onError: continueRegularOutput` en `Read document.xml` → comportamiento silencioso: sub success + `kb_text: '[Sin texto extraíble]'` + `status: 'incluido'` engañoso. **Fix DOCX v3c (2026-05-21, activo):** versión ruidosa final.
  - `Prep DOCX→ZIP` (Code, `$input.all()`, renombra binary a `.zip` + mimeType `application/zip`).
  - `Decompress DOCX` (`n8n-nodes-base.compression` op decompress, prefix `file_`).
  - `Pick document.xml` (Code, `$input.all()`, busca `binary[k].fileName === 'document.xml' && directory ends with 'word'`, **throw** con nombre archivo + inventario del ZIP si no encuentra — sin fallback silencioso).
  - `Read document.xml` (`extractFromFile` op text, `onError: stopWorkflow` default).
  - `XML → Texto` (Code, `$input.all()`, regex tolerante a `w:t` Y `w<N>:t` para namespaces docx exóticos, decodifica entities numéricas `&#160;` y `&#xA0;`. Throw si XML vacío o texto < 20 chars).
  - Sub + padre `FFhkdTFCjTtfyvhP` con `settings.errorWorkflow: HRDQ9Ju4NAIUV0qyhKzlz` → cualquier throw cae en `n8n_incidencias` y `work.thenucleo.com/incidencias`.
  - Soporta múltiples .docx por cliente (iteración `$input.all()` en los 3 Code).
  - Trade-off explícito: si UN .docx revienta el sub entero, todo el KB Fetch del cliente falla y el análisis queda en `analizando` hasta CRON reset (`V60MieFkQzOszxhh`, 15 min). Preferencia "ruidoso > resiliencia parcial" para uso interno. Detalle en anti-patrón **#19** abajo.

### analisis_trigger_entrega
**ID:** `JtXdkXHm6RyGOJft` — ✅ Activo
**Trigger:** Webhook POST `/entregar-analisis`
Shim ligero: recibe `conversation_id` desde Bubble, dispara `analisis_entrega` async y responde 200 OK inmediato.

### analisis_entrega
**ID:** `QW8VZ9cV5ECsSKvZ` — ✅ Activo
Lee `analisis_wip`, extrae `folder_id` desde `bb_link_drive_analisis` del cliente, **renderiza HTML semántico** (briefing 12 secciones + 4 segmentos × {Empatía 7×5 / Buyer tabla / Ángulos 5 cards}), sube a Drive como **Google Doc nativo** vía multipart/related y actualiza `estado=entregado` + `doc_url`.

**Flujo (8 nodos):** Recibir conversation_id → Get `analisis_wip` → Estado `entregando` → Get `bub_clientes` → **Render HTML + Multipart** (Code node, genera HTML + body multipart/related con boundary) → **Subir HTML a Drive** (HTTP Request POST `https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&supportsAllDrives=true` con OAuth2 Drive cred + `Content-Type: multipart/related; boundary=...` + body raw) → Estado `entregado` (set `doc_url=https://docs.google.com/document/d/{id}/edit`) → Mensaje assistant (chat msg con link Doc).

**Por qué HTTP Request en vez de Drive node**: el nodo `n8n-nodes-base.googleDrive` operation `createFromText` envía el contenido como `text/plain` y no expone el MIME type del source. Aunque `convertToGoogleDocument: true` convierte el archivo a GDoc, las marcas Markdown (`#`, `**`, `-`) quedan literales — Google no las renderiza. Para forzar interpretación, hay que subir como `text/html` con metadata `mimeType: application/vnd.google-apps.document` vía multipart/related → Google mapea tags HTML a estilos nativos del Doc (H1/H2/H3, listas, tablas, negritas). Encaja con la excepción del nodo Supabase upsert documentada en este mismo doc: nodo nativo no expone el header → HTTP Request justificado.

**Cambio 2026-05-12** (entrada en log-cambios): se eliminó el nodo Drive y se reemplazó por HTTP Request multipart. Code node renombrado de `Render Markdown + folder` a `Render HTML + Multipart`. URL del Doc cambia de `/file/d/{id}/view` a `/document/d/{id}/edit`.

### analisis_cron_reset_analizando
Documentado arriba en sección CRON. Reset de filas atascadas en `analizando`.

---

## Subworkflows RAG y herramientas IA

### Cerebro IA — Indexar Contexto Drive [Subworkflow]
**ID:** `NI1oUwIY99TGk496` — ✅ Activo
Subworkflow auxiliar del CRON `ZnJSkoWlSusmEjhO` que indexa documentos Drive del cliente al fileSearchStore Gemini correspondiente.

### Cerebro IA — Reindexar RAG Manual [Webhook]
**ID:** `BqNTrwoQ2iJIcAB4` — ✅ Activo
**Trigger:** Webhook `/reindexar_rag_cerebro`
Permite forzar reindexado RAG de un cliente concreto desde Bubble (botón manual).

**Estructura (refactor 2026-05-12, fix `helpers.httpRequestWithAuthentication`):**
1. `Webhook Reindexar` → `Respond 200` (paralelo) + `Validar Input`
2. `Validar Input` (Code) — extrae `cliente_notion_id` / `agencia_id` del body. Sin HTTP.
3. `GET Cliente` (Supabase node nativo, op `getAll`, table `bub_clientes`, filter `notion_id eq`) — cred `pmc312jjJKdPClmj`.
4. `Preparar Payload` (Code) — construye payload final combinando `$('Validar Input')` + `$json` del Supabase. Valida `link_drive` presente.
5. `Ejecutar Indexacion` → subworkflow `NI1oUwIY99TGk496` (`waitForSubWorkflow: false`).

Antes del refactor, `Preparar Payload` hacía la llamada Supabase con `this.helpers.httpRequestWithAuthentication`, bloqueado por el task runner en Code nodes (anti-patrón documentado).

### Newsletter IA — Indexar Contexto Drive [Subworkflow] (`newsletter_kb_fetch`)
**ID:** `w6Gqo8B6Sqp6Mq9x` — ✅ Activo (refactorizado 2026-04-29)

Subworkflow con 2 triggers:
1. `Execute Workflow Trigger` — invocado por el CRON `kZE3W2ae0upyGt2E` (reindexación nocturna).
2. Webhook `/indexar_contexto_newsletter` — invocado por `newsletter_tool_loop` (tool `cargar_contexto_cliente` async cuando el cliente tiene `link_drive` pero no hay store en `rag_stores`).

12 nodos (antes 21). Crea fileSearchStore Gemini + indexa archivos Drive del cliente (Google Doc/Sheet/PDF/Text + opcional página web vía Jina) + UPSERT `rag_stores` con `Prefer: resolution=merge-duplicates` y PK compuesta `(notion_id, tipo='newsletter')` + UPDATE `newsletter_wip.kb_text` + estado `ready_to_generate` (con grounding) o `collecting` (sin contexto). Distinción cron vs tool_loop: prefijo `conversation_id = "cron-nl-*"` evita actualizar `newsletter_wip` cuando corre desde el cron. Renombrar workflow pendiente a `newsletter_kb_fetch`.

---

## Workflow de error de bots externos

### Detectar Errores BOTgoogle (NOTOCAR)
**ID:** `9WM__jEMrviSSC6KyJCT9` — ✅ Activo
Configurado como `errorWorkflow` en varios workflows (incluido `GjijIDEUyiH05Mg0`). No tocar — gestiona errores del bot Google externo. NO confundir con `HRDQ9Ju4NAIUV0qyhKzlz` (Errores Flujos Plataforma) que es el error handler general de la app.

---

## Notas de arquitectura n8n

- **Credenciales siempre por ID**, nunca hardcodeadas en expresiones
- **Supabase:** usar nodo HTTP Request con `service_role` key (bypass RLS)
- **Error workflow:** configurado a nivel de workflow, no nodo a nodo
- **Retry:** solo en nodos críticos (Notion API, Supabase upsert) — max 3 intentos, backoff exponencial

---

## Lecciones aprendidas — anti-patrones a EVITAR

Descubiertos durante auditoría 2026-04-17 del sync Notion↔Supabase↔Bubble. Cualquier workflow nuevo o modificado debe revisarse contra esta lista.

### 1. `$input.first()` tras HTTP Request con paginación → solo lee la primera página

**Síntoma:** el HTTP devuelve N páginas (items) pero el Code node siguiente procesa solo 1.

**Incorrecto:**
```js
const results = $input.first().json.results || [];
```

**Correcto:**
```js
const results = $input.all().flatMap(i => i.json.results || []);
```

**Dónde ocurrió:** `Normalizar tareas Notion` en Reconciliación. Procesaba 100 de 1233 tareas. 1133 tareas nunca se comparaban.

---

### 2. Paginación HTTP con `maxRequests` + `limitPagesFetched: true` → corte silencioso

**Síntoma:** la paginación para a los N requests configurados aunque haya más datos.

**Incorrecto:**
```json
{
  "pagination": {
    "paginationCompleteWhen": "other",
    "completeExpression": "={{ !$response.body.has_more }}",
    "limitPagesFetched": true,
    "maxRequests": 10
  }
}
```

**Correcto:** quitar `limitPagesFetched` (o ponerlo a `false`) y confiar en `completeExpression`.

**Dónde ocurrió:** Query Notion en Reconciliación. Cortaba a 1000 tareas (10 páginas × 100).

---

### 3. Upsert Supabase sin `synced_at` / `sync_status` → métrica de frescura rota

**Síntoma:** `synced_at` queda como timestamp de INSERT inicial. `synced_at < last_edited_time` no indica desfase real (solo que el upsert no actualiza el campo).

**Correcto:** incluir SIEMPRE en el payload del upsert:
```js
synced_at: new Date().toISOString(),
sync_status: 'clean'
```

**Dónde ocurrió:** `Upsert de Tareas` en SYNC + `Preparar upsert Supabase` en Reconciliación.

---

### 4. GET PostgREST sin `limit` explícito → cap implícito de 1000 filas

**Síntoma:** tabla con 1415 filas devuelve solo 1000. Puede enmascararse si hay dedup downstream (como `supMap` por `notion_id`).

**Correcto:**
- Añadir query param `limit=5000` (o el esperado)
- O header `Range: 0-9999` con `Prefer: count=exact`

---

### 5. CREATE en Bubble sin guard anti-duplicados → fila repetida

**Síntoma:** cuando `bubble_id` en Supabase está vacío (no se grabó en un intento anterior), CREATE crea un duplicado si Bubble ya tenía la fila.

**Correcto:** antes de CREATE, hacer `GET Bubble WHERE notion_id = X`. Si existe, usar su `_id` y hacer PATCH en su lugar.

**Dónde ocurrió:** SYNC trigger (parcheado 2026-04-17). Reconciliación pendiente de aplicar el guard (riesgo bajo porque CREATE solo dispara para `missing_supabase`).

---

### 6. Loop Over Items + GET Supabase con filtro cuyo valor puede ser `undefined` → flow se corta

**Síntoma:** el Loop no vuelve a iterar porque el GET devuelve 0 items y el backward-link a Loop nunca se ejecuta. Las N-1 iteraciones restantes se pierden.

**Correcto:**
- Guard en el filtro: `={{ $json.cliente_notion_ids?.[0] || 'INEXISTENTE' }}`
- O IF previo que saltea GET cuando el campo clave está vacío
- Mejor aún: no hacer el GET dentro del loop — resolver todo previamente (catálogo en memoria)

**Dónde ocurrió:** `GET notion_empresas en Supabase (resuelve nombre del cliente)` en SYNC. Tareas sin cliente asignado rompen el resto del sync.

---

### 7. Reconciliación que compara solo Notion↔Supabase → Bubble huérfano

**Síntoma:** si un PATCH a Bubble falla silenciosamente pero Supabase se actualizó, Bubble queda desfasado y la reconciliación no lo detecta (Notion y Supabase coinciden).

**Correcto:** extender la reconciliación para comparar también Supabase↔Bubble. Pendiente de implementar.

---

### 8. Settings forbiddens en PUT de n8n Public API

Al hacer `PUT /api/v1/workflows/:id`, algunos campos de `settings` están prohibidos. Whitelist conocido:
```
executionOrder, timezone, errorWorkflow, callerPolicy,
saveDataErrorExecution, saveDataSuccessExecution,
saveManualExecutions, saveExecutionProgress, executionTimeout
```

Campos a FILTRAR antes del PUT: `availableInMCP`, `timeSavedMode`, `binaryMode`.

### 9. Versionado draft vs active sin publicar

n8n autosavea cambios del editor como **draft** (`meta.versionId`) pero la ejecución corre la **versión active publicada** (`activeVersion.versionId`). Si guardas cambios y no publicas, las ejecuciones siguen usando la versión vieja.

**Diagnóstico**: la execution termina `success` pero un nodo intermedio (`Get`, filter) devuelve 0 items con un criterio que ya cambiaste en el editor — el flujo se interrumpe a mitad sin error.

**Fix**: pulsar el botón **"Publish"** del workflow tras cualquier cambio relevante. Si dudas: comparar `meta.versionId` vs `activeVersion.versionId` con `n8n_get_workflow` mode=full.

**Aparición real**: 2026-04-22 en `analisis_entrega` — filtro `bub_clientes` por `bubble_id` en versión active vs `notion_id` en draft. El click "Generar Doc" parecía funcionar (status `success`) pero no creaba el Doc en Drive porque `Get bub_clientes` devolvía 0.

---

### 10. DELETE/limpieza dentro de loop sin `onError: continueRegularOutput` → drift permanente por aborto

**Síntoma:** nodo de limpieza (DELETE Bubble, DELETE Supabase, etc.) dentro de un `SplitInBatches` falla con 404 ("ya no existe") → el workflow aborta → los pasos posteriores (otras limpiezas, log, loop.next) no corren → la fila que disparó el fallo queda zombie → siguiente corrida del cron vuelve a pillarla, falla igual, bucle infinito.

**Incorrecto:** nodo con `onError` implícito (stopWorkflow) y sin tolerancia a 404.

**Correcto:** en nodos de limpieza cuyo 404 es éxito semántico ("ya no existe → objetivo cumplido"), añadir:
```json
{ "onError": "continueRegularOutput" }
```
Así el flujo pasa el item a los siguientes nodos y el loop sigue iterando.

**Aparición real**: 2026-04-24 en `ZqccS38F2Lz8WFwX` (huérfanas). El DELETE Bubble fallaba 404 cuando la fila ya había sido borrada en una corrida anterior, pero el DELETE del espejo había fallado ese día → zombie en `bub_tareas_notion`. Cron cada 3h abortando 10+ veces seguidas en la misma fila. Fix: `onError: continueRegularOutput` en DELETE Bubble + saneado del operador unary `notEmpty` del IF `tiene bubble_id?` (requería `singleValue: true` por el validador estricto de n8n-mcp).

---

### 11. `JSON.parse` sobre output Claude con prosa larga → falla intermitente por comillas sin escapar

**Síntoma:** workflow funciona el 90% de los días. El día que Claude genera un string que contiene comillas dobles dentro de un campo JSON (frases tipo `"ver más"`, `"sobre nosotros"`, citas), el `JSON.parse` revienta con `Expected ',' or '}' after property value in JSON at position N`. La ejecución muere en el nodo parser, sin commit ni marca de publicado.

**Incorrecto:** pedir a Claude que devuelva un objeto JSON con un campo string largo de prosa, y parsear con `JSON.parse(cleaned)`. El prompt nunca garantiza el escapado correcto de comillas dentro de strings, especialmente en campos de cuerpo largo. Fragmento del prompt roto:

```
Devuelve SOLO un objeto JSON válido, con este schema:
{ "title": ..., "markdown_body": string (cuerpo largo en markdown) }
```

**Correcto:** delimitar los campos con tags XML y extraer con regex. Claude está entrenado para no romper sus propias tags. Las comillas, llaves, apóstrofes y demás caracteres dentro del cuerpo se transmiten literal sin escapado.

```
Devuelve EXACTAMENTE:
<title>...</title>
<slug>...</slug>
<excerpt>...</excerpt>
<markdown_body>
...cualquier prosa con "comillas" y demás...
</markdown_body>
```

```js
const pick = (tag) => {
  const m = rawText.match(new RegExp("<" + tag + ">([\\s\\S]*?)</" + tag + ">"));
  if (!m) throw new Error("Falta tag <" + tag + ">");
  return m[1].trim();
};
const article = { title: pick("title"), slug: pick("slug"), ... };
```

**Aparición real:** 2026-04-26 en `CNlBtiFCwY69I6Wl` (Blog Zenyx — DIARIO 18:00 Madrid). Ejecución `104650` falló en `Parse Claude and Build Markdown` con `Expected ',' or '}' at position 3025` porque Claude generó la frase `tienes tres líneas antes del "ver más"` dentro de `markdown_body`. Fix: cambiado contrato JSON → XML tags, sustituido `JSON.parse` por extracción regex. Verificado con re-ejecución `104653` (post sobre LinkedIn con múltiples comillas dobles dentro del cuerpo, parsea sin problemas).

**Aplica también a:** cualquier workflow Claude/IA cuyo output incluya un campo string largo (markdown, descripciones, transcripts limpios, emails). Si tu campo string puede contener comillas dobles, no uses JSON. Usa XML tags.

---

### 12. `$('Node X').first().json[0].field` con HTTP Request a PostgREST → `undefined` silencioso

**Síntoma:** error `URL parameter must be a string, got undefined` (o assignment field se queda vacío) en un nodo downstream que referencia el output de un HTTP Request a PostgREST con filtro tipo `?col=eq.X`. La ejecución n8n marca el nodo como error sin más pista.

**Incorrecto:**
```js
$('Get Cliente').first().json[0].cliente_id
```

PostgREST devuelve un array de filas como JSON top-level: `[{...}, {...}]`. Cuando ese response llega a un HTTP Request node n8n, n8n no envuelve cada fila como un item separado por defecto — devuelve **un solo item cuyo `.json` ES el array entero**. Por tanto:

- `.first().json` = el array `[{...}, {...}]`
- `.first().json[0]` = la primera fila ✅ — esto SÍ es válido si lo que buscas es la fila entera
- `.first().json[0].cliente_id` = el campo de la primera fila ✅

**¿Entonces dónde rompe?** En realidad rompe cuando el query devuelve **una sola fila y n8n auto-promociona** o cuando la versión del nodo HTTP Request usa `splitItems` implícito. Tras algunas combinaciones de versión / configuración, `.first().json` ya es la fila desplegada (objeto, no array). En ese caso `.json[0]` es undefined.

**Correcto (defensivo):**
```js
// Caso 1 — sabes que devuelve 1 fila:
$('Get Cliente').first().json.cliente_id

// Caso 2 — no sabes si auto-promociona:
($('Get Cliente').first().json[0] || $('Get Cliente').first().json).cliente_id

// Caso 3 — fuerza array para iterar siempre:
($('Get Cliente').all().map(i => i.json).flat())[0].cliente_id
```

**Aparición real:** 2026-04-30 en `9wnB9NI8Capa4b8s` (newsletter_entrega). 3 nodos rotos: `Get Cliente Drive` (URL con `.json[0].cliente_id`), `Update Metadata con URL Doc` (URL con `.json[0].conversation_id`), `Save Mensaje Doc Generado` (fieldValue con `.json[0].conversation_id`). Workflow heredó el patrón cuando la fuente upstream cambió de "splitItems on" a "single item con array". Fix: cambiar todos a `.json.field` (Caso 1) tras confirmar que el upstream devuelve siempre 1 fila por filtrar por PK. Validado con execution exitosa que generó Doc en Drive.

**Aplica a:** cualquier workflow que encadene HTTP Request → Code/HTTP/Supabase con expresión `.json[X]` donde el upstream es PostgREST con filtros restrictivos. Verificar siempre con un Run del workflow real antes de asumir.

---

### 13. IF sobre HTTP Request con `neverError:true` chequea `$json.statusCode` que no existe → 404 nunca se detecta

**Síntoma:** un workflow que debe reaccionar a respuestas HTTP de error (típicamente 404 de Notion/Bubble/Supabase) deja pasar todos los casos de error y nunca dispara la rama de tratamiento. Las ramas de "archived/in_trash/etc." sí funcionan, así que el bug es invisible en revisión casual — solo se nota cuando una entidad se purga del sistema externo y el espejo local nunca se limpia.

**Incorrecto:**
```json
// Nodo HTTP Request:
{ "options": { "response": { "response": { "neverError": true } } } }

// Nodo IF downstream:
{ "leftValue": "={{ $json.statusCode }}", "rightValue": 404, "operator": "equals" }
```

`neverError:true` hace que el nodo HTTP no aborte en 4xx/5xx. Pero **sin `fullResponse:true`**, el output es solo el body de la respuesta. n8n NO añade un campo `statusCode` a `$json` automáticamente en ese modo. Por eso `$json.statusCode` siempre es `undefined` y el IF jamás matchea.

**Correcto — opción A (preferida, mínima):** leer el campo de status que la API devuelve dentro del body. Para Notion el shape de error es:
```json
{ "object": "error", "status": 404, "code": "object_not_found", "message": "..." }
```
→ usar `$json.status` (no `statusCode`). Para Supabase PostgREST: `$json.code` o `$json.message`. Para Bubble: comprobar `$json.statusCode` solo si activaste `fullResponse`, sino `$json.status` o el shape específico de su error.

**Correcto — opción B (más correcta semánticamente):** activar `fullResponse:true` en el HTTP Request → el body queda en `$json.body` y el status real en `$json.statusCode`. Pero ojo: cambia el shape para TODOS los chequeos downstream (los `archived`/`in_trash` pasarían a ser `$json.body.archived`/`$json.body.in_trash`). Solo merece la pena si vas a leer también headers o múltiples códigos.

**Aparición real:** 2026-05-04 en `ZqccS38F2Lz8WFwX` (CRON huérfanas). Bug latente desde la creación del workflow (2026-03-02). El cron limpiaba correctamente páginas archivadas o en papelera de Notion, pero **NUNCA** las páginas purgadas (papelera vaciada o ID inexistente). Resultado: tarea "Elaboración de Videos" llevaba 24 días huérfana en `bub_tareas_notion` después de purgarse de Notion el 2026-04-10. Ben detectó la inconsistencia comparando UI Bubble con Notion. Fix: opción A, cambiar `cond-404` de `$json.statusCode` a `$json.status`.

**Aplica a:** cualquier workflow que use HTTP Request con `neverError:true` y un IF posterior que chequee status code. Verificar siempre con una llamada real (curl o Postman) qué shape devuelve la API en error.

---

### 14. Sync que mapea relación de Notion sin resolver el campo derivado → NULL silencioso

**Síntoma:** un campo "denormalizado" (típicamente nombre/etiqueta) queda NULL en el sistema destino aunque el ID relacionado se sincroniza correctamente. La pérdida es invisible hasta que alguien intenta filtrar o visualizar por nombre.

**Incorrecto:** el normalizador extrae solo el ID de la relación Notion y los pasos de escritura ni siquiera incluyen el campo de nombre como property:
```js
// Normalizar
return { json: {
  ...,
  cliente_notion_id: relationFirstId(props['Cliente']),
  // ❌ falta: cliente_nombre derivado
}};
```
```json
// Crear/Actualizar (Bubble node):
"properties": { "property": [
  { "key": "cliente_notion_id", "value": "..." }
  // ❌ falta: cliente_nombre
]}
```

**Correcto:** añadir un nodo getAll de la entidad referenciada (executeOnce, alwaysOutputData) y construir un map ID → nombre en el step Decisor; emitir el campo derivado y declararlo como property en los nodos de escritura.

```js
// En Decidir Acción:
const clientes = $('Listar Clientes Bubble').all().map(i => i.json);
const map = {};
for (const c of clientes) if (c?.notion_id && c?.nombre_empresas) map[c.notion_id] = c.nombre_empresas;
const cliente_nombre = (n.cliente_notion_id && map[n.cliente_notion_id]) || null;
```

**Dónde ocurrió:** `GjijIDEUyiH05Mg0` (2026-04-21 → 2026-05-08). 300 tareas con `cliente_nombre = NULL` en Bubble + Supabase. Detectado al listar Backlog y ver todas las filas con NULL.

**Aplica a:** cualquier sync que persista campos derivados/denormalizados desde una relación. Si el destino tiene tanto el ID como el nombre, ambos deben mantenerse poblados; el ID solo no es suficiente.

---

### 15. Code node bajo Task Runner: allow-list selectiva (no es "todo `this.*` bloqueado")

**Síntoma:** El Code falla con uno de estos errores específicos según qué API se intenta:
- `TypeError: this.getWorkflowStaticData is not a function`
- `Error: The function "helpers.httpRequestWithAuthentication" is not supported in the Code Node`
- `ReferenceError: fetch is not defined`
- `Error: Module 'https' is disallowed`
- `Error: Module 'crypto' is disallowed`

**Causa:** n8n moderno ejecuta los Code nodes en `JsTaskRunner` (VM aislado en proceso separado). La allow-list es restrictiva PERO **selectiva** — no todos los `this.*` están bloqueados. Verificado con smoke tests directos el 2026-05-24.

**Lo que NO funciona (bloqueado):**
- `this.getWorkflowStaticData(...)` — usar `$getWorkflowStaticData('global')` sin `this.`.
- `this.helpers.httpRequestWithAuthentication(...)` — bloqueado especialmente en runtime sub-workflow (`executeWorkflow` invoke). Puede parecer que funciona en ejecución manual del workflow padre (falso positivo).
- `this.helpers.requestWithAuthentication(...)` — bloqueado por el mismo motivo (no confirmado por test, asumir bloqueado).
- `fetch` global — no existe.
- `require('https')`, `require('crypto')` — módulos bloqueados.

**Lo que SÍ funciona (verificado):**
- `this.helpers.request(opts)` — helper legacy (request-promise). Acepta `simple: false + resolveWithFullResponse: true` y NO lanza en 4xx/5xx.
- `this.helpers.httpRequest(opts)` — helper moderno (axios). Lanza AxiosError en 4xx/5xx pero hace HTTP correctamente.
- `$getWorkflowStaticData('global')` (sin `this.`) — para cache entre ejecuciones.
- `$input`, `$('NodeName').first().json`, `$env.X` — referencias normales.
- `Buffer`, `JSON`, `Date`, sintaxis ES2022, `new Promise(setTimeout)`.

**Patrón correcto para HTTP autenticado en Code (en vez de `httpRequestWithAuthentication`):** mover la autenticación a manual usando `$env` + headers + `this.helpers.request`. Patrón canónico para Supabase:

```javascript
const SUPABASE_KEY = $env.SUPABASE_SERVICE_ROLE_KEY;
if (!SUPABASE_KEY) throw new Error('[X] $env.SUPABASE_SERVICE_ROLE_KEY no esta definido');
const sb = async (opts) => {
  const headers = Object.assign({}, opts.headers || {}, {
    'apikey': SUPABASE_KEY,
    'Authorization': 'Bearer ' + SUPABASE_KEY
  });
  if (opts.body !== undefined && opts.json && !headers['Content-Type']) {
    headers['Content-Type'] = 'application/json';
  }
  const reqOpts = { method: opts.method, uri: opts.url, headers, simple: false, resolveWithFullResponse: true };
  if (opts.json) reqOpts.json = true;
  if (opts.body !== undefined) reqOpts.body = opts.body;
  const resp = await this.helpers.request(reqOpts);
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    throw new Error('Supabase HTTP ' + resp.statusCode + ': ' + JSON.stringify(resp.body).slice(0,300));
  }
  return resp.body;
};
```

Mismo patrón aplicable a Gemini (header `x-goog-api-key`), Anthropic (`x-api-key`), Bubble (`Authorization: Bearer`), etc.

**Patrón alternativo (si no quieres tocar Code):** sacar la operación HTTP a un nodo `HTTP Request` nativo ANTES del Code, dejando el Code solo con transformación de datos. Recomendado para autenticación compleja (OAuth2 refresh, JWT firma local, etc.).

**Caso especial JWT verification:** para verificar firma de JWT entrante NO uses `require('crypto')` ni implementación RSA local (bloqueado). Usa `HTTP Request → https://oauth2.googleapis.com/tokeninfo?id_token=<token>` (Google verifica por ti) o el equivalente del IdP.

**Dónde ocurrió:**
- `8snJvdNsmRM2yI2y` (2026-05-08). 4 iteraciones de patches al jsCode fallidas (`this.getWorkflowStaticData` → `$getWorkflowStaticData` → `fetch` → `require('https').get` → `require('crypto')`) antes de aceptar que la verificación JWT no se puede hacer dentro del Code y refactorizar a tokeninfo via HTTP Request.
- `BqNTrwoQ2iJIcAB4` (2026-05-12). Code `Preparar Payload` usaba `this.helpers.httpRequestWithAuthentication.call(this, 'supabaseApi', opts)` para leer `bub_clientes`. Fallaba con `helpers.httpRequestWithAuthentication is not supported in the Code Node`. Fix: dividir en `Validar Input` (Code) + `GET Cliente` (Supabase node nativo, op `getAll`, filter `notion_id eq`) + `Preparar Payload` (Code, solo armado de payload).
- `NI1oUwIY99TGk496` + `7yjLwl4cEJa7XAYY` + `JI5Tr7IogqXgaI7a` (2026-05-24). 3 workflows Cerebro con Code nodes haciendo `httpRequestWithAuthentication` para Supabase. Cuando el Code corre en sub-workflow vía `executeWorkflow` la restricción se vuelve dura (en ejecución manual del workflow padre a veces parecía pasar — falso positivo). Fix aplicado: helper `sb` manual usando `this.helpers.request` (legacy request-promise, ver patrón canónico en la sección "Patrón correcto" arriba) + headers `apikey` + `Authorization: Bearer $env.SUPABASE_SERVICE_ROLE_KEY`.

**Aplica a:** cualquier Code node nuevo o legacy con `this.*` o HTTP interno. Si revisas Code legacy con esos patrones, marcar para refactor — funcionarán en n8n viejo pero romperán cuando la instancia migre a task runner. Ver memoria `feedback_n8n_task_runner_this.md`.

---

### 17. Lookup en Bubble Data API tras POST reciente → falso negativo por latencia de índice

**Síntoma:** un sync `Buscar Bubble → Decidir → Crear/Actualizar` decide `create` aunque la fila ya existe en Bubble. Resultado: filas duplicadas con mismo `external_id` (notion_id, clickup_id, etc.). Solo afecta a ejecuciones que corren <60s después de una creación previa.

**Causa:** la Bubble Data API tiene latencia de indexado de búsqueda de ~30-60s tras un POST. Un `getAll` con `constraint <external_id> = X` puede devolver vacío aunque el objeto exista. El paso `Decidir Acción` interpreta el vacío como "no existe" → manda a la rama `create` → segunda fila duplicada en Bubble.

**Incorrecto:**
```
Normalizar → Buscar Tarea en Bubble (n8n-nodes-base.bubble, getAll, filter external_id) → Decidir Acción
```

**Correcto:** consultar el espejo Supabase en su lugar. El webhook reactivo `FGxG67I24POOUeHW` (Bubble DB Trigger → upsert `bub_*`) tiene latencia ~1-2s, reduciendo la ventana de race 30×. El `bubble_id` del espejo se usa para los PATCH/DELETE downstream.

```
Normalizar → Buscar Tarea en Supabase (n8n-nodes-base.supabase, table bub_<X>, filter external_id) → Decidir Acción
// Decidir Acción: m.bubble_id (campo espejo) en lugar de m._id (campo Bubble)
```

**Dónde ocurrió:** `GjijIDEUyiH05Mg0` (2026-05-12 → 2026-05-13). Tarea Notion `35ee4743-b0ae-809d-b3e0-dba9d84bc84c` duplicada (2 filas Bubble creadas con 41s de diferencia). Fixed 2026-05-13: lookup migrado a `bub_tareas_notion` (Supabase), Decidir Acción adaptado a `m.bubble_id`.

**Aplica a:** cualquier sync con patrón "external triggers polling → buscar Bubble por external_id → crear si no existe". Auditar como mínimo:
- `eR5SWFkxJmjMT1VI` (SYNC TAREAS — ClickUp → Bubble)
- `FcTmv78nLjbCb2Ea08qbt` (SYNC CLIENTES — Notion → Bubble)
- `SjqnIOJYPAkFMFfW` (SYNC CLIENTES — ClickUp → Bubble)

**No aplica a:** workflows donde el `Buscar` tiene tiempo (>60s) entre ejecuciones del mismo external_id, o donde no existe espejo Supabase con su DB Trigger correspondiente.

---

### 18. Chat IA en n8n con KB grande + tier Anthropic bajo → 429 `rate_limit_error` silencioso

**Síntoma:** un nodo `@n8n/n8n-nodes-langchain.agent` (o el chain Anthropic equivalente) revienta con `NodeOperationError: The service is receiving too many requests from you` y descripción `429 rate_limit_error … This request would exceed your organization's rate limit of N input tokens per minute`. El WIP del chat (`analisis_wip`, `newsletter_wip`, etc.) queda colgado en `estado='analizando'` hasta que el CRON de reset (`V60MieFkQzOszxhh` u otro) lo libere a los 15 min. La rueda del usuario gira en vacío.

**Causa:** los tiers de Anthropic limitan **input tokens por minuto, por modelo**. Tier 1 (5 $ acumulados en compras) = 30k input/min en Sonnet — un único prompt de chat con KB de Drive 15k chars + system prompt grande + historial ya consume 18-22k tokens. Dos peticiones en el mismo minuto rebasan el cubo y la 2ª recibe 429. Tier 2 (40 $) ≈ 80k/min y desbloquea el caso. Tiers 3-4 son para uso multi-miembro / multi-cliente simultáneo.

**Diagnóstico**: en `n8n_executions` con `mode: "error"`, el campo `error.description` cita explícitamente el límite. El mensaje en `primaryError.message` ("The service is receiving too many requests from you") es el wrapper genérico de LangChain y no revela el origen.

**Incorrecto** (parchear como si fuera bug del agente):
- Subir `maxIterations`, añadir retries en el nodo, truncar prompt sin haber confirmado el tier real.

**Correcto:**
1. Confirmar el límite real del cliente en `console.anthropic.com/settings/limits` antes de tocar el workflow.
2. Si el tier es bajo y la causa raíz es coste, subir tier (compras acumuladas hasta el umbral: 5 → 40 → 200 → 400 $).
3. Si el tier no se puede subir, opciones de software: truncar KB del prompt (head + tail con cap N chars), recortar historial a últimos 5 mensajes, o cambiar a un modelo con cubo separado (Haiku para clasificación, Sonnet para generación pesada).
4. `retryOnFail` con `waitBetweenTries: 60000` ayuda en bursts puntuales pero NO resuelve uso sostenido por encima del cubo.

**Dónde ocurrió:** `FFhkdTFCjTtfyvhP` (`IA Análisis — Tool Loop [SUB]`), execution `130773` (2026-05-21). BRIEFING_INICIAL con KB 15 212 chars. Cuenta Anthropic TheNucleo estaba en Nivel 1. Resuelto con upgrade a Nivel 2 (compra 35 $ acumulado a 40 $). Sin tocar el workflow.

**Aplica a:** TODOS los chats IA del Portal (`IA Cerebro — Chat por Cliente` `JI5Tr7IogqXgaI7a`, `IA Newsletter — Entrada` `inWFSAEDLCH1kx5P`, `IA Análisis — Entrada` `dtgF0G35aeJQVVfn`, y sus respectivos tool loops). Y a cualquier nuevo workflow IA que se monte. Antes de declarar "el workflow está roto" tras un error 429, **chequear primero el tier Anthropic activo**.

---

### 19. `n8n-nodes-base.extractFromFile` NO soporta `docx` → operación `text` vuelca el ZIP binario crudo

**Síntoma:** un workflow KB/RAG que lee .docx del Drive (Análisis, Newsletter, Cerebro, futuros) produce un `kb_text` que empieza con `PK\x03\x04\x14\b\b\b…` (firma de fichero ZIP) en vez del contenido textual. Downstream, el agent IA recibe bytes ilegibles y se inventa el contenido — en el caso real escribió literalmente *"el documento del Drive estaba en binario no legible, así que me apoyé en la web pública y mi conocimiento del sector"* y rellenó las 12 secciones del briefing con un cliente popular del sector que el modelo conocía de su training, no del cliente real.

**Causa:** las operaciones soportadas por `n8n-nodes-base.extractFromFile` (typeVersion 1.1) son: `csv`, `html`, `fromIcs`, `fromJson`, `ods`, `pdf`, `rtf`, `text`, `xml`, `xls`, `xlsx`, `binaryToPropery`. **NO existe `docx`**. Si configuras un nodo con `operation: text` y le pasas un .docx (que es internamente un ZIP con XMLs), el nodo intenta leer el buffer como texto plano UTF-8 y devuelve la representación literal de los bytes en `json.data`. El status del nodo es `success` (no error) porque el operation `text` no valida el formato.

**Diagnóstico:** mirar el output del nodo en `n8n_executions` mode `filtered`. Si `json.data` empieza por `PK\x03\x04`, es un .docx (o .xlsx, .pptx, cualquier OOXML) tratado como texto plano.

**Incorrecto:**
```json
{
  "name": "Extraer DOCX",
  "type": "n8n-nodes-base.extractFromFile",
  "parameters": { "operation": "text" }
}
```

**Incorrecto v2 (descartado el mismo 2026-05-21):** usar Code node con `require('jszip')`. El **task runner externo de n8n bloquea TODOS los `require()`** por allow-list (issue [community.n8n.io/t/external-task-runner-ignores-module-allowlist-in-code-node/190145](https://community.n8n.io/t/external-task-runner-ignores-module-allowlist-in-code-node/190145)). Falla con `Module 'jszip' is disallowed [line 10]` — mismo problema que `crypto`, `https`, `xlsx`. Memoria persistente `feedback_n8n_task_runner_this.md`.

**Correcto (v3, activo en producción 2026-05-21):** cadena de 5 nodos nativos, sin `require`. El .docx es un ZIP OOXML; `word/document.xml` contiene los párrafos `<w:p>` con runs `<w:t>texto</w:t>`. Decompresión vía el nodo nativo `n8n-nodes-base.compression`, parseo XML por regex en un Code limpio.

```
Switch (DOCX, output 2)
  → Prep DOCX→ZIP             (Code, renombra binary fileName a .zip + mimeType application/zip)
  → Decompress DOCX           (Compression op decompress, binaryPropertyName=data, outputPrefix=file_)
  → Pick document.xml         (Code, busca binary key que termine en document.xml, re-empaqueta)
  → Read document.xml         (extractFromFile op text, ahora SÍ es XML legible)
  → XML → Texto               (Code, regex w:t + decode entities + re-inyecta meta)
  → Restaurar metadata (idx 1)
```

`Prep DOCX→ZIP`:
```javascript
const item = $input.first();
const b = item.binary && item.binary.data;
if (!b) return [{ json: item.json }];
const fileName = (b.fileName || 'doc').replace(/\.docx?$/i, '.zip');
return [{ json: item.json, binary: { data: { ...b, fileName, fileExtension: 'zip', mimeType: 'application/zip' } } }];
```

`Pick document.xml` — **CUIDADO con las keys**: el nodo Compression `decompress` con `outputPrefix: file_` devuelve UN item con múltiples binary properties llamadas `file_0`, `file_1`, …, `file_20` (índices, NO nombres). El nombre real del archivo dentro del ZIP vive en `item.binary[key].fileName` (`document.xml`, `styles.xml`, …) y la ruta dentro del ZIP en `item.binary[key].directory` (`word`, `word/_rels`, `customXML`, vacío para raíz). Hay que iterar las keys y mirar los metadatos, NO matchear el nombre de la key. **Throw si no encuentra (sin fallback silencioso)** para que el error caiga en `n8n_incidencias`:
```javascript
const out = [];
for (const item of $input.all()) {
  const fileName = (item.json && item.json.file_name) || '<sin nombre>';
  if (!item.binary) {
    throw new Error(`[KB Fetch DOCX] ${fileName}: el item llega sin binary tras Decompress.`);
  }
  const keys = Object.keys(item.binary);
  const docKey = keys.find(k => {
    const b = item.binary[k];
    if (!b) return false;
    const dir = (b.directory || '').replace(/\/+$/, '');
    return b.fileName === 'document.xml' && (dir === 'word' || dir.endsWith('/word'));
  });
  const fallbackKey = docKey || keys.find(k => item.binary[k] && item.binary[k].fileName === 'document.xml');
  if (!fallbackKey) {
    const inventory = keys.map(k => {
      const b = item.binary[k] || {};
      return `${b.directory || ''}/${b.fileName || ''}`;
    }).join(', ');
    throw new Error(`[KB Fetch DOCX] ${fileName}: el ZIP no contiene word/document.xml. Contenido del ZIP: ${inventory}`);
  }
  out.push({ json: item.json, binary: { data: item.binary[fallbackKey] } });
}
return out;
```

`Read document.xml` (extractFromFile op text) se mantiene en `onError: 'stopWorkflow'` (default). Cualquier item llegando sin binary revienta el sub — y eso es lo que queremos: el throw del Pick ya impide ese caso, pero si en futuro se modifica la cadena, queremos enterarnos. Histórico: una versión intermedia (v3b) usó `continueRegularOutput` para apaciguar el revento, pero introdujo comportamiento silencioso (sub success + `kb_text` vacío + `status: 'incluido'`). Descartado: prefiere el revento ruidoso → `errorWorkflow` → `n8n_incidencias`.

`XML → Texto` (regex tolerante a `w<N>:t`, decodifica entities numéricas, throw si texto vacío):
```javascript
const decode = s => s
  .replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
  .replace(/&quot;/g, '"').replace(/&apos;/g, "'")
  .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(parseInt(n, 10)))
  .replace(/&#x([0-9a-fA-F]+);/g, (_, h) => String.fromCharCode(parseInt(h, 16)));

const metaItems = $('Preservar metadata').all();
const out = [];
const items = $input.all();
for (let i = 0; i < items.length; i++) {
  const item = items[i];
  const metaJson = (metaItems[i] && metaItems[i].json) || (metaItems[0] && metaItems[0].json) || {};
  const xml = (item.json && item.json.data) || '';
  if (!xml) throw new Error(`[KB Fetch DOCX] ${metaJson.file_name || '<sin nombre>'}: document.xml leido pero vacio.`);
  const paragraphs = xml.split(/<\/w:p>/);
  let text = '';
  for (const p of paragraphs) {
    const tags = p.match(/<w(?:[0-9]+)?:t[^>]*>([\s\S]*?)<\/w(?:[0-9]+)?:t>/g) || [];
    for (const t of tags) text += t.replace(/<w(?:[0-9]+)?:t[^>]*>/, '').replace(/<\/w(?:[0-9]+)?:t>/, '');
    text += '\n';
  }
  text = decode(text).replace(/\n{3,}/g, '\n\n').trim();
  if (!text || text.length < 20) {
    throw new Error(`[KB Fetch DOCX] ${metaJson.file_name || '<sin nombre>'}: el XML se parseo pero el texto resultante es vacio o demasiado corto (${text.length} chars). Posible variante de namespace XML no contemplada.`);
  }
  out.push({ json: { ...metaJson, text, extract_method: 'compression_xml', extract_chars: text.length } });
}
return out;
```

**Observabilidad obligatoria**: `settings.errorWorkflow: HRDQ9Ju4NAIUV0qyhKzlz` en el sub Y en el padre (`FFhkdTFCjTtfyvhP` cuando aplica) para que los throws caigan en `n8n_incidencias` y `work.thenucleo.com/incidencias`. Sin esto, los throws solo aparecen en el log de executions n8n (UI) y son fáciles de pasar por alto.

**Dónde ocurrió:** `Cfs3NFEE1enu1jTx` (`IA Análisis — KB Fetch [SUB]`). v1 (execution `130747`, 2026-05-21): `extractFromFile` op `text` → ZIP binario crudo en `json.data`. v2-jszip (intento corregir con `require('jszip')`, execution `130847`): task runner bloqueó el require → KB vacío. v2-cadena (primer intento con Compression, execution `130912`): Pick document.xml falsamente no encontraba el archivo porque buscaba en el NOMBRE de la binary key (`file_0`…`file_20`) en vez de en `binary[key].fileName`+`directory`. v3 (Compression + Pick correcto + onError defensivo, activo): valida con docx real de Aquagames. Archivo afectado: `Onboarding __ AquaGames - 2026_05_20… .docx`.

**Aplica a:** cualquier workflow KB/RAG actual o futuro que lea .docx del Drive con `extractFromFile`. **Audit cerrado 2026-05-21** sobre los 61 workflows del Portal: solo Análisis KB Fetch tenía el bug activo. Newsletter (`w6Gqo8B6Sqp6Mq9x`) y Cerebro (`NI1oUwIY99TGk496`) usan arquitectura distinta (suben directamente a Gemini fileSearchStore con `httpRequest`, filtran por mimeType y SOLO aceptan `application/vnd.google-apps.document`, `application/vnd.google-apps.spreadsheet`, `application/pdf`, `text/plain`) — **ignoran .docx silenciosamente** (no lo corrompen, pero tampoco lo indexan). Es un feature gap separado: si un cliente sube material en .docx, Newsletter y Cerebro IA no lo verán. Extender soporte requeriría descargar el .docx, parsearlo con JSZip y subir el texto extraído a Gemini como `text/plain`. Pendiente decidir si se extiende.

Si Bubble pasa también .xlsx, .pptx u otros OOXML, el mismo patrón JSZip funciona (cambia el path interno: `xl/sharedStrings.xml` para xlsx, `ppt/slides/slide*.xml` para pptx).

**No aplica a:** archivos PDF (operation `pdf` SÍ funciona), TXT/MD (`text` SÍ funciona porque son texto plano), JSON (`fromJson`), CSV (`csv`), HTML (`html`).

---

### 20. `$env.X` en `headerParameters.value` de HTTP Request nodes → `[ERROR: access to env vars denied]` en runtime

**Síntoma:** un HTTP Request node con un header tipo `Authorization: ={{ 'Bearer ' + $env.BUBBLE_API_TOKEN }}` muestra en el editor expression el texto `[ERROR: access to env vars denied]` en rojo bajo el campo Value. En runtime, el HTTP request se ejecuta SIN ese header (la expression evalúa a string vacío) → la API destino devuelve 401/403.

**Causa:** n8n self-hosted con `N8N_BLOCK_ENV_ACCESS_IN_NODE=true` (default desde n8n 1.x) **bloquea acceso a `$env.*` desde expressions evaluadas en parámetros de nodos**. La intención es prevenir exfiltración: si un payload externo (webhook untrusted, Form Trigger público) se cuela como expression sin escape, no puede leer env vars.

**Comportamiento observado por tipo de nodo:**
| Nodo | `$env.X` funciona | Por qué |
|---|---|---|
| Code node (jsCode) | ✅ Sí | El sandbox del Code node tiene `$env` siempre disponible — el flag NO afecta a Code nodes |
| HTTP Request `headerParameters.value` | ❌ No | Expression evaluator bloqueado por el flag |
| HTTP Request `url` | ❌ No | Idem |
| HTTP Request `jsonBody` **con cred bindeada** (`predefinedCredentialType` o `genericCredentialType`) | ✅ Sí | Verificado empíricamente en `Uqv3R3txzcg8GI1B`: `={{ $env.AIC_KEY }}` en jsonBody con cred Supabase bindeada funciona. Aparentemente el flag relaja la restricción cuando el node ya tiene auth bindeada — pero NO se ha verificado si funciona en `headerParameters.value` con cred bindeada (no probado) |

**Incorrecto (patches iniciales del 2026-05-24 que fallaron):**
```json
{
  "name": "Authorization",
  "value": "={{ 'Bearer ' + $env.BUBBLE_API_TOKEN }}"
}
```

**Correcto — opción A: cred Generic Header Auth bindeada** (patrón canónico):
```json
{
  "authentication": "genericCredentialType",
  "genericAuthType": "httpHeaderAuth"
}
```
Y bindear cred en UI (ID `IFAeIvEVDbrPBZIW` para Bubble, `fEKYLWb7Vhx4HnNs` para Gemini, etc.). Vía SDK: `credentials: { httpHeaderAuth: { id: 'IFAeIvEVDbrPBZIW', name: 'Bubble API Token' } }`.

**Correcto — opción B: cred predefined (Supabase, Anthropic, etc.)**:
```json
{
  "authentication": "predefinedCredentialType",
  "nodeCredentialType": "supabaseApi"
}
```
Para nodos HTTP que llaman a Supabase REST API, esto bindea la cred Supabase canónica (`13dKSjEd2XZCYpJa`) e inyecta `apikey` + `Authorization: Bearer ...` automáticamente. **No requiere `sendHeaders: true`**.

**Correcto — opción C: Code node intermedio** (para casos donde el secret va al body o se construye dinámicamente):
```js
// Code node antes del HTTP
return [{ json: { ...item, token: $env.BUBBLE_API_TOKEN } }];
```
Luego HTTP node usa `={{ $('Get Token').first().json.token }}` (lee del item del flow, no de $env).

**Workaround NO recomendado:** bajar `N8N_BLOCK_ENV_ACCESS_IN_NODE=false`. Amplía superficie de exposición a inyección via expressions evaluadas — no aceptado en TheNucleo (decisión 2026-05-24).

**Dónde ocurrió:**
- `UBYXNKZ1HHFTZyDX` (`IA Newsletter — Init`): 7 nodos HTTP Supabase + 1 Gemini con `apikey` + `Authorization: Bearer ={{ $env.SUPABASE_SERVICE_ROLE_KEY }}` en headers → fix: Supabase con `predefinedCredentialType: supabaseApi`, Gemini con cred httpHeaderAuth bindeada ID `fEKYLWb7Vhx4HnNs`.
- `8snJvdNsmRM2yI2y` (`OPS LOG — Mensajes Google Chat (Pub/Sub)`): 3 nodos HTTP Bubble con `Authorization: Bearer ={{ 'Bearer ' + $env.BUBBLE_API_TOKEN }}` → fix: cred httpHeaderAuth bindeada ID `IFAeIvEVDbrPBZIW`.
- `SfwR7gqs1hBIOV7i` (`IA Newsletter — Tool Loop [SUB]`): NO afectado porque su `$env.SUPABASE_SERVICE_ROLE_KEY` + `$env.GEMINI_API_KEY` viven dentro del Code `Process Tools` (jsCode), no en expression de HTTP node. Patch con `$env` es válido y se mantiene activo.

**Lección general:** si necesitas un secret en un HTTP Request node, usa cred bindeada (opciones A/B) — NUNCA `$env.X` en `headerParameters.value` ni en `url`. Si necesitas el secret en un Code node, `$env.X` en jsCode SÍ funciona. Aplica a Code de cualquier sub-workflow incluyendo workflows bajo Task Runner.

**Diagnóstico futuro:** si un workflow patcheado con `$env` en HTTP empieza a devolver 401/403 de la API destino tras un push reciente, revisar primero si el editor de n8n muestra `[ERROR: access to env vars denied]` en rojo bajo el campo. Es el indicador inequívoco.

---

## Historial de fixes críticos

### 2026-05-24 — Audit secrets Portal: 3 outliers IA con secrets hardcoded + pivot a cred bindeada

**Contexto:** tras la rotación de Gemini API key del mismo día (entrada principal del log), audit completo de los workflows del Portal buscando otros secrets hardcoded similares. Cobertura: 24/50 workflows, 100% IA + 100% ADS + muestreo SYNCs/CRONs/OPS antiguos.

**Outliers identificados (3 totales, todos del mismo origen — código pre-mayo antes de la disciplina `$env vars + cred bindeada`):**

1. **`SfwR7gqs1hBIOV7i`** (`IA Newsletter — Tool Loop [SUB]`) — Code `Process Tools` con **SUPABASE service_role JWT completo** (`eyJ...ZgRskYaJJn_VuMiMiyBZDhl7o0SsvKazbF8LacvCQRQ`) + **Gemini key vieja revocada** (`AIzaSyBWk-...`) hardcoded en las primeras líneas. Severidad CRÍTICA (bypass total RLS).
2. **`UBYXNKZ1HHFTZyDX`** (`IA Newsletter — Init`) — 7 nodos HTTP Supabase con `apikey` + `Authorization: Bearer eyJ...` hardcoded en `headerParameters` + 1 nodo Gemini con `?key=AIzaSyBWk-...` en URL. Severidad CRÍTICA (mismo JWT compartido).
3. **`8snJvdNsmRM2yI2y`** (`OPS LOG — Mensajes Google Chat (Pub/Sub)`) — 3 nodos HTTP Bubble con `Authorization: Bearer 088a20b5...` (Bubble API token) hardcoded en headers. Severidad MEDIA (Bubble token, no Supabase JWT).

**Fix aplicado (todos vía SDK MCP preservando webhookIds):**
- `SfwR7gqs1hBIOV7i`: `$env.SUPABASE_SERVICE_ROLE_KEY` + `$env.GEMINI_API_KEY` en el Code → ✅ funciona (Code nodes leen $env sin problema).
- `UBYXNKZ1HHFTZyDX` y `8snJvdNsmRM2yI2y`: **primer intento con `$env` en `headerParameters.value` FALLÓ** (anti-patrón #20 — `[ERROR: access to env vars denied]`). Rollback inmediato a versionIds anteriores. **Pivot al patrón canónico** (cred bindeada):
  - Ben creó 2 creds Header Auth en n8n UI: `Bubble API Token` (id `IFAeIvEVDbrPBZIW`) y `Gemini API Key` (id `fEKYLWb7Vhx4HnNs`).
  - Re-patch con SDK pasando `credentials: { httpHeaderAuth: { id, name } }` explícito.
  - 7 nodos Supabase de NL Init usan `predefinedCredentialType: supabaseApi` pero SDK no auto-asigna → Ben las bindeó en UI manualmente (1 click por nodo).

**activeVersionIds finales:**
- `SfwR7gqs1hBIOV7i = 0e116979-8d69-422e-9172-7ab6afa1de10` (rollback: `d6d7471a-...`)
- `UBYXNKZ1HHFTZyDX = 29fd0f99-598b-4fff-8486-080f30f590e1` (rollback: `e129bcdc-...`)
- `8snJvdNsmRM2yI2y = 5ceffae5-15e2-46a8-a48f-f677db2a00cb` (rollback: `711a9f4a-...`)

**No-action sobre rotación JWT Supabase:** el JWT vivo `eyJ...ZgRsk...` siguió en histórico git del backup repo `marketingthenucleo/n8nthenucleo` (privado, solo Ben). Decisión 2026-05-24: NO rotar — repo backup privado, blast radius limitado. Si en el futuro se hace público o gana colaboradores externos, rotar entonces.

**Workflows restantes sin auditar (~26):** SYNCs Notion/ClickUp/Bubble bidireccionales, CRONs reconciliación, OPS Tareas backfills, INTEGRACIONES F1 multi-provider sub-workflows, ERRORES. Riesgo estimado bajo: los 24 auditados (= mayor vector de riesgo IA + ADS + 4 SYNCs/CRONs antiguos) muestran consistentemente el patrón canónico (cred bindeada o `$env.AIC_KEY + aic_get_with_key`). Deferir audit a próxima sesión.

**Lección:** ver lección 20 ("$env.X en headerParameters.value de HTTP nodes → access denied"). Lección operativa adicional: para workflows complejos con webhook trigger + cred httpHeaderAuth, el SDK MCP **preserva `webhookId`** si se pasa explícito en `config.webhookId` del trigger node, y **preserva cred bindeada** si se pasa explícito en `config.credentials` con `{ id, name }` de la cred. Validado E2E hoy. Esto deroga la prudencia documentada el día anterior ("workflow muy complejo, mejor manual UI") — el SDK es seguro con cuidado de pasar IDs.

### 2026-05-12 — Fix `helpers.httpRequestWithAuthentication` en Reindexar RAG Manual
**Contexto:** ejecución `119925` del workflow `BqNTrwoQ2iJIcAB4` (`IA Cerebro — Reindexar RAG Manual [WEBHOOK]`) falló al disparar reindex desde Bubble. Payload: `cliente_notion_id=31de4743-b0ae-8165-aa1c-c14e6387385c` (Actualizate Psicología), `agencia_id` TheNucleo.

**Causa:** el Code `Preparar Payload` hacía la lectura de `bub_clientes` con `this.helpers.httpRequestWithAuthentication.call(this, 'supabaseApi', opts)`. El task runner bloquea ese helper en Code nodes — anti-patrón #15 ya documentado. Error: `The function "helpers.httpRequestWithAuthentication" is not supported in the Code Node`.

**Fix:** refactor del workflow vía `n8n_update_partial_workflow` (8 ops). Estructura nueva:
- `Webhook` → `Respond 200` (paralelo) + `Validar Input` (Code, sin HTTP)
- `Validar Input` → `GET Cliente` (Supabase node nativo, op `getAll`, table `bub_clientes`, filter `notion_id eq {{ $json.cliente_notion_id }}`, cred `pmc312jjJKdPClmj` auto-asignada por tipo)
- `GET Cliente` → `Preparar Payload` (Code, ahora solo arma el payload desde `$('Validar Input')` + `$json`)
- `Preparar Payload` → `Ejecutar Indexacion` (sin cambios)

**Validación:** ejecución `119932` (748 ms, 6/6 nodos success). GET Cliente devolvió Actualizate Psicología con `link_drive` correcto, subworkflow `NI1oUwIY99TGk496` disparado en background.

**Lección:** el anti-patrón #15 sigue presente en workflows legacy. Cualquier Code que ataque `this.helpers.*` debe migrarse a "HTTP/Supabase node ANTES + Code que lee `$('Node').first().json` DESPUÉS". Ver memoria `feedback_n8n_task_runner_this.md`.

### 2026-05-13 — Fix duplicados en sync Notion → Bubble (lookup contra Supabase)
**Contexto:** tarea Notion "PROBAR FORM DE LA WEB" (`35ee4743-b0ae-809d-b3e0-dba9d84bc84c`) aparecía en Bubble en columna `Backlog` aunque en Notion estaba en `Listo`. Investigación reveló 2 filas en `tareas_notion` con el mismo notion_id: `bubble_id=1778603984900x…` (estado=`Listo`, actualizada hoy) y `bubble_id=1778604025071x…` (estado=`Backlog`, huérfana desde 2026-05-12 16:40). Ambas creadas con 41s de diferencia ese mismo día.

**Causa raíz:** el nodo `Buscar Tarea en Bubble` (Bubble Data API `getAll` filter `notion_id`, limit 1) sufre de **latencia de indexado de búsqueda** de la Data API de Bubble (~30-60s tras un POST). Cuando los dos Notion Triggers (`pageAddedToDatabase` + `pagedUpdatedInDatabase`) capturan la misma tarea en minutos consecutivos (típico: alta + edición inmediata), la segunda ejecución no ve la fila creada por la primera → decide `create` → duplicado. El nodo `Decidir Acción` con `limit:1` siempre coge la misma fila en las ejecuciones futuras → la otra queda congelada y el kanban Bubble la muestra en su estado obsoleto.

**Cambios:**
- **Workflow modificado:** `GjijIDEUyiH05Mg0` — reemplazado nodo `Buscar Tarea en Bubble` por `Buscar Tarea en Supabase` (nodo nativo `n8n-nodes-base.supabase`, table `bub_tareas_notion`, filter `notion_id eq {{$json.notion_id}}`, limit 1, `alwaysOutputData: true`, credencial `pmc312jjJKdPClmj`). Adaptado Code `Decidir Acción` para leer `m.bubble_id` (Supabase) en lugar de `m._id` (Bubble) — única diferencia funcional, resto de lógica intacta. Vía `n8n_update_partial_workflow` (5 ops atómicas: removeNode + addNode + 2 addConnection + updateNode).
- **Workflow temporal one-shot:** `A5l8tUqebI91uTS3` (`FIX TAREAS — Borrar Duplicado bubble_id huerfano [MANUAL]`) — webhook `/fix-borrar-duplicado-tarea` + Bubble delete `tareas_notion/1778604025071x227539385650226600`. Ejecutado 1 vez (200 OK), workflow desactivado.
- **Limpieza espejo:** `DELETE FROM bub_tareas_notion WHERE bubble_id='1778604025071x227539385650226600'` (necesario porque `FGxG67I24POOUeHW` solo propaga INSERT/UPDATE desde Bubble, no DELETEs).

**Por qué Supabase como fuente del lookup:** el espejo `bub_tareas_notion` se actualiza vía webhook reactivo `FGxG67I24POOUeHW` disparado por DB Trigger Bubble al insertar/actualizar; latencia ~1-2s. La ventana de race se reduce de ~30-60s a ~1-2s (30× más estrecha). No es cero — sigue habiendo una ventana mínima — pero suficiente porque el polling Notion son ciclos de 60s, mucho más espaciados.

**Lección — nuevo anti-patrón #17 (latencia indexado Bubble Data API):** cualquier sync que `Buscar→Decidir Acción→Crear/Actualizar` consultando Bubble Data API tras un POST reciente puede sufrir falsos negativos por la latencia del índice de búsqueda. Solución estándar: que el `Buscar` consulte la fuente consistente más rápida disponible (Supabase espejo si existe, mantenido por `FGxG67I24POOUeHW`). Aplica también a `eR5SWFkxJmjMT1VI` (SYNC TAREAS — ClickUp → Bubble), `FcTmv78nLjbCb2Ea08qbt` (SYNC CLIENTES — Notion → Bubble) si presentan el mismo patrón "Buscar Bubble por external_id" — pendiente auditar.

### 2026-05-08 — Fix `agencia_id` NULL en sync Notion → Bubble (sibling)
**Contexto:** descubierto en la misma sesión del fix de `cliente_nombre`. Mismo workflow (`GjijIDEUyiH05Mg0`), mismo corte temporal (2026-04-21 11:20). Detectado al filtrar en Bubble por `agencia_id = Current User's agencia_id's Uuid Supabase` y no obtener resultados — la tarea "Programar email de venta" (Dra. Camino, Bloqueadas, fecha 2026-05-07) existía en `bub_tareas_notion` pero su `agencia_id = NULL`.

**Cambios:**
- **Workflow modificado:** `GjijIDEUyiH05Mg0` — añadida property `agencia_id` constante (`e748c7d4-5823-413d-8cb3-532896f6e41d`, uuid_supabase de TheNucleo) en `Crear` y `Actualizar Tarea en Bubble`. Vía `n8n_update_partial_workflow` (2 ops, `parameters.properties.property` array completo).
- **RPC:** `public.backfill_agencia_id_pendientes()` — devuelve `(bubble_id, agencia_id constante)` para 303 candidatos.
- **Workflow nuevo:** `2Rt6xK2jQfh7VhA5` (`OPS TAREAS — Backfill agencia_id [MANUAL]`).

**Lección reforzada:** el anti-patrón #14 (campo derivado/constante olvidado en sync) golpea en cascada — cuando se descubre un caso, conviene auditar TODO el payload contra el schema destino antes de cerrar. En este sync quedan campos potencialmente afectados por la misma omisión: `aprobador_*`, `observadores_*`, `incidencia`, `bloqueado_por_ids`, `bloqueando_ids` (pendiente confirmar uso real).

### 2026-05-16 — ALLOWED_TABLES 23→25 (espejo Notificaciones)
**Contexto:** módulo Notificaciones (`Notificacion` + `Notificacion_Receptor` en Bubble, MVP funcional desde 2026-05-15) vivía solo en Bubble. Sin espejo Supabase, bloqueada analítica y lookups n8n vía service_role.

**Cambios:**
- **Workflow modificado:** `FGxG67I24POOUeHW` (SYNC ESPEJO — Bubble → Supabase) — `ALLOWED_TABLES` 23 → 25 (añadidas `bub_notificacion`, `bub_notificacion_receptor`). Vía `n8n_update_partial_workflow` con `patchNodeField` sobre `parameters.jsCode`. Credenciales del HTTP Request "Upsert Supabase Mirror" preservadas (`13dKSjEd2XZCYpJa` — bug `update_workflow borra creds` evitado por usar patch quirúrgico).
- **Supabase:** migración `create_bub_notificacion_mirror_tables`. Convención `bub_*` estándar (`bubble_id text PK`, `_synced_at` con trigger, RLS ON, GRANT `service_role`). Índices GIN sobre `destinatarios` para queries por receptor.

**DB Triggers Bubble activos desde 2026-05-16:** uno por Data Type ("A Notificacion is modified" + "A Notificacion_Receptor is modified") → API Connector `sync_bubble_mirror` con `body.tabla` correspondiente + `body.bubble_id = X now's unique id`.

### 2026-05-08 — Fix `cliente_nombre` NULL en sync Notion → Bubble + backfill 300 tareas
**Contexto:** desde el 2026-04-21 (cuando se rehizo el workflow `GjijIDEUyiH05Mg0`) las tareas creadas/editadas en Notion guardaban `cliente_nombre = NULL` en Bubble y, por replicación, en `bub_tareas_notion`. 300 filas afectadas. Detectado al pedir un listado de Backlog 4-6 mayo y ver `cliente_nombre = NULL` en todas.

**Causa raíz:** el nodo `Normalizar Tarea de Notion` extrae `cliente_notion_id` (la propiedad relation de Notion solo trae el ID), pero ningún paso resolvía el nombre del cliente. Los nodos `Crear` y `Actualizar Tarea en Bubble` no incluían `cliente_nombre` en el payload.

**Cambios:**
- **Workflow modificado:** `GjijIDEUyiH05Mg0` (SYNC TAREAS — Notion → Bubble) — añadido nodo `Listar Clientes Bubble` (getAll typeName `clientes`, executeOnce, alwaysOutputData) re-ruteado entre `Listar Users Bubble` y `Decidir Acción`. `Decidir Acción` construye `clienteNombreByNotionId[c.notion_id] = c.nombre_empresas` y emite `cliente_nombre`. `Crear` y `Actualizar Tarea en Bubble` añaden la property `cliente_nombre`. Vía `n8n_update_partial_workflow` (6 ops, creds preservadas). Versión `f81b9189`.
- **RPC Supabase:** `public.backfill_cliente_nombre_pendientes()` (RETURNS TABLE `bubble_id text, cliente_nombre text`, SECURITY DEFINER, GRANT a service_role).
- **Workflow nuevo:** `rONvzi9sdbFvgYYo` (`OPS TAREAS — Backfill cliente_nombre [MANUAL]`) — Manual Trigger → HTTP Request RPC → Bubble update. Inactivo, manual, reutilizable.

**Anti-patrón observado (n8n PostgREST RPC):** la primera ejecución del workflow backfill incluía un Code node intermedio "Split Items" que asumía que el output de la RPC venía como `{body: [...]}` o `{data: [...]}`. Falso: el HTTP Request de n8n auto-splitea el array PostgREST en N items individuales. El Code node procesaba `$input.first().json = {bubble_id, cliente_nombre}` y devolvía `[]` por cada item. Solución: eliminar el Code; conectar RPC directo al PATCH. Lección: cuando una RPC devuelve `RETURNS TABLE`, n8n entrega cada fila como item — no añadir splitter.

**Resultado:** ejecución `114871` (97 s, 300 PATCHes success). Verificado en Supabase: tareas con `cliente_notion_id` ✅ y `cliente_nombre` ❌ pasaron de **300 → 0**. 59 huérfanas restantes son legacy sin `cliente_notion_id` (no recuperables, ortogonales al bug).

### 2026-05-07 — Nuevo workflow OPS LOG + ALLOWED_TABLES a 23 tablas
**Contexto:** captura automática de logs operativos por cliente desde espacios de Google Chat. Detalle completo en [[google-chat-log|docs/google-chat-log]].

**Cambios:**
- **Workflow nuevo:** `xzNDkDNiUOYOA2Ku` (`OPS LOG — Captura desde Google Chat`) — skeleton inactivo. Tag `portal` aplicado vía REST API (PUT `/workflows/{id}/tags`, MCP `addTag` sigue roto).
- **Workflow modificado:** `FGxG67I24POOUeHW` (`SYNC ESPEJO — Bubble → Supabase`) — `ALLOWED_TABLES` 22 → 23 (añadida `bub_actividad_diaria_log`). Vía `n8n_update_partial_workflow` con `patchNodeField`.
- **Supabase:** tabla nueva `bub_actividad_diaria_log` (creada como `bub_log_tareas` y renombrada en la misma sesión a propuesta de Ben para evitar confusión con `bub_tareas_notion`) + campo nuevo `bub_clientes.gchat_space_id`.

**Pendiente Ben:** crear Bubble Data Type `actividad_diaria_log` y campo `gchat_space_id` en Cliente, configurar Google Chat App + service account, y rellenar mapping `gchat_space_id` por cliente.

### 2026-05-04 — SYNC ABSOLUTO ampliado a 22 tablas (sistema Addons)
**Contexto:** F1 del sistema de Addons + Onboarding requería sincronizar 3 tablas Bubble nuevas (`Addons_Catalogo`, `Addons_Agencia`, `Addons_Codigos_Descuento`) a Supabase.

**Workflow modificado:** `FGxG67I24POOUeHW` (SYNC ABSOLUTO) — array `ALLOWED_TABLES` del nodo "Validar Payload" ampliado de 19 → 22 entradas (añadidas `bub_addons_catalogo`, `bub_addons_agencia`, `bub_addons_codigos_descuento`). Vía SDK n8n con `update_workflow` + `publish_workflow`.

**Tablas espejo creadas en Supabase** (proyecto `cbixhqjsnpuhcrcjppah`): convención estándar `bub_*` con campos sistema Bubble (`bubble_id` PK, `creator_id`, `modified_date`, `created_date`) + `_synced_at` + trigger `trg_set_synced_at`.

**Issues encontrados durante validación end-to-end:**
1. Bubble Data API devuelve **404 "Type not found"** si los Data Types están en versión TEST pero el workflow apunta a LIVE. Workaround: deploy Bubble TEST→LIVE. (TODO opcional: hacer workflow detect version-aware leyendo `bubblegroup.workflow.app_version` del header `baggage`.)
2. Field con **TAB invisible al final del nombre** (`campos_credenciales_json\t`) → tras el normalize del workflow queda como `campos_credenciales_json_` y el upsert a Supabase falla con "column not found in schema cache". Renombrar el field en Bubble lo resuelve.
3. Bubble bulk import **NO mapea al built-in `Slug`** — solo a fields custom. Crear field custom `slug` (text) en cada Data Type que necesite slug.
4. Bubble Data API **omite fields vacíos** del response — si un field no tiene valor, no aparece en el JSON, no se sincroniza.

**Resultado:** 34 addons + 1 código descuento sincronizados correctamente a `bub_addons_*` con todos los fields esperados.

### 2026-04-17 — Auditoría completa sync tareas
**Contexto:** tareas en Notion=Listo aparecían Backlog en Bubble por días/semanas.

**Workflows modificados:**
- `gKhvS7eP1B169bhbtc44a` (SYNC trigger): añadido nodo `GET Bubble por notion_id` antes de `Preparar objeto Bubble` para prevenir duplicados en CREATE.
- `aX4Zo7SCTl45R4H5` (Reconciliación):
  - Query Notion sin cap de paginación (1000 → sin límite) + sort `last_edited_time DESC`
  - Cron de 3h → **30 min**
  - Normalizar tareas Notion: `$input.first()` → `$input.all().flatMap(...)` (bug #1)
  - Preparar upsert: añadido `synced_at` + `sync_status` (bug #3)
  - PATCH/CREATE Bubble: añadido `last_local_edit` (bug #5)

**Limpieza one-shot en Bubble:**
- Borrados 41 duplicados de `tareas_notion` (mismo notion_id en varias filas)
- Creadas 9 tareas faltantes en Bubble que solo existían en Supabase

**Resultado:** corrida de Reconciliación pasó de detectar 6 desfases (sobre 100 comparadas) a **430 desfases** (sobre 1232 comparadas) en una sola corrida. Sistema ahora alinea 100% de tareas cada 30 min.

**Backups:** `C:/tmp/wf_sync_tareas_BACKUP.json`, `C:/tmp/wf_recon_pre_norm.json`.
- **Timeouts Bubble:** Bubble espera máx 30s en webhooks sincrónicos → si el proceso es más largo, usar patrón async (respuesta inmediata + polling)

### 2026-04-24 — Huérfanas en bucle infinito por 404 no tolerado
**Contexto:** el cron `ZqccS38F2Lz8WFwX` (huérfanas cada 3h) fallaba 10+ ejecuciones consecutivas en la misma fila del espejo `bub_tareas_notion` (bubble_id `1775547010855x261429236250644740`). El registro ya no existía en Bubble pero sí en el espejo → DELETE Bubble devolvía 404 → aborto → DELETE espejo nunca corría → zombie permanente.

**Causa raíz:** círculo vicioso del propio cron. Una corrida anterior borró de Bubble pero falló al borrar del espejo. Las siguientes corridas encuentran un bubble_id que ya no existe en Bubble, abortan con 404, y nunca llegan a limpiar el espejo.

**Fix aplicado (workflow `ZqccS38F2Lz8WFwX`):**
- `DELETE Bubble tareas_notion`: añadido `onError: "continueRegularOutput"`. Ahora el 404 se trata como éxito semántico y el flujo continúa al DELETE del espejo.
- `IF tiene bubble_id?`: saneado operador unary `notEmpty` (añadido `singleValue: true`). Bug de forma preexistente que el validador estricto de n8n-mcp bloqueaba en el guardado. Comportamiento en runtime idéntico.

**Por qué no hace falta reconciliación Bubble→espejo:** Bubble no permite borrar tareas manualmente desde el portal. El único camino legítimo de delete es Notion → huérfanas cron → Bubble + espejo. Con el fix del onError, los espejo-zombies se auto-sanan en la siguiente corrida sin necesidad de diff adicional.

**Verificación:** esperar a la siguiente corrida automática o pulsar "Ejecutar Manualmente" en el workflow. La fila zombie debe desaparecer de `bub_tareas_notion` y el loop continuar con el resto de huérfanas.

**Anti-patrón asociado:** #10 (DELETE/limpieza dentro de loop sin `onError: continueRegularOutput`).

### 2026-04-26 — Blog Zenyx muere por `JSON.parse` con comillas sin escapar
**Contexto:** workflow `CNlBtiFCwY69I6Wl` (Blog Zenyx — DIARIO 18:00 Madrid) llevaba semanas activo publicando 1 post/día. Ejecución `104650` falló en `Parse Claude and Build Markdown` con `SyntaxError: Expected ',' or '}' after property value in JSON at position 3025`. Diagnóstico: Claude había generado `tienes tres líneas antes del "ver más"` dentro del campo `markdown_body` y las comillas dobles literales rompieron el `JSON.parse`. Fallo intermitente por diseño del contrato.

**Causa raíz:** el contrato Claude→parser pedía un objeto JSON `{ title, slug, excerpt, markdown_body }` donde `markdown_body` es prosa larga. Pedirle a un LLM que escape comillas dentro de strings JSON nunca es 100% fiable; tarde o temprano cuela una `"` literal y el parse muere.

**Fix aplicado (workflow `CNlBtiFCwY69I6Wl`, vía `update_workflow` SDK):**
- `Claude Generate Article` → system prompt sección OUTPUT: cambiado de JSON schema a tags XML (`<title>`, `<slug>`, `<excerpt>`, `<markdown_body>`).
- `Parse Claude and Build Markdown` → sustituido `JSON.parse(cleaned)` por extracción regex `<tag>([\s\S]*?)</tag>` con función `pick(tag)`. Resto del nodo (slug normalize, frontmatter, return) sin cambios.
- `Build Claude Prompt` → texto del prompt cambia de "en JSON con el schema indicado" a "siguiendo el formato XML indicado".

**Verificación:** ejecución `104653` procesó el Ep.09 (Luis Garau) con múltiples comillas dobles dentro del cuerpo (`"No tengo tiempo para crear contenido"`, `"ver más"`, `"Sobre nosotros"`) sin error. Post commiteado en [`marketingthenucleo/thenucleo-landing@8002abd`](https://github.com/marketingthenucleo/thenucleo-landing/commit/8002abdcb1ecb3198f456849dcbcca3963ff808a) y row marcado publicado en `blog_videos`.

**Nota operativa SDK:** el `update_workflow` reemplaza completamente el workflow desde código y cambia los IDs internos de los nodos (ej: `cd00be92` → `351373ea`). Las credenciales se mantuvieron vinculadas igualmente — la ejecución funcionó sin reconectar — pero el riesgo de credencial perdida existe siempre con esta vía. Recomendado: cambios pequeños en producción se hacen mejor en la UI; el SDK solo si el cambio toca >1 nodo o el contrato entre nodos.

**Anti-patrón asociado:** #11 (`JSON.parse` sobre output Claude con prosa larga).

### 2026-05-02 — Notion Triggers sin `retryOnFail` → ruido por 502 transitorios

**Contexto:** workflow `FcTmv78nLjbCb2Ea08qbt` (SYNC Cliente Notion → Bubble) acumulaba ~10 ejecuciones error en 4 días (107993, 107802, 107800, 107777, 106685, …). Todas con el mismo patrón: nodo `Notion - Se agrega modifica un nuevo cliente` falla con `Bad gateway - the service failed to handle your request` (Cloudflare → Notion API) o `The connection was aborted, perhaps the server is offline`, `itemCount: 0`, `executionTime: 0`. Tasa real ~0.17% sobre ~5.760 polls del minuto. Cada error disparaba `HRDQ9Ju4NAIUV0qyhKzlz` y generaba ruido en `n8n_incidencias` / panel `/incidencias`.

**Causa raíz:** los Notion Triggers polleando cada minuto contra una API pública con SLA imperfecto. Cualquier 5xx esporádico de Cloudflare/Notion marca la ejecución como error sin posibilidad de reintento por defecto.

**Fix aplicado (vía `n8n_update_partial_workflow`):** activado en ambos Notion Triggers del workflow:
```
retryOnFail: true
maxTries: 3
waitBetweenTries: 2000
```

**Por qué no se pierden datos:** los polls fallidos NO avanzan el cursor interno `lastTimeChecked` del Notion Trigger (el HTTP a Notion devuelve 502 antes de entregar items). El siguiente poll exitoso vuelve a consultar con la misma marca temporal y recoge todo lo modificado en el intervalo "perdido". Verificado tras el fix: 74/74 clientes con `notion_id` en `bub_clientes`, 0 huérfanos en `bub_tareas_notion.cliente_notion_id`, último sync exitoso 30/04 19:58.

**Aplica a:** todos los workflows con `notionTrigger`, `gmailTrigger`, `httpRequest` polling, etc. Si la fuente externa puede dar 5xx esporádicos, el trigger necesita `retryOnFail` para no inflar el dashboard de incidencias con falsos positivos.

### 2026-05-02 — Reconciliación huérfanas: HTTP a Notion sin timeout y sin retry → cron bloqueado 5 minutos por una sola página

**Contexto:** ejecución 107811 (01/05 16:00) del cron `ZqccS38F2Lz8WFwX` (Reconciliación Tareas — huérfanas, cada 3h) abortó con `ECONNABORTED` tras `timeout of 300000ms exceeded`. El nodo `Notion: GET pagina` (HTTP Request, no el nodo Notion oficial) hizo GET a `/v1/pages/33ee4743-...` y se quedó esperando 5 minutos antes de abortar. Como está dentro de un `splitInBatches` de hasta 1000 tareas, un solo timeout aborta toda la reconciliación.

**Causa raíz:** dos defectos combinados:
1. **Timeout heredado por defecto = 300000ms (5 min)** — n8n-core asigna 5 min cuando no se especifica `parameters.options.timeout`. Notion responde típicamente <1s; 5 min es absurdo y agrava cualquier blip transitorio.
2. **Sin `retryOnFail`** — un único intento; si Notion falla en ese momento, el cron entero muere.

**Fix aplicado (vía `n8n_update_partial_workflow`):**
```
parameters.options.timeout: 30000   // 30s en vez de 5min
retryOnFail: true
maxTries: 3
waitBetweenTries: 2000
```

**Por qué NO se añadió `onError: continueRegularOutput`:** el flujo posterior es `IF eliminada o archivada?` que dispara `DELETE Bubble + DELETE espejo` cuando la página no existe en Notion. Si `Notion: GET pagina` continuara con item vacío tras un timeout, el IF podría evaluar TRUE (página "missing") y borrar tareas reales por error de red. El balance correcto es: reintenta los blips (cubre 99%), y en el 1% restante abortar es preferible a borrar datos vivos.

**Aplica a:** cualquier nodo `httpRequest` que: (a) llame a una API externa con SLA imperfecto, (b) esté dentro de un loop, y (c) alimente lógica de borrado downstream. Combinar siempre `retryOnFail` + `timeout` razonable. Si el siguiente nodo es destructivo, **no** añadir `continueRegularOutput`.

### 2026-05-04 — Reconciliación huérfanas: IF leía `$json.statusCode` (no existe) → páginas Notion purgadas nunca se limpiaban

**Contexto:** Ben detectó comparando UI Bubble vs Notion que la tarea "Elaboración de Videos" (`33ae4743-b0ae-819e-8232-d60ffa8a6c8b`) seguía en `bub_tareas_notion` con estado "Backlog" pese a haber sido purgada de Notion el 2026-04-10 (404 confirmado vía Notion MCP). El cron `ZqccS38F2Lz8WFwX` se ejecutaba sin errores cada 3h y limpiaba otras huérfanas correctamente, pero esta y muchas otras purgadas se acumulaban indefinidamente.

**Causa raíz:** el nodo `IF eliminada o archivada?` tenía 3 condiciones OR:
- `$json.statusCode == 404`
- `$json.archived == true`
- `$json.in_trash == true`

Las dos últimas funcionaban (páginas archivadas / en papelera de Notion devuelven el page object con esos flags). La de 404 jamás matcheaba: el nodo HTTP Request `Notion: GET pagina` tiene `neverError:true` pero no `fullResponse:true`, así que el output es solo el body de la respuesta. n8n NO añade `statusCode` al `$json` en ese modo. El error 404 de Notion devuelve `{"object":"error","status":404,"code":"object_not_found",...}` — el campo es `status`, no `statusCode`. Bug latente desde la creación del workflow (2026-03-02).

**Fix aplicado (vía `update_workflow` SDK):** cambio quirúrgico en el IF, condición `cond-404`:
- de: `leftValue: "={{ $json.statusCode }}"`
- a: `leftValue: "={{ $json.status }}"`

Resto del workflow intacto (mismas IDs de nodo, typeVersions, credenciales, posiciones). Publicado a producción versionId `817cdb97-bd97-43aa-9bf7-442594c78056`.

**Cómo verificar:** ejecución manual del workflow → debe registrar `eliminada_huerfana` para `33ae4743-b0ae-819e-8232-d60ffa8a6c8b` y otros notion_ids purgados, y borrar las filas correspondientes de `bub_tareas_notion` y de la Data Type `tareas_notion` en Bubble.

**Aplica a:** ver anti-patrón #13. Cualquier IF que chequee status code sobre HTTP Request con `neverError:true` debe usar el campo de status que la API devuelve dentro del body, no `$json.statusCode` (que solo existe si `fullResponse:true`).
