---
title: Secciones de la App
dominio: app
estado: activo
actualizado: 2026-05-22
tags: [app, portal, secciones, ui]
---

# Secciones de la App — TheNucleo Portal

**Frontend:** Bubble (no-code)
**Live:** portal.thenucleo.com
**Dev:** app-the-nucleo-agency.bubbleapps.io

---

## Índice de funcionalidades del portal

Tabla compacta de las funcionalidades reales del portal (no incluye `work.thenucleo.com` — landing/blog/comunidad están fuera del portal). Para detalle de cada una, ver la sección correspondiente más abajo.

| # | Funcionalidad | Qué hace | Softwares | Orden de participación |
|---|---|---|---|---|
| 1 | Dashboard | KPIs globales (tareas vencidas, incidencias, clientes críticos) | Bubble ← Supabase | Bubble lee `bub_*` y vistas |
| 2 | Crear Cliente | Alta cliente: crea carpetas Drive, página Notion, espejo Supabase | Bubble → n8n → Drive + Notion → Bubble (PATCH) → Supabase | Bubble form → `wvHcgVqqjkWJcJDu` → Drive (raíz + sub `d0B4LokmPhHWdg6g`) + Notion → PATCH Bubble (`notion_id`, `link_drive`) → SYNC ESPEJO — Bubble → Supabase `FGxG67I24POOUeHW` → Supabase |
| 3 | Sync Cliente Notion→Bubble | Cambios en Notion bajan a Bubble con anti-rebote | Notion → n8n → Bubble → Supabase | Notion Trigger (1 min) → `FcTmv78nLjbCb2Ea08qbt` → Bubble → SYNC ESPEJO → Supabase |
| 4 | Listado/Ficha Cliente | Display kanban/lista + ficha individual (read-only) | Bubble ← Supabase | Bubble lee `bub_clientes` y vistas |
| 5 | Chat Cerebro IA (por cliente) | Chat IA con contexto Drive del cliente (RAG) | Bubble → n8n → Claude + Gemini → Supabase | Bubble → `JI5Tr7IogqXgaI7a` → Tool Loop `7yjLwl4cEJa7XAYY` (Claude + fileSearchStore) → `chat_messages` → Bubble |
| 6 | Reindex RAG Cerebro (manual) | Reindexa Drive del cliente en Gemini | Drive → n8n → Gemini → Supabase | Botón Bubble → `BqNTrwoQ2iJIcAB4` → `NI1oUwIY99TGk496` → Gemini → `rag_stores` |
| 7 | Reindex RAG Cerebro (cron) | Reindex nocturno automático | Drive → n8n → Gemini → Supabase | CRON `ZnJSkoWlSusmEjhO` (3:00) |
| 8 | Newsletter IA | Chat co-creativo que genera newsletter Word por cliente | Bubble → n8n → Claude + Gemini → Drive → Supabase | `inWFSAEDLCH1kx5P` → `SfwR7gqs1hBIOV7i` → `9wnB9NI8Capa4b8s` (Word a Drive) + `w6Gqo8B6Sqp6Mq9x` (RAG) → `newsletter_wip` |
| 9 | Reindex RAG Newsletter | Reindex nocturno fuentes newsletter | Drive → n8n → Gemini → Supabase | CRON `kZE3W2ae0upyGt2E` (3:30) → `w6Gqo8B6Sqp6Mq9x` |
| 10 | Análisis Estratégico Cliente | Chat co-creativo (briefing 12 secciones + 4 segmentos) | Bubble → n8n → Claude + Gemini → Supabase | `dtgF0G35aeJQVVfn` → `FFhkdTFCjTtfyvhP` → `Cfs3NFEE1enu1jTx` (KB) → `JtXdkXHm6RyGOJft` + `QW8VZ9cV5ECsSKvZ` → `analisis_wip` |
| 11 | Reset stuck Análisis | Limpia conversaciones bloqueadas | n8n → Supabase | CRON `V60MieFkQzOszxhh` |
| 12 | Sync Tareas Notion→Bubble | Notion (master) baja a Bubble cada minuto | Notion → n8n → Bubble → Supabase | `GjijIDEUyiH05Mg0` (1 min) → Bubble → SYNC ESPEJO → Supabase |
| 13 | Crear Tarea (form) | Botón Bubble crea tarea en Notion | Bubble → n8n → Notion → Bubble | Bubble form → `eHyXBETcaGSNXqLk` → Notion → sync `GjijIDEUyiH05Mg0` baja a Bubble |
| 14 | OPS TAREAS — Aplicar Plantilla a Cliente | Crea N tareas Notion desde plantilla | Bubble → n8n → Notion → Bubble | Bubble → `KSBwigoSEpHl5OG1` → Notion → sync de vuelta |
| 15 | Reconciliación Tareas | Arregla huérfanas Notion↔Bubble↔Supabase | n8n → Notion + Bubble + Supabase | CRON `ZqccS38F2Lz8WFwX` |
| 16 | Kanban Operaciones (display) | Visualización tareas (8 estados, read-only) | Bubble ← Supabase | Bubble lee `v_tareas_panel` |
| 17 | Control Tiempo (Clockify) | Dashboard horas (resumen, cliente, miembro, trending) | Clockify → n8n → Supabase → Bubble | CRON `ccPQuZmH7DGYRRbe` (23:00) → `clockify_time_entries` → Bubble vía 10 RPCs `clockify_*` |
| 18 | Cálculo horas reales | Imputa horas Clockify a tarea | Clockify → n8n → Bubble | `1f6IGS3cGPMVhQInlG7nX` |
| 19 | Ops Monitor — Meta Ads | Captura alertas Gmail (rechazos/suspensiones/límites) | Gmail → n8n → Supabase → Bubble | `4gN3uGhH8NZX2BDU` (Gmail trigger 1 min) → `bub_dashboardmedia_alertas_operativas` |
| 20 | Ops Monitor — Google Ads | Receptor de Google Ads Script | Google Ads Script → n8n → Supabase | `fdmkhBOua6pbZh6P` |
| 21 | Finanzas (Holded) | Métricas, facturas, MRR, desgloses | Holded → n8n → Supabase → Bubble | CRON `vI3TbyxtFM6wjhBS` → Bubble vía `finanzas_metricas_mes` / `finanzas_facturas` / `finanzas_desgloses` / `finanzas_evolucion_mrr` |
| 22 | Incidencias (tareas) | Tareas operativas marcadas como incidencia (read-only) | Bubble ← Supabase | Bubble filtra `bub_tareas_notion` por `incidencia=true` |
| 23 | Ajustes | Config agencia, invitar miembros (vía GHL), tokens, onboarding | Bubble + GHL API | CRUD Bubble + API Connector Bubble→GHL para invitaciones/tokens |
| 24 | RRHH (perfiles + NPS) | Perfiles empleados, NPS, departamentos | Bubble ← Supabase | Bubble lee `bub_rrhh_*` |
| 25 | Notificaciones | (pendiente documentar) | — | — |
| 26 | Soporte | (pendiente documentar) | — | — |

