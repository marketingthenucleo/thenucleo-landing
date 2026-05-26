---
title: Roadmap Pipelines — Auditoría F1 → F2
dominio: portal
estado: en-construccion
actualizado: 2026-05-24
tags: [portal, pipelines, roadmap, auditoria, f2]
---

# Roadmap del desarrollo Pipelines (account / PM / equipo)

> **Auditoría 2026-05-24** del flujo Pipelines/Campañas (nomenclatura PxCx). Documenta qué está vivo, qué está en transición y qué bloquea el siguiente milestone (F2). Complementa a [`pipelines-presentacion.md`](./pipelines-presentacion.md) (visión del cambio), [`account-manual-pipelines.md`](./account-manual-pipelines.md), [`pm-manual-pipelines.md`](./pm-manual-pipelines.md), [`equipo-manual-pipelines.md`](./equipo-manual-pipelines.md) y [`ficha-cliente.md`](./ficha-cliente.md).

## Contexto

El flujo Pipelines/Campañas con nomenclatura PxCx es el nuevo modelo operativo de TheNucleo para que account, PM y equipo trabajen sobre la misma "dirección postal" por entregable (ej. `P1C1E2`, `P1C1FM1`). Hoy convive:

- Frontend del módulo "Pipelines y Campañas" **vivo en seed** dentro de `/ficha-cliente/` (datos hardcoded Dra. Neuss).
- Operación de account/PM **transicionando manualmente** (sin dropdown forzado, sin generación automática de tareas).
- Backend Supabase de Pipelines **inexistente** (4 tablas + RPCs solo diseñadas, no aplicadas).
- Equipo (5 roles) **aún no siente el cambio** porque hay mínimos clientes declarados.

El objetivo de este documento es enumerar los todos por fase para ver, de un vistazo, qué está hecho, qué está en mitad de transición y qué bloquea el siguiente milestone (F2). Fuentes consultadas: `docs/portal/pipelines-presentacion.md`, `account-manual-pipelines.md`, `pm-manual-pipelines.md`, `equipo-manual-pipelines.md`, `ficha-cliente.md`, `ficha-cliente-pipelines-handoff-landing.md`, `secciones-app.md`, `docs/infra/supabase-schema.md`, `docs/infra/n8n-workflows.md`, `docs/log-cambios.md`.

---

## Fase 0 — Ya en producción (ficha técnica detallada)

> Todos los items están **vivos hoy 2026-05-24**. Las referencias `archivo:línea` apuntan al estado en `main` después del commit `48af7c8` (verificadas leyendo el HTML). Los conteos de filas y existencia de RPCs/tablas están **verificados vía Supabase MCP el 2026-05-24** contra el proyecto `cbixhqjsnpuhcrcjppah` ("Bubble_datatype"). Commits verificados con `git log -- ficha-cliente/index.html`. Los IDs de workflow n8n proceden de `docs/infra/n8n-workflows.md` (no ejecutado contra n8n MCP en esta auditoría — flag pendiente).
>
> Correcciones aplicadas tras verificación contra Supabase:
> - `bub_clientes` real = **78 filas** (29 activos · 49 No Activo). El doc decía 73 / 34+42 — desfasado.
> - `fichas_de_producto` real = **57 filas** (coincide con CLAUDE.md). Una fuente intermedia decía 63 — incorrecta.
> - Tablas F2 (`cliente_pipelines`, `cliente_campanias`) confirmadas **MISSING** (no existen aún, como corresponde a F2 pendiente).

### A · Frontend Pipelines (`ficha-cliente/index.html`)

