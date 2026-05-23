---
title: Bubble API Connectors
dominio: bubble
estado: activo
actualizado: 2026-05-14
tags: [bubble, api, frontend]
---

# Bubble API Connectors — TheNucleo

**Estado:** auditoría completa — 59/59 calls auditadas (2026-05-14).
**Total:** 59 calls en 12 grupos activos (verificado en panel Bubble 2026-05-14, tras cleanups "estados flujos" + "Gestion plantillas" + `POST_MESSAGE`). **Todas auditadas**, incluido grupo 14 Control de Campañas (2026-05-14).
**Base URL canónica (destino):** `https://cbixhqjsnpuhcrcjppah.supabase.co` (cbi).
~~**Base URL legacy (en sunset):** `https://mawpgbtdvskmneqqcqag.supabase.co` (maw)~~ — proyecto **INACTIVE** desde mayo 2026. Cualquier call que aún apunte aquí está rota.
**Auth header Supabase:** `Authorization: Bearer {anon_key}` + `apikey: {anon_key}`

### Estado migración maw → cbi (2026-04-25)

| Grupo                                                                                                                         | Estado                                                                                                                                                                                   |
| ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Análisis Cliente                                                                                                              | ✅ Nativo cbi (siempre estuvo allí)                                                                                                                                                       |
| Supabase - Graficos Horas (Clockify)                                                                                          | ✅ Migrado a cbi (2026-04-25)                                                                                                                                                             |
| Facturacion (Finanzas)                                                                                                        | ✅ Migrado a cbi (2026-04-25). Workflow Holded `vI3TbyxtFM6wjhBS` ACTIVADO (2026-04-25) — las tablas cbi `holded_*` empezarán a poblarse en la próxima ejecución                          |
| Newsletter v2 (10 calls + 2 reuso de Análisis)                                                                                | ✅ Creado e inicializado (2026-04-29). Refactor sustituye al legacy "Actualizar email editado manual". 10ª call `newsletter_get_emails` añadida 2026-04-29 para iterar el RG Email Cards. |
| ~~Actualizar email editado manual~~                                                                                           | 🗑 ELIMINADO 2026-04-29 — 5 calls borradas (X=0 en Issue Checker). Sustituido por Newsletter v2.                                                                                         |
| Supabase - Gestion plantillas                                                                                                 | ✅ Migrado a cbi (2026-04-25)                                                                                                                                                             |
| Supabase - estados flujos                                                                                                     | ✅ Migrado a cbi (2026-04-25)                                                                                                                                                             |
| GHL (1 call)                                                                                                                  | ✅ Refactor v1→v2 (2026-04-28). Migrado a `services.leadconnectorhq.com/contacts/upsert` con PIT + `locationId`. No toca Supabase.                                                        |
| Supabase Mensajes Chat (2 calls, era 3) | ✅ Auditadas 2026-05-14. `chat_creacion_mensajes` borrada (0 usos), tabla `tarea_en_progreso` droppeada. |
| N8N - Workflows (7 calls) | ✅ Auditadas 2026-05-14 con body templates completos. |
| Supabase - estados flujos (4) | ✅ ELIMINADO 2026-05-14 — 4 calls + tabla `workflow_executions` droppeadas. Botón Cancelar_ejecucion borrado de Bubble por Ben. |
| Supabase - Gestion plantillas (2) | ✅ ELIMINADO 2026-05-14 — 2 calls + backend workflows Bubble borrados. Tablas nunca existieron en cbi. |
| Supabase - Funciones Genéricas chat | ✅ Auditado 2026-05-14 — `POST_MESSAGE` eliminada (0 usos). Grupo reducido a 1 call. |
| `finanzas_sync_status` | ✅ Auditado 2026-05-14 — GET directo a `holded_sync_log`. Funcional. |
| Stripe (2), Google chat (1), Control de Campañas (11), +1 Análisis IA — init | ✅ Auditadas 2026-05-14. |

---

## Regla fundamental

> **SIEMPRE usar como Action, NUNCA como Data source.**

Bubble cachea los Data sources y no refresca automáticamente. Toda llamada a Supabase o n8n debe ejecutarse como Action dentro de Workflows para garantizar datos frescos.

---

## Esquema de metadata por call (7 campos)

| # | Campo | Qué va ahí |
|---|---|---|
| 1 | **Nombre canónico** | `<grupo>_<accion>_<detalle>`. Único en todo Bubble. |
| 2 | **Patrón técnico** | Una etiqueta de la tabla de patrones. |
| 3 | **Qué hace** | 1 línea operacional + latency esperada + timeout. |
| 4 | **Consumidor Bubble** | Página/botón/workflow que la llama. |
| 5 | **Destino** | Workflow n8n ID, tabla/vista/RPC Supabase, o endpoint externo. |
| 6 | **Deuda técnica / flags** | Tags `json_safe_ok`, `data_type_empty`, `eq_en_url`, `rpc_table`, `rpc_jsonb`, etc. |
| 7 | **Breaking-change rule** | Qué rompería si cambias URL/body/response/params. |

---

## Tabla de patrones técnicos

| Etiqueta | Definición | Config canónica |
|---|---|---|
| `webhook_ff` | Webhook n8n **fire-and-forget**. UI refresca por Realtime WS. | `Action`, Data type=`Empty`, JSON-safe en texto libre. |
| `webhook_sync` | Webhook n8n **síncrono**, body con payload (<30s timeout Bubble). | `Action`, Data type=`JSON` inicializado. |
| `sb_get` | GET PostgREST con filtros `?col=eq.<v>`. | `Action`, Data type=`JSON`. |
| `sb_post` | INSERT a tabla. | `Action`, header `Prefer: return=representation`. |
| `sb_patch` | UPDATE a tabla con filtro `eq.`. | `Action`, `Prefer: return=representation` si se necesita la fila. |
| `sb_delete` | DELETE a tabla con filtro `eq.`. | `Action`. |
| `rpc_table` | RPC `RETURNS TABLE(...)` — array tipado iterable. | `Action`, params con prefijo `p_`. |
| `rpc_jsonb` | RPC `RETURNS jsonb/json` — texto plano, parsing manual. | `Action`. Preferir `rpc_table`. |
| `ext_auth` | Servicio externo con auth propia (GHL, etc.). | `Action`, headers a medida. |

---

## Sector 7 · Analisis Cliente (9 calls — auditadas 2026-04-22/23)

> Módulo chat co-creativo iterativo (briefing 12 secciones + 4 segmentos + entrega bajo demanda + panel derecho granular). Patrón canónico para chats nuevos.

### `analisis_send_message`
- **Alias Bubble:** `N8N - Trigger chat analisis`
- **Patrón:** `webhook_ff`
- **Tipo:** POST
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/chat-analisis`
- **Body template:**
  ```json
  {
    "conversation_id": "<conversation_id>",
    "agencia_id": "<agencia_id>",
    "cliente_id": "<notion_id>",
    "url_analizar": "<url_analizar>",
    "link_drive": "<link_drive>",
    "message": <message>
  }
  ```
  ⚠️ `message` SIN comillas envolventes; el operador `:formatted as JSON-safe` las añade. Resto con comillas.
- **Qué hace:** envía el mensaje del usuario del chat Análisis a n8n. Latencia <500ms. El agent procesa 30-180s y actualiza via Realtime.
- **Consumidor Bubble:** Page `/clientes/{empresa_id}/analisis` → Button Send + Workflow Enter.
- **Destino:** n8n workflow `dtgF0G35aeJQVVfn` (IA Análisis — Entrada) → `FFhkdTFCjTtfyvhP` (IA Análisis — Tool Loop [SUB]).
- **Flags:** `json_safe_ok`, `data_type_empty`.
- **Headers:** captura tiene `apikey` + `Authorization: Bearer` innecesarios (deuda 🟡 cosmetic).

### `analisis_get_wip`
- **Alias Bubble:** `SUPABASE - analisis_get_wip`
- **Patrón:** `sb_get`
- **Tipo:** GET
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/analisis_wip?conversation_id=eq.[conv_id]&select=*`
- **Returns:** array de 1 objeto fila completa de `analisis_wip`.
- **Consumidor Bubble:** Page Loaded step 8 → custom state `conv_metadata_estado` + `refresh mails event` step 1.
- **Destino:** Supabase cbi · tabla `public.analisis_wip`.
- **Flags:** `eq_en_url`, `returns_array`.

### `analisis_reset_wip`
- **Alias Bubble:** `SUPABASE - analisis_reset_wip`
- **Patrón:** `rpc_jsonb`
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/analisis_reset_wip`
- **Body:** `{ "p_conversation_id": "<conversation_id>" }`
- **Returns:** `{ "ok": true }`
- **Qué hace:** borra `chat_messages` de la conv + resetea fila `analisis_wip` a borrador.
- **Consumidor Bubble:** Button "Reiniciar conversación" en page Análisis.

### `analisis_trigger_entrega`
- **Alias Bubble:** `N8N - Analisis_trigger_entrega`
- **Patrón:** `webhook_sync`
- **Tipo:** POST
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/entregar-analisis`
- **Body:** `{ "conversation_id": "<conversation_id>" }`
- **Returns:** `{ "ok": true }`
- **Qué hace:** dispara generación del Doc en Drive del cliente. Async — la entrega real corre detrás.
- **Destino:** n8n `JtXdkXHm6RyGOJft` → `QW8VZ9cV5ECsSKvZ` (IA Análisis — Entrega [SUB]).
- **Consumidor Bubble:** Button "Generar Doc" (visible si `conv_metadata_estado = "completado"`).

### `analisis_get_briefing`
- **Alias Bubble:** `SUPABASE - analisis_get_briefing`
- **Patrón:** `rpc_table`
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/analisis_get_briefing`
- **Body:** `{ "p_conversation_id": "<p_conversation_id>" }`
- **Returns TABLE:** `seccion_num int, grupo text, titulo text, valor text` — 12 filas.

### `analisis_get_segmento_meta`
- **Alias Bubble:** `SUPABASE - analisis_get_segmento_meta`
- **Patrón:** `rpc_table`
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/analisis_get_segmento_meta`
- **Body:** `{ "p_conversation_id": "...", "p_idx": <1..4> }`
- **Returns TABLE:** `idx, nombre, descripcion, problematica, oportunidad` — 1 fila.

