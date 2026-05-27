---
title: Ficha de Cliente (admin-only)
dominio: ficha-cliente
estado: vivo
actualizado: 2026-05-25
version_dataset: F2.2 + iteración piloto Mel (tarde 2026-05-24) + F2.5e (5º tipo de trigger `SD` "Sin trigger definido" — canal ajeno al sistema, solo declarativo) + F2.7 Fase A (17 catálogos Supabase + RPC agregadora `catalogos_cliente_get`, seed Rock & Climb 16 entradas) + F2.7 Fase B Sprint 1+2 (panel Catálogos cableado a Supabase real con CRUD inline via PostgREST + sheet bottom + archivado) + F2.7 Fase B Sprint 3 (visibilidad de macros/catálogos por cliente — tabla `cliente_catalogo_visibilidad`, botón ⚙️ Gestionar abre sheet con toggle switches por cada macro y catálogo, datos preservados al ocultar). Deuda menor: link plantilla→campaña en flujo "picker eligió existente"; pickers FK webinar→comunidad_wsp/lead_magnet y editor `campos_capturar` jsonb pendientes (Sprint 4).
tags: [ficha-cliente, work, admin, supabase, oauth, mobile-first, pipelines]
---

# Ficha de Cliente — `work.thenucleo.com/ficha-cliente/`

Vista admin-only mobile-first para consultar y operar sobre la ficha de un cliente del portal. Lee `bub_clientes` vía RPCs admin-allowlist sin tocar las policies de la tabla. Incluye el módulo **Pipelines y Campañas** (visión PxCx, ver [[../portal/ficha-cliente-operativa]] para el modelo conceptual).

> ✅ **Vivo desde 2026-05-22** en `work.thenucleo.com/ficha-cliente/` (allowlist 5 emails TheNucleo desde 2026-05-25, `noindex`). **Módulo Pipelines y Campañas** vivo (F2.5d cerrada 2026-05-25; F2.5e tipo SD 2026-05-25): triggers `FM/FW/BD/DM/SD` (DM = auto-DM RRSS con keyword + mensaje; SD = "Sin trigger definido" — canal ajeno al sistema como broadcast WhatsApp, carteles físicos, eventos, boca a boca; solo declarativo, sin requisitos extra); creatividades 1-fila-por-pieza con código `<trigger.code><E|R|C|O><n>` (P1C1FM1E1, P1C1DM1R1, P1C1SD1O1…) — cada pieza apunta a un trigger destino obligatorio, categoría ANUNCIOS [Estático/Reel] / RRSS [Carrusel/Reel] / OTROS, sin cantidad (para varias piezas similares crear N entradas); sin Brief Drive (retirado por feedback Ben "aquí no tenemos URLs"). Backend completo en Supabase (`cliente_pipelines` + `cliente_campanias` + `cliente_triggers` + `cliente_emails` + `cliente_mensajes_whatsapp` + `cliente_creatividades` + `cliente_campania_plantillas` + RPCs).
>
> 🆕 **Módulo Catálogos del cliente (F2.7 Fase A + B Sprint 1+2+3 — 2026-05-25):** panel Catálogos pasa de mockup a 17 catálogos reales `cliente_catalogo_*` agrupados en 7 macro-categorías (📁 Recursos Drive · 💬 Comunicación · 📣 Marketing Meta · 💰 Operativo · 🎯 Producto del cliente · ⚠️ Gobierno · 🌐 Webs cliente). Lectura via RPC agregadora `catalogos_cliente_get` (1 fetch que trae los 17 catálogos + la lista de visibilidad). CRUD inline via PostgREST + sheet bottom: botón **+ Añadir** por catálogo, click en entrada → editar, botón archivar/desarchivar (soft-delete con badge `🗄`). **Visibilidad por cliente (Sprint 3):** botón **⚙️ Gestionar catálogos** arriba del panel abre sheet con toggle switches por cada macro y catálogo — Account oculta lo que no aplica al cliente concreto, los datos se preservan al ocultar. Seed Rock & Climb 16 entradas. Pendientes Sprint 4: pickers FK webinar→comunidad_wsp + lead_magnet, editor `campos_capturar` jsonb, buscador global, toggle "ver archivadas".
>
> 🆕 **Migración a subsecciones — Sprint 1 cerrado 2026-05-25:** `/ficha-cliente/` empieza a partirse en subsecciones hermanas accesibles desde el submenú del Cliente en Bubble. **Vivo:** `/estrategia/?id=<bubble_id>` (clon pelado con solo `PIPELINES_MODULE`, ver [[estrategia|docs/work/estrategia]]) y `/timeline/?id=<bubble_id>` (placeholder "en construcción", pendiente diseño del módulo). `/ficha-cliente/` **queda intacta y vivo** como monolito y fuente de verdad de los módulos clonados. Datos desaparece (su fuente está en Bubble), Anomalías era mockup → fuera de scope. **Convención de mantenimiento durante la convivencia:** cualquier cambio funcional a `PIPELINES_MODULE` se edita PRIMERO aquí, luego se propaga al clon en `/estrategia/index.html` (bit-a-bit por ahora). Cuando se clone el 3er panel (`/catalogo/`), bloquear más clones hasta extraer `_includes/admin-base.njk` + `assets/js/admin-shared.js` (deuda técnica registrada en [[deuda-tecnica]]). Bridge Portal → Work ampliado en el mismo sprint para aceptar `next_path` opcional (anti-open-redirect con allowlist de paths), ver [[bridge-portal-ficha]].

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

⚠️ **La allowlist vive en 9 sitios** que hay que sincronizar a mano:

- `EDITOR_EMAILS` en `playbook/index.html` (frontend)
- `EDITOR_EMAILS` en `fichas-de-producto/index.html` (frontend)
- `EDITOR_EMAILS` en `ficha-cliente/index.html` (frontend)
- 3 RLS policies Supabase (`playbook_progreso`, `playbook_task_feedback`, `playbook_cliente_servicios`)
- Body hardcoded de RPC `playbook_cliente_detalle` (SECURITY DEFINER)
- Body hardcoded de RPC `ficha_cliente_listar` (SECURITY DEFINER)
- Body hardcoded de RPC `ficha_cliente_get` (SECURITY DEFINER)
- Body hardcoded de RPC `catalogos_cliente_get` (SECURITY DEFINER) — añadida 2026-05-25 con F2.7 Fase A
- **`ALLOWLIST` const en Edge Function `bridge_from_portal` + policy `admins_read_audit` de `bridge_audit_log` — añadidas 2026-05-25** (bridge portal→/ficha-cliente/, ver [[bridge-portal-ficha]])

> Las **17 tablas `cliente_catalogo_*`** (F2.7) NO usan allowlist hardcoded — usan policies con `is_comunidad_admin()` (la misma función que las tablas `cliente_pipelines`, `cliente_emails`, etc.). Al añadir/retirar admin se gestiona desde `comunidad_admins` (no requiere editar 17 × 4 = 68 policies).

> Nota adyacente — `/casuisticas/`, `/presentacion-pipelines/` y los 5 emails del frontend de `/disponibilidades/` también se sincronizan al mismo tiempo (mismo set), pero usan sus propios mecanismos (3 policies hardcoded `casuisticas_board_*`, copy del gate de presentación, `EDITOR_EMAILS` standalone). Total: 12 sitios frontend+backend al añadir/retirar editor.

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

**Datos**: 4 pipelines hardcoded en el `const SEED` (P1 Venta directa Curso Suplementación, P2 Captación leads, P3 Reactivación, P4 Newsletter mensual). Cada uno con campañas, triggers y emails alineados a la nomenclatura PxCx (ver [[../portal/ficha-cliente-operativa]] §3).

**UI**:

- Crumbs navegables (`Pipelines › P1C1 › P1C1FM1 ...`).
- Vistas: Lista de pipelines · Detalle pipeline (campañas, briefing, estado) · Detalle campaña (triggers + emails) · Detalle trigger · Detalle email.
- Toggle "Mostrar archivados" (`S.showArchived`).
- Nota visible permanente: **"📌 Datos seed F1 · Los 4 pipelines de Dra. Neuss vienen hardcoded para validar UI. En F2 esto se cablea a Supabase por cliente."**
- Briefings de Drive son `drive://...` placeholders (no abren — sólo nombre del archivo).

**Pendiente F2**: 4 tablas Supabase nuevas (`cliente_pipelines` + `cliente_campanias` + `cliente_triggers` + `cliente_emails`) + RPCs CRUD + RLS por `cliente_id`. La visión completa del modelo está en [[../portal/ficha-cliente-operativa]] §10 punto 4.

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

**Visibilidad por cliente (Sprint 3, decisión 2026-05-25 + iteración misma sesión: opt-in):**

Tabla nueva `cliente_catalogo_visibilidad` con `(cliente_bubble_id, scope_type CHECK ('macro','catalogo'), scope_key, oculto bool, audit)` + UNIQUE compuesta. **Semántica opt-in:** si NO existe row → **OCULTO** por defecto (decisión Ben: "todas las macros sin seleccionar y ya las elegirá Valentina"). Si existe con `oculto=true` → oculto. Si existe con `oculto=false` → visible. Macro oculta tiene **precedencia**: aunque sus catálogos estén marcados visibles individualmente, no se renderizan.