#### A1 · Módulo "Pipelines y Campañas" (árbol P → C → Triggers + Emails)
- **Container HTML**: `ficha-cliente/index.html:1087` — `<div id="pipelines-module">` dentro de `<section class="panel" id="panel-pipelines">`.
- **IIFE encapsulado** `PIPELINES_MODULE` en líneas `1681–2385` — contiene seed, plantillas, state, renderers, handlers.
- **Seed hardcoded Dra. Neuss**: variable `SEED` en líneas `1695–1756`. 4 pipelines (P1 Venta directa Curso, P2 Captación leads, P3 Reactivación, P4 Newsletter mensual), 4 campañas, triggers + emails anidados.
- **Inicialización**: `PIPELINES_MODULE.init()` desde `renderCliente()` línea `1447`.
- **Renderers por nivel**:
  - `render()` 1801–1806 (despacha según vista activa)
  - `renderList()` 1834–1853
  - `renderPipelineView(pId)` 1904–1952
  - `renderCampaignView(pId, cId)` 1954–2055
  - `renderTriggerView(pId, cId, tId)` 2057–2079
  - `renderEmailView(pId, cId, eId)` 2081–2116
- **Navegación**: `go(view)` / `back()` / `gotoList()` líneas `2118–2135`.
- **Commit de origen**: `8b2d3e9 feat(ficha-cliente): portar modulo Pipelines y Campañas con seed F1`.
- **Commit de ajuste**: `48af7c8 fix(ficha-cliente): retirar chip 'Pipelines · mockup'` (el módulo no es mockup, es seed real F1).

#### A2 · Switch Account-view ↔ PM-view
- **Control HTML**: `1811–1813` — `<div class="pip-role-switch" role="tablist">` con dos `<button data-role="account|pm">`.
- **Handler**: `2150–2153` en `attachAllHandlers()` — actualiza `S.role` y llama `render()`.
- **State**: `S.role` en línea `1760` (valores `'account' | 'pm'`).

#### A3 · Toggle "Mostrar archivados"
- **Control HTML**: `1815–1818` — `<input type="checkbox" data-toggle="archived">`.
- **Handler**: `2154–2156` — actualiza `S.showArchived` y re-renderiza.
- **State**: `S.showArchived` en línea `1761` (boolean).

#### A4 · Drawer "Nueva Campaña" + 6 plantillas (en realidad 7: `evento` también está)
- **Drawer HTML**: `1166–1178` — `<div class="sheet" id="sheet">` + backdrop `1167`.
- **Array `PLANTILLAS`**: líneas `1684–1692` (7 entries con slug + nombre + triggers/emails preset).
  - `venta-meta` (1T, 0E) · `capt-fm` (1T, 3E) · `capt-fw` (1T, 3E) · `react-bd` (1T, 3E) · `news` (1T, 1E) · `lanz` (3T, 5E) · `evento` (1T, 2E)
- **Función**: `openNewCampaignSheet(pId)` líneas `2229–2317` — calcula siguiente código (`p.code + 'C' + (p.camps.length + 1)`), renderiza grid `.pip-plantilla-card`, rebind handlers en `rebind()`.
- **Disparador**: handler `data-action="new-campaign"` línea `2171`.

#### A5 · Función `emailCode(camp, email)` (regla nomenclatura emails)
- **Definición**: líneas `1774–1780`.
- **Lógica**: si email aplica a todos triggers → `P1C1E2`. Si aplica a subset → `P1C1FM1FW1E2` (concatena trigger codes ordenados FM→FW→BD).
- **Usado en**: `renderCampaignView()` 2031, `renderEmailView()` 2086.
- **Encapsula**: caso 5 de la nomenclatura .docx (emails con/sin trigger según aplicabilidad).

#### A6 · Componente colapsable `.coll-group` (reutilizado en 3 paneles)
- **CSS**: `334–369` — clases `.coll-group`, `.coll-group-header`, `.coll-group-caret`, `.coll-group-dot/name/count/body` + animación `collOpen 0.18s`.
- **Handler global `toggleCollGroup(header)`**: `1650–1666` — click + Enter/Space, alterna `.open` y `aria-expanded`.
- **Helper `renderDatosSection(listId, countId, fields)`**: `1328–1347` — pinta filas + badge contador (verde si completo / ámbar si parcial / neutro `MOCKUP · N` si 100% placeholder).
- **Llamado 5 veces** desde `renderCliente()` líneas `1398–1440` (Identificación, Contacto, Presencia digital, Accesos, Operaciones internas).
- **Commit**: `94fce60 feat(ficha-cliente): agrupar datos y catalogos en desplegables colapsables`.