### `analisis_get_segmento_empatia`
- **Alias Bubble:** `SUPABASE - analisis_get_segmento_empatia`
- **Patrón:** `rpc_table`
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/analisis_get_segmento_empatia`
- **Returns TABLE:** `bloque_num, bloque_key, bloque_label, item_num, item` — 35 filas (7 bloques × 5 items).

### `analisis_get_segmento_buyer`
- **Alias Bubble:** `SUPABASE - analisis_get_segmento_buyer`
- **Patrón:** `rpc_table`
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/analisis_get_segmento_buyer`
- **Returns TABLE:** `row_num, label, value` — ~24 filas (label/value agnóstico).

### `analisis_get_segmento_angulos`
- **Alias Bubble:** `SUPABASE - analisis_get_segmento_angulos`
- **Patrón:** `rpc_table`
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/analisis_get_segmento_angulos`
- **Returns TABLE:** `num, titulo, enfoque, mensaje` — 5 filas.

### `Análisis IA - init` (10ª call, identificada 2026-05-14)
- **Patrón:** `webhook_ff`
- **Tipo:** POST
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/init-analisis`
- **Body template:**
  ```json
  {
    "conversation_id": "<conv_id>",
    "agencia_id": "<agencia_id>",
    "cliente_notion_id": "<cliente_notion_id>"
  }
  ```
- **Data type Bubble:** `Empty` (fire-and-forget — Bubble no consume el response).
- **Destino:** workflow n8n `8hAokf6zfQl0dMlR` (IA Análisis — Init). ACTIVE ✅ desde 2026-04-30 (memoria `project_analisis_greeting.md`).
- **Qué hace:** dispara el greeting inicial del chat Análisis. Workflow 16 nodos:
  1. Verifica si la conv ya tiene mensajes (idempotente — si los hay, no hace nada).
  2. Lee `bub_clientes` por `notion_id` → extrae `nombre_empresas`, `bb_link_drive_analisis`, `link_drive`.
  3. Si tiene `bb_link_drive_analisis` poblado → lista archivos del Drive del cliente con nodo Google Drive.
  4. Filtra archivos soportados (`.pdf|.docx|.txt|.md|.json`). Otros formatos quedan flageados como `no_soportado`.
  5. Si hay soportados → genera resumen narrativo con Gemini 2.5 Flash (temperatura 0.3, maxTokens 300, thinking=0).
  6. Upsert `kb_files[]` en `analisis_wip` (on_conflict=conversation_id, merge-duplicates).
  7. Insert mensaje `assistant` en `chat_messages` con greeting HTML formateado (lista archivos clickables + narrative + link Drive).
  8. Branches alternativos: sin Drive vinculado / con Drive pero sin archivos soportados → greeting alternativo sin RAG.
- **Consumidor Bubble:** Page Loaded de `/clientes/{empresa_id}/analisis` (después de `get_or_create_conversation`). Solo dispara cuando la conv es nueva.
- **Flags:** `webhook_ff`, `data_type_empty`, `idempotent` (skip si conv ya tiene mensajes).
- **✅ Fix aplicado 2026-05-14 — credenciales migradas a env vars:** 7 nodos del workflow `8hAokf6zfQl0dMlR` actualizados vía `n8n_update_partial_workflow` (operación `updateNode`):
  - 6 nodos HTTP Request Supabase: `apikey` + `Authorization` → `$env.SUPABASE_SERVICE_ROLE_KEY`
  - 1 nodo `Gemini Greeting`: URL limpia + query param `key` → `$env.GEMINI_API_KEY` (`sendQuery: true`)
  - Verificado con script Python: 0 hardcoded secrets en el JSON del workflow.
  - ✅ **Env vars añadidas en EasyPanel + restart confirmado (2026-05-14):** `SUPABASE_SERVICE_ROLE_KEY` + `GEMINI_API_KEY`. Estructura verificada vía MCP: 0 hardcoded secrets en el JSON del workflow.

---

## Supabase - Graficos Horas (6 calls — Clockify RPCs, re-auditadas 2026-05-14)

Todas POST a `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/<funcion>`. Patrón `rpc_table`. Firmas RPC verificadas en cbi (todas `SECURITY DEFINER`, params con defaults: `p_fecha_inicio` y `p_fecha_fin` default a últimos 30 días).

**Shared headers (Collection):**
- `Authorization: Bearer <anon_key cbi>`
- `apikey: <anon_key cbi>`
- `Prefer: return=representation` — 🟢 **deuda cosmética:** innecesario en RPC POST (las RPCs siempre devuelven resultado, no es upsert). Inocuo.

**Estado consumo:** datos vivos confirmados con sample 2026-05-14 — `clockify_resumen` devuelve 171.12h, 270 entries, 24 clientes, 6 miembros activos. Las 6 alimentan el dashboard Control de Tiempo en `/operaciones` (tab Clockify).

### `clockify_resumen`
- **Body:** `{ p_agencia_id, p_fecha_inicio, p_fecha_fin }`
- **Returns TABLE:** `total_horas numeric, total_entries bigint, promedio_diario_horas numeric, pct_facturable numeric, horas_facturables numeric, horas_no_facturables numeric, clientes_activos bigint, miembros_activos bigint` (1 fila).
- **Consumidor Bubble:** card "Resumen semana" en dashboard Control de Tiempo.

### `clockify_por_cliente`
- **Body:** `{ p_agencia_id, p_fecha_inicio, p_fecha_fin, p_limit }`
- **Returns TABLE:** `cliente_nombre text, horas numeric, entries bigint, horas_facturables numeric, miembros bigint, color text, pct numeric, coste numeric` (N filas, default top 10).
- **Consumidor Bubble:** tabla "Horas por cliente" + costes.
- **🟡 Deuda menor:** Bubble envía `"<p_limit>"` con comillas (string). La firma RPC espera `integer DEFAULT 10`. PostgREST coerciona pero lo correcto sería `<p_limit>` sin comillas (numérico). Inocuo hoy.

### `clockify_por_miembro`
- **Body:** `{ p_agencia_id, p_fecha_inicio, p_fecha_fin }`
- **Returns TABLE:** `usuario_email text, nombre text, horas numeric, entries bigint, clientes bigint, promedio_diario numeric, color text, pct numeric, coste_hora numeric, tarifa_mensual numeric` (N filas).
- **Consumidor Bubble:** tabla "Horas por miembro" + costes/tarifas.
- **JOINs internos:** `usuario_email` (en `clockify_time_entries`) → LEFT JOIN `bub_user` para resolver `nombre`. `coste_hora` viene de `clockify_tarifas` por email; si no hay tarifa → 0.

### `clockify_trending`
- **Body:** `{ p_agencia_id, p_fecha_inicio, p_fecha_fin }`
- **Returns TABLE:** `semana date, horas numeric, entries bigint, miembros bigint, clientes bigint, horas_facturables numeric` (N filas, 1 por semana).
- **Consumidor Bubble:** datos crudos para gráfico semanal (tabla detallada).

### `clockify_chart_donut`
- **Body:** `{ p_agencia_id, p_fecha_inicio, p_fecha_fin }`
- **Returns TABLE:** `labels text, valores text, colores text` (1 fila — strings concatenados por `;`).
- **Consumidor Bubble:** plugin chart Donut por miembro. Sample: `"Camilo;Joaquin;Damian;…" / "76.5;30.9;30.6;…" / "rgb(99,162,255);rgb(255,99,132);…"`.
- **Patrón:** helper pre-formateado — Bubble splitea por `;` y pasa arrays al plugin del chart.

### `clockify_chart_trending`
- **Body:** `{ p_agencia_id, p_fecha_inicio, p_fecha_fin }`
- **Returns TABLE:** `x_labels text, y_valores text` (1 fila — strings concatenados por `;`).
- **Consumidor Bubble:** plugin chart línea (horas por semana). Sample: `"16 Feb;23 Feb;02 Mar;…" / "76.0;61.1;52.4;…"`.

### 4 RPCs Clockify sin consumidor (backlog intencional)
`clockify_por_tarea`, `clockify_cliente_miembro`, `clockify_coste_por_cliente`, `clockify_dashboard` existen en cbi pero no tienen UI en Bubble. Creadas durante el diseño del dashboard de Control de Tiempo, la UI correspondiente nunca se construyó. No son deuda activa — coste cero (PostgreSQL functions), sin riesgo de regresión. Quedan en backlog hasta que se decida si construir esas vistas del dashboard de tiempo.

---

## Facturacion (6 calls — Finanzas / Holded)

Firmas RPC verificadas en cbi (2026-05-14). Todas POST a `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/<funcion>` excepto `finanzas_sync_status` (GET directo a tabla). Las 4 RPCs `finanzas_*` son **SECURITY INVOKER** (no DEFINER) — dependen de policies RLS de `holded_*` para que `anon` pueda SELECT.

**Shared headers (Collection):** `Authorization: Bearer <anon_key>`, `apikey: <anon_key>`, `Content-Type: application/json`.

**Estado infraestructura (verificado live):** workflow `vI3TbyxtFM6wjhBS` (SYNC FINANZAS) corre cron 4AM Madrid (02:00 UTC) daily. 14 ejecuciones consecutivas OK confirmadas (2026-05-01 → 2026-05-14), procesando ~122 facturas + ~155 gastos por run.

### `finanzas_metricas_mes`
- **Body:** `{ p_agencia_id }` — Bubble omite `p_mes` (DEFAULT NULL → mes actual).
- **Firma:** `(p_agencia_id uuid, p_mes date DEFAULT NULL)`
- **Returns TABLE:** `mes date, mrr numeric, ingresos numeric, gastos numeric, margen numeric, clientes_activos integer, ticket_medio numeric, churn_mrr numeric, pct_impagos numeric, total_impagado numeric, num_facturas_impagadas integer` (1 fila).
- **Sample (Initialize 2026-04-27):** mes `2026-04-01`, MRR 1500, ingresos 5962.24, gastos 4948.21, margen 1014.03, 7 clientes activos, ticket medio 214.29, **pct_impagos 432.91% / total_impagado 25810.9€ / 31 facturas impagadas** ⚠️.
- **Consumidor Bubble:** dashboard Finanzas → cards de métricas del mes.