**Accionables por el usuario** (botón / form / chat input): 2, 5, 6, 8, 10, 13, 14, 23, 24.
**Display only o automáticos** (cron / trigger / sync): el resto.

---

## 1. Dashboard (`/dashboard`)

### Propósito
Vista de control global de la agencia. Primera pantalla al iniciar sesión.

### KPIs principales
Origen de datos: Bubble Data Type `tareas_notion` y `clientes` (espejo en cbi: `bub_tareas_notion`, `bub_clientes`).
- **Tareas vencidas:** COUNT donde `fecha_entrega < hoy` AND `estado NOT IN ('Completado', 'Cancelado')`
- **Incidencias activas:** COUNT donde `incidencia = true` AND `estado NOT IN ('Completado', 'Cancelado')`
- **Clientes críticos:** COUNT de clientes donde `estado = 'Activo'` y tienen tareas vencidas
- **Tareas en progreso:** COUNT `estado = 'En Progreso'`
- **Tareas esta semana:** COUNT con `fecha_entrega` en los próximos 7 días

### Componentes UI
- **Cards KPI** — fila superior con números grandes (JetBrains Mono), color de alerta si supera umbral
- **Lista tareas urgentes** — tabla filtrada por prioridad=Urgente o vencidas, ordenadas por fecha
- **Feed de actividad** — últimas entradas de `activity_log` (acciones del equipo)

⚠️ **Eliminado:** el "Sidebar Chat IA Tareas" descrito en versiones anteriores **no existe** en la UI actual. Las tareas se crean desde botones que disparan el workflow `eHyXBETcaGSNXqLk` (OPS TAREAS — Crear desde Formulario Bubble), no desde un chat. Los chats vivos son: Cerebro IA, Newsletter IA y Análisis Estratégico — todos viven dentro de la Ficha Cliente, no en el Dashboard.

### Data sources usados (como Actions, nunca Data source Bubble)
- Data Types Bubble `tareas_notion` y `clientes` para los counts.
- ⚠️ NO existe RPC `get_dashboard_kpis` — los conteos se hacen client-side en Bubble con búsquedas filtradas.

---

## Multi-provider Notion+ClickUp (transversal a Operaciones y Clientes)

Desde 2026-05-07 el portal soporta dos proveedores de gestión de tareas mutuamente excluyentes por agencia:

- **Discriminador:** `bub_agencia.proveedor_tareas` (Option Set Bubble `Proveedor de Tareas`, Display lowercase `notion`/`clickup`).
- **Page Bubble independiente:** `tareas_clickup` con Kanban dinámico (columnas por status real del Space CU). Validada con dummies — F2.F (onboarding Zenyx con tareas reales) pendiente.
- **Botón "Tareas" en `/clientes`:** redirect condicional según `Current User's agencia's proveedor_tareas` → `tareas_clickup` (CU) o `operaciones` (Notion, default seguro si vacío).
- **Tablas polimórficas:** `bub_tareas_notion` y `bub_clientes` con discriminadores `provider` + `external_id` + `metadata` (jsonb encoded en text). Sentinel `cu_<folder_id>` en `notion_id` para clientes CU.
- **Detalle completo:** [[clickup]].

---

## 2. Clientes (`/clientes`)

### Propósito
Gestión del portfolio de clientes. Vista dual Kanban / Lista.