---

### B · Datos cliente base (Supabase cbi)

| Objeto | Tipo | Detalle | Desde |
|---|---|---|---|
| `bub_clientes` | tabla | **78 filas reales** (29 Activo · 49 No Activo) — verificado Supabase MCP 2026-05-24. PK `bubble_id text`. Columnas clave: `nombre_empresas`, `gchat_space_id` (idx parcial), `provider` default `'notion'`, `external_id`, `metadata jsonb`, `estado` (Activo/No Activo). Campo legacy `bb_servicios_contratados` eliminado 2026-05-22. RLS habilitado sin policies para `authenticated` (lectura por GRANT, edición vía RPCs SECURITY DEFINER). | sync desde Bubble |
| `ficha_cliente_listar()` | RPC | `RETURNS TABLE(bubble_id, nombre_empresas, sector, estado, fecha_onboarding)`. Allowlist hardcoded 4 emails. Filtra `COALESCE(estado,'') <> 'No Activo'`. Orden alfabético. `SECURITY DEFINER` + `RAISE EXCEPTION 'forbidden' ERRCODE 42501`. GRANT EXECUTE TO authenticated. Consumida en `init()` del selector dropdown. | 2026-05-22 |
| `ficha_cliente_get(p_bubble_id)` | RPC | `RETURNS jsonb`. Devuelve `to_jsonb(c.*)` + array `servicios` agregado con `jsonb_agg` desde `playbook_cliente_servicios` ordenado por `orden NULLS LAST, created_at`. Cada servicio: `{ficha_titulo, categoria_nombre, categoria_color, unidades, periodo, notas, orden}`. Mismo allowlist + SECURITY DEFINER. | 2026-05-22 base; ampliación `servicios` mismo día (migration `ficha_cliente_get_incluir_servicios`) |
| `playbook_cliente_servicios` | tabla junction | **199 filas** (verificado MCP). `cliente_bubble_id text` + `ficha_id uuid FK fichas_de_producto ON DELETE SET NULL` + denormalizados (`ficha_titulo`, `categoria_nombre`, `categoria_color`) + `precio numeric`, `unidades text`, `periodo text` default `'mensual'`, `notas`, `orden int`. RLS `pcs_editor_all` (ALL) con allowlist editores. | 2026-05-14, bulk seed 2026-05-22 |

- **Commits**: `6703abf feat(ficha-cliente): cablear con bub_clientes via RPC SECURITY DEFINER` · `d08f1ea fix(ficha-cliente): cargar servicios reales desde playbook_cliente_servicios` · `365a448 feat(ficha-cliente): agrupar servicios por categoria + buscador`.
- **Gate auth**: allowlist 4 emails (Benjamin Sanchis, Alejandro López, marketing.thenucleo, Mel Dalmazo) + URL deep-link `?id=<bubble_id>` (decodificado en `init()`).

---

### C · Páginas admin operativas (entorno del flujo PxCx)