**Cascada al activar macro:** cuando Account toggle ON una macro, el frontend envía un array UPSERT en una sola request: 1 row para la macro + N rows para todos sus catálogos (todos con `oculto=false`). Al desactivar la macro solo se actualiza la macro — los catálogos individuales mantienen su estado (irrelevante visualmente porque la macro está oculta y la precedencia oculta el bloque entero).

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

### 2026-05-27 — F3 PM Board: estado final tras 4 iteraciones del día
Módulo nuevo en rol PM dentro de la vista Pipeline: pulsa **Crear tareas Notion** y se abre un **board drag-and-drop** debajo de la card. Las tareas se generan dinámicamente desde la declaración del Account (Triggers/Emails/WhatsApps/Creatividades de TODAS las campañas activas del pipeline). El PM empaqueta cards en **tareas madre** con drag-drop antes de empujar a Notion/ClickUp.

#### Diseño final (commits `d8273af` → `74e4145` → `0b6ecd0` → `6b04beb` → `baa75c8`)

**Generación dinámica:**
- `proposeTasks(c)` — función pura por Campaña. Algoritmo determinista de 5 pases (Estrategia → Producción mensajes → Triggers → Creatividades → Lanzamiento) siguiendo la plantilla canónica del [manual PM](../portal/pm-manual-pipelines.md).
- `proposeTasksForPipeline(p)` — itera campañas activas + concatena. Es la que dispara la card PM en `renderPipelineView`. El board agrega todas en un solo pool.
- Cada tarea generada con defaults de las 24 propiedades Notion: `estado:'todo'`, `fecha_entrega:null`, `prioridad:'media'`, `area_tarea:areaForRol(rol)`, `responsables:[]`, `aprobador:''`, `observadores:[]`, `estimacion_horas:null`, `descripcion:''`, `incidencia:false`.

**UI canvas + tareas madre:**
- Pool flex-wrap arriba con todas las cards sueltas (las que no están dentro de ningún master).
- Botón **+ Tarea madre** crea contenedores (`S.tasksBoard.masters[]`) con título editable. Cada master es una caja grande con drop-zone interna.
- Drag-and-drop bidireccional pool ↔ master ↔ master via SortableJS connected lists (group `pm-board`). `task.parent_master_id` apunta a master.id o null.
- Botón 🗑 en cada master pregunta confirm si tiene hijas y las devuelve al pool.

**Cards compactas + modal Notion al click:**
- Card 220px: code-tag + estado-dot color + warning/incidencia icons + título (2 líneas truncado) + descripción preview (80 chars) + meta chips `📅 fecha` / `📂 PxCy` / `👤 N`.
- Click en card → modal centrado (max 600px) estilo "Notion page open" con TODAS las 24 propiedades editables: Estado / Fecha entrega / Prioridad / Área / Rol sugerido / Responsables (chips multi) / Aprobador / Observadores (chips multi) / Estimación / Incidencia / Bloqueado por (read-only desde `depende_de`) + Comentario / Descripción (textarea grande, va al body Notion como bloques paragraph).
- Cierre del modal: click en backdrop, botón ×, botón "Listo" del footer, o tecla Esc.
- SortableJS distingue tap (= abre modal) de drag (= mueve) con `delay:120` + `touchStartThreshold:8`.

**Estado:**
- `S.tasksBoard = { pId, tasks, masters, expandedTaskId, warnings, dirty, lastPushAt }` puro JS in-memory.
- EFÍMERO: cero tablas Supabase nuevas, cero localStorage. Reset al cambiar de pipeline/cliente. Persiste a través del toggle Account↔PM dentro del mismo pipeline.

**Push:**
- Fase 0 dry-run: `console.log(payload)` + toast "Simulación: N tareas listas". El POST real al webhook n8n `eHyXBETcaGSNXqLk` queda placeholder commented out.
- Payload v1.1: incluye `pipeline.campanias[]` (todas las activas con id/code/nombre/kpi/fechas/plantilla_slug) + `masters[]` (contenedores con `client_temp_id` + título) + cada `task` con `parent_master_id` + las 24 propiedades Notion (`estado`, `fecha_entrega`, `prioridad`, `area_tarea`, `responsables[]`, `aprobador`, `observadores[]`, `estimacion_horas`, `estimacion_min` calculado, `descripcion`, `incidencia`, `depende_de_codes[]`) + `idempotency_key`.

**Constantes Notion canónicas:**
- `TASK_ESTADOS` (5): por hacer / en curso / revisión / bloqueada / hecho (cada uno con color hex para el dot en card).
- `TASK_PRIORIDADES` (4): baja / media / alta / urgente.
- `TASK_AREAS` (11): estrategia / copy / diseño / meta_ads / crm / newsletter / community / dev / comercial / rrhh / otros. Autopoblada desde `rol_sugerido` via `areaForRol(rol)`.
- `TASK_ROLES` (8): estratega / copy / diseño / media_buyer / crm_manager / community / dev / pm.
- `TASK_MEMBERS` (8 hardcoded, Fase 0): Ben Sanchis · Alejandro López · Mel Dalmazo · Valentina Ramírez · Camilo Pérez · Damian Ortiz · Joaquín Tagle · Valeria Díez. Cuando se cablee RPC `bub_user` se vuelve dinámico.

**Sheet anterior `openTasksSheet`:** queda como código muerto en el archivo (no se invoca). Será removido cuando Fase 1 se valide en producción.

**Dependencias para Fase 1 (cableado real):**
- Backend F2 Pipelines en Supabase: tablas `cliente_pipelines/campanias/triggers/emails/whatsapps/creatividades` + RPC `ficha_pipelines_get`. Sin esto el payload lleva códigos PxCx pero no FKs reales.
- Workflow n8n `eHyXBETcaGSNXqLk` modificado para aceptar `source: 'ficha-cliente-pm-board'`, branch por `proveedor_tareas` (Notion 2-pass / ClickUp nativo), persistencia `idempotency_key` en `bub_tareas_notion.metadata.batch_idempotency`.
- `S.proveedorTareas` actualmente fallback a 'notion'. Cuando esté en `ficha_cliente_get` (LEFT JOIN `bub_agencia`), el botón "🚀 Empujar a Notion/ClickUp" se vuelve dinámico.

**Allowlist:** NO crece. Fase 0/1/2 no añaden tablas Supabase nuevas; el escrito a `bub_tareas_notion` lo hace el workflow n8n con `service_role`, no la UI directamente.

**Refs:**
- Código: [`ficha-cliente/index.html`](../../ficha-cliente/index.html) (función `PIPELINES_MODULE`) + clon bit-a-bit en [`estrategia/index.html`](../../estrategia/index.html).
- Librería drag: SortableJS 1.15.2 via jsDelivr CDN.
- Plan original: `~/.claude/plans/me-gustaria-que-recogieras-peppy-lemur.md` (descartado el approach kanban del plan; el final es canvas + masters + modal Notion).
- Manual PM actualizado: [`pm-manual-pipelines.md`](../portal/pm-manual-pipelines.md).
- Log cronológico de iteraciones: `docs/log-cambios.md` entrada 2026-05-27 "F3 PM Board — diseño final del día".

> ⚠️ **Iteraciones descartadas hoy** (para no confundir si miras commits): v1 kanban 6 columnas por fase (`d8273af`) — feedback Ben: no era kanban; v2 inline expanded card 320px con todas props inline (en commits `74e4145`/`0b6ecd0`/`6b04beb`) — feedback Ben: cards demasiado grandes, mejor compactas + modal. El estado final (`baa75c8`) es canvas+masters + cards compactas + modal Notion.

### 2026-05-25 — F2.7 Fase B Sprint 3: visibilidad de macros/catálogos por cliente
Commits `7eef03f` (lectura+UPSERT inicial) + `d8fd260` (fix checkbox "Error" por body vacío con return=minimal) + **iteración misma sesión** (cambio a semántica opt-in: default oculto + cascada al activar macro). Migration Supabase `f2_7_sprint3_catalogos_visibilidad`. Tabla nueva `cliente_catalogo_visibilidad` + RLS con `is_comunidad_admin()` + RPC `catalogos_cliente_get` ampliada para devolver array `visibilidad`. Frontend: botón "⚙️ Gestionar catálogos" abre sheet bottom con switches por macro (7) + catálogo (17 agrupados). UPSERT vía PostgREST `on_conflict=cliente_bubble_id,scope_type,scope_key` + `Prefer: resolution=merge-duplicates,return=representation`. Cascada al activar macro: envía array UPSERT con macro + todos sus catálogos. Auto-hide de macros con todos sus catálogos ocultos. Datos preservados al ocultar.

Helper `tableRequest()` ampliado: ahora acepta `prefer` opcional (compat retro — si no se pasa, mantiene el `Prefer: return=representation` previo en POST/PATCH). Además tolera body vacío en cualquier respuesta (lee como text primero; si vacío → null; si no, JSON.parse con try/catch).

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