### `finanzas_facturas_pendientes`
- **Body:** `{ p_agencia_id, p_tipo_vista: "pendientes", p_dias }`
- **URL endpoint:** `/rpc/finanzas_facturas` (misma RPC que `_impagadas`, distinto `p_tipo_vista`).
- **Firma:** `(p_agencia_id uuid, p_tipo_vista text, p_dias integer DEFAULT 30)`
- **Returns TABLE:** `id integer, holded_id text, contacto_nombre text, concepto text, total numeric, fecha date, fecha_vencimiento date, estado text, numero_factura text, dias_retraso integer, cliente_notion_id text` (N filas).
- **Consumidor Bubble:** tabla Facturas Pendientes (estado `pending` o `partial`).
- **🟡 Deuda menor:** `p_dias` se envía como `"<p_dias>"` (string). Firma espera integer. PostgREST coerciona, pero correcto sería `<p_dias>` sin comillas.

### `finanzas_facturas_impagadas`
- **Body:** `{ p_agencia_id, p_tipo_vista: "impagadas" }` — `p_dias` omitido → default 30.
- **URL endpoint:** `/rpc/finanzas_facturas` (misma RPC).
- **Returns TABLE:** mismo schema que `_pendientes` (estado `overdue`).
- **Sample (Initialize 2026-04-27):** 31 facturas overdue, mayor concentración en BERSO JM SLU (5 facturas, 4.7k€) + Xplora Wild SL + ENJOY & PADEL + FREEXDAY EXPERIENCE.
- **Consumidor Bubble:** tabla Facturas Impagadas.

### `finanzas_desgloses`
- **Body:** `{ p_agencia_id }` — `p_mes` omitido (default mes actual).
- **Firma:** `(p_agencia_id uuid, p_mes date DEFAULT NULL)`
- **Returns TABLE:** `categoria text, nombre text, monto numeric, pct numeric` (N filas).
- **Sample (Initialize 2026-04-27):** `ingreso/puntual 4462.24€ (74.8%)`, `ingreso/recurrente 1500€ (25.2%)`.
- **Consumidor Bubble:** gráfico desglose ingresos/gastos del mes.

### `finanzas_evolucion_mrr`
- **Body:** `{ p_agencia_id }`
- **Firma:** `(p_agencia_id uuid)` — sin params opcionales, devuelve serie completa.
- **Returns TABLE:** `mes date, mes_label text, mrr numeric, ingresos numeric, pct_max numeric` (N filas, 1 por mes).
- **Sample (Initialize 2026-04-27):** serie desde `2025-11-01 (Nov 2025)` con MRR/ingresos por mes.
- **Consumidor Bubble:** gráfico Evolución MRR.

### `finanzas_sync_status`
- **Tipo:** **GET** (no RPC) — lee directamente de tabla `holded_sync_log`.
- **URL:** `/rest/v1/holded_sync_log?order=id.desc&limit=1&select=id,started_at,finished_at,status,trigger_type,facturas_procesadas,gastos_procesados`
- **Returns:** array de 1 fila → `{id, started_at, finished_at, status, trigger_type, facturas_procesadas, gastos_procesados}`.
- **Consumidor Bubble:** indicador "Última sincronización" en dashboard.
- **⚠️ Nota Initialize:** el sample mostrado en plugin queda congelado del momento de inicialización. La frescura real se valida llamando la call en runtime.

### 🟡 Deudas detectadas en el grupo
1. **`p_dias` como string** (cosmético, PostgREST coerciona).
2. **`Prefer: return=representation` en Collection** — innecesario en RPC POST (las RPCs siempre devuelven resultado). Inocuo.
3. **`cliente_notion_id = null` — decisión de diseño, no deuda:** el sync `vI3TbyxtFM6wjhBS` no enlaza `holded_facturas.contacto_nombre` con `bub_clientes.notion_id`. No hay clave compartida entre ambos (Holded usa nombres libres, Notion/Bubble usan UUIDs). Fuzzy match nunca estuvo en scope. Las finanzas funcionan sin el link. Si algún día se necesita cruzar facturas con clientes, se añade matching en el workflow de sync.
4. **`SECURITY INVOKER` en las 4 RPCs `finanzas_*`** — corren con permisos del caller (`anon` desde Bubble). Las policies RLS de `holded_facturas`/`holded_gastos` deben permitir SELECT a `anon`. Si algún día las RPCs devolvieran array vacío silenciosamente desde Bubble pero datos OK en Supabase SQL Editor → primer check = RLS de `holded_*`.

---

## Supabase Mensajes Chat (2 calls — auditadas 2026-05-14)

Operaciones sobre `chat_messages` (cbi). Grupo limpiado de la 3ª call legacy `chat_creacion_mensajes` que leía `tarea_en_progreso` (Chat Tareas obsoleto desde 2026-04-25, tabla droppeada 2026-05-14).

### `obtener_mensajes`
- **Patrón:** `sb_get`
- **Tipo:** GET
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/chat_messages?conversation_id=eq.[conversation_id]&select=id,conversation_id,role,content,created_at&order=created_at.asc`
- **Params:** `conversation_id` (text)
- **Returns:** array `[{id, conversation_id, role, content, created_at}]` — mensajes de la conv en orden cronológico.
- **Qué hace:** carga el historial de mensajes para cualquier chat (Cerebro, Newsletter, Análisis).
- **Consumidor Bubble:** 8 usos (verificados 2026-05-14 vía Search Tool — Action type): `Chat_tareas_general` ×1 ⚠️ legacy candidato a revisión, `analisis_cliente` ×2, `clientes` ×3, `newsletter` ×2. También reusada en grupo `Newsletter v2`.
- **Flags:** `eq_en_url`, `returns_array`.

### `borrar_mensajes_conversacion`
- **Patrón:** `sb_delete`
- **Tipo:** DELETE
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/chat_messages?conversation_id=eq.[conversation_id]`
- **Headers:** `Prefer: return=representation` (🟡 deuda menor — innecesario si no se usa la fila devuelta)
- **Params:** `conversation_id` (text)
- **Returns:** fila(s) borrada(s) (por el header Prefer).
- **Qué hace:** borra todos los mensajes de una conversación (reset de chat).
- **Consumidor Bubble:** 1 uso en page `clientes` (Action type, 2026-05-14).
- **Flags:** `eq_en_url`.

### ~~`chat_creacion_mensajes`~~ 🗑 ELIMINADA 2026-05-14
Borrada con 0 usos (Action type + Uses API). Apuntaba a `tarea_en_progreso` (Chat Tareas legacy obsoleto). Tabla droppeada el mismo día (migration `drop_tarea_en_progreso_legacy`).

---

## Supabase - Funciones Genéricas chat (1 call — auditadas 2026-05-14)

Grupo genérico para infra de chats IA. Reducido de 2 a 1 call tras eliminar `POST_MESSAGE` (0 usos — n8n inserta los mensajes directo con service_role).

**Shared headers (Collection):** `Authorization: Bearer <anon_key>`, `apikey: <anon_key>`, `Content-Type: application/json`.