### Vista Kanban
- Columnas (8 etapas del ciclo cliente — OS `bub_os_niveles`, campo `bub_clientes.niveles`): `Onboarding` | `En fase análisis/estrategia` | `En lanzamiento` | `Campañas lanzadas` | `Genera primeros leads` | `Genera leads cualificados` | `Genera primeras ventas` | `Cliente estable`
- **No filtra por `estado`** (Activo/No Activo). El campo `estado` se usa para distinguir cliente vivo vs archivado y se ve en la card / Vista Lista.
- Cards con: `nombre_empresas`, responsables (avatars desde `admin_cliente`), `facturacion` (numeric), `bb_estado_facturacion`
- ⚠️ **Read-only** en Bubble. NO hay drag-and-drop ni edición inline. Cualquier cambio de etapa o estado del cliente se hace vía botón → webhook n8n → Notion → sync de vuelta a Bubble (Notion es master vía sync `FcTmv78nLjbCb2Ea08qbt`). Bubble es solo capa de display para clientes y tareas.

### Vista Lista
- Tabla sortable por: `nombre_empresas`, `facturacion`, `estado`, `fecha_onboarding`, `nps`, `niveles`
- Filtros: responsable, sector, estado
- Búsqueda por nombre

### Modal Crear Cliente
Formulario con campos del Data Type `clientes` (Bubble):
- `nombre_empresas` (obligatorio)
- `sector` (dropdown)
- `correo_principal`, `telefono_principal`, `contacto_principal`
- Datos fiscales: `dni_nif`, `direccion_fiscal`, `nombre_sociedad`, `pais`, `provincia`, `codigo_postal`
- `pagina_web`, `link_drive`, `bb_link_drive_analisis`, `logo_imagen`/`logo_url`
- `facturacion` (numeric), `descripcion_plan`, `niveles`
- `fecha_onboarding`, `ultimo_seguimiento`, `bb_proxima_factura`

✅ **Estado del flujo Bubble → Notion (2026-04-27):** workflow `wvHcgVqqjkWJcJDu` (SYNC CLIENTES — Bubble → Notion + Drive) **reescrito y activado**. Hoy crear cliente en Bubble:
- ✅ Crea fila en Bubble Data Type `clientes`.
- ✅ Webhook a n8n `wvHcgVqqjkWJcJDu` → crea carpeta raíz cliente en Drive (idempotente) + invoca subworkflow `d0B4LokmPhHWdg6g` para subcarpetas L1/L2/L3 + actualiza Doc Maestro Drive + crea página en Notion DB Empresas + PATCH Bubble portal con `notion_id` / `link_drive` / `bb_link_drive_analisis`.
- ✅ Mirror automático a `bub_clientes` (cbi) vía SYNC ESPEJO — Bubble → Supabase `FGxG67I24POOUeHW` disparado por DB Trigger Bubble.
- ✅ Bidireccional: cambios en Notion bajan a Bubble vía `FcTmv78nLjbCb2Ea08qbt` (anti-rebote por comparación de contenido).

### Subpáginas de Cliente

#### Ficha Cliente (`/clientes/{empresa_id}`)
- Header: `nombre_empresas`, `logo_url`, `estado`, responsables, `facturacion`, `sector`, `fecha_onboarding`
- Tabs:
  - **Resumen:** KPIs del cliente (tareas activas, tiempo invertido este mes, incidencias)
  - **Tareas:** Lista/Kanban filtrada por `bub_tareas_notion.cliente_notion_id = <notion_id>` (1 cliente por tarea — escalar, no array)
  - **Tiempo:** Widget Clockify — RPC `clockify_por_cliente` (cbi)
  - **Facturas:** RPC `finanzas_facturas` (cbi) con filtro por `cliente_notion_id` ⚠️ tabla cbi vacía hasta migrar el sync Holded
  - **Plan/Descripción:** Edita `descripcion_plan`, `niveles` directamente en Bubble Data Type `clientes`

#### Chat Cerebro IA (`/clientes/{empresa_id}/cerebro`)
- Interfaz de chat fullscreen para un cliente específico
- Conversación tipo=`cerebro_{empresa_id}` en `chat_conversations`
- El IA tiene contexto completo del cliente: tareas, tiempo, facturas, notas, documentos Drive (RAG)
- Útil para: preparar reuniones, generar informes, resolver dudas estratégicas del cliente
- Webhook: `JI5Tr7IogqXgaI7a`

#### Newsletter IA (`/clientes/{empresa_id}/newsletter`)
- Flujo conversacional para generar emails de newsletter para el cliente
- Izquierda: chat para dar el brief (tono, tema, CTA, longitud)
- Derecha: preview HTML del email generado
- Botones: Regenerar / Copiar HTML / Marcar como enviado
- Estado gestionado en `newsletter_wip` (cbi, antes `newsletter_emails_wip`)
- Webhook entrada: `inWFSAEDLCH1kx5P`