- **Visión PxCx / modelo conceptual de Pipelines**: [[../portal/ficha-cliente-operativa]] — el WHY, las 7 reglas, las casuísticas, las plantillas de campaña.
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
5. ~~**Panel Catálogos cableado**~~ ✅ **Cerrado 2026-05-25 (F2.7 Fase A + B Sprint 1+2+3).** 17 tablas `cliente_catalogo_*` + tabla auxiliar `cliente_catalogo_visibilidad` + RPC agregadora `catalogos_cliente_get` con allowlist. Frontend: panel con 7 macros + 17 catálogos, CRUD inline via PostgREST (helper `tableRequest`), archivado soft-delete, visibilidad opt-in por cliente con cascada al activar macro. Seed Rock & Climb 16 entradas. Ver sección "Panel Catálogos" arriba para detalle.
6. **F2.7 Fase B Sprint 4 (mejoras del panel Catálogos)** — pendiente. Scope:
    - **Pickers FK** para webinar (`comunidad_wsp_id` + `lead_magnet_id`). Hoy esos 2 campos no salen en el form de webinar — quien quiera relacionar un webinar con su comunidad WSP o lead magnet tiene que hacerlo vía SQL en Supabase Studio.
    - **Editor `campos_capturar` jsonb** en plantillas Form Meta (UI con chips para defaults + extras). Hoy queda como el default del schema `{"extras":[],"defaults":["nombre","email","telefono"]}`.
    - **Buscador global** del panel — los 17 catálogos pueden llenarse de entradas. Filtrar por nombre/tipo/URL en una sola caja.
    - **Toggle "Ver archivadas"** — hoy las archivadas se muestran SIEMPRE tachadas con badge `🗄`. Opción para ocultarlas y limpiar el ruido visual.
    - **Bulk operations** — importar lista (CSV/JSON), exportar CSV.
7. **F2.7 Fase C (cablear Campaña → Catálogo)** — pendiente. Scope:
    - Sección "Recursos asociados" dentro del detalle de Campaña.
    - Picker por tipo de recurso que muestra las entradas activas+visibles del catálogo del cliente.
    - Modelo de referencia: `recurso_id uuid` + `nombre_snapshot text` (decisión 2026-05-25 "snapshot+vivo": entrada archivada → snapshot con `🗄`; entrada activa → lee vivo del catálogo).
    - 1 plantilla de Campaña hardcodeada (la del PDF Rock and Climb) que declare qué refs pide. Cuando haya 3-4 plantillas reales, abrir builder.
    - Tabla nueva `campania_sesion_webinar` para webinars con N sesiones específicas (PDF3 Actualízate tiene 3 masterclass V/S/D con Meet links y horarios — son temporales del lanzamiento, NO recursos del catálogo).
8. **Panel Anomalías** — integrar `n8n_incidencias` filtradas por cliente + checks operativos derivados (servicios sin Drive, campañas sin briefing).
9. **Allowlist en tabla `playbook_editors(email)`** cuando crezca a 5+ editores. Hoy son 5 + ya hay 8 sitios (frontend × 3 + RLS policies × 3 + RPCs × 4). Cuando llegue el 6º editor, migrar.

---

## 🚀 Inicializador del módulo Catálogos (F2.7) — cierre 2026-05-25

> **Documento de onboarding para reabrir el trabajo del módulo Catálogos sin reconstruir contexto.** Lectura completa antes de tocar Sprint 4 o Fase C. Si solo necesitas el TL;DR, lee los 3 primeros bloques (📌 TL;DR · 🧭 Contexto · 🏛️ Arquitectura). El resto es referencia para cuando te sientes a programar.

### 📌 TL;DR

- **Qué es:** un panel dentro de `/ficha-cliente/` que sustituye al PDF "lanzamiento" que las Account mantenían en Google Docs. Almacena recursos **reutilizables** del cliente (carpetas Drive, comunidades WhatsApp, cuentas publicitarias, webinars, etc.) en 17 catálogos agrupados en 7 macros visuales.
- **Estado:** Fase A (datos Supabase) + Fase B Sprint 1+2+3 (UI completa: lectura + CRUD + visibilidad por cliente) **cerrados y en producción**. Sembrado Rock & Climb con 16 entradas reales.
- **Pendiente inmediato:** Sprint 4 (pickers FK + editor jsonb + buscador + toggle archivadas) y Fase C (cablear Campaña→Catálogo).
- **Trabajo total esta sesión:** 10 commits del `7de0b79` al `e74ef2f` + este inicializador. 2 migrations Supabase aplicadas. 4 docs canónicos actualizados (este, `log-cambios.md`, `infra/supabase-schema.md`, `CLAUDE.md` raíz).

### 🧭 Contexto: por qué existe el módulo Catálogos

Antes de F2.7, las Account de TheNucleo mantenían el contexto operativo de cada cliente en **Google Docs** — un PDF "lanzamiento" por campaña con secciones libres: presupuesto Meta Ads, briefings de diseño, links a carpetas Drive (estáticos, vídeos), comunidad WhatsApp final del cliente, formulario Meta enriquecido, análisis cluster, productos del cliente, caveats operativos críticos ("NO PONER JAMÁS VISITAS SUCESIVAS"), webinars con sus 3 sesiones V/S/D, etc.

Ese formato **NO escala**: la información se duplica entre campañas, se desactualiza, no es buscable, y cada Account la organiza distinto. F2.7 lo reemplaza por una biblioteca estructurada en Supabase con UI en el portal admin.

**Los 3 PDFs de referencia que dieron forma al schema** (revisables en la conversación de log-cambios entrada Fase A):

1. **Rock & Climb** (ocio — escalada). Comunidad WhatsApp lead-gen con form Meta + 1 email + carpetas Drive para estáticos/vídeos + calendario mensual con 8 talleres a precios distintos (15-45€).
2. **Dra. Neus Muñoz** (infoproductora médica). Form Meta + 1 email de bienvenida + briefings vídeos/estáticos + 2 URLs web (consultas/funnel) + análisis cluster + ángulos de venta + **regla crítica** "NO PONER JAMÁS VISITAS SUCESIVAS" + tipo de consulta con precio/duración/objetivo.
3. **Actualízate Psicología** (infoproductora — lanzamiento webinar). Webinar con 3 masterclass distintas (Meet links + horarios) + LP webinar + thank you + página de venta + reunión 1:1 booking + 25 emails GHL programados + comunidad WSP + grabaciones Drive.

De cada PDF se derivó qué tipos de catálogo eran reusables entre campañas del mismo cliente (carpetas Drive, comunidad WSP, cuenta publicitaria, pixel, página FB/IG, etc.) versus qué era one-off de una campaña (las 3 sesiones específicas de un webinar, los 25 emails programados, el presupuesto de UN lanzamiento concreto). Lo reusable vive en catálogo; lo one-off vive en Pipelines/Campaña (Fase C, pendiente).

**Framing acordado (decisión Ben, F2.7 Fase A):** **Híbrido A+C** — biblioteca de recursos con **tipos cerrados** (los definimos nosotros, son 17, no se pueden añadir desde la UI) + entradas y visibilidad abiertas por cliente. Se descartó la opción B (schema builder Notion-like) por coste y por la dificultad de validar campos dinámicos contra constraints. Se descartó la opción D (campo libre en Campaña) por no resolver el problema de reutilización.

### 🏛️ Arquitectura

**Jerarquía 3 niveles** (la palabra "principal" puede referirse a niveles 1 o 2 — Ben las llamó "ambos" en una pregunta de la sesión):

```
NIVEL 1 — Macro (carpeta visual con emoji, fija en el frontend)
├─ 📁 Recursos Drive
├─ 💬 Comunicación
├─ 📣 Marketing Meta
├─ 💰 Operativo
├─ 🎯 Producto del cliente
├─ ⚠️ Gobierno
└─ 🌐 Webs cliente

   NIVEL 2 — Catálogo (grupo colapsable, 1 tabla Supabase cada uno, fijo)
   ├─ Carpetas Drive ──────────── cliente_catalogo_carpeta_drive
   ├─ Documentos ─────────────── cliente_catalogo_documento
   ├─ Comunidades WhatsApp ─── cliente_catalogo_comunidad_wsp
   ├─ Emails remitentes ────── cliente_catalogo_email_remitente
   ├─ Etiquetas segmentación ─ cliente_catalogo_etiqueta
   ├─ Cuentas publicitarias ── cliente_catalogo_cuenta_publicitaria
   ├─ Pixels / Datasets ────── cliente_catalogo_pixel
   ├─ Páginas FB / IG ──────── cliente_catalogo_pagina_social
   ├─ Públicos personalizados ─ cliente_catalogo_publico_personalizado
   ├─ Plantillas Form Meta ── cliente_catalogo_plantilla_form_meta
   ├─ Presupuestos ─────────── cliente_catalogo_presupuesto
   ├─ Lead magnets ─────────── cliente_catalogo_lead_magnet
   ├─ Webinars ─────────────── cliente_catalogo_webinar (FK → comunidad_wsp + lead_magnet)
   ├─ Sistemas de reserva ── cliente_catalogo_sistema_reserva
   ├─ Productos / Servicios ─ cliente_catalogo_producto_servicio
   ├─ Reglas / Caveats ────── cliente_catalogo_regla
   └─ Webs del cliente ───── cliente_catalogo_web_cliente

      NIVEL 3 — Entry (fila concreta dentro de un catálogo)
      • "Carpeta Drive Estáticos Rock & Climb" (en cliente_catalogo_carpeta_drive)
      • "Primera Visita Online · 135€ · 45 min" (en cliente_catalogo_producto_servicio)
      • "NO PONER JAMÁS VISITAS SUCESIVAS" (en cliente_catalogo_regla)
      …
```

