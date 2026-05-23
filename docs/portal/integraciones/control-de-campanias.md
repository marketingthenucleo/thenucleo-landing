---
title: Control de Campañas — Handoff sesión 2026-05-13
dominio: integraciones
estado: en construcción
actualizado: 2026-05-21
tags: [meta-ads, google-ads, control-campanias, ops-monitor, ads, handoff]
---

> **Sesión 2026-05-13 (Google Ads creds + smoke):** completado el trabajo manual Ben pendiente (OAuth Client Web en `app-thenucleo`, Refresh Token via OAuth Playground, Developer Token MCC `H71Kpt_llSXQ6kdSio2Qxg`, `aic_set_with_key('google-ads', ...)` row `327bbbcb-...`). Smoke test E2E con workflow temporal `m77TBjKCZDaW1c4E` (ya borrado): PASS en 1.4s, **11 cuentas Google Ads accesibles** desde MCC `6005054046` (10 hijas ENABLED + MCC). Hallazgos: API v20+ obligatoria (v18/v19 404), `googleAds:search` no soporta `pageSize`, drift formato IDs (API sin guiones vs script legacy con guiones). Próximo bloqueo: migration `ads_normalize_google_ids` antes del Discovery.
>
> **Sesión 2026-05-12 (continuación):** workflow #1 `hwKBGC6QWP2dFObT` smoke test verde (ejec 120108, 23 cuentas + 3 alertas), tag `portal` aplicado y **activado** (cron */30 8-21 Madrid). Workflow #2 `VhlqAQ1vH9HldpH5` `SYNC ADS — Meta Estructura` creado + RPC `ads_upsert_estructura` aplicada, ambos pendientes smoke test (requiere marcar 1 cuenta activa).

# Control de Campañas (legacy: "Ops Monitor")

Reemplazo completo de la sub-funcionalidad **Operaciones → Control de campañas** del portal `portal.thenucleo.com`. Foco actual: **Meta Ads** (Google Ads en fase 2).

## Índice

