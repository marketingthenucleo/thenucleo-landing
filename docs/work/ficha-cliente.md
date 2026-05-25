---
title: Ficha de Cliente (admin-only)
dominio: ficha-cliente
estado: vivo
actualizado: 2026-05-25
version_dataset: F2.2 + iteración piloto Mel (tarde 2026-05-24) + F2.7 Fase A (17 catálogos Supabase + RPC agregadora `catalogos_cliente_get`, seed Rock & Climb 16 entradas) + F2.7 Fase B Sprint 1+2 (panel Catálogos cableado a Supabase real con CRUD inline via PostgREST + sheet bottom + archivado) + F2.7 Fase B Sprint 3 (visibilidad de macros/catálogos por cliente — tabla `cliente_catalogo_visibilidad`, botón ⚙️ Gestionar abre sheet con toggle switches por cada macro y catálogo, datos preservados al ocultar). Deuda menor: link plantilla→campaña en flujo "picker eligió existente"; pickers FK webinar→comunidad_wsp/lead_magnet y editor `campos_capturar` jsonb pendientes (Sprint 4).
tags: [ficha-cliente, work, admin, supabase, oauth, mobile-first, pipelines]
---

# Ficha de Cliente — `work.thenucleo.com/ficha-cliente/`

Vista admin-only mobile-first para consultar y operar sobre la ficha de un cliente del portal. Lee `bub_clientes` vía RPCs admin-allowlist sin tocar las policies de la tabla. Incluye el módulo **Pipelines y Campañas** (visión PxCx, ver [[../portal/ficha-cliente]] para el modelo conceptual).

> ✅ **Vivo desde 2026-05-22** en `work.thenucleo.com/ficha-cliente/` (allowlist 5 emails TheNucleo desde 2026-05-25, `noindex`). **Módulo Pipelines y Campañas** vivo (F2.5d cerrada 2026-05-25): triggers `FM/FW/BD/DM` (DM = auto-DM RRSS con keyword + mensaje); creatividades 1-fila-por-pieza con código `<trigger.code><E|R|C|O><n>` (P1C1FM1E1, P1C1DM1R1…) — cada pieza apunta a un trigger destino obligatorio, categoría ANUNCIOS [Estático/Reel] / RRSS [Carrusel/Reel] / OTROS, sin cantidad (para varias piezas similares crear N entradas); sin Brief Drive (retirado por feedback Ben "aquí no tenemos URLs"). Backend completo en Supabase (`cliente_pipelines` + `cliente_campanias` + `cliente_triggers` + `cliente_emails` + `cliente_mensajes_whatsapp` + `cliente_creatividades` + `cliente_campania_plantillas` + RPCs).
>
> 🆕 **Módulo Catálogos del cliente (F2.7 Fase A + B Sprint 1+2+3 — 2026-05-25):** panel Catálogos pasa de mockup a 17 catálogos reales `cliente_catalogo_*` agrupados en 7 macro-categorías (📁 Recursos Drive · 💬 Comunicación · 📣 Marketing Meta · 💰 Operativo · 🎯 Producto del cliente · ⚠️ Gobierno · 🌐 Webs cliente). Lectura via RPC agregadora `catalogos_cliente_get` (1 fetch que trae los 17 catálogos + la lista de visibilidad). CRUD inline via PostgREST + sheet bottom: botón **+ Añadir** por catálogo, click en entrada → editar, botón archivar/desarchivar (soft-delete con badge `🗄`). **Visibilidad por cliente (Sprint 3):** botón **⚙️ Gestionar catálogos** arriba del panel abre sheet con toggle switches por cada macro y catálogo — Account oculta lo que no aplica al cliente concreto, los datos se preservan al ocultar. Seed Rock & Climb 16 entradas. Pendientes Sprint 4: pickers FK webinar→comunidad_wsp + lead_magnet, editor `campos_capturar` jsonb, buscador global, toggle "ver archivadas".

---

## Resumen ejecutivo