**Tabla auxiliar transversal:** `cliente_catalogo_visibilidad` (`cliente_bubble_id × scope_type='macro'|'catalogo' × scope_key × oculto bool`). Permite que Account oculte una macro o un catálogo para un cliente sin tocar los datos. **Default opt-in:** sin row = oculto.

### 🛠️ Stack técnico

- **Frontend:** HTML standalone (`ficha-cliente/index.html`, ~5000 líneas inline). Sin framework, sin bundler. Carga `@supabase/supabase-js` desde jsdelivr. Eleventy lo trata como passthrough copy (no procesa el template).
- **Backend:** Supabase project `cbixhqjsnpuhcrcjppah` (cbi, eu-west-1).
- **Auth:** Google OAuth via `/comunidad/entrar/`. Sesión compartida con `/playbook/` y `/fichas-de-producto/`. Allowlist 5 emails.
- **Lectura masiva:** RPC agregadora `catalogos_cliente_get(p_bubble_id text)` SECURITY DEFINER. **1 fetch** devuelve jsonb con 18 keys (los 17 catálogos + `visibilidad` array). Allowlist hardcoded en el body de la RPC.
- **Escritura:** **PostgREST directo** (sin RPC). Helper `tableRequest(table, opts)` hace POST/PATCH/DELETE/UPSERT al endpoint `/rest/v1/<tabla>` con el token del usuario. Las **policies RLS con `is_comunidad_admin()`** validan cada operación.
- **UPSERT** (visibilidad y similares): query `?on_conflict=col1,col2,...` + header `Prefer: resolution=merge-duplicates,return=representation`. **No usar `return=minimal`** (devuelve body vacío y rompe `res.json()` — bug `d8fd260` cerrado en esta sesión).

### 🗄️ Schema completo en Supabase (F2.7 — 18 tablas)

**Convención común a las 17 `cliente_catalogo_*`:**

```sql
id                 uuid PK default gen_random_uuid()
cliente_bubble_id  text NOT NULL                  -- FK lógica a bub_clientes.bubble_id
…campos del tipo…
archivada          boolean NOT NULL DEFAULT false  -- soft-delete (snapshot-friendly)
archivada_en       timestamptz
created_at         timestamptz NOT NULL DEFAULT now()
updated_at         timestamptz NOT NULL DEFAULT now()
created_by         text DEFAULT auth.email()
```

Indexes obligatorios por tabla: `(cliente_bubble_id)` + parcial `(cliente_bubble_id) WHERE archivada=false`. RLS ON + 4 policies `(SELECT/INSERT/UPDATE/DELETE) TO authenticated USING/WITH CHECK is_comunidad_admin()`. Trigger `BEFORE UPDATE EXECUTE FUNCTION update_updated_at()`.

**Campos específicos de cada catálogo** — detalle en [[../infra/supabase-schema|docs/infra/supabase-schema]] sección "Catálogos del cliente — F2.7 Fase A". Resumen:

| Tabla | Campos clave (además de la convención común) |
|---|---|
| `cliente_catalogo_carpeta_drive` | nombre, url, categoria CHECK (estaticos/videos/briefs/analisis/otros), notas |
| `cliente_catalogo_documento` | nombre, url, tipo CHECK (brief/analisis/estrategia/contrato/cluster/angulos/otro), notas |
| `cliente_catalogo_comunidad_wsp` | nombre, invite_url, tipo CHECK (final_cliente/interna/beta), notas |
| `cliente_catalogo_email_remitente` | direccion, display_name, principal bool, verificado bool, notas. UNIQUE parcial `(cliente)` WHERE principal=true AND archivada=false (solo 1 principal activo) |
| `cliente_catalogo_etiqueta` | slug, descripcion, notas. UNIQUE parcial `(cliente, slug)` WHERE archivada=false |
| `cliente_catalogo_cuenta_publicitaria` | nombre, plataforma CHECK (meta/google), account_id_externo, activa bool, notas. UNIQUE parcial por (cliente, plataforma, account_id_externo) entre activas |
| `cliente_catalogo_pixel` | nombre, plataforma, pixel_id_externo, eventos_configurados, notas. UNIQUE parcial por externo |
| `cliente_catalogo_pagina_social` | nombre, plataforma CHECK (facebook/instagram), page_id_externo, url_publica, verificada bool. UNIQUE parcial por externo |
| `cliente_catalogo_publico_personalizado` | nombre, plataforma, audience_id_externo, tamano_estimado int, tipo CHECK (custom/lookalike/saved), fuente, activo bool. UNIQUE parcial por externo |
| `cliente_catalogo_plantilla_form_meta` | nombre, form_id_meta, **`campos_capturar` jsonb** DEFAULT `{"extras":[],"defaults":["nombre","email","telefono"]}`, notas |
| `cliente_catalogo_presupuesto` | linea, canal CHECK (meta_ads/google_ads/otros), importe_eur numeric NOT NULL, periodo CHECK (mensual/trimestral/anual/unico), fecha_inicio, fecha_fin, activo bool, notas |
| `cliente_catalogo_lead_magnet` | nombre, tipo CHECK (pdf/video/audio/otro), url, descripcion, activo bool, notas |
| `cliente_catalogo_webinar` | nombre, descripcion, precio_eur, landing_registro_url, thank_you_url, sales_page_url, reunion_1on1_url, replay_url, **comunidad_wsp_id uuid REFERENCES #3 ON DELETE RESTRICT**, **lead_magnet_id uuid REFERENCES #12 ON DELETE RESTRICT**, activo bool |
| `cliente_catalogo_sistema_reserva` | nombre, plataforma CHECK (bookeo/resos/mindbody/propio/otros), url_publica_reserva, notas |
| `cliente_catalogo_producto_servicio` | nombre, tipo CHECK (consulta/sesion/curso/producto_digital/suscripcion/otro), precio_eur, duracion_minutos int, descripcion, url_compra, activo bool, notas. **No confundir con `playbook_cliente_servicios`** (servicios que TheNucleo presta al cliente). |
| `cliente_catalogo_regla` | regla, ambito CHECK (copy/ads/diseno/comunicacion/general), severidad CHECK (critica/importante/sugerencia), descripcion, activa bool, notas |
| `cliente_catalogo_web_cliente` | nombre, url, tipo CHECK (web_principal/landing/funnel/blog/checkout/thank_you/otro), descripcion, activa bool |

**Tabla auxiliar `cliente_catalogo_visibilidad`:**

```sql
id                  uuid PK default gen_random_uuid()
cliente_bubble_id   text NOT NULL
scope_type          text NOT NULL CHECK (scope_type IN ('macro','catalogo'))
scope_key           text NOT NULL                      -- 'recursos_drive'|… (macro) o 'carpetas_drive'|… (catalogo)
oculto              boolean NOT NULL DEFAULT true
audit               created_at, updated_at, created_by DEFAULT auth.email()
UNIQUE (cliente_bubble_id, scope_type, scope_key)
INDEX  (cliente_bubble_id)
INDEX  (cliente_bubble_id) WHERE oculto = true
```

**RPC `catalogos_cliente_get(p_bubble_id text) RETURNS jsonb`:**

- SECURITY DEFINER + `SET search_path = public, pg_temp`.
- Allowlist hardcoded en body: 5 emails (`benjamin.sanchis`, `camilo.carvajal`, `damian.gomez`, `joaquin.almeida`, `valentina.ramirez` @thenucleo.com). RAISE `forbidden` ERRCODE `42501` si email no autorizado.
- GRANT EXECUTE TO authenticated.
- Devuelve jsonb con 18 keys: los 17 catálogos (`carpetas_drive`, `documentos`, …, `webs_cliente`) cada uno con `jsonb_agg(to_jsonb(t.*) ORDER BY archivada, …)` + `visibilidad` con `jsonb_agg({scope_type, scope_key, oculto})`.
- 1 fetch cubre todo el panel — no se hacen 18 calls separadas.

### 🗺️ Mapa del código en `ficha-cliente/index.html`

Líneas aproximadas (el archivo crece — usar `Grep` con los anchors si los números difieren):