#### Ficha Cliente — `work.thenucleo.com/ficha-cliente/` (admin allowlist, desde 2026-05-22)
- Vista admin standalone fuera del Portal Bubble, en la cara pública `work.thenucleo.com` (con gate auth + noindex). Mobile-first dark+verde (paleta TheNucleo, NewBlack, theme switch dark/light).
- **Stack frontend:** standalone single-file HTML + CSS + JS inline (sin bundler), `@supabase/supabase-js` vía CDN jsdelivr. Vive en `marketingthenucleo/thenucleo-landing/ficha-cliente/index.html`.
- **SEO bloqueado:** `<meta name="robots" content="noindex,nofollow">` + `Disallow` en `robots.txt` + `eleventyExcludeFromCollections: true` en el frontmatter Eleventy.
- **Gate auth:** overlay full-screen (`.gate`) que tapa todo hasta validar sesión. Si email no está en allowlist hardcoded → bloqueo permanente. Mismo patrón que `/playbook/` y `/fichas-de-producto/`.
- **5 tabs sticky:** Datos · Pipelines · Catálogos · Servicios · Anomalías.
- **Selector cliente:** bottom-sheet con buscador (filtra por nombre + sector). Items `picker-item` con avatar (logo o inicial), nombre, sector. Click → `ficha_cliente_get` + `history.replaceState` para deep-link compartible. URL `?id=<bubble_id>`.
- **Backend:** 2 RPCs nuevas `ficha_cliente_listar()` + `ficha_cliente_get(p_bubble_id)` (SECURITY DEFINER + allowlist hardcoded, mismo patrón que `playbook_cliente_detalle`). Resuelven que `bub_clientes` no tiene policies para `authenticated` sin necesidad de añadirlas. Detalle en [[supabase-schema|docs/infra/supabase-schema]] sección "Ficha de Cliente — RPCs sobre bub_clientes".
- **Panel "Datos" cableado con `bub_clientes`** — 5 grupos colapsables con badge contador `X/N`:
  - Identificación: `nombre_empresas`, `nombre_sociedad`, `dni_nif`, `direccion_fiscal` + `codigo_postal` + `provincia` + `pais` (concatenados), `telefono_principal`. Abierto por defecto.
  - Contacto: `contacto_principal`, `correo_principal`. WhatsApp queda `MOCKUP` (no está en el espejo).
  - Presencia digital: `pagina_web`. Instagram / Facebook / gestor del dominio quedan `MOCKUP`.
  - Accesos y credenciales: Meta BM / Google Ads / GHL / DNS todos `MOCKUP` (no están en `bub_clientes` — habrá que decidir si entran como columnas nuevas o como tabla aparte tipo `cliente_accesos`).
  - Operaciones internas: `link_drive`, `bb_link_drive_analisis`, `notion_id`, `gchat_space_id`, `slug`, `fecha_onboarding`, `ultimo_seguimiento`, `nps`, `facturacion`.
- **Status chips dinámicos:** `estado`, `sector`, `plan_actual`, `bb_estado_facturacion`, indicador "Google Chat activo" si `gchat_space_id` poblado.
- **Avatar:** `logo_url` o `logo_imagen` si existen, fallback a inicial del nombre.
- **Servicios contratados:** cableado real desde `playbook_cliente_servicios` (199 filas, Supabase nativo) vía la RPC `ficha_cliente_get` ampliada (`jsonb_agg(pcs.*)` ordenado por `orden NULLS LAST, created_at`, migration `ficha_cliente_get_incluir_servicios` aplicada 2026-05-22 tras detectar que el panel mostraba "Sin servicios" porque seguía leyendo `bb_servicios_contratados` ya droppeado). Render agrupado por `categoria_nombre` con headers colapsables (dot color desde `categoria_color`, count pill), buscador que aparece si hay >4 items (filtra por título/categoría/unidades/periodo/notas y auto-expande categorías con match), botón Expandir/Colapsar todo, contador total en el section-title. Si el cliente solo tiene 1 categoría visible, esa categoría se abre directa. Estado interno (`state.allOpen`, `state.openCats: Set`) sobrevive a re-renders por search/toggle.
- **Pipelines y Campañas (vivo desde 2026-05-23):** módulo nuevo dentro de la ficha. Árbol Pipelines → Campañas → Triggers (FM/FW/BD) + Emails con nomenclatura PxCx. Vista Account = edición completa con drawers para crear Pipeline / Campaña (con catálogo abierto de Plantillas) / Trigger / Email. Vista PM = lectura + CTA "Crear tareas Notion" por Campaña. Toggle "Mostrar archivados" (regla `.docx` caso 9: códigos no caducan). Datos seed hardcoded de Dra. Neuss (4 pipelines latentes: P1 Venta directa Curso, P2 Captación leads, P3 Reactivación, P4 Newsletter mensual) hasta que se construya el backend F2 (tablas `cliente_pipelines` + `cliente_campanias` + `cliente_triggers` + `cliente_emails` + RPCs `ficha_pipelines_get` / `ficha_codigos_catalogo` / 4 upserts + ampliar `ficha_cliente_get`). Detalle funcional en [[ficha-cliente]], handoff de implementación en [[ficha-cliente-pipelines-handoff-landing]], manual Account en [[account-manual-pipelines]], manual PM en [[pm-manual-pipelines]], manual equipo en [[equipo-manual-pipelines]], presentación al equipo en [[pipelines-presentacion]]. ⚠️ **Bug pendiente:** el chip del header sigue diciendo `Pipelines · mockup` (residuo del placeholder anterior) — cambiar a `Pipelines · seed Neus` o retirar.
- **Catálogos / Anomalías:** siguen marcados visiblemente como `MOCKUP` con badge gris. No se inventan datos.
- **Componente `.coll-group`** (reutilizado en Datos / Catálogos / Servicios): header con caret animado + dot + nombre + badge contador `X/N` (`.ok` verde / `.warn` ámbar / `.mock` gris). Body con anim `collOpen` 180ms. Toggle global vía `[data-coll-toggle]` (click + Enter/Space, `aria-expanded`). Servicios tiene su propio `[data-toggle]` por mantener estado de búsqueda + openCats.
- **Helper `renderDatosSection(listId, countId, fields)`** — pinta `fieldRow({label, value, mock, isUrl})` + actualiza badge (verde/ámbar/neutro). Cada row pill: `MOCKUP` (gris) / `PENDIENTE` (ámbar, valor vacío) / `OK` (verde, valor presente). URLs detectadas + ancla `target="_blank"`.
- **Theming:** dark/light en `.theme-toggle` del header. Persistencia en `localStorage` clave `ficha-cliente.theme`. Variables CSS reactivas vía `[data-theme="light"]` en `<html>`. Default dark si no hay clave.
- **Mobile-first specifics:** touch targets ≥44px (header buttons, coll-group headers, catalog-items), bottom-sheets en vez de modales, tabs scrollables horizontalmente (`overflow-x: auto`), anti-zoom iOS (`font-size: 16px` mínimo en inputs), `viewport-fit=cover` + `env(safe-area-inset-bottom)` en sheet padding.
- **No es el mismo que el Bubble Data Type Clientes** — esta página es admin-only externa al Portal (mobile-first, leer datos), no la ficha del Portal Bubble.