| Página | Archivo | Tabla/RPC | RLS | Última iter |
|---|---|---|---|---|
| `/ficha-cliente/` | `ficha-cliente/index.html` | RPCs `ficha_cliente_listar` + `ficha_cliente_get` | allowlist 4 emails vía SECURITY DEFINER | 2026-05-23 (refactor `.coll-group`) |
| `/playbook/` | `playbook/index.html` | `playbook_onboarding` (single-row slug='default') + `playbook_progreso` (per-cliente) · RPCs `playbook_publico(p_bubble_id)` (anon) + `playbook_cliente_detalle(p_bubble_id)` (editor) | `playbook_read_all` (SELECT anon) + `playbook_update_editors` (UPDATE allowlist 4 emails, Mel añadida 2026-05-15 con `lower()`) | 2026-05-22 (responsive layer ≤720px) |
| `/fichas-de-producto/` | `fichas-de-producto/index.html` | `fichas_categorias` (12 filas verif. MCP) + `fichas_de_producto` (**57 filas verif. MCP**, coincide con CLAUDE.md). Lectura REST directa + PATCH debounce 500ms `(id, field)`. | 8 policies admin (`fc_select/insert/update/delete_admin × 2 tablas`) usando `public.is_comunidad_admin()` | 2026-05-22 (rewrite mobile-first: tabs por categoría, FAB, sheet bottom) |
| `/casuisticas/` | `casuisticas/index.html` | `casuisticas_board` single-row `id='global'`, columna `data jsonb` (4 columnas bolsa/newsletter/hibrido/dudas) | allowlist email 4 admin vía `auth.email()` | 2026-05-15 (migración localStorage → Supabase) |
| `/disponibilidades/` | `disponibilidades/index.html` | `disponibilidad_franjas_base` (6 miembros × 14 franjas L–V) + `disponibilidad_overrides` (time-series) + `festivos_es` (10 nacionales 2026) · RPC `disponibilidad_miembros()` SECURITY DEFINER JOIN `bub_user` + franjas | habilitado vía `is_comunidad_admin()` | 2026-05-20 (go-live, 3 capas AHORA/HOY/SEMANA + modal 7 tipos override) |

---

### D · Sincronización tareas y clientes (canal del código PxCx)

| Workflow ID | Nombre | Trigger | I/O resumen | Última mod | Estado |
|---|---|---|---|---|---|
| `eHyXBETcaGSNXqLk` | OPS TAREAS — Crear desde Formulario Bubble | Webhook POST Bubble | In: formulario tarea (nombre, cliente, responsables) → Out: tarea creada en Bubble (+ espejo Notion vía sync) | — | activo |
| `KSBwigoSEpHl5OG1` | OPS TAREAS — Aplicar Plantilla a Cliente | Webhook POST Bubble | In: `cliente_id + plantilla_id` → Out: N tareas padre + M subtareas Notion (consume `bub_plantillas_tareas_notion` + `bub_plantillas_subtareas_notion`) | — | activo |
| `GjijIDEUyiH05Mg0` | SYNC TAREAS — Notion → Bubble (v2) | Notion polling 1 min (`created` + `pagedUpdatedInDatabase`), retry 3× con 5s | In: cambios DB Notion `b67f8416-322f-4761-ba36-40b938ae9387` (TAREAS) → Out: CRUD Bubble `tareas_notion` + espejo Supabase `bub_tareas_notion` (latencia 1-2s). 24 propiedades sincronizadas. | 2026-05-18 (hardening anti-race: dedupe `notion_id` + retry) | activo |
| `eR5SWFkxJmjMT1VI` | SYNC TAREAS — ClickUp → Bubble | Webhook HMAC `/clickup_tasks_inbound` + whitelist | In: eventos taskUpdated/Created/Deleted desde ClickUp workspace `9008203585` → Out: CRUD Bubble (multi-provider `provider='clickup'`) | 2026-05-07 (plan v3 ClickUp) | inactivo (espera F1.3) |
| `FcTmv78nLjbCb2Ea08qbt` | SYNC CLIENTES — Notion → Bubble | 2 Notion Triggers DB Empresas `fd1652ef-…` (`pageAdded` suma Clockify + `pageUpdated` sync solo) | In: props cliente Notion → Out: POST/PATCH Bubble `clientes` + CREATE Clockify (solo alta) + PATCH Notion con `notion_id`. Anti-rebote por comparación contenido (opción D). | 2026-05-08 (fix `cliente_nombre` NULL) | activo |
| `wvHcgVqqjkWJcJDu` | SYNC CLIENTES — Bubble → Notion + Drive | Webhook POST `/SYNC_clientes_bubble_notion` desde Bubble | In: payload cliente Bubble → Out: CREATE Notion DB Empresas + sub-workflow Drive `d0B4LokmPhHWdg6g` (~17s) crea 5 L1 + 4 L2 + 4 L3 + PATCH Bubble con `notion_id` + `link_drive`. | 2026-05-23 (TODO pendiente L1 `Campañas` PxCx) | activo |