### `OBTENER_O_CREAR_CONVERSACION` (alias canónico: `get_or_create_conversation`)
- **Patrón:** `rpc_jsonb` (composite type, llega como objeto único, no array).
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/get_or_create_conversation`
- **Body template:**
  ```json
  {
    "p_agencia_id": "<agencia_id>",
    "p_user_bubble_id": "<user_bubble_id>",
    "p_tipo": "<tipo>",
    "p_estado": "active"
  }
  ```
- **Firma RPC verificada:** `(p_agencia_id uuid, p_tipo text, p_user_bubble_id text DEFAULT NULL, p_estado text DEFAULT 'active')`. **SECURITY DEFINER = true** (D1 hardening 2026-05-13). Orden de params en body de Bubble distinto al de la firma — irrelevante para PostgREST (matching por nombre).
- **Returns:** composite type `chat_conversations` (fila completa). Sample 2026-05-14:
  ```json
  {
    "id": "c0d27677-...",
    "agencia_id": "e748c7d4-...",
    "created_at": "2026-04-21T13:19:44Z",
    "updated_at": "2026-04-21T13:29:57Z",
    "estado": "active",
    "tipo": "test_conversacion",
    "metadata": {},
    "user_bubble_id": "benjamin.sanchis@thenucleo.com"
  }
  ```
- **Constraint:** UNIQUE(`agencia_id`, `tipo`) → si ya existe la conv del par, devuelve la existente; si no, la crea. Idempotente.
- **Convención `p_tipo`:** patrón canónico `<sector>_<notion_id>` (ej: `analisis_30de4743-…`, `newsletter_30de4743-…`, `cerebro_30de4743-…`). El sample con `"test_conversacion"` es de testing manual. ⚠️ **Bugs Page Loaded existentes** (ver `chat-cocreativo-blueprint.md`): Análisis usa `analisis_<bubble_id>` (debería ser notion_id) y Newsletter usa `newsletter` sin sufijo.
- **Consumidor Bubble:** Page Loaded de todos los chats co-creativos (Análisis, Newsletter, Cerebro) para obtener o crear la conversación del par cliente/sector.
- **Flags:** `rpc_jsonb` (composite type, no TABLE), `security_definer`, `idempotent`.

### ~~`POST_MESSAGE`~~ 🗑 ELIMINADA 2026-05-14

Era INSERT directo a `/rest/v1/chat_messages`. Audit reveló **0 usos en Bubble** (Action type + Uses API). Razón: los workflows n8n de los chats IA (Cerebro `JI5Tr7IogqXgaI7a`, Newsletter `inWFSAEDLCH1kx5P`, Análisis `dtgF0G35aeJQVVfn`) insertan los mensajes directamente con `service_role` — Bubble nunca necesita escribir mensajes, solo leerlos vía `obtener_mensajes`. Borrada del API Connector.

Esto reduce la urgencia de D3: la activación de RLS en `chat_messages` solo necesita 2 RPCs DEFINER (`chat_get_messages` + `chat_delete_messages`), no 3.

---

## ~~Supabase - estados flujos (4 calls — Ops Monitor)~~ 🗑 GRUPO ELIMINADO 2026-05-14

Feature Ops Monitor abandonado al 80%. Las 4 calls (`Crear_ejecucion_al_lanzar`, `Comprobar_estado_ejecucion`, `Cancelar_ejecucion`, `Leer_estado_ejecucion`) borradas por Ben tras auditoría con Search Tool:
- 3 con 0 usos (Crear/Comprobar/Leer).
- 1 con 1 uso (Cancelar en `clientes`) pero sin contraparte n8n que procesara el `status='cancelando'` → la única fila histórica quedó zombie 23 días sin resolverse.

Tabla `workflow_executions` droppeada en cbi el mismo día (migration `drop_workflow_executions_legacy`). Trigger `workflow_executions_updated_at` + policies RLS eliminados en cascada.

✅ **Bubble limpio 2026-05-14:** botón/workflow que llamaba a `Cancelar_ejecucion` borrado por Ben de page `clientes`.

---

## ~~Supabase - Gestion plantillas (2 calls)~~ 🗑 GRUPO ELIMINADO 2026-05-14

Las 2 calls (`up-sert-crear-subtarea-supabase` + `us-pert-plantilla-completa-supabase`) apuntaban a tablas `plantillas` / `plantillas_subtareas` que **nunca existieron en cbi** — eran del schema antiguo de maw (INACTIVE desde mayo 2026). En la migración maw→cbi del 2026-04-25 solo se cambió la base URL del API Connector, no las URLs específicas, dejando los POSTs apuntando a 404.

Estuvieron 20 días devolviendo 404 sin que nadie lo notara porque la funcionalidad **"Crear plantilla / Añadir subtarea"** del portal estaba duplicada en 2 ramas:

```
Botones UI Bubble
├─→ Steps 1-3: Create/Modify Data Types Bubble nativos (Plantillas_tareas_notion + _subtareas_notion)
│       ↓
│   DB Trigger Bubble → SYNC ABSOLUTO FGxG67I24POOUeHW → bub_plantillas_*_notion en cbi  ✅ ACTIVO
│
└─→ Step 4: Schedule backend workflow `nueva_plantilla_supabase`
        ├─ Step 1: POST upsert-plantilla-completa-supabase (404)
        └─ Step 2: Schedule on list `crear_plantilla_subtarea_supabase`
                 └─ Step 1: POST upsert-crear-subtarea-supabase (404)   ❌ ROTO, impacto = 0
```

Las 22 plantillas + 108 subtareas en cbi vienen del camino real (SYNC ABSOLUTO), no de estas calls. Cleanup ejecutado por Ben en Bubble 2026-05-14:
- Eliminado Step 4 del workflow frontend `Button Crear Plantilla is clicked`.
- Eliminados los 2 backend workflows: `nueva_plantilla_supabase` + `crear_plantilla_subtarea_supabase`.
- Eliminadas las 2 API Connector calls del grupo.

No hay migration Supabase asociada — las tablas `plantillas` / `plantillas_subtareas` nunca existieron en cbi (verificado con `information_schema.tables`).

---

## N8N - Workflows (7 calls — auditadas 2026-05-14)

Todas POST con `Content-Type: application/json`. Patrón mixto `webhook_ff` / `webhook_sync` según el flujo.

### `Trigger_Agregar_plantilla_a_cliente_paso_1`
- **Patrón:** `webhook_ff`
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/aplicar_plantilla`
- **Body:**
  ```json
  {
    "bubble_id": "<bubble_id de la plantilla>",
    "cliente_notion_id": "<notion_id del cliente>",
    "agencia_id": "<agencia_id>"
  }
  ```
- **Destino:** `KSBwigoSEpHl5OG1` (OPS TAREAS — Aplicar Plantilla a Cliente).

### `Cliente Sync Bubble Notion`
- **Patrón:** `webhook_sync`
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/SYNC_clientes_bubble_notion`
- **Body:** 27 campos (`source`, `bubble_id`, `notion_id`, `agencia_id` + 23 campos cliente: nombre, estado, correo_principal, telefono_principal, pagina_web, dni_nif, codigo_postal, sector, contacto_principal, direccion_fiscal, nombre_sociedad, pais, provincia, link_drive, bb_link_drive_analisis, plan_actual, descripcion_plan, logo_url, bubble_updated_at, nps, niveles, fecha_onboarding, ultimo_seguimiento).
- **Destino:** `wvHcgVqqjkWJcJDu` (SYNC CLIENTES — Bubble → Notion + Drive). ✅ activo, validado 2026-04-27.
- **Notas:** En alta crea estructura Drive + página Notion + escribe links a Bubble. En update solo PATCHea Notion. ⚠️ Bubble serializa campos vacíos como string `"null"` — el wf normaliza defensivamente. `agencia_id` hardcoded a `e748c7d4-5823-413d-8cb3-532896f6e41d`. `nps` SIN comillas (Number).

### `Trigger_cerebro`
- **Patrón:** `webhook_ff`
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/chat_cerebro`
- **Body:**
  ```json
  {
    "conversation_id": "<conversation_id>",
    "agencia_id": "<agencia_id>",
    "cliente_notion_id": "<cliente_notion_id>",
    "user_bubble_id": "<user_bubble_id>",
    "mensaje": "<mensaje>"
  }
  ```
- **Destino:** `JI5Tr7IogqXgaI7a` (IA Cerebro — Chat por Cliente).
- **Flag:** `<mensaje>` debe ir con JSON-safe en caller (texto libre).

### `Trigger_crear_tarea_formulario`
- **Patrón:** `webhook_sync`
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/crear_tarea_formulario`
- **Body:** 16 campos (`nombre`, `cliente_notion_id`, `responsable_notion_user_id`, `aprobador_notion_user_ids`, `observadores_notion_user_ids`, `prioridad`, `area_tarea`, `fecha_entrega`, `estimacion_min`, `estado`, `incidencia`, `bloqueado_por_ids`, `bloqueando_ids`, `agencia_id`, `descripcion`, `user_id`).
- **Destino:** `eHyXBETcaGSNXqLk` (OPS TAREAS — Crear desde Formulario Bubble).
- **Flag:** `<nombre>` y `<descripcion>` SIN comillas en bracket (JSON-safe en caller).

### `Trigger_actualizar_rag`
- **Patrón:** `webhook_ff`
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/reindexar_rag_cerebro`
- **Body:**
  ```json
  {
    "cliente_notion_id": "<cliente_notion_id>",
    "agencia_id": "<agencia_id>"
  }
  ```
- **Destino:** `BqNTrwoQ2iJIcAB4` (IA Cerebro — Reindexar RAG Manual [WEBHOOK]).

### `Trigger Actualizar Holded`
- **Patrón:** `webhook_ff`
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/sync_holded_finanzas`
- **Body:** `{ "agencia_id": "<agencia_id>" }`
- **Destino:** `vI3TbyxtFM6wjhBS` (SYNC FINANZAS — Holded → Supabase). ✅ activo desde 2026-04-25.

### `sync_bubble_mirror`
- **Patrón:** `webhook_ff`
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/espejo_a_supabase`
- **Body:** `{ "tabla": "<tabla>", "bubble_id": "<bubble_id>" }`
- **Destino:** `FGxG67I24POOUeHW` (SYNC ESPEJO — Bubble → Supabase).

---

## Newsletter v2 (9 calls — refactor 2026-04-29) ✅ CREADAS E INICIALIZADAS

Grupo nuevo en API Connector. Sustituye al legacy "Actualizar email editado manual" (5 calls) + grupo "Newsletter" (1 call). Plan: refactor `newsletter_emails_wip` (legacy) → `newsletter_wip` (cbi unificada). Detalle del refactor en [[04-chat-newsletter|docs/sectores/04-chat-newsletter]].

**Conv inicializadora (datos completos para Bubble RPC introspect):** `922cfab0-c9f7-4d65-9e5b-62b2764c0d74` (cliente_id `30de4743-b0ae-81e2-835a-dcb7ca7d38d2` "Actualízate Psicología"). Mantenida en cbi tras inicialización para futuras re-inits si se modifican RPCs.

**Shared headers del grupo** (clonados del grupo Análisis Cliente Conversion):
- `apikey: <anon_key cbi>`
- `Authorization: Bearer <anon_key cbi>`
- `Content-Type: application/json`