| Pieza | Anchor (Grep) | Línea aprox. |
|---|---|---|
| Helper `rpc(fn, body)` | `async function rpc\(fn, body` | ~1371 |
| Helper `tableRequest(table, opts)` | `async function tableRequest` | ~1396 |
| Helper `escapeHtml(s)` | `function escapeHtml\(s\)` | ~1410 |
| `renderCliente(c)` (llama a los renders de cada panel) | `renderServiciosPanel\(servicios\);` + `CATALOGOS_MODULE.loadFor` | ~1556 |
| Handler global `[data-coll-toggle]` (con guard `[data-cat-add]`) | `function toggleCollGroup` | ~1823 |
| `openSheet(title, subtitle, html)` + `closeSheet()` | `function openSheet` | ~1820 |
| HTML del `#panel-catalogos` | `id="panel-catalogos"` | ~1205 |
| CSS de `.coll-group*` (compartido con Datos, Servicios) | `Collapsible group \(Datos` | ~333 |
| CSS de `.cat-macro*`, `.cat-pending-badge`, `.catalog-item.archived` | `Macro-categoría dentro del panel` | ~372 |
| CSS de `.cat-add-btn`, `.cat-item-action`, `.cat-form-*` | `Botón "\+ Añadir"` | ~535 |
| CSS de `.catalogos-controls`, `.cat-manage-btn`, `.vis-*` | `Controles superiores del panel` | ~620 |
| `CATALOGOS_MODULE` IIFE (todo el módulo) | `^const CATALOGOS_MODULE` | ~4280 a ~4720 |
| Config `MACROS` (7) con `key/emoji/label/catalogos[]` | `7 macro-categorías` | dentro del módulo |
| Config `OPTS` (selects predefinidos) | `Opciones de selects reusables` | dentro |
| Config `CATALOGOS` (17 con `label/dot/table/getName/getMeta/getUrl/fields[]`) | `Schema por catálogo` | dentro |
| `isHidden(scopeType, scopeKey)` (default opt-in) | `Visibilidad por cliente \(semántica opt-in` | dentro |
| `renderItem`, `renderCatalogo`, `renderMacro`, `render` | `function renderItem` | dentro |
| `openCreateForm`, `openEditForm`, `submitForm`, `archiveFromForm`, `closeForm` | `function openCreateForm` | dentro |
| `openVisibilitySheet`, `renderVisibilityForm`, `toggleVisibility`, `refreshVisibilitySheet` | `function renderVisibilityForm` | dentro |
| `renderPreservingOpen()` (re-render conservando coll-groups abiertos) | `function renderPreservingOpen` | dentro |
| `loadFor(id)` (entry-point del módulo) | `async function loadFor\(id\)` | dentro |
| Click handlers delegados (`data-cat-manage`, `data-cat-add`, `data-cat-edit`, `data-form-*`) | `Click handlers delegados` | dentro |
| Change handler de `[data-vis-toggle]` | `change listener para los toggles` | dentro |
| Bootstrap (init → rpc ficha_cliente_listar → rpc ficha_cliente_get → renderCliente) | `function init\(\)` | ~4185 |

### 🎨 Convenciones de programación reusables del módulo

Si vas a tocar Sprint 4 o Fase C, conviene seguir estos patrones para que el código quede coherente:

1. **Render dinámico desde array `fields[]`** — los forms NO se escriben a mano. Cada catálogo declara qué campos tiene (con `type`, `required`, `default`, `options`, `placeholder`, `step`) y `renderField()` los pinta. Para añadir un campo nuevo a un catálogo basta con añadir un objeto al array. Para añadir un nuevo TIPO de campo (ej: color picker, multi-select), ampliar el switch dentro de `renderField()`.
2. **Delegate handlers en `document`** — todos los clicks/changes se capturan en `document.addEventListener`, no en cada elemento. Usar `data-*` attributes para identificar acción + parámetros (`data-cat-add="<key>"`, `data-cat-edit="<key>" data-entry-id="<uuid>"`, `data-vis-toggle data-scope-type="..." data-scope-key="..."`). **Evitar `onclick` inline** — el bug `5fa8363` enseñó que `event.stopPropagation()` inline ROMPE delegate handlers que viven en document.
3. **Sheet bottom reutilizado** — `openSheet(title, subtitle, html)` + `closeSheet()` ya están implementados en líneas ~1820. El mismo `#sheet-body` sirve para form de catálogos, sheet de visibilidad, picker de cliente, etc. Llenar `innerHTML` con el render que toque.
4. **State local en el módulo, no global** — el módulo CATALOGOS guarda `data`, `loading`, `errorMsg`, `currentBubbleId`, `formState` en variables let dentro del IIFE. NO se exponen al window. Solo `loadFor` y `render` se devuelven en el `return { … }`.
5. **Refresh tras CRUD = `refreshAll()` + `renderPreservingOpen()`** — tras INSERT/UPDATE/DELETE, re-fetch agregado (1 RPC barato) y re-render del panel preservando qué coll-groups estaban abiertos. La UX no salta.
6. **UPSERT siempre con `return=representation`** — NO `return=minimal` (bug `d8fd260`). El helper `tableRequest` ya tolera body vacío como defensa, pero `representation` es el patrón correcto del módulo.
7. **Validación required client-side antes del submit** — `collectFormValues()` lanza `Error("Falta el campo X")` si alguno required está vacío. Se atrapa en `submitForm()` y se muestra en el banner `.cat-form-error` sin cerrar el sheet.
8. **Strings vacíos opcionales → `null`** — al enviar al backend, los `text/textarea/url` opcionales que estén `''` se convierten a `null` (no machacar defaults DB con `''`).

### 📋 Decisiones tomadas (extendido con razón)

| Decisión | Valor | Por qué | Cuándo | Quién |
|---|---|---|---|---|
| Framing del módulo | Híbrido A+C (tipos cerrados, entradas y visibilidad abiertas por cliente) | Schema builder Notion-like (opción B) era caro y validar campos dinámicos contra constraints es frágil. Híbrido cubre 95% de los casos sin esa complejidad. | F2.7 Fase A | Ben |
| Cuántos catálogos | 17 (3 PDFs validaron el set) | Cubre Rock & Climb (ocio), Dra. Neus (infoproductora consulta), Actualízate (infoproductora webinar). 95% de los clientes TheNucleo. | F2.7 Fase A | Ben + 4 criterios |
| Cuántas macros | 7 (📁💬📣💰🎯⚠️🌐) | Agrupación natural para que el panel no parezca 17 grupos sueltos. Las macros son **solo visuales** (no tablas) hasta Sprint 3 donde se les añadió visibilidad. | F2.7 Fase A | Ben |
| FKs entre catálogos | Solo `webinar.comunidad_wsp_id` + `webinar.lead_magnet_id`, ambos `ON DELETE RESTRICT` | Webinar es la única entidad que naturalmente compone otras (su comunidad WSP, su lead magnet). El resto son independientes. RESTRICT obliga a archivar webinar antes de borrar comunidad/lead magnet referenciados. | F2.7 Fase A | Ben |
| Política de borrado | Solo archivar (soft-delete), NO DELETE duro desde UI | Trazabilidad. **Crítico para Fase C:** cuando Campaña referencie entradas del catálogo, un DELETE duro rompería referencias retroactivas. Si hay que limpiar de verdad, SQL en Supabase Studio (admin). | F2.7 Fase B Sprint 2 | Ben |
| RLS vs allowlist hardcoded | Las 17 tablas + 1 visibilidad usan **RLS con `is_comunidad_admin()`**, no allowlist hardcoded en policies | Más mantenible: añadir admin = INSERT en `comunidad_admins`, no editar 68 policies. La allowlist hardcoded queda solo en la RPC `catalogos_cliente_get` (lectura agregada). | F2.7 Fase A | Patrón existente |
| Lectura: 1 RPC o N fetches | 1 RPC agregadora `catalogos_cliente_get` | Frontend hace 1 request en lugar de 18. Más rápido y más simple de cachear/refresh. | F2.7 Fase A | Ben |
| Escritura: RPC o PostgREST | **PostgREST directo** (no RPC) | 17 catálogos × 3 operaciones = 51 RPCs hubiera sido demasiado. RLS valida cada operación. Helper `tableRequest()` abstrae el fetch. | F2.7 Fase B Sprint 2 | Decisión técnica |
| Bootstrap de URLs sin URL real | Placeholder `https://drive.google.com/...PENDIENTE-...` + badge naranja "URL pendiente" | El PDF de origen tiene hipervínculos que no se renderizan al copiar. Mejor crear la entrada con URL placeholder + nota explicativa que omitirla. Account la completa después. | Seed Rock & Climb | Decisión Claude validada por Ben |
| Visibilidad: del cliente o del usuario | **Del cliente** (Supabase, no localStorage) | Si Mel oculta "Sistemas de reserva" para Rock & Climb porque no aplica, Ben también lo ve oculto al abrir Rock & Climb. Visión consistente entre admins. | F2.7 Sprint 3 | Ben |
| Default de visibilidad | **Opt-in** (sin row = oculto) | "Que por defecto estén todas sin seleccionar y ya las elegirá Valentina". Cambio iterado en la misma sesión Sprint 3 (de opt-out → opt-in). | F2.7 Sprint 3 iteración | Ben |
| Cascada al activar macro | Activar macro → UPSERT array con macro + todos sus catálogos en `oculto=false` | Sin cascada, activar la macro no mostraría nada porque los catálogos seguirían ocultos por el default opt-in. La cascada hace UX natural ("activé Marketing Meta y veo sus 5 catálogos"). Al desactivar la macro, los catálogos individuales mantienen su estado (irrelevante por la regla de precedencia). | F2.7 Sprint 3 iteración | Decisión Claude validada por Ben |
| Snapshot vs vivo (Fase C) | **Híbrido:** FK live + `nombre_snapshot text` | Cuando Campaña referencie una entrada del catálogo: entrada archivada → snapshot con `🗄`; entrada activa → lee vivo. Patrón de Stripe (`payment_link archived`) y GitHub (`deleted-user "ghost"`). Aún NO implementado — para Fase C. | F2.7 Fase A planning | Decisión Claude validada por Ben |
| Sesiones específicas de webinar | NO en catálogo — van en `campania_sesion_webinar` (tabla nueva en Fase C) | Las 3 masterclass V/S/D de Actualízate son temporales del lanzamiento concreto, no recursos evergreen del cliente. Si se relanza en septiembre, la entidad "Webinar" se reutiliza pero las sesiones son nuevas. | F2.7 Fase A planning | Decisión Claude validada por Ben |