> Los 4 primeros son los que canalizarán las tareas PxCx; los 2 últimos preparan el ecosistema cliente (Notion + Drive) donde viven las Campañas.

---

## Fase 1 — En transición manual esta semana / próxima

### Account (Ben / Melina)
- [ ] **Volcado piloto real de 3-5 clientes** en el módulo Pipelines de la ficha. Doc dice "Esta semana — Account vuelca el mapa real de 3-5 clientes piloto. Neus el primero" (`pipelines-presentacion.md`).
- [ ] Pegar link briefing Drive en campo `briefing_drive` de cada Campaña (manual hasta F2).
- [ ] Aplicar las 7 reglas de oro PxCx en cada cliente piloto (P primero, orden fijo, secuencial, no reutilizar, único Account, no caducan, mismo código en todos los sistemas).
- [ ] Mantener disciplina: archivar (no borrar) campañas inactivas. Versionar internamente en Drive con `_v2`, `_v3` sin renombrar código.

### PM (Melina)
- [ ] **Crear tareas Notion con código en el título manualmente**. Doc dice "Próxima semana — PM empieza a crear tareas Notion con código en el título (manualmente, sin dropdown forzado todavía)".
- [ ] Recorrido matinal de fichas activas: detectar Campañas "Declaradas" sin tareas + gaps (sin briefing, sin fecha BD, sin KPI).
- [ ] Verificación viernes: comprobar entregables Drive con código (`P1C1E1_copy.docx` ✓), perseguir si falta.

### Equipo (5 roles)
- [ ] Empezar a consumir tareas con código en el título cuando PM las cree. Sin esperar al dropdown forzado.
- [ ] Guardar entregables en Drive con nomenclatura por rol:
  - Estratega: `PxCx_briefing`, `_angulos`, `_cluster`.
  - Copy: `PxCxEn_copy`, `PxCx_copy_RRSS_vN`.
  - Diseño: `PxCxEn_diseno`, `PxCx_estatico_vN`, `PxCx_reel_vN`.
  - Media Buyer: `PxCxFMn_form`, `PxCx_lanzar`, objetos Meta nombrados igual que código.
  - CRM: `PxCxBDn_segmento`, `PxCxFWn_form`, workflows GHL nombrados código.

### Drive (estructura periférica)
- [ ] **TODO 2026-05-23 en workflow `wvHcgVqqjkWJcJDu`**: añadir L1 "Campañas" en la creación de carpeta cliente. Hoy Account crea subcarpetas `PxCx — Nombre/` a mano bajo una L1 inconsistente.

---

## Fase 2 — Backend Supabase + dropdown forzado Bubble (siguiente milestone)

### Schema Supabase (diseñado, NO aplicado)
- [ ] Aplicar migración `cliente_pipelines`: `id uuid PK`, `cliente_bubble_id text FK`, `codigo text`, `nombre`, `objetivo_negocio`, `estado`, `responsable_account text`, `notas`, timestamps.
- [ ] Aplicar migración `cliente_campanias`: `pipeline_id FK`, `codigo`, `nombre`, `plantilla_origen FK`, `estado`, `fecha_inicio/fin`, `presupuesto_eur`, `canal_principal`, `kpi_objetivo`, `link_briefing_drive`, `responsable_pm`, `notas_account`.
- [ ] Aplicar migración `cliente_triggers`: `campania_id FK`, `codigo` (FM/FW/BD + n), `tipo`, `descripcion`, `link_externo`, `fecha_lanzamiento` (obligatoria si BD), `estado`.
- [ ] Aplicar migración `cliente_emails`: `campania_id FK`, `codigo` (En), `orden`, `espera_desde_anterior`, `objetivo`, `triggers_aplicables text[]`, `link_copy_drive`, `link_diseno_drive`, `link_ghl_workflow`, `estado`.
- [ ] Aplicar migración `cliente_campania_plantillas` (catálogo cerrado seed: 6 plantillas, abrible en Fase 3).
- [ ] RLS por email admin allowlist (mismo patrón que `playbook_update_editors`).
- [ ] RPCs CRUD: `pipeline_upsert`, `campania_upsert` (con `plantilla_origen` que pre-puebla triggers/emails), `trigger_upsert`, `email_upsert`, `archivar_<entidad>`.
- [ ] Ampliar `ficha_cliente_get(p_bubble_id)` para devolver árbol Pipelines completo en un JSON (mismo patrón que el array `servicios` actual).