> ℹ️ **Doc técnico frontend en repo landing:** `marketingthenucleo/thenucleo-landing/ficha-cliente/fichacliente.md` (junto al `index.html`). Contiene la spec del componente `.coll-group`, helpers JS, theming, mobile-first. **Pendiente refrescar tras push del v3** (2026-05-23): la sección "Pipelines" del doc sigue describiendo el placeholder anterior con 4 sub-secciones rotables (Pipelines/Campañas/Tareas/Eventos) que **ya no existe** — el panel vivo es el árbol PxCx con drawers. Verificación realizada por curl 2026-05-23: HTML contiene `P1C1FM1`, `P2C1FM1`, `P3C1BD1`, `P4C1BD1`, `triggersAplicables`, `Crear tareas Notion`, `Mostrar archivados`, `Curso Suplementación` — todas características del v3.

> 🔧 **Pendientes en repo `thenucleo-landing` para próxima sesión allí** (detectados 2026-05-23 al auditar `fichacliente.md` + `adminpaginasinternas.md` + `landingdeudatecnica.md`):
>
> 1. **Refrescar `ficha-cliente/fichacliente.md`** sección "Pipelines — módulo F1 con SEED hardcoded" — describe el placeholder anterior, no el v3 vivo. Sustituir por la spec del v3 (árbol Pipelines→Campañas→Triggers+Emails, switch Account/PM, drawers, toggle archivados, seed Neus). Referenciar [[ficha-cliente]] del vault para el modelo operacional.
> 2. **Bug visual en header de `/ficha-cliente/`**: el chip `Pipelines · mockup` sigue hardcoded en `chips.push(...)`. Residuo del placeholder anterior. Cambiar a `Pipelines · seed Neus` o retirar.
> 3. **Actualizar `docs/.../adminpaginasinternas.md`**:
>    - Sección `/ficha-cliente/`: "Pipelines (mockup F1)" → "Pipelines (UI con seed Neus desde 2026-05-23, backend F2 pendiente)".
>    - Tabla resumen: cambiar "+ mockup (Pipelines, Catálogos, Anomalías)" por "+ UI con seed (Pipelines) + mockup (Catálogos, Anomalías)".
>    - Sección `/casuisticas/` "Por auditar" → completar con detalle real (vivo desde 2026-05-14, kanban 4 columnas, persistencia `localStorage`, sin backend Supabase). Detalle en `docs/work/casuisticas.md` del vault.
> 4. **Actualizar `docs/.../landingdeudatecnica.md`** añadiendo 2 items nuevos:
>    - Chip `Pipelines · mockup` en header de `/ficha-cliente/` (descrito arriba).
>    - Doc `fichacliente.md` desactualizado tras push del v3 (descrito arriba).
> 5. **Convención cross-repo**: la sesión Claude que hizo push del v3 al landing no actualizó los docs del propio repo landing. Para evitar esto, declarar en `CLAUDE.md` del landing que cualquier cambio funcional en `/ficha-cliente/` debe propagarse a `fichacliente.md` + `adminpaginasinternas.md` + `landingdeudatecnica.md` en el mismo PR.