### 🍳 Recetas (cómo hacer X)

#### Añadir un campo a un catálogo existente

Ejemplo: añadir `notas_internas text` a `cliente_catalogo_carpeta_drive`.

1. **Supabase:** `ALTER TABLE public.cliente_catalogo_carpeta_drive ADD COLUMN notas_internas text;` (via MCP `apply_migration` o Supabase Studio).
2. **RPC:** si el campo necesita salir en la lectura agregada, ya viene incluido por `to_jsonb(t.*)`. No tocar.
3. **Frontend (`ficha-cliente/index.html`)**: en `CATALOGOS_MODULE > CATALOGOS.carpetas_drive.fields`, añadir un objeto:
   ```js
   { key:'notas_internas', label:'Notas internas', type:'textarea' }
   ```
4. **Opcional:** si quieres que el campo se vea en el `meta` del item read-only, modificar `getMeta: r => ...` para incluirlo.
5. **Test:** abre el panel Catálogos, click en una entrada, debería aparecer el campo nuevo en el sheet.
6. **Doc:** actualizar [`docs/infra/supabase-schema.md`](../infra/supabase-schema.md) sección F2.7 con el campo añadido + entrada en [`docs/log-cambios.md`](../log-cambios.md).

#### Ampliar un enum CHECK constraint

Ejemplo: añadir `'reels_carousel'` a `cliente_catalogo_carpeta_drive.categoria`.

1. **Supabase:**
   ```sql
   ALTER TABLE public.cliente_catalogo_carpeta_drive DROP CONSTRAINT cliente_catalogo_carpeta_drive_categoria_check;
   ALTER TABLE public.cliente_catalogo_carpeta_drive ADD CONSTRAINT cliente_catalogo_carpeta_drive_categoria_check
     CHECK (categoria IN ('estaticos','videos','briefs','analisis','reels_carousel','otros'));
   ```
2. **Frontend:** en `OPTS.drive_cat` (dentro del módulo CATALOGOS), añadir `'reels_carousel'` al array.
3. **Test + doc:** igual que arriba.

#### Añadir un catálogo nuevo (los 17 son fijos — esto es un cambio gordo)

Solo hacerlo si pasa los 4 criterios del framing original (reusabilidad / identidad propia / lifecycle / frecuencia >50%). Si solo aplica a 1-2 clientes, NO añadir catálogo — usar `cliente_catalogo_regla` o un campo libre en Campaña.

Si tras los criterios sí entra:

1. **Supabase:** crear tabla `cliente_catalogo_<nombre>` siguiendo la convención común (PK uuid, cliente_bubble_id, campos del tipo, archivada bool, audit, RLS + 4 policies, trigger updated_at, indexes (cliente_bubble_id) + parcial WHERE archivada=false).
2. **Supabase:** modificar la RPC `catalogos_cliente_get` para añadir una key nueva en el `jsonb_build_object` que haga `jsonb_agg` de la tabla nueva.
3. **Frontend:**
   - Añadir al objeto `CATALOGOS` con `{label, dot, table, getName, getMeta, getUrl?, fields[]}`.
   - Añadir el `key` del catálogo al array `catalogos[]` de la macro que le toque dentro de `MACROS`.
   - Si la macro no existe (raro), crearla en `MACROS` y añadir CSS si necesita color especial.
4. **Doc:** actualizar `docs/infra/supabase-schema.md` sección F2.7 con la tabla #18 + el doc canónico de ficha-cliente con el nuevo catálogo en la tabla y la macro correspondiente. Entrada en `docs/log-cambios.md`.

#### Sincronizar la allowlist (8 sitios)

Al añadir/retirar admin:

1. **Frontend × 3** (los 3 admin pages):
   - `EDITOR_EMAILS` en `playbook/index.html`
   - `EDITOR_EMAILS` en `fichas-de-producto/index.html`
   - `EDITOR_EMAILS` en `ficha-cliente/index.html`
2. **RLS policies × 3** (todas en Supabase):
   - `playbook_progreso` (3 policies de SELECT/INSERT/UPDATE)
   - `playbook_task_feedback` (3 policies)
   - `playbook_cliente_servicios` (3 policies)
3. **Bodies de RPCs × 4** (SECURITY DEFINER hardcoded allowlist):
   - `playbook_cliente_detalle`
   - `ficha_cliente_listar`
   - `ficha_cliente_get`
   - **`catalogos_cliente_get`** ← añadida en F2.7 Fase A
4. **(Adyacente — NO confundir)** Casuísticas tiene su propia allowlist en 3 policies `casuisticas_board_*`. Disponibilidades usa `is_comunidad_admin()` con tabla.
5. **Las 17 tablas `cliente_catalogo_*` + `cliente_catalogo_visibilidad` NO requieren tocar nada** — usan `is_comunidad_admin()` que lee de `comunidad_admins`. Para dar acceso al panel basta `INSERT INTO comunidad_admins (user_id) VALUES ('<uid>')`.

#### Reset de visibilidad de un cliente (a default opt-in)

```sql
DELETE FROM public.cliente_catalogo_visibilidad WHERE cliente_bubble_id = '<bubble_id>';
```

Tras esto, sin rows → todo oculto → Account empieza desde cero.

#### Activar todo para un cliente (debug / smoke test)

```sql
-- Activar todas las macros + todos los catálogos
INSERT INTO public.cliente_catalogo_visibilidad (cliente_bubble_id, scope_type, scope_key, oculto)
SELECT '<bubble_id>', 'macro', key, false
FROM (VALUES ('recursos_drive'),('comunicacion'),('marketing_meta'),('operativo'),('producto'),('gobierno'),('webs')) AS m(key)
ON CONFLICT (cliente_bubble_id, scope_type, scope_key) DO UPDATE SET oculto = false;

INSERT INTO public.cliente_catalogo_visibilidad (cliente_bubble_id, scope_type, scope_key, oculto)
SELECT '<bubble_id>', 'catalogo', key, false
FROM (VALUES
  ('carpetas_drive'),('documentos'),('comunidades_wsp'),('emails_remitentes'),('etiquetas'),
  ('cuentas_publicitarias'),('pixels'),('paginas_sociales'),('publicos_personalizados'),('plantillas_form_meta'),
  ('presupuestos'),('lead_magnets'),('webinars'),('sistemas_reserva'),('productos_servicios'),
  ('reglas'),('webs_cliente')
) AS c(key)
ON CONFLICT (cliente_bubble_id, scope_type, scope_key) DO UPDATE SET oculto = false;
```

### 🐛 Troubleshooting

**Si el botón "+ Añadir" no abre el sheet:**
- Verifica que NO has añadido `onclick="event.stopPropagation()"` inline al botón. Eso BLOQUEA el delegate handler que vive en document. (Bug `5fa8363` cerrado.)
- Verifica que el handler de `[data-coll-toggle]` tiene el guard `if (e.target.closest('[data-cat-add]')) return;` (línea ~1825).

**Si el toggle de visibilidad muestra "Error" pese a guardar OK:**
- Probable causa: `Prefer: return=minimal` devuelve body vacío y `res.json()` rompe. (Bug `d8fd260` cerrado.) Fix doble: helper `tableRequest` tolera body vacío + usar `return=representation`.
- Verifica con `SELECT * FROM cliente_catalogo_visibilidad WHERE cliente_bubble_id = '...';` — si las rows están ahí, el INSERT funcionó.

**Si el POST/PATCH devuelve 403/42501:**
- Probable: `is_comunidad_admin()` devuelve false. Verifica que tu uid está en `comunidad_admins`:
  ```sql
  SELECT EXISTS(SELECT 1 FROM comunidad_admins WHERE user_id = auth.uid()) AS is_admin;
  ```