### Frontend ficha (`/ficha-cliente/index.html`)
- [ ] Cablear el módulo Pipelines a las nuevas RPCs (reemplazar seed hardcoded Dra. Neuss).
- [ ] Persistir crear/editar/archivar P/C/Triggers/Emails contra Supabase.
- [ ] Avisos ámbar en PM-view: Campaña sin `link_briefing_drive`, Trigger BD sin `fecha_lanzamiento`, Campaña sin KPI.

### Hooks Bubble + n8n (dropdown forzado de código)
- [ ] **Crítico**: añadir dropdown forzado de código PxCx en el formulario "Crear tarea" de Bubble. Lee Pipelines/Campañas/Triggers/Emails del cliente seleccionado desde Supabase. Sin código, no se crea la tarea.
- [ ] Drawer "Crear tareas Notion" por Campaña en PM-view: pre-genera todas las tareas según la plantilla origen (cada una con código, área canónica, responsable sugerido). Checkbox para desmarcar las que no aplican.
- [ ] Workflow n8n nuevo (o extensión de `eHyXBETcaGSNXqLk`): consume el drawer, crea N tareas en Notion en una sola llamada con código garantizado.
- [ ] Actualizar `wvHcgVqqjkWJcJDu` para crear L1 "Campañas" en Drive al crear cliente + RPC futura para crear subcarpeta `PxCx — Nombre/` cuando Account declara campaña.

### Equipo (validación post-F2)
- [ ] Validar que tarea Notion `P2C1E2 — Diseño email Dra. Neuss` llega completa con código y carpeta Drive pre-creada.
- [ ] Validar handoff Drive → Notion → Meta/GHL sin renombrado intermedio.

---

## Fase 3 — Catálogo abierto + escalado (backlog)

- [ ] Abrir catálogo de Plantillas: Account puede crear plantillas nuevas desde la ficha (hoy son 6 fijas). Doc dice "Cuando F2 esté validado — Catálogo abierto de Plantillas".
- [ ] Vista catálogo de plantillas accesible para PM y equipo (no solo Account).
- [ ] Automatizar duplicado de briefing master desde plantilla al Drive del cliente al declarar Campaña (hoy Account lo hace manual).
- [ ] Vincular automáticamente objetos Meta Ads / workflows GHL al código PxCx al lanzar (hoy Media Buyer y CRM nombran a mano).
- [ ] Dashboard transversal "Pipelines de todos los clientes": vista PM para detectar Campañas declaradas sin tareas en bulk (hoy una ficha cada vez).
- [ ] KPIs por Pipeline/Campaña (presupuesto vs gastado, leads previstos vs reales) leídos desde Meta Ads + GHL.

---

## Bloqueadores cruzados (afectan varias fases)

| Bloqueador | Fase impactada | Quién desbloquea |
|---|---|---|
| Dropdown forzado código Notion en Bubble inactivo | F2 | Backend Supabase F2 + dev Bubble |
| Drawer "Crear tareas Notion" no existe | F2 | Mismo paquete F2 |
| Link briefing Drive obligatorio no validado en UI | F2 (aviso ámbar) | Frontend ficha tras RPCs |
| Account = único creador de códigos (regla cultural) | F0–F3 todas | Disciplina operativa (no técnico) |
| Mismo código en Drive/Notion/Meta/GHL | F1–F2 | Disciplina + automatización gradual F2/F3 |
| L1 "Campañas" pendiente en workflow creación Drive | F1 / F2 | Editar `wvHcgVqqjkWJcJDu` (TODO 2026-05-23) |
| Catálogo Plantillas cerrado | F3 | Tabla `cliente_campania_plantillas` + UI |