> ✅ **Módulo Pipelines vivo (2026-05-23):** la implementación frontend del módulo "Pipelines y Campañas" se pusheó a `main` en `marketingthenucleo/thenucleo-landing`. Deploy Vercel auto. Solo UI con datos seed hardcoded — backend Supabase (`cliente_pipelines` + RPCs) es F2 posterior. Visión operacional: [[ficha-cliente]]. Brief de implementación usado: [[ficha-cliente-pipelines-handoff-landing]].
>
> 📘 **Documentos para el equipo** (2026-05-23):
> - [[pipelines-presentacion]] — presentación del cambio en 1 página (Account + PM + Equipo). Incluye flowchart end-to-end + tabla maestra. Léelo primero.
> - [[account-manual-pipelines]] — manual operativo para Account paso a paso. Incluye tabla "qué tareas se generan al declarar".
> - [[pm-manual-pipelines]] — manual operativo para PM. Flujo diario + tabla maestra de reparto por rol + cómo generar tareas Notion con código forzado.
> - [[equipo-manual-pipelines]] — manual del equipo ejecutor (Estratega creativo · Copy · Diseño · Media Buyer · CRM Manager). 6 pasos universales + secciones por rol con qué códigos llegan y dónde guarda cada entregable.
>
> 🎨 **Mockups interactivos de origen (2026-05-23):** 3 iteraciones guardadas en `Design/mockups/ficha-cliente-v2/` (gitignored): `index-v2.html` (split layout + wizard 3 pasos — con invenciones), `index-v3.html` (pegado a fuentes, sin invenciones, con multi-trigger de email + regla código caso 5 + soporte casuísticas .docx), `index-integrado.html` (v3 dentro de la ficha completa con todas las secciones). Stack: React+Tailwind+Lucide CDN, datos seed hardcoded de Dra. Neuss. Sirvieron como fuente de verdad para la implementación en `thenucleo-landing`.

---

## 3. Operaciones (`/operaciones`)

### Propósito
Centro de gestión de tareas del equipo. Vista principal de trabajo diario.

### Kanban de Tareas (8 columnas)
Estados en orden:
1. `Sin Asignar`
2. `Backlog`
3. `Por hacer`
4. `En Progreso`
5. `En Revisión`
6. `Bloqueado`
7. `Completado`
8. `Cancelado`

**Comportamiento:**
- ⚠️ **Read-only** en Bubble. NO hay drag-and-drop ni edición inline. Notion es master de tareas. Cambios de estado se hacen desde Notion → bajan a Bubble vía polling 1 min (`GjijIDEUyiH05Mg0`) → mirror a `bub_tareas_notion` (cbi) vía SYNC ESPEJO. El sync inverso `9mEU2MzE14mGpry2` (Bubble→Notion) está **archivado** (2026-04-27): el kanban operativo en Bubble no estaba en uso, se rehará desde cero si se necesita.
- Cards muestran: `nombre`, `cliente_nombre`, `responsable_nombres` (avatar), `fecha_entrega`, `prioridad` (color), badge si `incidencia=true`
- Filtros: responsable, cliente, prioridad, área, rango fechas
- Búsqueda por nombre
- Click en card → Popup/modal con detalle completo

**Colores de prioridad en cards:**
- Urgente: `#ef4444` (rojo)
- Alta: `#f97316` (naranja)
- Media: `#eab308` (amarillo)
- Baja: `#6b7280` (gris)

**Data source:** Data Type Bubble `tareas_notion` directo (Action, no Data source Bubble). El espejo en cbi es `bub_tareas_notion` para queries SQL/n8n.

**Campos clave de `bub_tareas_notion` (cbi mirror):** `bubble_id`, `notion_id`, `nombre`, `estado`, `prioridad`, `area_tarea`, `fecha_entrega`, `cliente_notion_id` (escalar — 1 cliente por tarea), `cliente_nombre`, `responsable_nombres` (concatenado), `responsables` (array), `aprobador_emails`, `observadores_emails`, `bloqueado_por_ids`, `bloqueando_ids`, `incidencia` (boolean), `estimacion_min`, `estimacion_horas`, `duracion_real_min`, `real_horas`, `position`, `last_edit_source` (anti-rebote multi-provider, F0 2026-05-02), `provider`, `external_id`, `external_url`, `metadata`.

### Plantillas de Tareas
Tab secundario en Operaciones.
- Lista de plantillas desde `bub_plantillas_tareas_notion` (cbi, 20 filas) + `bub_plantillas_subtareas_notion` (cbi, 100 filas)
- Cada plantilla muestra: `nombre`, `area_tarea`, `urgencia`, número de subtareas
- Botón "Aplicar" → popup para seleccionar tarea padre y responsable → POST webhook `KSBwigoSEpHl5OG1` (OPS TAREAS — Aplicar Plantilla a Cliente)
- Botón "Nueva plantilla" / "Añadir subtarea" → Create/Modify directos en Data Types Bubble nativos `Plantillas_tareas_notion` + `Plantillas_subtareas_notion`. DB Trigger Bubble → SYNC ABSOLUTO `FGxG67I24POOUeHW` → espejo `bub_plantillas_*_notion` en cbi. (Antes había una rama legacy con 2 backend workflows + 2 API Connector calls a tablas `plantillas`/`plantillas_subtareas` que nunca existieron en cbi → eliminado 2026-05-14.)

### Control de Tiempo (Clockify Dashboard)
Tab secundario. Componentes nativos Bubble con:
- **Resumen semana** (RPC `clockify_resumen` en cbi) — total_horas, entries, pct_facturable, etc.
- **Donut chart:** distribución por miembro (RPC `clockify_chart_donut`)
- **Trending chart:** horas por semana (RPC `clockify_chart_trending`)
- **Tabla por miembro:** horas y coste (RPC `clockify_por_miembro`)
- **Tabla por cliente:** horas y coste (RPC `clockify_por_cliente`)
- Selector de rango de fechas global