- Si NO está, INSERT a `comunidad_admins` con tu uid (sacarlo de `auth.users` por email).

**Si la RPC `catalogos_cliente_get` devuelve `forbidden`:**
- Tu email no está en la allowlist hardcoded del body de la RPC. Editar la RPC vía MCP `apply_migration` para añadir tu email al array `v_allowlist`. (Y sincronizar los otros 7 sitios — ver receta arriba.)

**Si una entrada NO aparece en el panel pese a estar en DB:**
- Verifica que la macro padre y el catálogo no estén ocultos: `SELECT * FROM cliente_catalogo_visibilidad WHERE cliente_bubble_id = '<id>';`
- Recuerda: **sin row = oculto** (opt-in). Account tiene que haber activado la macro/catálogo para que se vea.
- Si la entrada está `archivada=true`, se ve tachada con badge `🗄` pero sigue visible. No se filtra.

**Si el panel muestra "Ninguna macro activada todavía":**
- Es el estado inicial de un cliente nuevo. Click en "⚙️ Gestionar catálogos" y activa las macros que apliquen.

### 🧪 Cómo testear

**Local:**
```bash
npm run dev
# Abre http://localhost:8080/ficha-cliente/?id=1778244949886x259108771172188160
# (login Google en /comunidad/entrar/ con uno de los 5 emails de la allowlist)
```

Caveat: el OAuth callback está configurado para `work.thenucleo.com`. Si la sesión no persiste en localhost, login primero en prod y el storage se comparte (ambos usan el mismo `STORAGE_KEY`).

**Producción:** push a `main` → Vercel rebuildea en ~30s → abrir `https://work.thenucleo.com/ficha-cliente/?id=<bubble_id>`.

**Smoke tests SQL** (vía MCP `execute_sql` o Supabase Studio):
```sql
-- 1. Tablas existen
SELECT count(*) FROM information_schema.tables
 WHERE table_schema='public' AND table_name LIKE 'cliente_catalogo_%';
-- Esperado: 18 (17 catálogos + 1 visibilidad)

-- 2. RPC responde
SELECT catalogos_cliente_get('1778244949886x259108771172188160')::text;
-- Si no eres admin → ERROR 42501 forbidden

-- 3. Seed Rock & Climb intacto
SELECT 'carpetas' AS tipo, count(*) FROM cliente_catalogo_carpeta_drive WHERE cliente_bubble_id = '1778244949886x259108771172188160' UNION ALL
SELECT 'docs', count(*) FROM cliente_catalogo_documento WHERE cliente_bubble_id = '1778244949886x259108771172188160' UNION ALL
SELECT 'wsp', count(*) FROM cliente_catalogo_comunidad_wsp WHERE cliente_bubble_id = '1778244949886x259108771172188160' UNION ALL
SELECT 'form', count(*) FROM cliente_catalogo_plantilla_form_meta WHERE cliente_bubble_id = '1778244949886x259108771172188160' UNION ALL
SELECT 'pres', count(*) FROM cliente_catalogo_presupuesto WHERE cliente_bubble_id = '1778244949886x259108771172188160' UNION ALL
SELECT 'prod', count(*) FROM cliente_catalogo_producto_servicio WHERE cliente_bubble_id = '1778244949886x259108771172188160';
-- Esperado: 2 carpetas, 3 docs, 1 wsp, 1 form, 1 pres, 8 prod = 16 total

-- 4. Policies activas
SELECT count(*) FROM pg_policies WHERE schemaname='public' AND tablename LIKE 'cliente_catalogo_%';
-- Esperado: 72 (17×4 catálogos + 4 visibilidad)
```

### 📖 Glosario

- **Macro** — carpeta visual con emoji que agrupa 1+ catálogos (📁 Recursos Drive, ⚠️ Gobierno, etc.). NO es tabla, vive solo en el frontend (`MACROS` array). Tiene `key` (string) que se usa como `scope_key` en `cliente_catalogo_visibilidad`.
- **Catálogo** — grupo colapsable que corresponde a 1 tabla Supabase (`cliente_catalogo_*`). Tiene `key` (string), `label` (UI), `dot` (color), `table` (nombre Supabase), `fields[]` (schema del form), extractores `getName/getMeta/getUrl`.
- **Entry / Row** — fila concreta dentro de un catálogo. Cada entry pertenece a UN cliente (`cliente_bubble_id` FK).
- **Opt-in** — semántica de visibilidad por defecto: sin row en `cliente_catalogo_visibilidad` = oculto. Account activa lo que aplica al cliente.
- **Opt-out** (descartado) — semántica anterior (Sprint 3 inicial, commit `7eef03f`): sin row = visible. Account ocultaba lo que no aplicaba. Cambiada en la misma sesión por petición de Ben.
- **Cascada (al activar macro)** — al hacer toggle ON una macro, el frontend envía un array UPSERT con la macro + todos sus catálogos en `oculto=false`. Si no, el opt-in dejaría todo oculto pese a haber activado la macro.
- **Precedencia (de macro sobre catálogo)** — si una macro está oculta, ninguno de sus catálogos se renderiza, aunque estén marcados visibles individualmente.
- **Snapshot+vivo** — patrón previsto para Fase C: las referencias Campaña→Catálogo guardarán `recurso_id uuid` + `nombre_snapshot text`. Entrada activa → lee vivo del catálogo (cambios reales propagan). Entrada archivada → usa el snapshot (no se rompe el histórico).
- **PxCx** — nomenclatura de Pipelines y Campañas: P1 = Pipeline 1, P1C1 = Campaña 1 del Pipeline 1, P1C1FM1 = Form Meta 1 de esa campaña, etc. Ver `docs/portal/ficha-cliente.md` para detalle.
- **Bubble ID** — identificador único de cada cliente en Bubble (formato `1778244949886x259108771172188160`). Es el `cliente_bubble_id` que usan todas las tablas `cliente_*` como FK lógica.
- **`is_comunidad_admin()`** — función SQL SECURITY DEFINER que devuelve `EXISTS(SELECT 1 FROM comunidad_admins WHERE user_id = auth.uid())`. Usada por las 72 policies de F2.7 (17×4 + 4 visibilidad).

### 🔍 Bugs cerrados en la sesión 2026-05-25

| # | Commit | Bug | Causa | Fix |
|---|---|---|---|---|
| 1 | `5fa8363` | Botón "+ Añadir" no respondía | `onclick="stopPropagation()"` inline bloqueaba el delegate handler que vivía en `document` | Quitar el onclick + guard `closest('[data-cat-add]')` en handler de `[data-coll-toggle]` |
| 2 | `d8fd260` | Checkbox visibilidad mostraba "Error" pese a guardar OK | `Prefer: return=minimal` devuelve 201 con body vacío → `res.json()` lanza `SyntaxError: Unexpected end of JSON input` | Helper `tableRequest` tolera body vacío (lee como text primero, JSON.parse con try/catch) + `toggleVisibility` usa `return=representation` |
| 3 | `64440ea` | Cambio semántica visibilidad de opt-out a opt-in | Decisión iterada de Ben: "todas sin seleccionar, las elegirá Valentina" | `isHidden()` devuelve `true` por defecto + cascada al activar macro envía array UPSERT con macro + todos sus catálogos |

### 🗺️ Mapa de commits de esta sesión (en orden)

```
7de0b79  feat(ficha-cliente): F2.7 Fase B Sprint 1 — panel Catálogos read-only cableado
b59e9fd  feat(ficha-cliente): F2.7 Fase B Sprint 2 — CRUD inline (Añadir/Editar/Archivar)
bd7f958  docs(ficha-cliente): F2.7 Fase B Sprint 1+2 — propagación quirúrgica
5f95668  docs(ficha-cliente): F2.7 — política "solo archivar, sin DELETE duro"
5fa8363  fix(ficha-cliente): F2.7 — botón "+ Añadir" no respondía
7eef03f  feat(ficha-cliente): F2.7 Fase B Sprint 3 — visibilidad por cliente (opt-out inicial)
54b9980  docs(ficha-cliente): F2.7 Fase B Sprint 3 — propagación docs
d8fd260  fix(ficha-cliente): F2.7 Sprint 3 — checkbox "Error" pese a guardar OK
64440ea  feat(ficha-cliente): F2.7 Sprint 3 — semántica opt-in + cascada al activar macro
e74ef2f  docs(ficha-cliente): F2.7 — estado consolidado al cierre (versión corta previa)
[esta]   docs(ficha-cliente): F2.7 — inicializador extenso al cierre
```

Migrations Supabase aplicadas (orden):

```
f2_7_catalogos_cliente             — 17 tablas + RPC catalogos_cliente_get
f2_7_sprint3_catalogos_visibilidad — tabla auxiliar visibilidad + RPC ampliada
```

### 🚧 Roadmap pendiente (con scope detallado)

#### Sprint 4 — Mejoras del panel Catálogos (~1 día estimado)

Refinamientos de UX sin cambios de arquitectura.