- **Frontend**: HTML standalone en `thenucleo-landing/ficha-cliente/index.html`. Sin Eleventy templating (passthrough copy), sin framework. Carga Supabase JS desde jsdelivr. Mobile-first con paleta TheNucleo dark + verde, font NewBlack (theme switch).
- **Backend**: lectura sobre `bub_clientes` (73 filas) + `playbook_cliente_servicios` (199 filas) vía 2 RPCs `SECURITY DEFINER` con allowlist hardcoded. No escribe — operaciones de escritura siguen viviendo en el portal Bubble.
- **Auth**: Google OAuth reutilizando el flujo de `/comunidad/entrar/` (mismo `storageKey`). Allowlist 5 emails TheNucleo. Mismo patrón que `/playbook/` y `/fichas-de-producto/`.
- **URL deep-link**: `?id=<bubble_id>` carga directamente la ficha del cliente. Sin parámetro muestra el listado de clientes activos + buscador **inline** en el panel (fix 2026-05-25, antes era empty card "Elige un cliente" + botón que abría sheet). El botón "Cambiar" del header sigue abriendo el mismo sheet bottom para switch cuando ya hay cliente cargado.
- **Datos en producción**: 73 clientes activos (filtra `COALESCE(estado,'') <> 'No Activo'`). Selector ordenado alfabético por `nombre_empresas`.
- **Paneles**: 5 — **Datos** (5 grupos colapsables), **Servicios contratados** (agrupado por categoría), **Pipelines y Campañas** (Supabase real desde F2), **Catálogos** (Supabase real desde F2.7 Fase B — 17 catálogos en 7 macros, CRUD inline), **Anomalías** (MOCKUP plano).

---

## URLs y repos

