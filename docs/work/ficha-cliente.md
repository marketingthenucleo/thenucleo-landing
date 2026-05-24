---
title: Ficha de Cliente (admin-only)
dominio: ficha-cliente
estado: vivo
actualizado: 2026-05-24
version_dataset: F2.2.1 (read) + F2.2.2.A (5 upsert + archivar) vivos · F2.2.2.B (cableo drawers + stateBadge) pendiente
tags: [ficha-cliente, work, admin, supabase, oauth, mobile-first, pipelines]
---

# Ficha de Cliente — `work.thenucleo.com/ficha-cliente/`

Vista admin-only mobile-first para consultar y operar sobre la ficha de un cliente del portal. Lee `bub_clientes` vía RPCs admin-allowlist sin tocar las policies de la tabla. Incluye el módulo **Pipelines y Campañas** (visión PxCx, ver [[../portal/ficha-cliente]] para el modelo conceptual).

> ✅ **Vivo desde 2026-05-22** en `work.thenucleo.com/ficha-cliente/` (allowlist 4 emails TheNucleo, `noindex`). **Módulo Pipelines y Campañas** vivo desde 2026-05-23 con seed F1 hardcoded de Dra. Neuss. Backend Supabase (`cliente_pipelines` + `cliente_campanias` + `cliente_triggers` + `cliente_emails` + RPCs) es F2 — sesión técnica pendiente.

---

## Resumen ejecutivo

- **Frontend**: HTML standalone en `thenucleo-landing/ficha-cliente/index.html`. Sin Eleventy templating (passthrough copy), sin framework. Carga Supabase JS desde jsdelivr. Mobile-first con paleta TheNucleo dark + verde, font NewBlack (theme switch).
- **Backend**: lectura sobre `bub_clientes` (73 filas) + `playbook_cliente_servicios` (199 filas) vía 2 RPCs `SECURITY DEFINER` con allowlist hardcoded. No escribe — operaciones de escritura siguen viviendo en el portal Bubble.
- **Auth**: Google OAuth reutilizando el flujo de `/comunidad/entrar/` (mismo `storageKey`). Allowlist 4 emails TheNucleo. Mismo patrón que `/playbook/` y `/fichas-de-producto/`.
- **URL deep-link**: `?id=<bubble_id>` carga directamente la ficha del cliente. Sin parámetro abre el selector con buscador (sheet bottom).
- **Datos en producción**: 73 clientes activos (filtra `COALESCE(estado,'') <> 'No Activo'`). Selector ordenado alfabético por `nombre_empresas`.
- **Paneles**: 5 — **Datos** (5 grupos colapsables), **Servicios contratados** (agrupado por categoría), **Pipelines y Campañas** (seed F1), **Catálogos** (MOCKUP), **Anomalías** (MOCKUP plano).

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

**Editores actuales** (4 emails):

- `benjamin.sanchis@thenucleo.com`
- `alejandro.lopez@thenucleo.com`
- `marketing.thenucleo@gmail.com`
- `mel.dalmazo@thenucleo.com` (añadida 2026-05-15)

⚠️ **La allowlist vive en 7 sitios** que hay que sincronizar a mano:

- `EDITOR_EMAILS` en `playbook/index.html` (frontend)
- `EDITOR_EMAILS` en `fichas-de-producto/index.html` (frontend)
- `EDITOR_EMAILS` en `ficha-cliente/index.html` (frontend)
- 3 RLS policies Supabase (`playbook_progreso`, `playbook_task_feedback`, `playbook_cliente_servicios`)
- Body hardcoded de RPC `playbook_cliente_detalle` (SECURITY DEFINER)
- Body hardcoded de RPC `ficha_cliente_listar` (SECURITY DEFINER)
- Body hardcoded de RPC `ficha_cliente_get` (SECURITY DEFINER)

Cuando crezca a 5+ editores migrar a tabla `playbook_editors(email)` y reescribir las 3 RPCs + 3 policies para consultarla. Mientras tanto es asumible.

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

### Panel "Catálogos"

MOCKUP en `.coll-group` (Plantillas de Campaña + Plantillas de Trigger). No se inventan datos — placeholders explícitos. Cableado real depende de la decisión sobre `cliente_plantillas_campania` (ver [[../portal/ficha-cliente]] §4).

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
4. **F2.2.2.B cableo drawers frontend (siguiente paso)** — wire de los drawers de `PIPELINES_MODULE` ("Nuevo Pipeline" / "Nueva Campaña" / "Nuevo Trigger" / "Nuevo Email" + edit inline + archivar) a las 6 RPCs F2.2.2.A. Tras cada save: `await rpc('ficha_X_upsert', {...})` + `await PIPELINES_MODULE.loadFor(bubbleId)` para refresco completo. Refactor `stateBadge()` (`ficha-cliente/index.html`) — ampliar de 3 a 14 labels + clases CSS (2 pipeline + 3 campaña + 4 trigger + 6 email). Retirar banner "modo lectura · F2.2.1" al cerrar.
3. **Piloto con Melina sobre Neus** — sentarse 30 min y declarar los 4 pipelines reales en el módulo (cuando #2 esté listo). Validar si el modelo aguanta.
4. **Migrar 5 clientes más activos** al modelo en sesiones acompañadas con Account.
5. **Panel Catálogos cableado** — depende de las RPCs F2.
6. **Panel Anomalías** — integrar `n8n_incidencias` filtradas por cliente + checks operativos derivados (servicios sin Drive, campañas sin briefing).
7. **Allowlist en tabla `playbook_editors(email)`** cuando crezca a 5+ editores.