1. **Pickers FK en webinar** para `comunidad_wsp_id` + `lead_magnet_id`.
   - Hoy esos 2 campos NO aparecen en el form de webinar (`CATALOGOS.webinars.fields` no los incluye).
   - Añadir `type='picker'` nuevo a `renderField()` que pinte un select con las entradas activas+visibles del catálogo referenciado.
   - Si el catálogo referenciado está vacío, mostrar mensaje "Crea primero una entrada en [Comunidades WhatsApp / Lead magnets]".
   - Opción `null` (sin asociación) válida.

2. **Editor `campos_capturar` jsonb** en plantillas Form Meta.
   - Hoy el campo queda como el default del schema (`{"extras":[],"defaults":["nombre","email","telefono"]}`).
   - UI con chips: 2 secciones (Defaults / Extras), botón "+ añadir campo" en cada una, click en chip para eliminar.
   - Defaults editables (Account puede quitar uno) pero con confirm.
   - Persistir como jsonb completo, no patches granulares.

3. **Buscador global del panel.**
   - Caja `<input type="search">` arriba del panel (entre los controles y la primera macro).
   - Al escribir, filtrar las entradas de los 17 catálogos por nombre/meta/URL/notas (case-insensitive, sin acentos).
   - Auto-expandir los coll-groups con matches. Si no hay matches, mostrar mensaje "Sin resultados".

4. **Toggle "Ver archivadas".**
   - Botón al lado del de "⚙️ Gestionar catálogos" → toggle ON/OFF.
   - OFF (default): las entradas con `archivada=true` se ocultan completamente.
   - ON: vuelven a verse tachadas con badge `🗄` (comportamiento actual).
   - Estado en localStorage del usuario (preferencia personal, NO del cliente).

5. **Bulk operations** (opcional, baja prioridad).
   - "Importar CSV" en cada catálogo: parse client-side + INSERT en batch.
   - "Exportar CSV" del catálogo entero (filtrado o no).
   - Útil para clientes con muchos catálogos preexistentes (ej. infoproductor con 50+ productos).

**Estimación total Sprint 4:** ~1 día con foco. 1, 2 y 3 son lo prioritario. 4 y 5 son nice-to-have.

#### Fase C — Cablear Campaña → Catálogo (~3-5 días estimado)

El gran paso pendiente: que las Campañas del módulo Pipelines referencien entradas del catálogo en lugar de tener campos URL sueltos. **Es lo que justifica F2.7 desde el principio** (las URLs sueltas se retiraron de Campaña en F2.5b/F2.5c precisamente porque iban a vivir en el catálogo).

1. **Modelo de referencia** — patrón snapshot+vivo:
   - Tablas Pipelines/Campañas existentes (`cliente_campanias`, `cliente_triggers`, `cliente_emails`, `cliente_mensajes_whatsapp`, `cliente_creatividades`) **NO** se tocan en su columna principal. En su lugar:
   - Tabla nueva `campania_recurso_referencia` con `(campania_id uuid FK, scope_type 'campania'|'trigger'|'email'|...|, scope_id uuid FK, catalogo_key text, recurso_id uuid, nombre_snapshot text, created_at)`.
   - El frontend al renderizar una Campaña/Trigger/Email lee las refs y muestra "Carpeta Drive: [nombre vivo o snapshot] ↗".

2. **UI** — sección "Recursos asociados" dentro del detalle de Campaña:
   - Picker por tipo de catálogo (botón "Asociar carpeta Drive", "Asociar comunidad WSP", etc.).
   - Cada picker filtra `activos + visibles` del catálogo del cliente.
   - Al asociar, INSERT en `campania_recurso_referencia` con `recurso_id` + `nombre_snapshot` capturado del momento.

3. **Plantillas de Campaña** — `cliente_campania_plantillas` ya existe. Añadir 1 plantilla **hardcodeada** que reproduzca el PDF Rock & Climb (qué tipos de recurso pide). Si el modelo aguanta con 3-4 plantillas reales, abrir builder. Por ahora 1 plantilla validada con Account es suficiente.

4. **`campania_sesion_webinar`** — tabla nueva para webinars con N sesiones específicas (PDF3 Actualízate: 3 masterclass V/S/D con Meet links + horarios). Estas sesiones NO van en el catálogo (son temporales del lanzamiento). Cada sesión: `(campania_id, webinar_id FK al catálogo, fecha, hora, meet_url, recap_url, asistentes_count)`.

5. **Riesgos a vigilar:**
   - **Archivado del catálogo con referencias activas:** decidir si bloquea o solo avisa. Recomendación: avisar, no bloquear (snapshot guarda historia).
   - **Renombrado en el catálogo y vista de Campaña antigua:** snapshot debería sobreescribir vivo solo si la entrada está archivada. Si activa, lee vivo (la realidad cambió).
   - **N+1 queries:** si una Campaña tiene 10 refs, no hacer 10 SELECTs. Usar JOIN en la RPC `ficha_pipelines_get` o ampliarla.
   - **Tipo SD (Sin trigger definido — F2.5e):** un trigger SD puede no necesitar referencias del catálogo (es canal externo). Lo verificas al diseñar Fase C — quizás SD no entra en el picker de recursos.

**Estimación total Fase C:** ~3-5 días. Es donde el módulo Catálogos demuestra su valor.

#### Adyacentes (cuando haga falta, no urgentes)

- **Panel Anomalías** — integrar `n8n_incidencias` filtradas por cliente + checks derivados (campañas sin briefing, servicios sin Drive, webinars sin replay >7 días después de la última sesión, etc.).
- **Migración allowlist a tabla `playbook_editors(email)`** cuando crezca a 6+ editores. Hoy son 5 con 8 sitios sincronizados. Llegando a 6 conviene.
- **Builder de plantillas de Campaña** — cuando haya 3-4 plantillas reales y se valide divergencia.
- **Histórico de uso por entrada del catálogo** — "esta carpeta Drive está referenciada en N campañas". Necesita Fase C primero.

### 🎬 Cómo arrancar la próxima sesión

1. **Lee este inicializador** (estás aquí). Si la sesión es para Sprint 4: lee también los apartados Recetas + Troubleshooting. Si es Fase C: lee también el modelo conceptual en [[../portal/ficha-cliente-operativa|docs/portal/ficha-cliente-operativa]].
2. **Verifica el estado en prod:** abre `https://work.thenucleo.com/ficha-cliente/?id=1778244949886x259108771172188160` (Rock & Climb). Debería verse el botón "⚙️ Gestionar catálogos" y, tras activar las 5 macros con datos (recursos_drive, comunicacion, marketing_meta, operativo, producto), las 16 entradas seed.
3. **Verifica que Supabase está al día** (no hay migrations sueltas):
   ```sql
   SELECT version FROM supabase_migrations.schema_migrations ORDER BY version DESC LIMIT 5;
   ```
   Deberían aparecer `f2_7_catalogos_cliente` y `f2_7_sprint3_catalogos_visibilidad` entre las recientes.
4. **Confirma con Ben qué Sprint/Fase atacar.** Sprint 4 es ~1 día. Fase C es ~3-5 días. No mezclar.
5. **Crea TODOs** con los items concretos del Sprint elegido (los listados arriba ya tienen scope cerrado).
6. **Sigue las convenciones del módulo** (sección "Convenciones de programación reusables").
7. **Propaga docs en cada cierre de sub-tarea** — los 4 docs canónicos (este, `log-cambios.md`, `supabase-schema.md`, `CLAUDE.md` raíz) tienen que reflejar lo nuevo.

### 📁 Mapa de archivos canónicos

- **Frontend único:** `ficha-cliente/index.html` (módulo `CATALOGOS_MODULE` + helper `tableRequest` + CSS catalogos-controls/cat-form-*/vis-*).
- **Docs canónicos:**
  - [`CLAUDE.md`](../../CLAUDE.md) raíz — sección `/ficha-cliente/` (línea ~128) con párrafo F2.7 consolidado.
  - [`docs/work/ficha-cliente.md`](ficha-cliente.md) — este archivo. Secciones "Panel Catálogos" + "Visibilidad por cliente" + "Política de borrado" + este inicializador.
  - [`docs/log-cambios.md`](../log-cambios.md) — 2 entradas del 2026-05-25 (Fase A / Fase B Sprint 1+2+3 + bugfixes + opt-in).
  - [`docs/infra/supabase-schema.md`](../infra/supabase-schema.md) — sección "Catálogos del cliente — F2.7 Fase A" con tabla de 17 catálogos + sub-sección "Tabla auxiliar `cliente_catalogo_visibilidad`" + RPC ampliada.
- **Visión conceptual:** [`docs/portal/ficha-cliente.md`](../portal/ficha-cliente.md) — modelo PxCx, 7 reglas, plantillas de Campaña, framing del módulo.
- **SQL revisable** (no commiteado, referencia): `c:\tmp\catalogos-cliente-f2.7.sql` (versión inicial del Sprint 1; las iteraciones posteriores se aplicaron vía MCP, no se actualizó el archivo local).