1. [Iniciador para nuevo chat](#iniciador-para-nuevo-chat)
2. [Plan maestro](#plan-maestro)
3. [Estado actual (2026-05-12)](#estado-actual)
4. [IDs y referencias clave](#ids-y-referencias-clave)
5. [Decisiones técnicas tomadas](#decisiones-técnicas-tomadas)
6. [Bugs encontrados y fixes](#bugs-encontrados-y-fixes)
7. [Próximos pasos en orden](#próximos-pasos-en-orden)
8. [Anti-patrones evitados](#anti-patrones-evitados)
9. [Smoke tests realizados](#smoke-tests-realizados)

---

## Iniciador para nuevo chat

> Copia y pega exactamente este bloque al iniciar un nuevo chat. Da contexto completo en 1 mensaje sin necesidad de releer la sesión anterior.

```
Estoy continuando el módulo "Control de campañas" del portal TheNucleo.

ANTES DE NADA, lee el handoff completo: `docs/portal/integraciones/control-de-campanias.md`.
Wireframe HTML de referencia visual: `c:\tmp\ads_environment.html` (función renderAjustesCuentas es la pantalla actual).

ESTADO TRAS SESIÓN 2026-05-14 — foco: Bubble frontend pantalla "Cuentas Ads".

== INFRA (todo cerrado) ==

✅ Supabase: 7 tablas ads_* + 16 RPCs (panel/acciones/sync/helpers). Proyecto cbixhqjsnpuhcrcjppah.
✅ n8n: 9 workflows producción (Meta Discovery/Estructura/Daily/Intra-día + Google x4 + Acciones webhook).
   Endpoint acciones: POST https://n8n-n8n.irzhad.easypanel.host/webhook/ads_action

== BUBBLE — página control-ads (estado 2026-05-14) ==

✅ API Connector plugin "Control de Campañas": 11 calls (7 GET RPCs Supabase + 3 POST n8n + 1 RPC asignar).
   Initialize verde en todos.

✅ Params verificados en workflow Bubble:
   p_agencia_id = Current User's agencia_id's Uuid Supabase
   p_periodo    = last_7d  (sin comillas extra — template del API Connector ya tiene "")

✅ Custom states de la página control-ads:
   cuentas_vinculadas → Type: SUPABASE - ads_cuentas_panel  + is a list
   cuentas_pendientes → Type: SUPABASE - ads_cuentas_pendientes + is a list

✅ Page Loaded workflow (5 steps):
   Step 1: Set state Seccion_activa of Menu_lateral = A
   Step 2: API call ads_cuentas_panel   (p_agencia_id + p_periodo)
   Step 3: API call ads_cuentas_pendientes (p_agencia_id)
   Step 4: Set state cuentas_vinculadas = Result of Step 2
   Step 5: Set state cuentas_pendientes = Result of Step 3

✅ Table "Cuentas ya vinculadas":
   Type = SUPABASE - ads_cuentas_panel
   Data source = Current Page's cuentas_vinculadas
   9 columnas configuradas: Provider / Cuenta / Cliente / Ownership / BM Dueño /
   Estado / Asignada("—") / Último Sync / Acciones (Reasignar + Archivar)

✅ RepeatingGroup "Cuentas Ads pendientes":
   Type = SUPABASE - ads_cuentas_pendientes
   Data source = Current Page's cuentas_pendientes
   Estructura visual completa (chips filtros + search + cards con 5 bloques).
   ⚠️ Text elements YA COLOCADOS pero sin dato dinámico — pendiente cablear.

✅ KPI cards (5): Pendientes / Match ≥0.7 / Match <0.7 / Sin sugerencia / Problemas
   Expresiones: Current Page's cuentas_pendientes:filtered(...):count

== PENDIENTE (por orden) ==

1. CABLEAR text elements del RG "Cuentas Ads pendientes".
   Prefijo: Current cell's SUPABASE - ads_cuentas_pendientes's <campo>
   Campos del RPC: nombre, external_account_id, provider, currency, ownership,
   business_id, discovered_at, sugerencia_cliente_nombre, sugerencia_score,
   notas_count, account_status, disable_reason.

2. Conditionals del card (borde izquierdo de color):
   - account_status ≠ 1     → danger
   - sugerencia_score ≥ 0.7 → verde (accent)
   - sugerencia_score < 0.7 AND not empty → warn
   - sugerencia_score empty  → muted

3. Conditional tag DESHABILITADA/PAGO PENDIENTE:
   - account_status = 2 → texto "DESHABILITADA"
   - account_status = 3 → texto "PAGO PENDIENTE"

4. Filtros chips → filtran RG por estado del custom state "filtro_pendientes":
   Patrón: Ignore empty constraints ON + is in (memoria feedback_bubble_multidropdown_filter.md).
   Chips: Todas / Match ≥0.7 / Match <0.7 / Sin match / Con problema.

5. Botón Asignar → workflow:
   - Deshabilitar si account_status ≠ 1 (conditional: is not clickable)
   - Al click: API call ads_asignar_cliente (p_cuenta_id, p_cliente_id, p_autor)
     + re-run Page Loaded API calls + Set states

6. Botón Notas → abrir popup Notas (RPC ads_notas_listar + call ads_notas_crear).

7. Botones Reasignar/Archivar en tabla vinculadas → workflows n8n/RPC.

8. Pantalla Métricas (tabla cuentas activas + drill-down campañas/adsets/anuncios).

9. Pantalla Alertas (panel ads_alertas + botón Resolver).

== CONTEXTO CRÍTICO ==
- Bubble es SOLO display. Acciones = botón → webhook/RPC → reload states. Sin drag-drop ni edición inline.
- Patrón refresh: tras response webhook → re-run API calls del Page Loaded → Set states de nuevo.
- Wireframe HTML función renderAjustesCuentas() (línea 886) = spec exacta pantalla Cuentas Ads.
- Wireframe función renderControlCuentas() (línea 600) = spec pantalla Métricas.
- Wireframe función renderAlertas() (línea 1007) = spec pantalla Alertas.

Reglas: paso a paso, datos directos (no preguntar lo que ya está resuelto). Skill bubble-builder
obligatoria antes de cualquier expresión/workflow Bubble.
```

---

## Plan maestro

Ruta absoluta: `C:\Users\Benjamin\.claude\plans\whimsical-churning-shore.md`

Plan v5 aprobado. Contexto y decisiones de alto nivel ahí.

---

## Estado actual

### ✅ Fase 0 — Meta App + Auth (completada)

| Artefacto | Detalle |
|---|---|
| Meta App | Nombre `Ads Control Portal` · App ID `1626417301947904` · Tipo Empresa · En producción · Marketing API añadido |
| App Secret | `fa5b8f54abf4e16c5ec4ce6ce8e3fb71` (ROTAR al cerrar el setup) |
| Business Manager | `The Nucleo` · ID `459242169567605` |
| System User | `thenucleoadssync` · ID `122135715861053861` · Rol Admin · Token never-expires · 23 ad accounts visibles |
| Token | guardado cifrado en `agencia_integraciones_config` (id `4da2d9ab-2c36-46f7-bd71-f8c77b32c66f`) |
| Permisos | `ads_read`, `ads_management`, `business_management` (Standard Access — sin App Review) |

### ✅ Fase 1A — Schema Supabase (completada)

Proyecto: `cbixhqjsnpuhcrcjppah` (eu-west-1).

7 tablas `ads_*` creadas (migration `ads_schema_initial`):
- `ads_cuentas` (multi-provider, auto-discovery, `cliente_id` NULLABLE hasta asignar, `estado_interno IN (pendiente_asignar, activa, archivada, sin_acceso)`)
- `ads_campanias`, `ads_adsets`, `ads_anuncios` (snapshot + KPIs + scoring `winner/scalable/ontarget/fatigue/loser/nodata`)
- `ads_insights_diario` (time-series INSERT-only via UPSERT)
- `ads_notas` (audit trail acciones desde Bubble)
- `ads_alertas` (alertas operativas — UNIQUE `(entity_external_id, reason)` desde migration `ads_alertas_unique_fix`)

Realtime publication ON sobre las 7. RLS service_role only. 5 triggers `updated_at` (insights_diario y notas son INSERT-only sin trigger). 27 índices.

⚠️ **NO se ha tocado** `bub_dashboardmedia_alertas_operativas` (686 filas) ni `bub_dashboardmedia_cuentas_ads` (5 filas). Convivencia temporal hasta migración final post-validación E2E.

### ✅ Fase 1B — RPCs Supabase (completadas)

11 funciones (migration `ads_rpcs_initial`):
- Panel: `ads_cuentas_panel(p_agencia, p_periodo)`, `ads_cuentas_pendientes(p_agencia)`, `ads_campanias_panel`, `ads_adsets_panel`, `ads_anuncios_panel`, `ads_insights_serie`, `ads_notas_listar`
- Acción: `ads_asignar_cliente(p_cuenta, p_cliente, p_autor)`, `ads_notas_crear(...)`
- Helpers portados de OptiMetrics: `ads_extract_conversion(p_actions, p_action_values)` (parseIns) + `ads_calcular_scoring(p_cuenta)` (scoreAll)

GRANT EXECUTE a `authenticated` solo en panels/list. Writes/helpers solo service_role.

### ✅ Sistema `aic_*` (bugfix + wrappers)

Migration `aic_fix_search_path_pgcrypto`: arregló bug `pgp_sym_encrypt does not exist` (search_path original sin `extensions`).

Migration `aic_with_key_wrappers`: wrappers nuevos
- `aic_set_with_key(p_agencia, p_slug, p_provider, p_creds, p_key, p_meta)` → uuid
- `aic_get_with_key(p_agencia, p_slug, p_key)` → jsonb

Migration `ads_meta_creds_listas_jsonb`: RPC específica meta-ads que descifra + calcula HMAC-SHA256 `appsecret_proof` en una sola transacción (workaround task runner n8n que bloquea `crypto.subtle`/`require('crypto')`):
- `ads_meta_creds_listas(p_agencia, p_key)` → jsonb `{access_token, appsecret_proof, app_id, business_id, system_user_id}`

### ✅ AIC_KEY configurada en n8n

- Variable de entorno `AIC_KEY` en EasyPanel container n8n
- También se añadió `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` (default true bloquea `$env.*` desde Code/expressions)
- Validada con length 32 desde Code node
- Solo Ben conoce el valor; vive en EasyPanel y se pasa como parámetro a las RPCs `aic_*_with_key`

### ⏳ Fase 1C — Workflows n8n (2 de 8 creados)

**Workflow #1: `SYNC ADS — Meta Discovery Cuentas`** (id `hwKBGC6QWP2dFObT`) — ✅ **ACTIVO**

- Smoke test ejecuciones 120077, 120090, 120102, **120108 (success, 4s, 23 cuentas + 3 alertas)** — fix `ads_alertas_unique_fix` validado E2E.
- 6 nodos: Cron → Descifrar Creds Meta (`ads_meta_creds_listas`) → GET Meta `/me/adaccounts` → Mapear cuentas + derivar alertas → fan-out a UPSERT ads_cuentas + UPSERT ads_alertas.
- Settings: timezone Europe/Madrid · errorWorkflow `HRDQ9Ju4NAIUV0qyhKzlz` · availableInMCP true.
- Tag `portal`: ✅ APLICADO (+ tag `ads`). Workflow ✅ ACTIVO (cron `*/30 8-21 * * *`).

**Workflow #2: `SYNC ADS — Meta Estructura`** (id `VhlqAQ1vH9HldpH5`) — ✅ **ACTIVO**

- 9 nodos en cadena con loop SplitInBatches:
  `Cron 05:30 daily Madrid → Descifrar Creds Meta → GET Cuentas Activas (PostgREST filter estado_interno=eq.activa) → Iterar Cuentas (Split size 1) → GET /v19.0/<acc>/campaigns → GET /<acc>/adsets → GET /<acc>/ads → Code "Armar Payload RPC" → POST /rpc/ads_upsert_estructura → loop back`
- Settings: timezone Europe/Madrid · errorWorkflow `HRDQ9Ju4NAIUV0qyhKzlz`.
- Tags `portal` + `ads` aplicados ✅. ACTIVO desde 2026-05-12 17:21 UTC.
- Smoke test ejec **120121 (success, 9.5s)** sobre cuenta `act_619783006508057` The Nucleo: 32 campañas + 43 adsets + 87 anuncios poblados en Supabase.

**Workflow #3: `CRON ADS — Meta Daily 06:00`** (id `pIxC6RNqHISWvpoU`) — ⏸ INACTIVO

- 11 nodos en cadena con loop SplitInBatches:
  `Cron 06:00 daily Madrid → Descifrar Creds Meta → Calcular Fecha Ayer (Code) → GET Cuentas Activas → Iterar Cuentas (Split size 1) → GET /v19.0/<acc>/insights level=account → idem level=campaign → level=adset → level=ad → Code "Armar Payload Insights" (merge 4 arrays con entity_type) → POST /rpc/ads_insertar_insights_diario → loop back`
- Settings: timezone Europe/Madrid · errorWorkflow `HRDQ9Ju4NAIUV0qyhKzlz` · `availableInMCP=true`.
- Smoke test ejec **120124 (success, 5.3s)** sobre cuenta The Nucleo: 4 filas en `ads_insights_diario` (1 por entity_type). Spend 19.07€, 2923 impr, 37 clicks, CTR 1.27%, CPC 0.52€, conv=0 (cuenta sin tracking pixel/CAPI configurado).
- Tag `portal`: ⚠️ PENDIENTE UI. URL: https://n8n-n8n.irzhad.easypanel.host/workflow/pIxC6RNqHISWvpoU
- Activación pendiente tras tag.

**Workflow #4: `CRON ADS — Google Y Meta Intra-día 30min`** (id `Uqv3R3txzcg8GI1B`) — ✅ **ACTIVO** (unificado 2026-05-21)

- 20 nodos: el cron `*/30 8-21 Madrid` lanza 2 ramas paralelas (Google + Meta) independientes, cada una con su propio loop SplitInBatches y scoring inline.
- **Rama Google (10 nodos):**
  `Descifrar Creds Google (RPC aic_get_with_key p_slug=google-ads) → Refresh → Access Token (POST oauth2.googleapis.com/token) → GET Cuentas Activas (eq.google) → Iterar Cuentas → GAQL Snapshot Campaign (LAST_7_DAYS) → GAQL Snapshot AdGroup → GAQL Snapshot Ad → Code "Armar Payload Snapshot Google" → POST /rpc/ads_actualizar_kpis_snapshot → POST /rpc/ads_calcular_scoring → loop back`
  - Mapping Google → schema canónico: `costMicros/1e6 → spend`, `ctr*100 → ctr` (Google viene 0–1, Meta en %), `averageCpc/1e6 → cpc`, `conversions → actions[purchase]`, `conversionsValue → action_values[purchase]`, `reach/frequency → null` (Google no los devuelve).
  - Reliability: los 3 GAQL + 2 RPCs llevan `onError: continueRegularOutput` para que un fallo de cuenta no detenga el loop.
- **Rama Meta (10 nodos):**
  `Descifrar Creds Meta → GET Cuentas Activas1 (eq.meta) → Iterar Cuentas1 → GET Insights Campaign (last_7d) → GET Insights Adset → GET Insights Ad → Code "Armar Payload Snapshot" → POST /rpc/ads_actualizar_kpis_snapshot → POST /rpc/ads_calcular_scoring → loop back`
  - Réplica byte-a-byte del workflow legacy `BCgSCKjzryYaFYMC` (mismos endpoints v19.0, mismos campos, mismos parámetros). Sin `onError` extra — si revienta cae al errorWorkflow.
- Settings: timezone Madrid · errorWorkflow `HRDQ9Ju4NAIUV0qyhKzlz` · `availableInMCP=true`.
- Tags `portal` + `ads` aplicados ✅. ACTIVO desde 2026-05-13; rama Google añadida y unificada con Meta el 2026-05-21.
- **Por qué fusión Google+Meta:** ambas ramas comparten cron idéntico y los mismos 2 RPCs downstream. Mantenerlos en workflows separados desincronizaba la ventana de snapshot vista por Bubble (Google y Meta refrescando KPIs en momentos ligeramente distintos cada 30 min). Fusionando, ambos providers escriben en la misma franja temporal.

**Workflow #4-legacy: `CRON ADS — Meta Intra-día 30min`** (id `BCgSCKjzryYaFYMC`) — ⏸ **INACTIVO desde 2026-05-21**

- Sustituido por la rama Meta del workflow unificado `Uqv3R3txzcg8GI1B` (réplica byte-a-byte de sus 10 nodos).
- Conservado sin archivar como fallback de rollback rápido. No modificar.
- Smoke test histórico ejec **120129 (success, 4.3s)** sobre cuenta The Nucleo: campaña "Form Nativo" spend 135.78€ / 23149 impr / 292 clicks / CTR 1.26% / CPC 0.47€ / conv=6 / CPA 22.63€ / score='ontarget'.

**Workflow #5 (fusionado #6+#7+notas): `OPS ADS — Acciones Bubble [WEBHOOK]`** (id `sNpVWEkinc4g0KfA`) — ✅ **ACTIVO**

- 17 nodos. Webhook `/ads_action` (typeVersion 2.1, `onError: continueRegularOutput`, responseMode: responseNode) → Switch Action (v3.4, mode expression, 4 outputs: refresh/status_toggle/nota_crear/fallback) routea a 3 branches paralelas, cada una termina en su propio Respond to Webhook (typeVersion 1.5):
  - **refresh** (9 nodos): GET cuenta → Descifrar Creds → 3 GETs Meta Insights (campaign/adset/ad, last_7d) → Armar Payload → POST kpis_snapshot → POST scoring → Respond.
  - **status_toggle** (4 nodos): Descifrar Creds → POST `graph.facebook.com/<id>` con `status` → POST `ads_aplicar_status_toggle` → Respond.
  - **nota_crear** (2 nodos): POST `ads_notas_crear` → Respond.
- Settings: timezone Madrid · errorWorkflow `HRDQ9Ju4NAIUV0qyhKzlz` · `availableInMCP=true`.
- Smoke tests:
  - nota_crear ejec **120146 (success, 0.4s)** ✅
  - status_toggle ejec **120147 (success, 1.4s)** sobre campaña PAUSED→PAUSED ✅
  - refresh ejec **120149 (success, 3.7s)** sobre cuenta The Nucleo ✅
- Tags `portal` + `ads` aplicados ✅. **ACTIVO** desde 2026-05-12.
- **Endpoint público PROD**: `POST https://n8n-n8n.irzhad.easypanel.host/webhook/ads_action` (validado E2E con curl externo HTTP 200 / 297ms).

**Payload Bubble (ejemplos):**

```json
// refresh
{ "action": "refresh", "cuenta_id": "<uuid Supabase>" }

// status_toggle
{
  "action": "status_toggle",
  "agencia_id": "<uuid>", "cuenta_id": "<uuid>",
  "entity_type": "campaign|adset|ad",
  "entity_external_id": "<id Meta>",
  "new_status": "ACTIVE|PAUSED|ARCHIVED",
  "autor_user_id": "<email>"
}

// nota_crear
{
  "action": "nota_crear",
  "agencia_id": "<uuid>", "cuenta_id": "<uuid>",
  "entity_type": "campaign|adset|ad",
  "entity_external_id": "<id Meta>",
  "autor_user_id": "<email>",
  "titulo": "<text>",
  "contenido": "<text>",
  "tipo": "manual"
}
```

**Workflow Google legacy redirigido a `ads_alertas`: `OPS ADS — Receptor Google Ads Script`** (id `fdmkhBOua6pbZh6P`) — ✅ ACTIVO (legacy mantenido en convivencia)

- 11 nodos. Trigger: webhook `POST /webhook/google-ads-alertas` ← Google Apps Script externo "TheNucleo — Ops Monitor" (en `ads.google.com` MCC TheNucleo → Herramientas → Scripts, programado cada hora) que itera `AdsManagerApp.accounts().get()` y empuja alertas JSON pre-formateadas.
- 5 detecciones en el Apps Script: `rechazo` (ad.approval_status=DISAPPROVED), `limitada_presupuesto` (spend hoy ≥ 95% budget), `gasto_caido` (delta hoy/ayer < -40%), `quality_score` (keyword QS<4), `cpc_anomalo` (CPC hoy > 1.25× media 7d).
- **Cambio 2026-05-12**: añadido nodo `POST ads_upsert_alerta_google` conectado en PARALELO al "Humanizar alerta con IA" desde "Lookup Cuentas_Ads". La rama legacy (Humanizar → Crear alerta en Bubble) sigue intacta. La nueva rama llama a RPC `ads_upsert_alerta_google` con **auto-discovery**: si el `customer_id` no existe en `ads_cuentas`, lo crea como `pendiente_asignar` con `provider='google'`.
- Smoke test E2E: curl externo POST `/webhook/google-ads-alertas` con 2 alertas sintéticas → HTTP 200 / 5.4s → ambas en `ads_alertas` con `cuenta_id` resuelto a Limón y Kiwi.
- 1 cuenta importada manualmente: `562-486-5472` Limón y Kiwi (uuid `55c3d3e1-c491-49cb-a10e-16d5ed82bcf8`, cliente_notion_id `2ffe4743-...`, estado_interno `activa`). Resto de cuentas que el script descubra se crearán automáticamente como `pendiente_asignar` cuando lleguen alertas.

### ⏳ Fases pendientes

| Fase | Estado |
|---|---|
| 1C Workflows Meta (5 de 5) | ✅ Activos producción + smoke E2E |
| 1C Google Ads alertas legacy → ads_alertas (auto-discovery) | ✅ Workflow `fdmkhBOua6pbZh6P` modificado, smoke E2E verde 2026-05-12 |
| 1.5 Onboarding cliente Meta | Pendiente |
| 2A Bubble API Connector (11 calls: 7 GET Supabase + 3 POST n8n + 1 RPC asignar) | ✅ Specs entregadas + Initialize verde 2026-05-13. Pendiente re-Initialize tras migration `ads_panel_pendientes_extended` |
| 2B Bubble pantallas (Métricas + Alertas + Cuentas Ads) | Pendiente (manual Ben) — wireframe completo `c:\tmp\ads_environment.html` con datos reales |
| 2C Realtime (descartado plugin) | ✅ Patrón decidido: **re-run on action + botón refresh manual**. Sin plugin. Cubre el caso "el que toca, ve" que es lo requerido. Multi-user con drift por refresh manual. |
| Google Ads OAuth corporate + Developer Token + aic_set | ✅ Hecho 2026-05-13: row `327bbbcb-...`, smoke test verde (11 cuentas) |
| Migration `ads_normalize_google_ids` (REPLACE guiones + RPC normaliza entry point) | ✅ Hecho 2026-05-13 (5 filas normalizadas + `ads_upsert_alerta_google` con regexp_replace) |
| Google Ads Discovery/Estructura/Daily/Intra-día (4 workflows) | ✅ ACTIVOS 2026-05-13. Smoke E2E verde en los 4 (executions 120830/120866/120867/120876). Tags `portal+ads` aplicados. |
| Ramificar workflow #5 Acciones (branch status_toggle Google) | ✅ Hecho 2026-05-13. 8 nodos nuevos en branch FALSE del IF Provider Meta. Smoke verde ejec `120880` (Campaign Limón y Kiwi PAUSED→PAUSED). Migration `ads_aplicar_status_toggle_google_aware` para enum extendido. |
| Archivar workflow Gmail `4gN3uGhH8NZX2BDU` | Pendiente (tras 2 semanas smoke test) |

### 🏗️ FASE 2 Bubble — decisiones de UX consolidadas (2026-05-13)

**Jerarquía de navegación** (vive bajo Operaciones, NO bajo Ajustes):

```
Operaciones
└── Control de Campañas           ← agrupador sidebar
    ├── Métricas                  ← dashboard operativo diario (KPIs cuentas activas + drill-down 3 niveles)
    ├── Alertas                   ← panel `ads_alertas` con resoluble manual
    └── Cuentas Ads               ← setup / asignación / reasignación (Pendientes + Activas metadata-only)
```

**Reglas de separación de responsabilidades** entre sub-secciones:

| Sub-sección | Frecuencia uso | Qué muestra | Qué NO muestra |
|---|---|---|---|
| **Métricas** | Diaria, varias veces | Tabla cuentas activas con KPIs spend/conv/ctr/cpa/freq/score + drill-down campañas → adsets → anuncios + switches pausar/activar + notas por entidad | Cuentas pendientes (eso vive en Cuentas Ads) |
| **Alertas** | Diaria | Panel `ads_alertas` filtradas por sev (pago/crítica/warning), provider, cuenta. Botón "Resolver" → UPDATE resolved_at | KPIs |
| **Cuentas Ads** | Semanal o menos | Cards pendientes con fuzzy match + dropdown asignar + tabla activas SOLO metadata (cliente, ownership, BM dueño, fecha asignación, último sync). Cero KPIs. | KPIs (esos están en Métricas) |

**Scoring** (portado de OptiMetrics `scoreAll`):

| Score | Lectura para un media buyer | Criterio aproximado |
|---|---|---|
| **winner** | Top performance, proteger | CPA pct 75+ ∧ CTR pct 65+ |
| **scalable** | Buena, con margen para escalar | CPA pct 55+ ∧ CTR pct 45+ |
| **ontarget** | Estable, dentro de objetivo | El resto que convierte sin alarmas |
| **fatigue** | Saturación creativa | Freq ≥ 5 ∧ CTR cayendo |
| **loser** | Crítica, decidir antes de seguir gastando | Freq ≥ 7 o (CPA pct <20 ∧ CTR pct <25) |
| **nodata** | Sin spend / sin métricas | Pausada o recién lanzada |

"**Cuentas sanas**" = unión de winner + scalable + ontarget. KPI visible en Métricas.

**Patrón Realtime descartado** (decisión consolidada):

- Plan v5 inicial decía "Supabase Realtime con plugin". Tras analizar caso de uso real ("multi-user pero el que toca tiene que ver lo que hace en tiempo real, drift entre users es OK") → **patrón decidido sin plugin**:
  - Tras response del webhook (refresh/status_toggle/nota_crear) → workflow Bubble re-corre las API calls de los RGs de la pantalla → el que disparó la acción ve su cambio inmediato.
  - Botón `↻ Refresh` manual en cada pantalla para drift entre usuarios o cron */30min en background.
  - 0 plugins, 0 WU idle, 100% Bubble vanilla.
- Si en F2 entran muchos media buyers concurrentes y se quiere ver cambios de otros en vivo → reevaluar plugin Supabase Realtime entonces.

**Wireframe HTML standalone**: `c:\tmp\ads_environment.html` con datos reales 2026-05-13 (28 pendientes + 1 activa + 12 campañas + 10 adsets + 6 anuncios + 12 alertas). Sirve como referencia visual fiel para construir las 3 pantallas en Bubble.

### 🔒 Deuda técnica seguridad (revisar a futuro)

- **API Connector Bubble "Control de Campañas" usa `service_role` (Private) en shared header** — mismo patrón que el resto de APIs Supabase del portal (Clockify, Análisis Cliente, Newsletter, etc.). Marcado Private → vive solo en servidor Bubble, no se expone al cliente. **Riesgo residual**: cualquier workflow Bubble accesible al user efectivamente bypassea RLS porque la RPC corre con service_role. Aceptable mientras las RPCs `ads_*_panel` filtren internamente por `p_agencia_id` (lo hacen). **Revisar cuando**: (a) haya multi-tenant real con más de una agencia en producción, o (b) migración a auth Supabase nativo desde Bubble (descartado actualmente por fricción UX). Tracking: 2026-05-13.

---

## IDs y referencias clave

### Supabase

```
Proyecto: cbixhqjsnpuhcrcjppah (eu-west-1)
URL:      https://cbixhqjsnpuhcrcjppah.supabase.co
Agencia:  e748c7d4-5823-413d-8cb3-532896f6e41d
```

Migrations aplicadas (orden cronológico):
1. `ads_schema_initial`
2. `ads_rpcs_initial`
3. `aic_with_key_wrappers`
4. `aic_fix_search_path_pgcrypto`
5. `ads_meta_creds_listas` (TABLE return — DEPRECADO)
6. `ads_meta_creds_listas_jsonb` (jsonb return — el bueno)
7. `ads_alertas_unique_fix` (fix bug 42P10)
8. `ads_upsert_estructura` (RPC `(p_cuenta_id, p_campanias, p_adsets, p_anuncios) RETURNS jsonb` — UPSERT atómico de campañas/adsets/anuncios con FK resolution interna; consumida por workflow `VhlqAQ1vH9HldpH5`)
9. `ads_insertar_insights_diario` (RPC `(p_cuenta_id, p_fecha, p_rows) RETURNS jsonb` — UPSERT a `ads_insights_diario` calculando conv/revenue via `ads_extract_conversion` + roas/cpa con protección div-zero; consumida por workflow `pIxC6RNqHISWvpoU`)
10. `ads_actualizar_kpis_snapshot` (RPC `(p_cuenta_id, p_preset, p_campanias, p_adsets, p_anuncios) RETURNS jsonb` — UPDATE de KPIs snapshot en las 3 tablas de entidad; aplica `ads_extract_conversion` + roas/cpa/cvr con protección div-zero; consumida por workflow unificado `Uqv3R3txzcg8GI1B` (ambas ramas Google + Meta) y por `sNpVWEkinc4g0KfA` branch refresh. Legacy `BCgSCKjzryYaFYMC` desactivado 2026-05-21)
11. `ads_aplicar_status_toggle` (RPC `(p_agencia_id, p_cuenta_id, p_entity_type, p_entity_external_id, p_new_status, p_autor_email) RETURNS jsonb` — UPDATE status en tabla correspondiente + INSERT `ads_notas` tipo='accion' + INSERT `activity_log`; consumida por workflow `sNpVWEkinc4g0KfA`)
12. `ads_notas_crear_returns_jsonb` (DROP+CREATE — cambio de `ads_notas_crear` `RETURNS uuid` → `RETURNS jsonb` `{ok, nota_id}`; PostgREST text/plain con scalar rompe parseo n8n)
13. `ads_upsert_alerta_google` (RPC `(p_agencia_id, p_customer_id, p_tipo, p_campaign_name, p_ad_id, p_detalle, p_titulo, p_external_id, p_es_critica, p_cliente_id) RETURNS jsonb` — **auto-discovery** + UPSERT alerta. Si customer_id no existe en `ads_cuentas`, lo crea como `pendiente_asignar`. Consumida por workflow legacy `fdmkhBOua6pbZh6P` en paralelo a Bubble)

### Meta

```
App ID:           1626417301947904  (app: "Ads Control Portal")
App Secret:       fa5b8f54abf4e16c5ec4ce6ce8e3fb71  (rotar al final)
Business Manager: The Nucleo · ID 459242169567605
System User ID:   122135715861053861  (thenucleoadssync)
System User Token: EAA... (guardado cifrado en aic_*, NO repetir aquí)
Permissions:      ads_read, ads_management, business_management
Access Level:     Standard
Token Expiry:     Never
```

### n8n

```
Instancia:     https://n8n-n8n.irzhad.easypanel.host
EasyPanel:     container n8n (env vars: AIC_KEY, N8N_BLOCK_ENV_ACCESS_IN_NODE=false, WEBHOOK_URL, N8N_RUNNERS_MAX_OLD_SPACE_SIZE=512)
Tag portal:    8JEzIL3gJwyclObr
Workflow #1:   hwKBGC6QWP2dFObT (SYNC ADS — Meta Discovery Cuentas) ⏸ inactivo
Error WF:     HRDQ9Ju4NAIUV0qyhKzlz (ERRORES — Capturar y Registrar Plataforma)
Cred Supabase: 13dKSjEd2XZCYpJa (1. Espejo Supabase) ← la que usa SYNC ABSOLUTO
```

### Ad accounts descubiertas (23)

Todas en EUR. Las 3 con problemas operativos:
- `act_602669753672904` Worknature Visual — status 3 UNSETTLED (pago pendiente)
- `act_1322520174901846` Nubes de Algodon — status 2, disable_reason 15 (deshabilitada)
- `act_645522843669890` Tengo Teatro 2 — status 2, disable_reason 3 (deshabilitada)

Las 2 "owned" (BM TheNucleo):
- `act_662490442156132` (sin nombre, balance 0, owned)
- `act_619783006508057` The Nucleo (balance 167.29€, owned)

Resto 18 partner.

---

## Decisiones técnicas tomadas

| Decisión | Por qué | Alternativas descartadas |
|---|---|---|
| Patrón datos: Cache Supabase + Realtime push | Bubble lee Supabase (0 coste Meta por vista). Realtime refresca UI cuando cron actualiza. | On-demand puro (estilo OptiMetrics): cada vista pega a Meta. Caro y no escala. |
| Cron */30 min 08-21 + cron 06:00 Daily | Rate limit Meta Standard Access es `300 + 40 × active_ads` calls/hora por ad account. Uso real ~10 puntos/h por cuenta. Margen 30×. | Cron horario o on-demand puro. |
| Schema `ads_*` (no `bub_*`) | Fuente es Supabase, Bubble lee. Mismo patrón que `clockify_*`/`holded_*`. | `bub_*` (espejo Bubble) o RENAME tablas viejas — habría roto Gmail listener + Google Ads Script legacy. |
| Wrappers `aic_*_with_key` | Permite n8n llamar via PostgREST HTTP simple (no conexión PostgreSQL directa con SET LOCAL). Atomicidad garantizada. | Nodo PostgreSQL con SET LOCAL — funcional pero más infraestructura. |
| HMAC en Supabase (`ads_meta_creds_listas`) | Task runner n8n bloquea `crypto.subtle` y `require('crypto')`. pgcrypto.hmac() lo resuelve en una sola transacción. | HMAC puro JS en Code node — feo y frágil. |
| RPC `RETURNS jsonb` (no TABLE) | n8n auto-promociona inconsistentemente. jsonb devuelve objeto plano. | RETURNS TABLE — requiere `($json[0] \|\| $json).field` defensivo en cada nodo siguiente. |
| Cred Supabase `13dKSjEd2XZCYpJa` (no `pmc312jjJKdPClmj`) | Verificada inspeccionando SYNC ABSOLUTO `FGxG67I24POOUeHW`. Apunta a proyecto correcto `cbixhqjsnpuhcrcjppah`. | `pmc312jjJKdPClmj` (asumido por skill n8n desactualizada). |
| Web Crypto API descartada en favor de Supabase HMAC | Aunque `crypto.subtle` está disponible en Node 16+, el task runner n8n usa `vm.runInContext` sin exponer `crypto` global. Bloqueado por anti-patrón #15. | — |
| Bubble en modo display + 3 acciones controladas | Memory `feedback_bubble_solo_lectura`. Excepciones aprobadas: filtros UI, notas internas, pausar/activar (NO presupuesto, NO creación). | Bubble drag-drop / edición inline / cambio presupuesto desde Bubble. |
| App Meta creada desde cero (no reciclar OptiMetrics) | App Ben personal `26693925696941734` queda archivada. `Ads Control Portal` 1626417301947904 es la corporate. | Reusar OptiMetrics. |
| System User renombrado de `SheetsReporting` (en lugar de crear nuevo) | Meta BM Standard solo permite 1 admin System User. SheetsReporting era admin único. Renombrar conserva su ID (61581615834355 → display name `thenucleoadssync`, ID System User 122135715861053861). Los tokens existentes que tenía siguen vivos. | Crear otro admin (bloqueado) o pasar SheetsReporting a employee (rompe lo que use). |

---

## Bugs encontrados y fixes

### Bug 1: Sistema `aic_*` nunca funcionó (creado 2026-05-04, vacío hasta hoy)

**Síntoma:** primer `aic_set` falló con `42883: function pgp_sym_encrypt(text, text) does not exist`.

**Causa:** `pgcrypto` instalado en schema `extensions`, pero `aic_set`/`aic_get` originales sin `SET search_path` → no encontraban `pgp_sym_encrypt`.

**Fix:** migration `aic_fix_search_path_pgcrypto` — recreó `aic_set`, `aic_get` + creó wrappers `_with_key` con `SET search_path = public, extensions, pg_temp`.

**Lección:** funciones SECURITY DEFINER que usan extensiones deben declarar search_path explícito incluyendo `extensions`.

### Bug 2: `crypto is not defined` en Code node n8n

**Síntoma:** ejecución 120090, nodo "Calcular appsecret_proof" falla con `ReferenceError: crypto is not defined`.

**Causa:** task runner n8n usa `vm.runInContext` que NO expone `crypto` global (aunque Node 16+ lo trae). Anti-patrón documentado #15.

**Fix:** mover HMAC a Supabase. Migration `ads_meta_creds_listas_jsonb` crea RPC que descifra creds + calcula `appsecret_proof` HMAC-SHA256 con `pgcrypto.hmac()` en la misma transacción. Workflow actualizado: eliminado Code node + URL nueva `/rpc/ads_meta_creds_listas`.

**Lección:** evitar `crypto`, `require`, `https`, `fetch` en Code nodes. Mover crypto a Postgres si se puede.

### Bug 3: PostgREST `on_conflict` con partial unique index

**Síntoma:** ejecución 120102, nodo "UPSERT ads_alertas" falla con `42P10 there is no unique or exclusion constraint matching the ON CONFLICT specification`.

**Causa:** Schema original tenía `CREATE UNIQUE INDEX uq_ads_alertas_abierta WHERE resolved_at IS NULL`. PostgREST requiere UNIQUE constraint **completo** (sin WHERE) para `ON CONFLICT`.

**Fix:** migration `ads_alertas_unique_fix` — DROP partial index + ADD `UNIQUE(entity_external_id, reason)` constraint completo. Una alerta resuelta + nueva detección actualizan la misma fila (resolved_at se gestiona por app, Bubble filtra `resolved_at IS NULL`).

**Verificado:** ejecución 120108 (2026-05-12 17:06 UTC, 4s success). 23 cuentas + 3 alertas insertadas sin error 42P10.

### Bug 4 (descubierto pero no aplicable): n8n MCP `addTag` reporta success y no aplica tag

**Síntoma:** `n8n_update_partial_workflow` con `addTag: portal` devuelve success pero el tag NO aparece.

**Workaround:** PUT REST `https://n8n-n8n.irzhad.easypanel.host/api/v1/workflows/{id}/tags` con header `X-N8N-API-KEY` y body `[{"id":"8JEzIL3gJwyclObr"}]`.

**Pendiente:** aplicar al workflow `hwKBGC6QWP2dFObT` desde UI o con API key.

---

## Próximos pasos en orden

### Inmediato (al retomar)

1. ✅ ~~Workflow #1 `hwKBGC6QWP2dFObT`: smoke test verde, tag `portal` aplicado, activado.~~
2. **Workflow #2 `VhlqAQ1vH9HldpH5` `SYNC ADS — Meta Estructura`**:
   - **(a)** Aplicar tag `portal` desde UI (bug MCP `addTag`). URL: https://n8n-n8n.irzhad.easypanel.host/workflow/VhlqAQ1vH9HldpH5
   - **(b)** Marcar 1 cuenta como `activa` para smoke test: `UPDATE ads_cuentas SET estado_interno='activa' WHERE external_account_id='act_619783006508057';` (The Nucleo owned).
   - **(c)** Smoke test: ejecución manual + validar `SELECT count(*) FROM ads_campanias/ads_adsets/ads_anuncios WHERE cuenta_id=<uuid>`.
   - **(d)** Si OK, activar el workflow (toggle Active).

### Workflows n8n restantes (7)

Crear en este orden:

5. `SYNC ADS — Meta Estructura` — extiende Discovery con campañas/adsets/anuncios. Itera `ads_cuentas` con estado_interno='activa', llama `/<ad_account_id>/campaigns?fields=...&limit=500`, idem adsets y ads. UPSERT en tablas correspondientes. Cron 05:30 daily.

6. `CRON ADS — Meta Daily 06:00` — insights del día anterior por entidad → `ads_insights_diario`. `time_range={"since":"YYYY-MM-DD","until":"YYYY-MM-DD"}`.

7. `CRON ADS — Meta Intra-día 30min` — `date_preset=last_7d` snapshot KPIs en `ads_campanias`/`adsets`/`anuncios`. Llama SUB scoring después.

8. `OPS ADS — Recalcular Scoring [SUB]` — llamado por intra-día. RPC `ads_calcular_scoring(p_cuenta_id)` por cuenta.

9. `OPS ADS — Refresh On-Demand [WEBHOOK]` — disparado por botón "Actualizar ahora" Bubble.

10. `OPS ADS — Pausar/Activar Entidad [WEBHOOK]` — botones Bubble. POST `/<entity_id> {status}`. UPSERT estado + INSERT `ads_notas` tipo=accion + INSERT `activity_log`.

11. Equivalentes Google Ads (Daily + Intra-día) — Cuando Ben tenga OAuth refresh token MCC.

### Para todos los workflows

- Tag `portal` obligatorio (vía PUT REST por bug `addTag` MCP).
- `errorWorkflow: HRDQ9Ju4NAIUV0qyhKzlz`.
- Timezone `Europe/Madrid`.
- Llamar `aic_get_with_key` o `ads_meta_creds_listas` para descifrar creds, nunca tokens hardcoded.
- Respetar BUC: leer header `x-business-use-case-usage`, si score>75 → Wait `estimated_time_to_regain_access × 60s + 60s`.
- Batch nativo `?ids=` (max 50) cuando se itere por múltiples ad accounts.
- Validar antes de crear vía `validate_workflow` MCP.
- Smoke test manual antes de activar cron.

### Tras workflows validados

12. **Onboarding cliente Meta** (proceso operativo, no técnico):
    - Cliente añade BM TheNucleo (`459242169567605`) como Partner en su Business Settings con permiso "Manage campaigns".
    - Siguiente cron descubre automáticamente la nueva ad account → `ads_cuentas` con `estado_interno='pendiente_asignar'`.
    - Ben asigna desde Bubble Ajustes → Meta Ads.

13. **Bubble (manual)**:
    - API Connector: 7 calls SELECT (paneles + insights + notas listar) + 3 webhooks POST (notas crear, status_toggle, refresh).
    - Pantalla Ajustes → Integraciones → Meta Ads (RG cuentas pendientes con fuzzy match cliente).
    - Pantalla Control de campañas rediseñada (filtros, smartbar, tabla, drill-down 3 niveles, charts, switches, notas, refresh).
    - Plugin Supabase Realtime para refresh automático RGs.
    - Añadir Meta + Google a `bub_addons_catalogo` Data Type.

14. **Migración final**:
    - Archivar workflow `4gN3uGhH8NZX2BDU` (Gmail listener) tras 2 semanas de smoke test del polling Meta.
    - INSERT histórico `bub_dashboardmedia_alertas_operativas` → `ads_alertas`.
    - DROP `bub_dashboardmedia_alertas_operativas` y `bub_dashboardmedia_cuentas_ads`.
    - Borrar `META_USER_TOKEN` y `GOOGLE_ACCESS_TOKEN` del `.env` OptiMetrics.
    - Archivar app `OptiMetrics` (26693925696941734) en developers.facebook.com.

---

## Anti-patrones evitados

Memorias críticas aplicadas en esta sesión:

- **`feedback_n8n_task_runner_this.md`**: bloqueado `crypto.subtle` y `require('crypto')` → HMAC movido a Supabase.
- **`feedback_n8n_addtag_bug.md`**: MCP `addTag` no aplica → workaround PUT REST documentado.
- **`feedback_n8n_update_borra_creds.md`**: evitar `update_full_workflow` → usar `update_partial_workflow` con `patchNodeField`.
- **`feedback_n8n_mcp_array_indices.md`**: `patchNodeField` con `params[N].value` rompe arrays → usar `removeNode + addNode` para items de array.
- **`feedback_n8n_postgrest_json0.md`**: PostgREST RETURNS TABLE devuelve array, n8n auto-promociona inconsistentemente → usar RETURNS jsonb cuando posible.
- **`feedback_doc_vs_realidad.md`**: docs n8n drift → verificar contra MCP, no asumir.
- **`feedback_naming_tareas_reservado.md`**: nombres de tabla `ads_*` (no `tareas`).
- **`project_supabase_rules.md`**: parámetros `p_`, `SECURITY DEFINER` + `search_path`, RLS service_role only.
- **`feedback_bubble_solo_lectura.md`**: Bubble es display, acciones vía webhook→n8n→provider→polling.
- **`feedback_user_identifier_email.md`**: `cliente_id` = notion_id canónico, `agencia_id` = uuid Supabase.

---

## Smoke tests realizados

### Sistema `aic_*`

```sql
-- aic_set_with_key + aic_get_with_key con clave dummy 32 chars
DO $$ ... $$;  -- Resultado: cifrado/descifrado OK, clave incorrecta rechazada.
```

### Token Meta validado contra Graph API

```bash
curl -sG "https://graph.facebook.com/v19.0/me/adaccounts" \
  --data-urlencode "access_token=EAA..." \
  --data-urlencode "appsecret_proof=59d39a935605d934044cec1992bd2c06751ba63ebcf3c8ef409a706cc27cfcb3"
# Resultado: 23 ad accounts devueltas
```

### Helper `ads_extract_conversion`

```sql
SELECT * FROM ads_extract_conversion(
  '[{"action_type":"purchase","value":"5"},...]'::jsonb,
  '[{"action_type":"purchase","value":"249.95"}]'::jsonb
);
-- Resultado: conv=5, revenue=249.95, atc=15, ic=8, lpv=80
```

### Workflow n8n ejecuciones

| Ejecución | Estado | Notas |
|---|---|---|
| 120077 | error | `access to env vars denied` → fix `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` |
| 120090 | error | `crypto is not defined` en Code node → fix HMAC en Supabase |
| 120102 | error | `42P10 on_conflict` → fix UNIQUE constraint normal |
| 120108 | ✅ success (4s) | 23 cuentas UPSERT + 3 alertas UPSERT — fix validado E2E |

---

## Cómo continuar tras handoff

Si arrancas un chat nuevo:
1. Lee este doc completo.
2. Lee `~/.claude/plans/whimsical-churning-shore.md`.
3. Pega el bloque "Iniciador para nuevo chat" del principio.
4. Empieza por el paso 1 de "Próximos pasos en orden": re-ejecutar `hwKBGC6QWP2dFObT` y validar con SQL.

Si la re-ejecución es OK:
- Aplicar tag `portal` (UI o PUT REST).
- Activar el workflow (toggle).
- Pasar al siguiente workflow `SYNC ADS — Meta Estructura`.

Si falla algún paso:
- Inspeccionar la ejecución con `mcp__n8n-mcp__n8n_executions get id=<ID> mode=error`.
- Diagnosticar.
- Aplicar fix mínimo + smoke test.
- Documentar en `docs/log-cambios.md` y en sección "Bugs encontrados" de este handoff.