✅ Todas las RPCs migradas a cbi (2026-04-25). Params reales: `p_agencia_id`, `p_fecha_inicio`, `p_fecha_fin`.

**Cómo se generan los miembros del control de horas (2026-05-02):** no hay alta explícita en el portal. Los miembros emergen de los `time_entries` que sincroniza el workflow `ccPQuZmH7DGYRRbe` (CRON 23:00, ventana 35 días) en `clockify_time_entries`. La RPC `clockify_por_miembro` agrupa por `usuario_email` y resuelve el `nombre` mediante `LEFT JOIN bub_user m ON m.email = c.usuario_email` (antes era `bub_miembro_notion`, migrado 2026-05-02). El `coste_hora` viene del JOIN con `clockify_tarifas` (PK `email`); si el email no está allí, `coste_hora = 0`.

### Ops Monitor (sub-feature de Operaciones)
Dashboard de salud operativa de los workflows n8n:
- **Estado de workflows:** lectura de `workflow_executions` en cbi.
- **Errores recientes:** tabla con `workflow_name`, `error_message`, timestamp.
- **Métricas de sync:** registros en `bub_tareas_notion`, `bub_clientes`, etc.
- **Latencia sync Notion → Supabase:** comparar `last_edited_time` Notion vs `_synced_at` cbi.
- Botón "Re-sync manual" → API Connector `Trigger_actualizar_rag` u otros del grupo "N8N - Workflows".

⚠️ El doc anterior trataba Ops Monitor como sección 9 propia. CLAUDE.md la define como **sub-funcionalidad dentro de Operaciones**. Aquí se mantiene esa convención.

---

## 4. Finanzas (`/finanzas`)

### Propósito
Visión financiera de la agencia desde Holded.

### Componentes
- **MRR actual** y evolución (sparkline) — RPC `finanzas_metricas_mes(p_agencia_id, p_mes)`
- **Ingresos / Gastos / Margen** este mes — mismo RPC
- **Ticket medio, churn MRR, % impagos, total impagado** — mismo RPC
- **Gráfico evolución MRR** — RPC `finanzas_evolucion_mrr(p_agencia_id)`
- **Lista de facturas** con filtros por estado (pendientes/impagadas) — RPC `finanzas_facturas(p_agencia_id, p_tipo_vista, p_dias)`
- **Desglose por categoría** (ingresos recurrente vs puntual, gastos por proveedor) — RPC `finanzas_desgloses(p_agencia_id, p_mes)`

⚠️ **NO existe ARR** en `holded_metricas`. Solo MRR, ingresos, gastos, margen. Si se quiere ARR, calcular client-side como `mrr * 12`.

---

## 5. Comunidad — MIGRADA a `work.thenucleo.com/comunidad` (2026-04-28)

> ⚠️ **Sección movida fuera del portal Bubble**. Ahora vive como **comunidad pública** en la landing (Eleventy SSG + Supabase nativo + Auth Google + crowdfunding). Plan original en `~/.claude/plans/1-migrar-2-requiern-iridescent-wolf.md`.

### Propósito (nuevo)
Comunidad pública de propuestas (ideas, servicios, herramientas) con votación, comentarios y crowdfunding hacia un pool. Visible a cualquier visitante. Captación SEO + branding.

### Stack
- **Frontend:** Eleventy v3 SSG + supabase-js cliente vía CDN (jsdelivr) en `thenucleo-landing/comunidad/`.
- **Auth:** Supabase Auth Google OAuth.
- **Datos:** tablas nativas `comunidad_propuestas`, `comunidad_comentarios`, `comunidad_votos_propuesta`, `comunidad_votos_comentario`, `comunidad_admins` (cbi). Las viejas `bub_comunidad_*` quedan obsoletas (cleanup pendiente).
- **Moderación:** Edge Function `comunidad_admin_action` (verify_jwt). Panel admin en `/comunidad/admin/` (excluido de sitemap, robots Disallow).
- **Crowdfunding:** modelo de pool por propuesta con `umbral_financiacion_pool` y `recaudado_pool`. Botón "Aportar" presente como **stub Fase 1**; activación con Stripe en Fase 2 (cuando Stripe PROD esté operativo).

### Pendientes operativos (no código)
1. Configurar Google OAuth en Supabase + Google Cloud Console (redirect `https://cbixhqjsnpuhcrcjppah.supabase.co/auth/v1/callback`).
2. Vercel proyecto `app-landing-thenucleo`: Env Var `SUPABASE_ANON_KEY` (build) + Deploy Hook → URL en secret `VERCEL_DEPLOY_HOOK_URL` de la Edge Function.
3. Tras primer login Google de Ben en `/comunidad/admin/`: `INSERT INTO comunidad_admins (user_id) VALUES ('<uid>');`.
4. Cleanup post-validación: archivar Data Types `Comunidad_*` en Bubble, ocultar UI sección 5 en portal Bubble (o redirigir a la landing), `DROP TABLE bub_comunidad_*` en cbi.

### Detalles de schema y RLS
Ver sección "Comunidad pública (cbi) — Tablas nativas" en [[supabase-schema|docs/supabase-schema]].

---