| # | Call Bubble | Use as | Method | URL | Body / Notes |
|---|---|---|---|---|---|
| 1 | `newsletter_get_wip` | Action | GET | `cbi/rest/v1/newsletter_wip?conversation_id=eq.[conversation_id]&select=*` | Returns array 1 fila (15 campos). |
| 2 | `newsletter_reset_wip` | Action | POST | `cbi/rest/v1/rpc/newsletter_reset_wip` | Body `{p_conversation_id}` → `{ok:true}`. Inicializado con UUID inventado para no destruir conv test. |
| 3 | `newsletter_trigger_entrega` | Action | POST | `n8n.../webhook/entregar-newsletter` | Body `{conversation_id}`. Data type **Empty**. Workflow `u9DsFadbpb7QiLaP` (inactivo hasta UI lista). Inicializado con UUID inventado. |
| 4 | `newsletter_get_parametros` | Action | POST | `cbi/rest/v1/rpc/newsletter_get_parametros` | Body `{p_conversation_id}` → 1 fila tipada (objetivo_secuencia, etapa_leads, segmento, cantidad_emails int, estado). Tipos verificados (`cantidad_emails` tipado como Number). |
| 5 | `newsletter_get_estrategia` | Action | POST | `cbi/rest/v1/rpc/newsletter_get_estrategia` | Body `{p_conversation_id}` → 1 fila (estrategia_texto, estado, cantidad_emails int). |
| 6 | `newsletter_get_email` | Action | POST | `cbi/rest/v1/rpc/newsletter_get_email` | Body `{p_conversation_id, p_idx}` → 1 fila (idx int, numero int, asunto, preheader, from_name, contenido_html, contenido_md, estado_aprobacion). `p_idx` parameter tipo **Number** (sin comillas en body). 1 email por idx — usada en Custom Event `cargar_email` (popup). |
| 6.5 | `newsletter_get_emails` | Action | POST | `cbi/rest/v1/rpc/newsletter_get_emails` | Body `{p_conversation_id}` → N filas tipadas (numero int, asunto, preheader, from_name, contenido_html, contenido_md, estado_aprobacion, cta_text, cta_url). Source del RG Email Cards. RPC aplicada en cbi 2026-04-29. |
| 7 | `newsletter_update_email` | Action | POST | `cbi/rest/v1/rpc/newsletter_update_email` | Body `{p_conversation_id, p_idx, p_asunto, p_contenido_html}` → `{ok, idx}`. Botón GUARDAR CAMBIOS del popup edición manual. RPC aplicada en cbi 2026-04-29. `p_contenido_md` opcional NO añadido como param Bubble. **Body template (fix 2026-04-30):** `<p_asunto>` y `<p_contenido_html>` SIN comillas envolventes (las añade `:formatted as JSON-safe` del caller); `<p_conversation_id>` CON comillas (UUID limpio). Para reinicializar, los body parameters de inicialización deben llevar **comillas literales como caracteres del valor** (`"Test asunto..."`, `"<p>...</p>"`) para producir JSON válido — Bubble inserta los chars tal cual. Validado E2E 2026-04-30. |
| 8 | `newsletter_send_message` | Action | POST | `n8n.../webhook/chat_newsletter` ⚠️ **underscore** | Body `{conversation_id, agencia_id, cliente_notion_id, tipo, mensaje}`. ⚠️ campos `cliente_notion_id` (NO `cliente_id`) y `mensaje` (NO `message`). Data type **Empty**. `<mensaje>` SIN comillas en bracket — JSON-safe en caller. Workflow `inWFSAEDLCH1kx5P` activado. |
| 9 | (reuso) `chat_get_or_create_conversation` | Action | POST | `cbi/rest/v1/rpc/get_or_create_conversation` | **Reusada del grupo Análisis Cliente Conversion** (no duplicada). Body 4 params: `{p_agencia_id, p_user_bubble_id, p_tipo, p_estado}`. Returns row completa de `chat_conversations`. Para Newsletter se llama con `p_tipo = "newsletter_" + cliente_notion_id` (sin sufijo timestamp — decisión cerrada B en sesión 2026-04-29). |
| 10 | (reuso) `obtener_mensajes` | Action | GET | `cbi/rest/v1/chat_messages?conversation_id=eq.[conversation_id]&order=created_at.asc&select=id,conversation_id,role,content,created_at` | **Reusada del grupo Análisis Cliente Conversion** (no duplicada). Genérica para cualquier chat. |

**Estado:** todas las 9 calls del grupo Newsletter v2 + las 2 reusadas validadas con Initialize. Grupo listo para que la página clon `/clientes/{id}/newsletter` las consuma desde Page Loaded + workflows.

---

## ~~Actualizar email editado manual (5 calls)~~ 🗑 ELIMINADO 2026-04-29

Grupo borrado completo. Las 5 calls (`newsletter_obtener_emails`, `estado_general_conv_obtener`, `reiniciar_newsletter_convers...`, `Eliminar_newsletters_cread...`, `Actualizar email editado ma...`) eliminadas con Issue Checker X=0 — ningún workflow Bubble las referenciaba. Sustituidas por las calls del grupo `Newsletter v2`.

---

## ~~Newsletter legacy (1 call)~~ 🗑 ELIMINADO 2026-04-29

`N8n - Trigger_newsletter chat` borrada (X=0). Sustituida por `newsletter_send_message` del grupo Newsletter v2.

---

## GHL (1 call — auditada 2026-05-14)

### `crear_contacto_invitacion`
- **Patrón:** `ext_auth` (servicio externo con auth propia)
- **Tipo:** POST
- **URL:** `https://services.leadconnectorhq.com/contacts/upsert`
- **Auth:** a nivel **Collection GHL** — Shared header `Authorization: Bearer pit-...` con Private Integration Token (PIT). NO se duplica por call.
- **Headers por call:**
  - `Content-Type: application/json`
  - `Version: 2021-07-28`
- **Body request:**
  ```json
  {
    "locationId": "wNl36msDFfWPWS4Fgpzt",
    "email": "<email>",
    "customFields": [
      { "key": "contact.invite_token", "field_value": "<token>" }
    ],
    "tags": ["invitacion_thenucleo"]
  }
  ```
- **Body response (auditada 2026-05-14 con sample real):**
  ```json
  {
    "new": true,
    "contact": {
      "id": "W9BDCXDmtdfVte2Fb1Zn",
      "dateAdded": "2026-04-28T16:58:01.854Z",
      "dateUpdated": "2026-04-28T16:58:01.854Z",
      "deleted": false,
      "tags": ["invitacion_thenucleo"],
      "type": "lead",
      "customFields": [],
      "locationId": "wNl36msDFfWPWS4Fgpzt",
      "email": "benjamin.sanchis@thenucleo.com",
      "emailLowerCase": "...",
      "bounceEmail": false,
      "unsubscribeEmail": false,
      "country": "ES",
      "createdBy": {"source": "INTEGRATION", "channel": "OAUTH", "sourceId": "...", "timestamp": "..."},
      "lastUpdatedBy": {"source": "...", "channel": "...", "sourceId": "...", "timestamp": "..."},
      "lastSessionActivityAt": "...",
      "validEmail": null,
      "validEmailDate": null
    },
    "traceId": "48ca72a5-82cc-4d54-99d0-37e8d2fc3afe"
  }
  ```
- **Campos clave del response (consumibles en Bubble):**
  - `new` (bool) → distingue alta nueva vs update de contacto existente.
  - `contact.id` (text) → GHL Contact ID. Persistir en Bubble para PATCHes futuros.
  - `contact.dateAdded` / `dateUpdated` → timestamps GHL.
- **Qué hace:** crea o actualiza (upsert) un contacto en la location única de la agencia, lo tagea como `invitacion_thenucleo` y guarda el invite_token como custom field. Idempotente — si el email ya existe, no duplica.
- **Consumidor Bubble:** Ajustes → invitación de miembros (ver memoria `project_ghl_integracion_ajustes.md`).
- **`locationId`:** hardcoded `wNl36msDFfWPWS4Fgpzt` (location única de la agencia). NO parametrizar.
- **Por qué upsert y no POST:** la location tiene "no duplicados por email" activado en GHL. El flujo de invitación debe ser idempotente (reenvío de invitación → mismo contacto, mismo token actualizado).
- **🟡 Deuda detectada 2026-05-14:** en el sample response `customFields: []` aparece **vacío** pese a haberlo enviado en el request. Posibles causas: (a) el custom field `contact.invite_token` no está creado en la location de GHL → GHL lo ignora silenciosamente; (b) la API v2 no devuelve customFields en el response. **Verificar:** abrir el contacto creado en GHL UI y comprobar si el campo `invite_token` está poblado. Si no lo está → crear el custom field en GHL antes de seguir usando esta call.
- **Flags:** `ext_auth`, `idempotent_upsert`.
- **Historial:** Refactor v1→v2 cerrado 2026-04-28 (migración desde endpoint v1 deprecado).

---

## ClickUp (2 calls — F2.E backend conectivity, 2026-05-05)

> Grupo nuevo en API Connector creado por Ben tras backend F2 cerrado. Sirve a la page Bubble independiente con Kanban CU (acceso desde botón "Tareas" de `/clientes` cuando `agencia.proveedor_tareas is Proveedor de Tareas clickup`). Las dos calls usan **response type auto-detectado por Initialize** (no Data Type Bubble persistido — no requieren espejo `bub_*` ni SYNC ABSOLUTO).

### `cu_get_space_statuses`
- **Alias Bubble:** `cu_get_space_statuses`
- **Patrón:** `webhook_sync`
- **Tipo:** POST
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/cu_get_space_statuses`
- **Headers:** `Content-Type: application/json`
- **Body template:**
  ```json
  {
    "agencia_id": "<agencia_id>",
    "space_id": "<space_id>"
  }
  ```
- **Parameters:** `agencia_id` (text), `space_id` (text). Privacy: NO privados.
- **Returns:** array tipado de objetos `{id, status, type, color, orderindex}` — uno por status del Space CU. `type` es `open|closed|custom`. `color` viene como hex (`#87909e`).
- **Qué hace:** GET `/v2/space/{space_id}` ClickUp API + extract statuses normalizado. Usado en Page Loaded del Kanban CU para poblar custom state `kanban_cu_columns` (lista de columnas dinámicas).
- **Consumidor Bubble:** Page Kanban CU independiente → Page Loaded step poblando state `kanban_cu_columns`.
- **Destino:** workflow wrapper n8n `wHuKjIisVripuobE` (`INTEGRACIONES — Wrapper Webhook Estados Espacio CU`) → ejecuta subworkflow `jsAnENkkzfTs6Kzu` (`INTEGRACIONES — Obtener Estados Espacio ClickUp [SUB]`) → CU API.
- **Initialize fixture:** `{agencia_id: "e748c7d4-5823-413d-8cb3-532896f6e41d", space_id: "90080425524"}` (Zenyx Workspace · Space "Wikipedia A1M" con 9 statuses, el más variado).
- **Flags:** `webhook_sync`, `returns_array`.