| Recurso | Ubicación |
|---|---|
| URL pública (selector) | https://work.thenucleo.com/ficha-cliente/ |
| URL deep-link cliente | https://work.thenucleo.com/ficha-cliente/?id=`<bubble_id>` |
| Repo frontend | [`marketingthenucleo/thenucleo-landing`](https://github.com/marketingthenucleo/thenucleo-landing) — branch `main` |
| Código | `ficha-cliente/index.html` (raíz del repo, ~2.100 líneas inline) |
| Backend | Supabase project `cbixhqjsnpuhcrcjppah` — tabla `bub_clientes` + RPCs (ver abajo) |

---

## Auth y allowlist

Reutiliza el mismo storageKey `thenucleo-comunidad-auth` que `/comunidad/entrar/`. La sesión se comparte entre `/playbook/`, `/fichas-de-producto/`, `/ficha-cliente/`.

**Editores actuales** (5 emails):

- `benjamin.sanchis@thenucleo.com`
- `alejandro.lopez@thenucleo.com`
- `marketing.thenucleo@gmail.com`
- `mel.dalmazo@thenucleo.com` (añadida 2026-05-15)
- `valentina.ramirez@thenucleo.com` (añadida 2026-05-25)

⚠️ **La allowlist vive en 8 sitios** que hay que sincronizar a mano:

- `EDITOR_EMAILS` en `playbook/index.html` (frontend)
- `EDITOR_EMAILS` en `fichas-de-producto/index.html` (frontend)
- `EDITOR_EMAILS` en `ficha-cliente/index.html` (frontend)
- 3 RLS policies Supabase (`playbook_progreso`, `playbook_task_feedback`, `playbook_cliente_servicios`)
- Body hardcoded de RPC `playbook_cliente_detalle` (SECURITY DEFINER)
- Body hardcoded de RPC `ficha_cliente_listar` (SECURITY DEFINER)
- Body hardcoded de RPC `ficha_cliente_get` (SECURITY DEFINER)
- Body hardcoded de RPC `catalogos_cliente_get` (SECURITY DEFINER) — **añadida 2026-05-25 con F2.7 Fase A**

> Las **17 tablas `cliente_catalogo_*`** (F2.7) NO usan allowlist hardcoded — usan policies con `is_comunidad_admin()` (la misma función que las tablas `cliente_pipelines`, `cliente_emails`, etc.). Al añadir/retirar admin se gestiona desde `comunidad_admins` (no requiere editar 17 × 4 = 68 policies).

> Nota adyacente — `/casuisticas/`, `/presentacion-pipelines/` y los 5 emails del frontend de `/disponibilidades/` también se sincronizan al mismo tiempo (mismo set), pero usan sus propios mecanismos (3 policies hardcoded `casuisticas_board_*`, copy del gate de presentación, `EDITOR_EMAILS` standalone). Total: 11 sitios frontend+backend al añadir/retirar editor.

Con 5 editores ya estamos en el umbral: cuando crezca a 6+ migrar a tabla `playbook_editors(email)` y reescribir las 3 RPCs + 3 policies + las de casuisticas para consultarla. Mientras tanto es asumible.

**Gate auth** (frontend): si el email no está en la allowlist, muestra pantalla de bloqueo con botón "Cerrar sesión y volver al login". Si está, pinta el selector / la ficha solicitada.

---

## RPCs (Supabase)

Ambas en proyecto `cbixhqjsnpuhcrcjppah`, `SECURITY DEFINER`, `GRANT EXECUTE TO authenticated`, allowlist hardcoded en el body, `RAISE EXCEPTION 'forbidden'` ERRCODE `42501` si el email no autoriza.

### `ficha_cliente_listar()` → `RETURNS TABLE`

Selector dropdown. Devuelve `(bubble_id text, nombre_empresas text, sector text, estado text)` filtrando `COALESCE(estado,'') <> 'No Activo'` y ordenado alfabético.

### `ficha_cliente_get(p_bubble_id text)` → `RETURNS jsonb`

Detalle por cliente. `to_jsonb(c.*)` de la fila completa de `bub_clientes` **+ array `servicios`** (ampliación 2026-05-22, migration `ficha_cliente_get_incluir_servicios`):

- `jsonb_agg(pcs.*)` de `playbook_cliente_servicios WHERE cliente_bubble_id = p_bubble_id`
- Orden `orden NULLS LAST, created_at`
- Cada elemento trae `ficha_titulo`, `categoria_nombre`, `categoria_color`, `unidades`, `periodo`, `notas`

Ver detalle del schema en [[../infra/supabase-schema]] sección "Ficha de Cliente".

---

## Paneles

### Panel "Datos"

5 grupos colapsables `.coll-group` con caret animado, dot de color, nombre y **badge `rellenos/total`**:

| Grupo | Origen | Notas |
|---|---|---|
| Identificación | `nombre_empresas`, `nombre_sociedad`, `dni_nif`, dirección fiscal (`direccion_fiscal` + `codigo_postal` + `provincia` + `pais`), `telefono_principal` | Por defecto **abierto** al cargar |
| Contacto | `email_principal`, contactos secundarios, `responsable_cuenta` | |
| Presencia digital | `pagina_web`, `logo_url` | ⚠️ Instagram, Facebook, Meta BM, Google Ads, GHL, DNS hoy son MOCKUP — pendiente decidir si entran como columnas nuevas o tabla aparte `cliente_accesos` |
| Accesos | (MOCKUP) | Hoy todos los campos son placeholder. Badge `MOCKUP · N` en gris neutro |
| Operaciones internas | `link_drive`, links análisis, `gchat_space_id`, NPS más reciente, `bb_estado_facturacion` | |

**Badge inteligente**: cuenta campos con valor real vs total, ignorando los mock. Verde si todo relleno, ámbar si faltan, `MOCKUP · N` (neutro) si la sección es 100% placeholder (caso Accesos hoy).

Patrón colapsable con atributo `[data-coll-toggle]` + handler global (click + Enter/Space + `aria-expanded`). Helper JS: `renderDatosSection(listId, countId, fields)` pinta los rows y actualiza el badge.

### Panel "Servicios contratados"

Lee el array `servicios` que viene en `ficha_cliente_get`. Renderiza **agrupado por `categoria_nombre`** con headers `.coll-group`:

- Dot del color de la categoría · nombre · count pill
- Buscador (matchea `ficha_titulo` / `categoria_nombre` / `unidades` / `periodo` / `notas`). Aparece **solo si hay >4 items**. Al escribir, auto-expande los grupos con match.
- Botón **"Expandir todo / Colapsar todo"** en la cabecera del panel.
- Cada fila muestra `ficha_titulo`, `unidades`, `periodo`, `notas`.

### Panel "Pipelines y Campañas"

Módulo F1 (vivo desde 2026-05-23). Implementación: ver `ficha-cliente/index.html` líneas 1677-2100 (`// Pipelines & Campañas module — F1: SEED hardcoded Dra. Neuss`).

**Datos**: 4 pipelines hardcoded en el `const SEED` (P1 Venta directa Curso Suplementación, P2 Captación leads, P3 Reactivación, P4 Newsletter mensual). Cada uno con campañas, triggers y emails alineados a la nomenclatura PxCx (ver [[../portal/ficha-cliente]] §3).

**UI**:

- Crumbs navegables (`Pipelines › P1C1 › P1C1FM1 ...`).
- Vistas: Lista de pipelines · Detalle pipeline (campañas, briefing, estado) · Detalle campaña (triggers + emails) · Detalle trigger · Detalle email.
- Toggle "Mostrar archivados" (`S.showArchived`).
- Nota visible permanente: **"📌 Datos seed F1 · Los 4 pipelines de Dra. Neuss vienen hardcoded para validar UI. En F2 esto se cablea a Supabase por cliente."**
- Briefings de Drive son `drive://...` placeholders (no abren — sólo nombre del archivo).

**Pendiente F2**: 4 tablas Supabase nuevas (`cliente_pipelines` + `cliente_campanias` + `cliente_triggers` + `cliente_emails`) + RPCs CRUD + RLS por `cliente_id`. La visión completa del modelo está en [[../portal/ficha-cliente]] §10 punto 4.

### Panel "Catálogos" (F2.7 Fase B Sprint 1+2 — vivo 2026-05-25)

Biblioteca de recursos reutilizables del cliente. **17 catálogos** agrupados visualmente en **7 macro-categorías**. Lectura via RPC agregadora `catalogos_cliente_get` (1 fetch). CRUD inline via PostgREST: las **68 policies** (4×17) con `is_comunidad_admin()` validan cada operación.

**Estructura del panel** (orden visual):

| Macro | Catálogos (tabla Supabase) |
|---|---|
| 📁 Recursos Drive | `cliente_catalogo_carpeta_drive` · `cliente_catalogo_documento` |
| 💬 Comunicación | `cliente_catalogo_comunidad_wsp` · `cliente_catalogo_email_remitente` · `cliente_catalogo_etiqueta` |
| 📣 Marketing Meta | `cliente_catalogo_cuenta_publicitaria` · `cliente_catalogo_pixel` · `cliente_catalogo_pagina_social` · `cliente_catalogo_publico_personalizado` · `cliente_catalogo_plantilla_form_meta` |
| 💰 Operativo | `cliente_catalogo_presupuesto` |
| 🎯 Producto del cliente | `cliente_catalogo_lead_magnet` · `cliente_catalogo_webinar` · `cliente_catalogo_sistema_reserva` · `cliente_catalogo_producto_servicio` |
| ⚠️ Gobierno | `cliente_catalogo_regla` (caveats tipo "NO PONER JAMÁS…") |
| 🌐 Webs cliente | `cliente_catalogo_web_cliente` |

Cada catálogo es un `.coll-group` colapsable con:
- **Dot color** distintivo por macro (azul Drive, púrpura comunicación, cian Meta, ámbar operativo, rojo producto, amarillo gobierno, turquesa webs).
- **Badge contador** `N` (activas) o `N · 🗄 M` cuando hay archivadas.
- Botón **+ Añadir** a la derecha del header (abre sheet bottom con form).

**Render de entrada (read-only)** — `.catalog-item`:
- Nombre + meta (categoria/tipo/plataforma/precio según catálogo).
- Badge naranja **"URL pendiente"** si la URL contiene la palabra `PENDIENTE` (convención del seed F2.7 para entradas importadas sin URL real visible en el PDF de origen).
- Badge gris **`🗄 archivada`** + tachado si soft-deleted.
- Icono **↗** a la derecha si hay URL real (no placeholder, no archivada) — abre en nueva pestaña, NO abre edit.

**CRUD inline (Sprint 2)**:

- **Crear**: botón "+ Añadir" del header → sheet bottom con form generado desde `fields` array del catálogo. Validación required client-side. POST a `/rest/v1/<tabla>` con `cliente_bubble_id` añadido automáticamente.
- **Editar**: click en cualquier `.catalog-item` (excepto su link ↗) → sheet bottom prellenado con valores actuales. PATCH a `/rest/v1/<tabla>?id=eq.<uuid>`.
- **Archivar / Desarchivar**: botón "Archivar" dentro del form de edit → `confirm()` + PATCH `archivada: true/false` + `archivada_en: now()` o `null`.
- **Toast** tras éxito + cierre del sheet.
- **Errores** Supabase (CHECK constraint, RLS, UNIQUE, etc.) se muestran en banner ámbar dentro del form sin cerrarlo.
- **Refresh tras CRUD**: re-fetch agregado completo (1 RPC barato) + preserva qué coll-groups estaban abiertos en el viewport. No salta el scroll.

**Tipos de campo soportados en el form** (config `fields`):
- `text`, `url`, `number` (con step), `date`, `textarea`, `select` (con `options`), `checkbox`.
- Strings vacíos opcionales se envían `null` para no machacar defaults DB.

**Visibilidad por cliente (Sprint 3, decisión 2026-05-25):**

Tabla nueva `cliente_catalogo_visibilidad` con `(cliente_bubble_id, scope_type CHECK ('macro','catalogo'), scope_key, oculto bool, audit)` + UNIQUE compuesta. Si NO existe row → visible (default). Si existe con `oculto=true` → oculto. Macro oculta tiene **precedencia**: aunque sus catálogos estén marcados visibles individualmente, no se renderizan.

- **UI:** botón "⚙️ Gestionar catálogos" arriba del panel (`.catalogos-controls` + `.cat-manage-btn`). Abre sheet bottom con 2 secciones: **Macros** (7 switches) + **Catálogos individuales** (17 switches agrupados por su macro, con `disabled` cuando la macro padre está oculta).
- **UPSERT** via `tableRequest('cliente_catalogo_visibilidad', { method:'POST', query:'on_conflict=cliente_bubble_id,scope_type,scope_key', prefer:'resolution=merge-duplicates,return=minimal', body:{...} })`. El helper acepta ahora `prefer` custom (Sprint 3 amplía el helper original).
- **Auto-hide de macros vacías:** si TODOS los catálogos de una macro están ocultos individualmente, la macro se omite del render aunque no esté explícitamente oculta. Evita "carpeta sin contenido" en pantalla.
- **Refresh sin recargar:** toggle → UPSERT → actualiza `data.visibilidad` en memoria → re-render del sheet (para reflejar disabled) + re-render del panel detrás preservando coll-groups abiertos.
- **Empty state:** si TODAS las macros están ocultas, el panel muestra `empty-card` "Todas las macros están ocultas para este cliente. Pulsa '⚙️ Gestionar catálogos' para reactivar".
- **Listener:** `change` (no `click`) en los `[data-vis-toggle]` — el browser ya gestiona el flip del checkbox, sólo persistimos el nuevo estado.
- **Vive en Supabase**, no en localStorage: la visibilidad es del cliente, no del usuario. Si Mel oculta "Sistemas de reserva" para Rock & Climb, Ben también lo ve oculto al abrir Rock & Climb.

**Política de borrado** (decisión 2026-05-25):
- **No hay DELETE duro desde la UI**, a propósito. El único modo de "borrar" desde Account es **archivar** (soft-delete con `archivada=true` + `archivada_en=now()`). Las archivadas siguen visibles tachadas con badge `🗄` y se pueden desarchivar.
- Razones: (1) trazabilidad — un borrado real rompe la historia; (2) **Fase C** (cuando Campaña referencie entradas del catálogo por FK + snapshot del nombre) un DELETE duro rompería esas referencias retroactivas y el patrón snapshot+vivo deja de funcionar; (3) consistencia con el resto de tablas `cliente_*` (emails, mensajes WhatsApp, creatividades, triggers) que ya usan `estado='archivado'`/`archivada=true` sin DELETE.
- Si alguna vez hace falta limpiar de verdad (entrada creada por error, duplicado, etc.): **SQL directo desde Supabase Studio** (acceso admin Ben). No es operativa de Account.

**Helpers JS** (en `ficha-cliente/index.html`):
- `tableRequest(table, opts)` — helper genérico PostgREST con `Prefer: return=representation` en POST/PATCH.
- `CATALOGOS_MODULE` — IIFE que encapsula `MACROS` (7), `CATALOGOS` (17 con `table` + `fields` + extractores read-only), `OPTS` (selects predefinidos), `loadFor()`, `render()`, `refreshAll()`, handlers de click delegados.

**Pendientes Sprint 3**:
- Pickers FK en webinar para `comunidad_wsp_id` y `lead_magnet_id` (hoy esos 2 campos no aparecen en el form de webinar).
- Editor `campos_capturar` jsonb en plantillas_form_meta (UI con chips para defaults + extras). Hoy queda como el default del schema.
- Buscador global del panel para los 17 catálogos.
- Toggle "Ver archivadas" (hoy se muestran siempre, tachadas y al final del orden).
- Bulk operations (importar lista, exportar CSV).

### Panel "Anomalías"

MOCKUP plano (sin colapsables). No se inventan datos. Visión futura: integrar con `n8n_incidencias` filtradas por cliente + checks operativos básicos (servicios sin Drive, campañas sin briefing, etc.).

---

## Chip strip (header de la ficha)

Pinta entre 1 y 5 chips según los datos del cliente:

| Chip | Condición | Variante |
|---|---|---|
| Estado | `c.estado` | verde si "Activo", rojo si contiene "no", ámbar otros |
| Sector | `c.sector` | neutro |
| Plan | `c.plan_actual` | neutro |
| Google Chat activo | `c.gchat_space_id` presente | verde |
| Facturación | `c.bb_estado_facturacion` | verde si al día, ámbar otros |
| ~~Pipelines · mockup~~ | ✅ **Retirado 2026-05-23** | era hardcoded; el módulo ya no es mockup |
| Anomalías · mockup | hardcoded (mantenido a propósito) | neutro |

---

## Fixes y cambios recientes

### 2026-05-25 — F2.7 Fase B Sprint 3: visibilidad de macros/catálogos por cliente
Commit `7eef03f` (frontend) + migration Supabase `f2_7_sprint3_catalogos_visibilidad`. Tabla nueva `cliente_catalogo_visibilidad` + RLS con `is_comunidad_admin()` + RPC `catalogos_cliente_get` ampliada para devolver array `visibilidad`. Frontend: botón "⚙️ Gestionar catálogos" abre sheet bottom con switches por macro (7) + catálogo (17 agrupados). UPSERT vía PostgREST `on_conflict=...&prefer:resolution=merge-duplicates`. Auto-hide de macros con todos sus catálogos ocultos. Datos preservados al ocultar.

Helper `tableRequest()` ampliado: ahora acepta `prefer` opcional (compat retro — si no se pasa, mantiene el `Prefer: return=representation` previo en POST/PATCH).

### 2026-05-25 — Fix botón "+ Añadir" del panel Catálogos
Commit `5fa8363`. El `onclick="event.stopPropagation()"` inline del botón rompía el delegate handler del módulo (vivía en `document`). Fix: quitar el onclick + añadir guard `if (e.target.closest('[data-cat-add]')) return;` en el handler de `[data-coll-toggle]` (línea ~1823).

### 2026-05-25 — F2.7 Fase B Sprint 2: CRUD inline en panel Catálogos
Commits `b59e9fd` (frontend). Reemplaza el panel mockup por CRUD completo via PostgREST (`tableRequest()` helper) + sheet bottom reutilizado (`openSheet/closeSheet`). Cada uno de los 17 catálogos declara `table` + array `fields` (text/url/number/date/textarea/select/checkbox) consumido por un render genérico. Validación required client-side. Strings vacíos opcionales → `null`. Archive desde form con `confirm()`. Tras CRUD: re-fetch agregado preservando grupos abiertos.

Fuera de scope (Sprint 3): pickers FK `comunidad_wsp_id` + `lead_magnet_id` en webinar; editor `campos_capturar` jsonb en plantillas_form_meta; buscador global del panel; toggle "ver archivadas".

### 2026-05-25 — F2.7 Fase B Sprint 1: panel Catálogos cableado read-only
Commit `7de0b79` (frontend). Reemplaza el HTML mockup (2 grupos placeholder) por container que el módulo JS llena con los 17 catálogos reales agrupados en 7 macro-categorías. CSS nuevo: `.cat-macro` / `.cat-macro-head` / `.cat-pending-badge` (URL placeholder) / `.cat-archived-badge` / `.catalog-item.archived`. `CATALOGOS_MODULE` IIFE con `MACROS` (7) + `CATALOGOS` (17) + `loadFor()` + `render()`. Lectura via RPC `catalogos_cliente_get` (1 fetch). Reusa el handler global `[data-coll-toggle]` para abrir/cerrar grupos.

### 2026-05-25 — F2.7 Fase A: schema Supabase de 17 catálogos
Commit `27a661d` (docs). Migration `f2_7_catalogos_cliente` aplicada vía MCP Supabase: 17 tablas `cliente_catalogo_*` + 36 indexes + 68 policies + 17 triggers + RPC agregadora `catalogos_cliente_get(p_bubble_id)` SECURITY DEFINER con allowlist 5 emails. Convenciones reusadas de `cliente_pipelines`/`cliente_emails`: PK uuid, `cliente_bubble_id` FK lógica, audit fields, `update_updated_at()` trigger, RLS con `is_comunidad_admin()`. Soft-delete con `archivada boolean + archivada_en timestamptz` (en lugar de `estado` text — biblioteca de recursos ≠ entidad con ciclo de vida).

**Seed Rock & Climb** (bubble_id `1778244949886x…`): 16 entradas en 6 catálogos derivadas del PDF de lanzamiento (2 carpetas drive con URL placeholder, 3 documentos —1 URL real + 2 placeholder—, 1 comunidad WSP real, 1 plantilla form Meta, 1 presupuesto Meta Ads 300€ único, 8 productos/servicios del calendario mensual de talleres 15-45€).

### Fix 2026-05-23 — Chip "Pipelines · mockup" retirado
Hardcoded en `ficha-cliente/index.html:1392`. Retirado en commit `48af7c8` porque el módulo Pipelines ya no es mockup (seed F1 funcional). Anomalías sigue con su chip porque sí es MOCKUP plano.

### Fix 2026-05-23 — Datos y Catálogos colapsables
Componente unificado `.coll-group` reutilizado en los 3 paneles (Datos / Catálogos / Servicios). Cada header con caret animado, dot de color, nombre y badge contador. Por defecto solo Identificación abierto. Refactor `.svc-group*` → `.coll-group*`. Helper `renderDatosSection(listId, countId, fields)` reemplaza el `.innerHTML = [...].join('')` por sección. Commit `94fce60`.

### 2026-05-23 — Módulo Pipelines y Campañas (F1)
Frontend vivo con seed hardcoded de Dra. Neuss. Ver commit `8b2d3e9` (`feat(ficha-cliente): portar modulo Pipelines y Campañas con seed F1`). Esto es lo que el chip "Pipelines · mockup" describía hasta ese momento como "mockup".

### 2026-05-22 — Servicios contratados agrupados
La RPC `ficha_cliente_get` se amplió para devolver `servicios` (jsonb_agg de `playbook_cliente_servicios`). El panel pasó de placeholder a render real agrupado por categoría + buscador.

### 2026-05-22 — Cableado inicial a `bub_clientes`
Vista lanzada. Antes era un mockup con datos inventados. Migration RPCs `ficha_cliente_listar` + `ficha_cliente_get`.

---

## Cross-refs

- **Visión PxCx / modelo conceptual de Pipelines**: [[../portal/ficha-cliente]] — el WHY, las 7 reglas, las casuísticas, las plantillas de campaña.
- **Infraestructura técnica**: [[../infra/supabase-schema]] sección "Ficha de Cliente" — RPCs, columnas relevantes, política allowlist.
- **Hub del dominio**: [[README]] — visión global de las páginas admin.
- **Deuda técnica**: [[deuda-tecnica]] — items abiertos del landing y admin.
- **Hermanas en `/playbook/`, `/fichas-de-producto/`**: [[playbook]] + [[fichas-de-producto]] — comparten allowlist, gate auth y patrón nav.

---

## Pendientes

1. ~~**F2 schema Supabase Pipelines y Campañas**~~ ✅ **Aplicado 2026-05-24.** 5 tablas (`cliente_campania_plantillas` + `cliente_pipelines` + `cliente_campanias` + `cliente_triggers` + `cliente_emails`) con RLS via `is_comunidad_admin()` (20 policies, 4×tabla) + 7 plantillas seed. Migration `ficha_cliente_pipelines_f2_schema` en `supabase/migrations/20260524_ficha_cliente_pipelines_f2_schema.sql`. Detalle en [[../infra/supabase-schema#pipelines-y-campañas]].
2. ~~**F2.2.1 RPC read + cableo frontend lectura**~~ ✅ **Cerrado 2026-05-24.** `ficha_pipelines_get(p_bubble_id)` (SECURITY INVOKER, devuelve jsonb con forma JS-friendly que matchea el SEED previo) + seed Neus migrado a DB (4 pipelines + 4 campañas + 4 triggers + 5 emails) + frontend modificado: `const SEED` removido, `PIPELINES_MODULE.loadFor(c.bubble_id)` cableado en `renderCliente`, módulo con `setData`/`loadFor`/`loadStatus`. Banner "modo lectura · F2.2.1" reemplaza la nota de seed. Migration en `supabase/migrations/20260524_ficha_cliente_pipelines_f2_read_rpc_and_seed_neus.sql`. **Decisión sobre `ficha_cliente_get`:** NO se amplía con `pipelines` — frontend hace 2 calls en paralelo (evita el puzzle DEFINER↔INVOKER, mantiene RPCs separadas por dominio).
3. ~~**F2.2.2.A RPC writes Supabase**~~ ✅ **Cerrado 2026-05-24.** 5 upserts (`ficha_pipeline_upsert`, `ficha_campania_upsert`, `ficha_trigger_upsert`, `ficha_email_upsert`) con auto-código server-side via regex sobre max actual (regla `.docx` §3.4: codes nunca se reutilizan) + `ficha_archivar_codigo(p_kind, p_id)` genérico para los 4 tipos. Todas `SECURITY INVOKER`, GRANT a authenticated, gate por RLS `is_comunidad_admin()`. "Servidor propone, usuario valida": cada upsert acepta `p_codigo_override` opcional. Smoke test: insert P5 + P5C1 + P5C1FM1 + P5C1BD1 (con fecha obligatoria) + email + UPDATE estado → 'copy-listo' + archivar + cleanup. Verde. Migration en `supabase/migrations/20260524_ficha_cliente_pipelines_f2_write_rpcs.sql`.
4. ~~**F2.2.2.B cableo drawers frontend**~~ ✅ **Cerrado 2026-05-24 en 5 micro-commits.** B.1: `stateBadge()` ampliado a 11 estados finos + CSS por familia de color (warn/info/ok/neutral). B.2: drawer "Nuevo Pipeline" wired a `ficha_pipeline_upsert`. B.3: drawer "Nueva Campaña" wired (sin link `plantilla_id` — deuda menor). B.4: archivar pipeline/campaña wired a `ficha_archivar_codigo`. B.5+6: drawers "Nuevo Trigger" (3 cards FM/FW/BD + form contextual + fecha obligatoria si BD) y "Nuevo Email" (form + chip multi-select de triggers aplicables con preview reactivo del código + equivalencia caso 5: marcados==todos → []) creados desde cero + wire. Banner "modo lectura · F2.2.1" retirado.
5. **Deuda menor abierta:**
    - Archivar trigger/email — añadir botón en `renderTriggerView` y `renderEmailView` (RPC ya soporta `kind='trigger'|'email'`).
    - Link plantilla→campaña al persistir — en B.3 se pasa `p_plantilla_id: null`. Cargar catálogo `cliente_campania_plantillas` en init y mapear slug→uuid antes del save, o ampliar la RPC con `p_plantilla_slug text` que resuelve server-side.
    - "Editar" en los detail views — hoy los views son read-only. Habilitar inline edit que llame al upsert correspondiente con `p_id` pasado (ya soportado por las RPCs, sólo falta la UI).
3. **Piloto con Melina sobre Neus** — sentarse 30 min y declarar los 4 pipelines reales en el módulo (cuando #2 esté listo). Validar si el modelo aguanta.
4. **Migrar 5 clientes más activos** al modelo en sesiones acompañadas con Account.
5. **Panel Catálogos cableado** — depende de las RPCs F2.
6. **Panel Anomalías** — integrar `n8n_incidencias` filtradas por cliente + checks operativos derivados (servicios sin Drive, campañas sin briefing).
7. **Allowlist en tabla `playbook_editors(email)`** cuando crezca a 5+ editores.