---

## Cómo verificar el estado de cada item

- **Fase 0 (UI vivo)**: abrir `https://work.thenucleo.com/ficha-cliente/?id=<bubble_id_neuss>` con email admin → ver árbol Pipelines con seed. Confirmar switch Account/PM, toggle archivados, drawer Nueva Campaña con 6 plantillas.
- **Fase 0 (datos)**: `mcp__supabase__list_tables` para ver `bub_clientes`, `playbook_cliente_servicios`, `playbook_onboarding` activas. Comprobar que las tablas Pipelines (`cliente_pipelines`, `cliente_campanias`, `cliente_triggers`, `cliente_emails`, `cliente_campania_plantillas`) NO existen aún.
- **Fase 0 (workflows)**: en n8n, los 6 workflows listados (eHyX…, KSBw…, GjijI…, eR5SW…, FcTmv…, wvHcg…) deben estar activos.
- **Fase 1 (transición)**: pedir a Ben/Melina nº de clientes con Pipelines reales declarados (objetivo 3-5 esta semana). Sample de tareas Notion últimas 7 días: ¿qué % lleva código PxCx en el título?
- **Fase 2 (backend)**: cuando se aplique, `mcp__supabase__list_tables` debería listar las 5 tablas nuevas + RPCs. `ficha_cliente_get` devuelve árbol Pipelines real (no seed).
- **Fase 2 (dropdown)**: crear tarea desde formulario Bubble sin código → debería bloquearse. Con código → tarea aparece en Notion con código en el título y baja sincronizada a Bubble vía `GjijIDEUyiH05Mg0`.
- **Fase 3**: validar que Account puede añadir plantilla nueva al catálogo y que aparece en el dropdown del drawer "Nueva Campaña".

## Archivos clave a modificar cuando se ejecute cada fase

- F2 schema: `docs/infra/supabase-schema.md` (documentación) + nuevas migraciones aplicadas vía MCP Supabase (`apply_migration`).
- F2 frontend: `ficha-cliente/index.html` (reemplazar seed por RPCs).
- F2 workflows: `eHyXBETcaGSNXqLk` (formulario crear tarea) y `wvHcgVqqjkWJcJDu` (añadir L1 Campañas Drive). Actualizar `docs/infra/n8n-workflows.md`.
- F2/F3 docs: actualizar `docs/portal/ficha-cliente.md` con estado real post-F2 + registrar cambios en `docs/log-cambios.md` por convención del repo.

---

## Cómo retomar este trabajo en otra sesión

Pegar este prompt al iniciar una nueva sesión de Claude Code en este repo:

> Contexto: hicimos una auditoría del estado del flujo Pipelines (account/PM/equipo) y lo documenté en `docs/portal/pipelines-roadmap.md`. La Fase 0 ya está verificada contra Supabase MCP (proyecto `cbixhqjsnpuhcrcjppah`) y contra el HTML + git log. Quiero continuar por **<elige una>**:
> - (a) Cerrar el TODO 2026-05-23 de Fase 1: añadir L1 "Campañas" en workflow n8n `wvHcgVqqjkWJcJDu` (SYNC CLIENTES — Bubble → Notion + Drive).
> - (b) Empezar Fase 2: diseñar y aplicar las 5 migraciones Supabase (`cliente_pipelines`, `cliente_campanias`, `cliente_triggers`, `cliente_emails`, `cliente_campania_plantillas`) + RLS + RPCs CRUD.
> - (c) Cablear el módulo Pipelines de `ficha-cliente/index.html` (líneas 1681–2385) contra esas RPCs nuevas, retirando el seed hardcoded Dra. Neuss (líneas 1695–1756).
> - (d) Implementar el dropdown forzado de código PxCx en el formulario "Crear tarea" de Bubble + extensión del workflow `eHyXBETcaGSNXqLk`.
>
> Antes de tocar nada, lee `docs/portal/pipelines-roadmap.md` entero y confirma el plan que propones para la opción elegida.