### `cu_get_kanban_tasks`
- **Alias Bubble:** `cu_get_kanban_tasks`
- **Patrón:** `sb_get`
- **Tipo:** GET
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/v_tareas_panel_clickup?agencia_id=eq.[agencia_id]&space_id=eq.[space_id]&select=*&order=position.asc`
- **Headers:**
  - `apikey: <supabase_anon_key cbi>`
  - `Authorization: Bearer <supabase_anon_key cbi>`
- **Parameters:** `agencia_id` (text), `space_id` (text). NO privados.
- **Returns:** array de filas de `v_tareas_panel_clickup`. 25 columnas: `id, bubble_id, notion_id, cu_task_id, url, agencia_id, nombre, estado, fecha_entrega, prioridad, responsables, responsable_nombres, cliente_notion_id, cliente_nombre, area_tarea, position, last_edited_time, synced_at, status_id, status_name, list_id, list_name, space_id, space_name, parent_external_id, dias_hasta_entrega`.
- **Qué hace:** lee tareas CU del Kanban filtradas por agencia + space directo desde la vista cbi. La vista filtra por defecto `provider='clickup' AND last_edited_time >= CURRENT_DATE - 20 días`.
- **Consumidor Bubble:** Page Kanban CU → RG cards interno por columna. Filtrado client-side por `status_id = current cell's id` (la columna del RG horizontal).
- **Destino:** Supabase cbi · vista `public.v_tareas_panel_clickup`.
- **Initialize:** ✅ inicializada 2026-05-07 con fila dummy temporal en `bub_tareas_notion` + `bub_clientes` (provider='clickup'). Bubble detectó los 25 campos individuales del response. Dummy borrado tras init. Vista vuelve a 0 filas hasta onboarding Zenyx (F2.F).
- **Gotcha histórico:** primer Initialize falló silenciosamente (response 200 con `[]`) y Bubble guardó como `raw body text` sin schema. Fix documentado: insertar dummy temporal cumpliendo ambos filtros de la vista (`provider='clickup'` y `last_edited_time >= CURRENT_DATE - 20 days`), re-init, borrar dummy.
- **Sintaxis URL Bubble:** placeholders con `[name]` (corchetes), NO `<name>` (angle brackets). Parameters declarados explícitos abajo (key=text, no privados, no opcionales).
- **Flags:** `sb_get`, `eq_en_url`, `returns_array`.

---

## Stripe (2 calls — auditadas 2026-05-14)

⚠️ **Naming inconsistente:** el grupo se llama "Stripe" pero solo 1 de las 2 calls toca Stripe. La 2ª es un Deploy Hook de Vercel. Bubble no permite mover calls entre grupos (limitación API Connector), queda flageado como deuda cosmética.

### `addons_descuento_sync`
- **Patrón:** `webhook_ff`
- **Tipo:** POST
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/addons_descuento_sync`
- **Body template:**
  ```json
  { "bubble_id": "<bubble_id>", "operation": "<operation>" }
  ```
- **Data type Bubble:** Empty.
- **Destino:** workflow n8n `bDYIpOSZ7Ge01Fqt` (SYNC ADDONS — Bubble → Stripe (Cupones)). `active: true` intencional — F2 Addons en rollout, las credenciales Stripe de producción aún no están configuradas en n8n. El webhook responde y procesa hasta el punto de llamar a Stripe, donde falla gracefully. La descripción interna del workflow ("INACTIVO: pendiente creds") es legacy y no refleja el estado real. Sin acción requerida.
- **Lógica del workflow (11 nodos):** Webhook → `GET Bubble Codigo` (Data Type Bubble `Addons_Codigos_Descuento`, nodo oficial) → `Build Stripe Params` (Code: normaliza operation create/update/deactivate basándose en `stripe_coupon_id` existente + flag `activo`) → `Route Operation` (Switch v3.4) → 3 branches:
  - **create:** POST `https://api.stripe.com/v1/coupons` (form-urlencoded: id, name, percent_off, duration=once, redeem_by, max_redemptions, metadata[bubble_id], metadata[codigo]) → PATCH Bubble set `stripe_coupon_id`.
  - **update:** POST `https://api.stripe.com/v1/coupons/{coupon_id}` (Stripe permite update solo de name/metadata).
  - **deactivate:** DELETE Stripe + PATCH Bubble clear `stripe_coupon_id`.
- Cada branch termina en `Activity Log Creado` (POST a `cbi/rest/v1/activity_log` con `clase=sync`, `accion=addons_descuento_sync_stripe`, metadata operation+coupon_id).
- **Trigger Bubble esperado:** DB Trigger Bubble en Data Type `Addons_Codigos_Descuento` (create/update/delete) → call API Connector.
- **Consumidor Bubble:** sin verificar Search Tool (pendiente). Probable: backend workflow Bubble que reacciona a DB Trigger sobre `Addons_Codigos_Descuento`.
- **Flags:** `webhook_ff`, `data_type_empty`, `f2_addons_rollout`.

### `trigger_rebuild_landing`
- **Patrón:** `ext_auth` (Vercel Deploy Hook con secret en URL).
- **Tipo:** POST
- **URL:** `https://api.vercel.com/v1/integrations/deploy/prj_QSnQBAmBM9hlfzPjbs50OHXhdt9D/HT2pAymgY5`
- **Body:** ninguno.
- **Data type Bubble:** Empty.
- **Destino:** Deploy Hook del proyecto Vercel `app-landing-thenucleo` (`prj_QSnQBAmBM9hlfzPjbs50OHXhdt9D`, ver memoria `reference_vercel_mcp.md`). Dispara rebuild de `work.thenucleo.com`.
- **Solapamiento con Edge Function:** la edge function `comunidad_admin_action` también dispara este Deploy Hook tras moderar propuestas comunidad. La call Bubble es independiente — probablemente para refrescar landing tras cambios admin desde portal (blog, addons, etc.). Verificar Search Tool para saber qué la dispara.
- **🟠 Deuda — secret en plain-text:** el segmento `HT2pAymgY5` de la URL es el secret del Deploy Hook. Si el plugin Bubble se exporta o entra en backup, anyone con el JSON puede triggering rebuilds arbitrarios. Impacto bajo (solo causa builds extra, costo Vercel) pero es leak de credencial.
- **Flags:** `ext_auth`, `secret_in_url`, `webhook_ff`.

---

## Google chat (1 call — auditada 2026-05-14)

### `obtener_id_gspace`
- **Patrón:** `webhook_ff`
- **Tipo:** POST
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/gchat_subscription_create`
- **Body template:**
  ```json
  {
    "cliente_bubble_id": "<This Clientes's unique id>",
    "gchat_space_id": "<This Clientes's gchat_space_id>"
  }
  ```
- **Data type Bubble:** Empty.
- **Destino:** workflow n8n **`gJfDb3Gwrf7fJ8Li`** "OPS LOG — Crear Subscription Google Chat por Cliente" (active desde 2026-05-08). ⚠️ **No está documentado en `CLAUDE.md`** (sección n8n) — falta añadir.
- **Qué hace (presumido):** crea una subscription Workspace Events API para que Google Pub/Sub empiece a empujar eventos del espacio Google Chat al workflow `8snJvdNsmRM2yI2y` (OPS LOG — Mensajes Google Chat). Insertará una fila en tabla `gchat_subscriptions` (24 subs activas según CLAUDE.md).
- **✅ Rename hecho por Ben 2026-05-14:** call renombrada a `gchat_suscripcion_crear` (o similar). Nombre anterior `obtener_id_gspace` era engañoso.
- **Consumidor Bubble:** botón en ficha cliente "Vincular Google Chat" (sección Clientes), confirmado por Ben.
- **Flags:** `webhook_ff`, `data_type_empty`.

---

## Control de Campañas (11 calls — módulo Ads v2, auditadas 2026-05-14)

Módulo Meta+Google Ads v2 nativo. Sirve la pantalla `/control-ads` del portal. Backend cerrado 2026-05-12 (9 workflows n8n + 16 RPCs + 7 tablas `ads_*` en cbi). Las 11 calls Bubble cubren: 7 lecturas de panel, 1 acción directa Supabase (`RETURNS void`), 3 acciones vía webhook n8n (mismo endpoint `/webhook/ads_action`, discriminadas por `body.action`).

**Shared headers Supabase (Collection):** `Authorization: Bearer <anon_key cbi>`, `apikey: <anon_key cbi>`, `Content-Type: application/json`.

> ⚠️ Body templates de las 3 calls n8n (`N8N - ads_refresh`, `N8N - ads_status_toggle`, `N8N - ads_action`) reconstruidos de la firma RPC Supabase + descripción del workflow `sNpVWEkinc4g0KfA`. Verificar contra Bubble UI si hay discrepancias.

### `ads_cuentas_panel`
- **Patrón:** `rpc_table`
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/ads_cuentas_panel`
- **Body:** `{ "p_agencia_id": "<agencia_id>", "p_periodo": "last_7d" }`
- **Firma verificada 2026-05-14:** `(p_agencia_id uuid, p_periodo text DEFAULT 'last_7d')`
- **Returns TABLE (24 cols):** `cuenta_id, cliente_id, cliente_nombre, provider, external_account_id, nombre, currency, ownership, business_id, account_status, disable_reason, spend, conv, ctr, cpa, roas, freq, campanias_activas, campanias_pausadas, campanias_issues, alertas_count, notas_count, score_max, last_sync_at`
- **Consumidor Bubble:** Page Loaded `/control-ads` step 1 → state `cuentas_vinculadas`. Table "Cuentas ya vinculadas" + KPIs globales.
- **Flags:** `rpc_table`.

### `ads_cuentas_pendientes`
- **Patrón:** `rpc_table`
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/ads_cuentas_pendientes`
- **Body:** `{ "p_agencia_id": "<agencia_id>" }`
- **Firma verificada 2026-05-14:** `(p_agencia_id uuid)`
- **Returns TABLE (14 cols):** `cuenta_id, external_account_id, nombre, provider, currency, ownership, business_id, account_status, disable_reason, discovered_at, sugerencia_cliente_id, sugerencia_cliente_nombre, sugerencia_score real, notas_count`
- **Consumidor Bubble:** Page Loaded step 2 → state `cuentas_pendientes`. KPI cards: PENDIENTES ASIGNAR (`:count`), MATCH SEGURO (`sugerencia_score ≥ 0.7`), MATCH PROBABLE (`< 0.7`), SIN MATCH (`sugerencia_score is empty`), PROBLEMAS CUENTA (`account_status ≠ 1`).
- **Flags:** `rpc_table`.

### `ads_campanias_panel`
- **Patrón:** `rpc_table`
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/ads_campanias_panel`
- **Body:** `{ "p_cuenta_id": "<cuenta_id>" }`
- **Firma verificada 2026-05-14:** `(p_cuenta_id uuid)`
- **Returns TABLE (23 cols):** `campania_id, external_id, nombre, status, effective_status, objective, daily_budget, lifetime_budget, spend, impressions, clicks, ctr, cpc, cpa, roas, freq, conv, score, diagnostic_state, diagnostic_reading, diagnostic_action, last_sync_at`
- **Consumidor Bubble:** Drill-down cuenta → RG campañas.
- **Flags:** `rpc_table`.