## 6. Incidencias (`/incidencias`)

Sección del portal Bubble que lista **tareas operativas marcadas como `incidencia=true`** en `bub_tareas_notion` (escalados del equipo). No incluye errores técnicos de workflows.

Los **errores técnicos de workflows n8n** viven fuera de Bubble desde 2026-04-27 — los captura el workflow `HRDQ9Ju4NAIUV0qyhKzlz` y aterrizan en la tabla Supabase `n8n_incidencias`. Visor independiente con login: [`work.thenucleo.com/incidencias`](https://work.thenucleo.com/incidencias) (Edge Function `incidencias_api`). Antes vivían en `bub_incidencias`, eliminada para descargar Bubble.

### Componentes
- Lista de incidencias activas ordenadas por urgencia
- Cards con: título, cliente, responsable, días activa, prioridad
- Filtros: cliente, responsable, estado
- Click → mismo popup/modal de detalle de tarea que Operaciones
- KPI rápido: número de incidencias abiertas esta semana vs semana pasada

---

## 7. Ajustes (`/ajustes`)

### Tabs

#### Config Agencia
- Nombre agencia, logo, timezone, moneda
- Horario laboral (para cálculos de días hábiles)

#### Miembros del Equipo
- Lista de miembros desde Bubble Data Type `user` (espejo `bub_user` en cbi, 13 filas).
- Editar: campos del User Bubble. La tarifa por hora vive en `clockify_tarifas` (PK email, columna `tarifa_mensual`).
- ⚠️ **NO existen** los campos `rol`, `departamento`, `apellido`, `clockify_id`, `activo` en `bub_user`. Si se quieren añadir, toca extender el Data Type Bubble.

#### Onboarding
- Checklist de configuración inicial (integraciones conectadas, sync activos, etc.)
- Estado visual de cada integración (Notion ✓, Clockify ✓, Holded ✓, GHL...)

#### Integración GHL
- Estado de conexión con GoHighLevel
- **Uso real:** envío de **invitaciones a miembros** del equipo y gestión de **tokens** vía API Connector Bubble → GHL (sin n8n intermedio).
- ⚠️ NO confundir con el workflow listener `Ik2Tt3Dw5ivL8qk7` (OPS CRM — Oyente GHL [PAUSADO]), que pertenece a Ops Monitor (alertas operativas de flujos rotos / email rebotado) y sigue inactivo.

---

## 8. Recursos Humanos

### Propósito
Vista interna de gestión de equipo. (Antes "RRHH / Liderazgo".)

### Componentes
- **Perfiles empleados:** lectura de `bub_rrhh_empleado_perfil` (espejo Bubble) — foto, rol, departamento, tipo de contrato. Tabla actualmente vacía en cbi (0 filas) — sección probablemente WIP.
- **NPS interno:** registros en `bub_rrhh_nps_registro` (vacía) — encuesta puntual de satisfacción.
- **Departamentos:** catálogo en `bub_os_rrhh_departamento` (4 filas) + asignación en `bub_rrhh_dpt_funcion` (vacía).
- **Tipo de contrato:** catálogo en `bub_os_rrhh_tipo_contrato` (3 filas).
- **Status de carga:** catálogo en `bub_os_rrhh_status_carga` (4 filas).
- **Horas por miembro:** integración con Clockify vía RPC `clockify_por_miembro`.
- **Carga de trabajo:** tasks activas por miembro (visual de barras).

⚠️ Las tablas `bub_rrhh_*` están vacías — sección con schema preparado pero sin data poblada.

---

## 9. Notificaciones

⏳ **Pendiente documentar.** Sección listada en CLAUDE.md sin detalle funcional. Cuando se implemente o documente, añadir aquí: propósito, componentes, fuente de datos, triggers que generan notificaciones.

---

## 10. Soporte

⏳ **Pendiente documentar.** Sección listada en CLAUDE.md sin detalle funcional.

---

## Patrones UI globales

### Navegación
- Sidebar izquierdo fijo con iconos + labels
- Ítem activo resaltado con borde izquierdo verde `#22c55e`
- Avatar usuario en parte inferior del sidebar

### Paleta de colores
| Token | Valor | Uso |
|---|---|---|
| Fondo | `#0c0d12` | Background page |
| Card | `#13151c` | Contenedores, modales |
| Borde | `#1e2130` | Separadores, bordes card |
| Texto principal | `#edeef3` | Títulos, texto destacado |
| Texto secundario | `#8b95a1` | Labels, subtítulos |
| Acento verde | `#22c55e` | CTAs, estados activos, badges éxito |
| Error | `#ef4444` | Alertas, estados error |
| Warning | `#f97316` | Prioridad alta, warnings |

### Tipografía
- **Space Grotesk** — todo el UI (labels, botones, texto)
- **JetBrains Mono** — números (KPIs, métricas, importes, horas)

### Componentes recurrentes
- **Badge estado tarea:** pill con color según estado (background tenue + texto)
- **Avatar responsable:** círculo con inicial o foto, tooltip con nombre completo
- **Empty state:** ilustración + texto cuando no hay datos en una lista
- **Loading skeleton:** animación mientras carga datos de Supabase
- **Toast notifications:** éxito (verde) / error (rojo) en esquina inferior derecha, auto-dismiss 4s