### `ads_adsets_panel`
- **Patrón:** `rpc_table`
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/ads_adsets_panel`
- **Body:** `{ "p_campania_id": "<campania_id>" }`
- **Firma verificada 2026-05-14:** `(p_campania_id uuid)`
- **Returns TABLE (20 cols):** `adset_id, external_id, nombre, status, effective_status, optimization_goal, daily_budget, lifetime_budget, spend, impressions, clicks, ctr, cpc, cpa, roas, freq, conv, score, last_sync_at`
- **Consumidor Bubble:** Drill-down campaña → RG ad sets.
- **Flags:** `rpc_table`.

### `ads_anuncios_panel`
- **Patrón:** `rpc_table`
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/ads_anuncios_panel`
- **Body:** `{ "p_adset_id": "<adset_id>" }`
- **Firma verificada 2026-05-14:** `(p_adset_id uuid)`
- **Returns TABLE (18 cols):** `anuncio_id, external_id, nombre, status, effective_status, creative_summary jsonb, spend, impressions, clicks, ctr, cpc, cpa, roas, freq, conv, score, last_sync_at`
- **Consumidor Bubble:** Drill-down ad set → RG anuncios.
- **Flags:** `rpc_table`.

### `ads_insights_serie`
- **Patrón:** `rpc_table`
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/ads_insights_serie`
- **Body:** `{ "p_entity_external_id": "<external_id>", "p_entity_type": "<entity_type>", "p_dias": <dias> }`
- **Firma verificada 2026-05-14:** `(p_entity_external_id text, p_entity_type text DEFAULT 'campaign', p_dias integer DEFAULT 30)`
- **Returns TABLE (8 cols):** `fecha date, spend, conv, ctr, cpa, roas, impressions bigint, clicks bigint`
- **Consumidor Bubble:** Panel detalle → gráfico de tendencia para la entidad seleccionada. `p_entity_type`: `'account' | 'campaign' | 'adset' | 'ad'`. `p_dias` SIN comillas (tipo integer).
- **Flags:** `rpc_table`.

### `ads_notas_listar`
- **Patrón:** `rpc_table`
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/ads_notas_listar`
- **Body:** `{ "p_entity_external_id": "<external_id>" }`
- **Firma verificada 2026-05-14:** `(p_entity_external_id text, p_limit integer DEFAULT 50)`
- **Returns TABLE (7 cols):** `id uuid, autor text, titulo text, contenido text, tipo text, metadata jsonb, created_at timestamptz`
- **Consumidor Bubble:** Panel lateral → feed de notas históricas de la entidad (cuentas, campañas, adsets, anuncios).
- **Flags:** `rpc_table`.

---

### `ads_asignar_cliente`
- **Patrón:** `rpc_void` → Data type `Empty`
- **Tipo:** POST
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/ads_asignar_cliente`
- **Body:** `{ "p_cuenta_id": "<p_cuenta_id>", "p_cliente_id": "<p_cliente_id>", "p_autor_email": "<p_autor_email>" }`
- **Firma verificada 2026-05-14:** `(p_cuenta_id uuid, p_cliente_id text, p_autor_email text)` → **RETURNS void**
- **Returns:** vacío (204 No Content). Data type Bubble: `Empty`.
- **Consumidor Bubble:** Botón "Asignar" en `Group Cuentas pendientes` → modal de asignación → call al confirmar. Pendiente cablear (handoff 2026-05-13).
- **🐛 Bugfix 2026-05-14:** URL apuntaba a `/rpc/ads_cuentas_panel` (errata del montaje 2026-05-12). Initialize previo devolvía datos de `ads_cuentas_panel` (24 cols) en lugar de void. Corregida URL + re-inicializada con Data type `Empty`. Body sin cambios — los 3 params coincidían con la firma real. Initialize fix: `p_cuenta_id = b442f990-07e2-4a3a-b85b-c40f5a66f882` + `p_cliente_id = 333e4743-b0ae-8082-9aff-f028c3010bc0` (ya asignado → idempotente) + `p_autor_email = benjamin.sanchis@thenucleo.com`.
- **Flags:** `data_type_empty`, `rpc_void`, `bugfix_2026-05-14`.

---

### `N8N - ads_refresh`
- **Patrón:** `webhook_ff`
- **Tipo:** POST
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/ads_action`
- **Body template:**
  ```json
  { "action": "refresh", "agencia_id": "<agencia_id>", "cuenta_id": "<cuenta_id>" }
  ```
- **Data type Bubble:** `Empty`.
- **Destino:** `sNpVWEkinc4g0KfA` (OPS ADS — Acciones Bubble [WEBHOOK]) → branch `refresh` → re-poll Meta API + RPC `ads_actualizar_kpis_snapshot` + RPC `ads_calcular_scoring`.
- **Consumidor Bubble:** Botón "Actualizar" en card de cuenta → fuerza re-sync sin esperar al cron de 30 min.
- **Flags:** `webhook_ff`, `data_type_empty`.

### `N8N - ads_status_toggle`
- **Patrón:** `webhook_ff`
- **Tipo:** POST
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/ads_action`
- **Body template:**
  ```json
  {
    "action": "status_toggle",
    "agencia_id": "<agencia_id>",
    "cuenta_id": "<cuenta_id>",
    "entity_type": "<entity_type>",
    "entity_external_id": "<entity_external_id>",
    "new_status": "<new_status>",
    "autor_email": "<autor_email>"
  }
  ```
- **Data type Bubble:** `Empty`.
- **Destino:** `sNpVWEkinc4g0KfA` → branch `status_toggle` → POST Meta API cambio de status + RPC `ads_aplicar_status_toggle(p_agencia_id, p_cuenta_id, p_entity_type, p_entity_external_id, p_new_status, p_autor_email)` → UPDATE entidad + INSERT nota + activity_log. `new_status`: `'ACTIVE' | 'PAUSED'`.
- **Consumidor Bubble:** Toggle activo/pausado en campañas, adsets, anuncios.
- **Flags:** `webhook_ff`, `data_type_empty`.

### `N8N - ads_action_nota_crear` (renombrada 2026-05-14 por Ben)
- **Patrón:** `webhook_sync`
- **Tipo:** POST
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/ads_action`
- **Body template:**
  ```json
  {
    "action": "nota_crear",
    "agencia_id": "<agencia_id>",
    "cuenta_id": "<cuenta_id>",
    "entity_type": "<entity_type>",
    "entity_external_id": "<entity_external_id>",
    "autor_user_id": "<autor_user_id>",
    "titulo": "<titulo>",
    "contenido": <contenido>
  }
  ```
- **Data type Bubble:** JSON. La RPC `ads_notas_crear` devuelve jsonb `{ok, nota_id}` desde 2026-05-12.
- **Destino:** `sNpVWEkinc4g0KfA` → branch `nota_crear` → RPC `ads_notas_crear(p_agencia_id, p_cuenta_id, p_entity_type, p_entity_external_id, p_autor_user_id, p_titulo, p_contenido, p_tipo DEFAULT 'manual')` → INSERT `ads_notas` → devuelve jsonb.
- **Consumidor Bubble:** Formulario "Nueva nota" en panel lateral de entidad.
- **✅ Rename aplicado 2026-05-14:** de `N8N - ads_action` → `N8N - ads_action_nota_crear`. Consumer en Bubble actualizado por Ben.
- **Flags:** `webhook_sync`, `json_safe_ok` (`<contenido>` texto libre — SIN comillas envolventes en template + `:formatted as JSON-safe` en caller).

### Estado deudas del grupo (2026-05-14)
1. **Body templates n8n reconstruidos** — no tomados directamente de Bubble UI. Verificar si difieren. (Pendiente menor)
2. **Rename `N8N - ads_action` → `N8N - ads_action_nota_crear`** — ✅ hecho por Ben 2026-05-14.
3. **`ads_asignar_cliente` pendiente cablear** en Bubble (handoff 2026-05-13).

---

## Patrones técnicos críticos

### RETURNS TABLE vs RETURNS jsonb
Las funciones PostgreSQL `RETURNS TABLE(...)` llegan a Bubble como array de objetos iterable. Las `RETURNS jsonb` llegan como texto plano y requieren parsing manual.

**Regla:** Siempre definir RPCs usados por Bubble como `RETURNS TABLE`.

### JSON-safe — escapar texto libre en bodies JSON

**Problema:** al construir `"<campo>": "<campo>"` en el Body template, Bubble inyecta el valor sin escapar. Si el usuario escribe `:`, `"`, saltos de línea → 422 Failed to parse request body.

**Fix oficial Bubble:**
1. Quitar las comillas envolventes del placeholder: `"message": <message>` (sin comillas).
2. En el workflow caller, aplicar `:formatted as JSON-safe` al value: `Input_Mensaje's value:formatted as JSON-safe`.

El operator escapa `"`, `\`, saltos de línea y añade las comillas envolventes. Si el template las trae se duplican y rompe.

**Aplica a:** todo texto libre del usuario en body JSON. UUIDs/URLs/enum fijos NO lo necesitan.

**CERRADO 2026-04-23:** los 4 chats (`analisis_send_message`, `newsletter_send_message`, `cerebro_send_message`, `tareas_send_message`) sanitizados.

### Helpers pre-formateados para charts
Plugins de charts esperan listas como texto separado. Patrón Bubble:
```
labels: Do a search for [resultado RPC]:each item's label:joined with ","
values: Do a search for [resultado RPC]:each item's valor:joined with ","
```

### Param `p_` en RPCs
Todos los parámetros de funciones PostgreSQL deben usar prefijo `p_` (e.g., `p_agencia_id`) para evitar el error 42702 (ambigüedad parámetro/columna).

### Patrón async para operaciones largas (>30s)
Bubble timeout en webhooks síncronos: 30 segundos. Para RAG, generación larga:
1. Bubble POST → n8n responde inmediato `{ "job_id": "uuid" }` (o vacío + Realtime WS).
2. UI consume cambios via Realtime sobre la tabla destino (`analisis_wip`, `newsletter_wip`).
3. Sin polling explícito — Realtime hace el push.

### Headers requeridos para Supabase
```
Authorization: Bearer {SUPABASE_ANON_KEY}
apikey: {SUPABASE_ANON_KEY}
Content-Type: application/json
Prefer: return=representation   ← solo en POST/PATCH si se necesita la fila
```

---

## Cuenta total por grupo

| # | Grupo Bubble | Calls | Estado auditoría |
|---|---|---|---|
| 1 | Analisis Cliente | 10 | ✅ auditadas completas 2026-05-14 (10/10, incluye `Análisis IA - init` con workflow `8hAokf6zfQl0dMlR` verificado) |
| 2 | Supabase - Graficos Horas (Clockify) | 6 | ✅ re-auditadas 2026-05-14 con firmas RPC + responses reales |
| 3 | Facturacion (Finanzas) | 6 | ✅ re-auditadas 2026-05-14 con firmas RPC + responses + workflow sync verificado live |
| 4 | N8N - Workflows | 7 | ✅ auditadas 2026-05-14 con body templates completos |
| 5 | **Newsletter v2** | 10 | ✅ creadas e inicializadas (2026-04-29). Sustituye al legacy. |
| 6 | ~~Supabase - estados flujos~~ | 0 | 🗑 ELIMINADO 2026-05-14 — 4 calls borradas + tabla `workflow_executions` droppeada (Ops Monitor abandonado al 80%) |
| 7 | **Supabase Mensajes Chat** | 2 | ✅ auditadas 2026-05-14 (era 3, `chat_creacion_mensajes` borrada) |
| 8 | ~~Supabase - Gestion plantillas~~ | 0 | 🗑 ELIMINADO 2026-05-14 — 2 calls + 2 backend workflows borrados. Apuntaban a tablas `plantillas`/`plantillas_subtareas` inexistentes en cbi desde migración maw→cbi 2026-04-25. Camino real (Data Types Bubble + SYNC ABSOLUTO) ya cubría el feature. |
| 9 | Supabase - Funciones Genéricas chat | 1 | ✅ auditada 2026-05-14 (`get_or_create_conversation`). `POST_MESSAGE` eliminada (0 usos) |
| 10 | GHL | 1 | ✅ auditada 2026-05-14 con response sample completa |
| 11 | **ClickUp** | 2 | ✅ Creado e inicializado 2026-05-05 |
| 12 | Stripe | 2 | ✅ auditadas 2026-05-14 (1 Stripe + 1 Vercel Deploy Hook — naming inconsistente). Deudas: secret Vercel plain-text + workflow F2 con `active:true` pero desc dice INACTIVO. |
| 13 | Google chat | 1 | ✅ auditada 2026-05-14 (`obtener_id_gspace` → workflow `gJfDb3Gwrf7fJ8Li`). Deuda: nombre engañoso (es subscription_create, no get_id) + workflow no documentado en CLAUDE.md. |
| 14 | **Control de Campañas** | 11 | ✅ auditadas 2026-05-14 (7 panel reads `rpc_table` + 1 `ads_asignar_cliente` void [bugfix URL] + 3 n8n webhook `/webhook/ads_action` por `body.action`. Firmas RPC verificadas cbi.) |
| **Total** | | **59** | ✅ **Auditoría completa 2026-05-14.** Todos los grupos auditados. |

---

## Deuda técnica cross-calls

| Sev | Call(s) | Problema | Acción |
|---|---|---|---|
| ✅ | ~~`analisis_*`~~ | Campo `empresa_id` mezclaba bubble_id y notion_uuid → CERRADO 2026-04-22. Renombrado a `cliente_id` (notion_id canónico). | Resuelto. |
| 🟡 | `analisis_send_message` | Headers `apikey` + `Bearer` innecesarios (es webhook n8n). | Quitar headers, re-inicializar call. |
| 🟡 | Sector 7 (4 calls) | Nombre visible Bubble ≠ nombre canónico doc. | Mantener alias documentados aquí. |
| ✅ | ~~`uspert-plantilla-completa-sup...`~~ | Typo en nombre + URL apuntaba a tabla inexistente en cbi → CERRADO 2026-05-14. Grupo entero eliminado (era redundante con SYNC ABSOLUTO). | Resuelto. |
| ✅ | ~~`crear_contacto_i...` (GHL)~~ | Marcada **RE-INITIALIZE** en Bubble. Schema antiguo apuntaba a v1 deprecada. → CERRADO 2026-04-28. Migrada a v2 `/contacts/upsert` con PIT + `locationId`. Renombrada a `crear_contacto_invitacion`. | Resuelto. |
| ✅ | ~~`chat_creacion_mensajes`~~ | Apuntaba a `tarea_en_progreso` (Chat Tareas legacy). → CERRADO 2026-05-14. Borrada con 0 usos, tabla droppeada. | Resuelto. |
| ✅ | ~~`Comprobar_estado_ejecucion` vs `Leer_estado_ejecucion`~~ | Posible duplicación. → CERRADO 2026-05-14. Grupo entero eliminado (Ops Monitor abandonado), tabla `workflow_executions` droppeada. | Resuelto. |
| 🔵 | "Actualizar email editado manual" (grupo) | Nombre del grupo solo describe 1 de las 5 calls. | Renombrar grupo a "Newsletter ops" o similar. |

---

## ✅ Auditoría completa (2026-05-14)

Todos los grupos y calls están auditados. Las 59 calls cubren los 12 grupos activos tras el cleanup de 3 grupos legacy (estados flujos + Gestion plantillas + POST_MESSAGE) en 2026-05-14.

---

## Historial

- **2026-04-22** — Inicio auditoría. Esquema 7 campos, tabla patrones (`webhook_ff`, `webhook_sync`, `sb_get`, `sb_post`, `sb_patch`, `rpc_table`, `rpc_jsonb`, `ext_auth`).
- **2026-04-22/23** — Sector 7 Análisis Cliente completo (9 calls).
- **2026-04-25** — Reestructura completa contra el panel real de Bubble. Pasamos de 9 grupos / ~38 calls inventados a 11 grupos / 46 calls reales. Marcadas pendientes de detalle el resto.
- **2026-05-05** — Grupo nuevo `ClickUp` con 2 calls (`cu_get_space_statuses` webhook_sync + `cu_get_kanban_tasks` sb_get). Sirve la page Bubble independiente con Kanban CU del plan F2.E. Activado workflow wrapper `wHuKjIisVripuobE` para que el primer call llegue al subworkflow `jsAnENkkzfTs6Kzu`. Total: 51 calls.
- **2026-05-14 (sesión 2)** — **Auditoría completada al 100%.** Grupo 14 Control de Campañas (11 calls) auditado con firmas RPC verificadas en cbi via MCP. Bugfix `ads_asignar_cliente`: URL apuntaba a `/rpc/ads_cuentas_panel` → corregida a `/rpc/ads_asignar_cliente`, re-inicializada con Data type `Empty` (RETURNS void). 7 panel reads documentadas con schemas completos (24/14/23/20/18/8/7 cols). 3 calls n8n al webhook `/webhook/ads_action` discriminadas por `body.action` (refresh/status_toggle/nota_crear). Workflow `gJfDb3Gwrf7fJ8Li` añadido a CLAUDE.md sección OPS. README.md count actualizado. Estado final: **59/59 calls auditadas.**
- **2026-05-14 (sesión 1)** — Re-conteo + cleanup masivo. Inicial: 14 grupos / 66 calls (vs 11 grupos / 51 documentadas). **Auditadas con detalle:** Supabase Mensajes Chat (2), N8N - Workflows (7), GHL (1, response sample completa), Supabase - Graficos Horas (6, firmas RPC verificadas + 1 sample por RPC). **Cleanups ejecutados:** (a) `chat_creacion_mensajes` borrada (0 usos) + tabla `tarea_en_progreso` droppeada + 2 workflows n8n del Chat Tareas legacy ya archivados; (b) **grupo entero "Supabase - estados flujos" eliminado** — Ops Monitor abandonado al 80% + tabla `workflow_executions` droppeada; (c) **grupo entero "Supabase - Gestion plantillas" eliminado** — apuntaba a tablas inexistentes en cbi, 20 días devolviendo 404 silenciosamente, redundante con SYNC ABSOLUTO Bubble→cbi. **Estado final:** 12 grupos activos / 60 calls (50 auditadas, 10 pendientes: Stripe 2, Google chat 1, Control de Campañas 11, +1 nueva Analisis, +`POST_MESSAGE`, +`finanzas_sync_status`). **Deudas flageadas:** GHL `customFields:[]` vacío; Clockify 4 RPCs huérfanas en cbi sin consumidor; `p_limit` y `p_dias` enviados como string; `cliente_notion_id = null` en facturas Holded (sync no enlaza con `bub_clientes`); 4 RPCs `finanzas_*` son SECURITY INVOKER (depende de RLS de `holded_*`). Auditada también Facturacion (6 calls) + workflow `vI3TbyxtFM6wjhBS` verificado live (cron 4AM Madrid, 14 ejecuciones consecutivas OK, ~122 facturas + 155 gastos/run). **Lección:** los responses Initialize del API Connector son snapshots congelados (caso confundido: `finanzas_sync_status` mostraba "stale 17 días" pero era el Initialize del 27/04 — la realidad confirmada en BD muestra sync corriendo perfectamente). Estado final auditadas: 52 (no 50). Pendientes: 8.
