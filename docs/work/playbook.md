---
title: Playbook de Onboarding (cuarentena)
dominio: playbook
estado: cuarentena
actualizado: 2026-05-22
version_dataset: V1 · 84 tareas · 16 campos
tags: [playbook, eleventy, supabase, oauth, publico, cuarentena]
---

# Playbook de onboarding — `work.thenucleo.com/playbook`

Herramienta interna en cuarentena para gestionar la escaleta operativa de onboarding cliente (Día 0 → Día 95). Editor compartido tipo Excel-mejorado con 3 vistas (Tabla, Timeline, Por persona), persistencia en Supabase y auth Google. Pensado para reemplazar la escaleta que Ben mantenía en Excel.

> ⚠️ **Estado actual: cuarentena (2026-05-11).** Sin enlace público desde portal/landing. URL conocida solo por el equipo. No indexable (`<meta noindex>`). Si pasa de fase exploratoria, decidir: subir al portal Bubble o consolidar en work.thenucleo.com.

---

## Resumen ejecutivo

- **Frontend**: HTML standalone en `thenucleo-landing/playbook/index.html`. Sin Eleventy templating (passthrough copy), sin framework. Carga Supabase JS desde jsdelivr.
- **Backend**: 1 tabla Supabase `public.playbook_onboarding` (slug PK, data jsonb). Sin FKs ni dependencias con `bub_*`, `v_tareas_panel` ni workflows n8n.
- **Auth**: Google OAuth reutilizando el flujo de `/comunidad/entrar/` (mismo storageKey `thenucleo-comunidad-auth`). Allowlist hardcoded en frontend Y RLS Supabase.
- **Editores actuales** (`Ben + Alex + marketing@ + Mel`):
  - `benjamin.sanchis@thenucleo.com`
  - `alejandro.lopez@thenucleo.com`
  - `marketing.thenucleo@gmail.com`
  - `mel.dalmazo@thenucleo.com` (añadida 2026-05-15)

  ⚠️ La allowlist vive en **6 sitios** que hay que sincronizar a mano: `EDITOR_EMAILS` (frontend) + 4 RLS policies Supabase (`playbook_progreso_write`, `playbook_update_editors`, `pcs_editor_all`, `ptf_editor_all`) + 1 gate hardcoded en el body de la RPC `playbook_cliente_detalle` (SECURITY DEFINER, bypasea RLS — el gate es explícito en el SQL). Cuando crezca a 5+ editores migrar a tabla `playbook_editors(email)`.
- **Datos en producción** (desde 2026-05-11 tarde): **84 tareas**, 49 días distintos, 7 fases (Pre-onboarding → Mes 4), 8 miembros (incl. Valeria). Dataset cargado desde CSV "OFERTA SERVICIOS — CONTROL DEFINITIVO V1" (Excel operativo) — reemplazó el primer dataset de 78 que Claude generó como semilla.
- **Campos por tarea**: 16 (id, day, dayKey, dayLabel, daySub, phase, title, sub, owners[], client, reg, notas, est, **fechaFija** ✨, **automatizable** ✨, **comoAuto** ✨). Los 3 últimos añadidos 2026-05-11 con el CSV V1.

---

## URLs y repos

| Recurso | Ubicación |
|---|---|
| URL pública | https://work.thenucleo.com/playbook/ |
| Repo frontend | [`marketingthenucleo/thenucleo-landing`](https://github.com/marketingthenucleo/thenucleo-landing) — branch `main` |
| Archivo principal | `thenucleo-landing/playbook/index.html` (standalone, ~109KB) |
| Project Supabase | `cbixhqjsnpuhcrcjppah` (eu-west-1) |
| Tabla | `public.playbook_onboarding` |
| Vercel project | `app-landing-thenucleo` (cuenta `marketingthenucleo`) |

---

## Supabase — schema y RLS

```sql
CREATE TABLE public.playbook_onboarding (
  slug        text PRIMARY KEY,           -- siempre 'default' por ahora
  data        jsonb NOT NULL DEFAULT '[]', -- array de tareas (ver schema abajo)
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  text                         -- email del último editor
);

-- 2 policies RLS:
-- SELECT pública (anon + authenticated leen)
CREATE POLICY playbook_read_all ON public.playbook_onboarding
  FOR SELECT USING (true);

-- UPDATE solo allowlist por email
CREATE POLICY playbook_update_editors ON public.playbook_onboarding
  FOR UPDATE
  USING (lower(auth.jwt() ->> 'email') = ANY(ARRAY[
    'benjamin.sanchis@thenucleo.com',
    'alejandro.lopez@thenucleo.com',
    'marketing.thenucleo@gmail.com'
  ]))
  WITH CHECK (lower(auth.jwt() ->> 'email') = ANY(ARRAY[...mismo...]));

-- Sin INSERT ni DELETE policies → solo se edita la fila default.

-- Trigger updated_at reusa función pública existente:
CREATE TRIGGER playbook_onboarding_updated_at
  BEFORE UPDATE ON public.playbook_onboarding
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
```

---

## Schema del JSON `data` (array de tareas)

Cada tarea es un objeto con los siguientes campos (16):

```ts
{
  id: number,            // único dentro del array, auto-incremental
  day: number,           // 0, 0.5, 1, ..., 95. Permite ordenación numérica
  dayKey: string,        // 'd0', 'd1', 'dseg', 'd31', etc. Agrupa rows del mismo día
  dayLabel: string,      // 'Día 0', 'Seguimiento', 'Día 31' (display)
  daySub: string,        // 'Cierre venta', 'Setup Meta' (subtítulo del día — editable en cabecera de grupo)
  phase: 1 | 2 | 3 | 4 | 5 | 6 | 7,  // editable vía F# pill en cabecera de grupo
  title: string,         // título de la tarea
  sub: string,           // detalle. Si contiene '\n· ' se renderiza como <ul> de bullets
  owners: string[],      // ['mel'] o ['valentin','joaquin']. Slugs internos. Y/O del CSV → ambos array
  client: boolean,       // ¿impacta al cliente directamente?
  reg: string,           // dónde se registra la tarea (doc, plantilla, herramienta)
  notas: string,         // notas internas libres
  est: string,           // '15', '90', 'Auto', '' → minutos estimados. Editable inline (acepta " min")
  fechaFija: boolean,    // NUEVO 2026-05-11. true = no modificable. Day picker disabled, candado visual
  automatizable: boolean,// NUEVO 2026-05-11. true = candidata a automatización. Icono ⚡ ámbar
  comoAuto: string       // NUEVO 2026-05-11. Texto libre describiendo cómo automatizar. Editable en popover
}
```

Reglas de derivación:
- `phase` se deriva de `day` al crear pero es **editable** (override manual). Rango por defecto: 0–0.99 = F1; 1–7 = F2; 8–24 = F3; 25–34 = F4; 35–54 = F5; 55–84 = F6; ≥85 = F7.
- `daySub` se preserva por `dayKey` cuando se reemplaza el dataset (ver "Añadir más datos" abajo).
- `owners` con `'tbd'` representan "Por asignar" — visualmente avatar dashed amarillo.

### PHASES dict (frontend)

```js
const PHASES = {
  1: 'Fase 1 · Pre-onboarding',
  2: 'Fase 2 · Onboarding + análisis',
  3: 'Fase 3 · Setup + lanzamiento (Meta + Google)',
  4: 'Fase 4 · Mes 1 · GMB + planificación Mes 2',
  5: 'Fase 5 · Mes 2 · ejecución + dossiers',
  6: 'Fase 6 · Mes 3 · OTAs + calendarios',
  7: 'Fase 7 · Mes 4 · continuidad',
};
```

### OWNERS dict (slugs internos → meta visual)

| slug | nombre | color | iniciales |
|---|---|---|---|
| `alex` | Alex | `#3b82f6` (azul) | A |
| `mel` | Mel | `#22c55e` (verde) | M |
| `valentina` | Valentina | `#8b5cf6` (violeta) | V |
| `valentin` | Valentín | `#ec4899` (rosa) | V |
| `joaquin` | Joaquín | `#f59e0b` (ámbar) | J |
| `camilo` | Camilo | `#0ea5e9` (cyan) | C |
| `damian` | Damián | `#ef4444` (rojo) | D |
| `valeria` | Valeria | `#14b8a6` (teal) | V |
| `tbd` | Por asignar | dashed | ? |

---

## Ficha del cliente + Servicios contratados (desde 2026-05-14)

Panel lateral editor-only (340px, sticky, **solo visible en la vista Timeline**, oculto en anon-mode y viewport < 1100px) que aparece al seleccionar un cliente en el dropdown de vista cliente.

El layout de 2 columnas (timeline a la izquierda, ficha a la derecha) está acotado al pane Timeline mediante el wrapper `.timeline-layout`. Cabecera, filtros, view-switcher, cliente-bar y sector-bar quedan a ancho completo. Las vistas Tabla y Kanban también ocupan ancho completo (la ficha no se muestra en ellas).

Se controla con `body[data-view="timeline"]` (atributo seteado por JS al cambiar de pestaña) combinado con `body.has-ficha` (cliente cargado en modo editor).

### Supabase — nuevas piezas

| Objeto | Tipo | Descripción |
|---|---|---|
| `playbook_cliente_servicios` | Tabla | Relación cliente ↔ ficha de producto con unidades, periodo, notas. RLS solo editores. Columna `precio numeric` persiste en BD pero ya no se usa desde la UI (2026-05-20). **Sync a Bubble desde 2026-05-22:** se replica al Data Type Bubble `playbook_cliente_servicios` (mismo nombre, 199 filas iniciales) vía workflow n8n `ewu5A5E05T4tz5CD` (SYNC FICHAS — Supabase → Bubble). Supabase sigue siendo master. |
| `playbook_cliente_detalle(p_bubble_id)` | RPC | SECURITY DEFINER + gate email. Devuelve `{cliente (19 campos), servicios[]}`. Anon recibe NULL. |

### Panel — secciones

**Ficha del cliente** (read-only, datos de `bub_clientes`):
- Cabecera: nombre empresa + sociedad + pill estado (color) + link Drive
- Pills: sector + nivel
- Bloque facturación: `facturacion` €/mes + plan_actual + descripcion_plan
- Fechas: onboarding · próxima factura · último seguimiento · NPS
- Contacto: nombre · email (mailto:) · teléfono (tel:) · web

**Servicios contratados** (CRUD completo):
- Lista de tarjetas agrupadas por categoría en acordeón (caret + dot color + conteo). Categorías y servicios ordenados alfabéticamente (`localeCompare('es')`). Cerrado por defecto; si solo hay 1 categoría se abre sola. Cada tarjeta mantiene su estructura interna (título, dot, chips de unidades/notas/categoría, edit/delete).
- Añadir: **combobox con búsqueda** sobre el catálogo `fichas_de_producto` (categorías colapsables con conteo; click expande). Búsqueda por **tokens-AND** sobre `titulo + categoría` normalizados (lowercase + sin tildes). Diccionario de **sinónimos** local para acrónimos comunes (`fb↔facebook↔meta`, `ig`, `gmb`, `ws`, `ads↔anuncios`, `ghl↔crm`, etc. — ver `FICHA_SYNONYMS` en `playbook/index.html`). Chip "borrador" en items con `estado≠publicada`.
- **Autofill de `unidades`** con el valor de `fichas_de_producto.unidad` al seleccionar la ficha. Se puede sobrescribir por cliente sin tocar el catálogo.
- Campo precio **eliminado de la UI** 2026-05-20 (form, editor inline y render de tarjetas). La columna `precio numeric` se mantiene en BD por compatibilidad.
- Editar inline por servicio (sin precio).
- Eliminar con confirm.

Los datos del contacto/facturación son de solo lectura en el Playbook — para editarlos hay que ir al portal Bubble.

---

## Marcar duda + Agregar nota en task cards (desde 2026-05-14)

Cada tarea del timeline muestra dos botones de acción cuando hay un cliente seleccionado en modo editor:

| Objeto | Tipo | Descripción |
|---|---|---|
| `playbook_task_feedback` | Tabla | `(cliente_bubble_id, task_id)` UNIQUE. `es_duda bool`, `nota text`, `updated_at`. RLS solo editores. |

**⚠ Duda:** toggle que pinta el botón en ámbar. Se persiste con UPSERT inmediato al click. Indica que esa tarea tiene una duda o bloqueo para ese cliente.

**+ Nota:** abre un textarea inline debajo de la tarea. Guardar UPSERT `nota`. El botón cambia a `📝 Nota` cuando hay contenido. Cancelar descarta cambios sin guardar.

El feedback se carga en paralelo con el progreso (`loadFeedbackCliente`) al seleccionar cliente. Invisible en anon-mode (cliente público) — solo editores.

---

## Frontend — arquitectura

### Stack y carga

- HTML + CSS + JS vanilla, **un solo archivo** `playbook/index.html`.
- Eleventy `addPassthroughCopy("playbook")` en `.eleventy.js` → se copia tal cual al `_site/playbook/`.
- Tokens de diseño TheNucleo inlined (no `tokens.css` compartido — para evitar dependencias).
- Supabase JS desde CDN: `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm`.
- Fuente NewBlack desde `/fonts/*.woff2` (compartida con resto landing).

### Vistas (3, todas desde el mismo dataset)

1. **Tabla** (default) — **único editor**. Sortable, búsqueda, sticky headers + collapse por día.
2. **Timeline** — solo lectura. Vertical con marcadores de día y cards por fase.
3. **Por persona** — solo lectura. Kanban de 9 columnas (8 miembros + tbd).

Decisión 2026-05-11: la edición se concentra en la vista Tabla. Timeline y Kanban son visualización pura (no se intentan editores en esas vistas).

### Columnas de la tabla (11)

1. `check-col` — checkbox de selección (bulk delete deprecado pero columna sigue por consistencia).
2. **Día** (sortable) — click abre day-picker. Disabled si `fechaFija=true`.
3. **🔒** (sortable) — toggle `fechaFija`. Icono ámbar lila si SI.
4. **Tarea** — title (contenteditable) + sub (contenteditable o `<ul>` de bullets si tiene `\n·`).
5. **Responsable** (sortable) — popover de owners (multi-select).
6. **Estim.** (sortable) — pill editable inline. Acepta number o 'Auto'. Quita sufijo " min" automáticamente.
7. **Impacto** (sortable) — toggle `client`.
8. **⚡** (sortable) — abre auto-picker (toggle + textarea `comoAuto`).
9. **Registrado en** — texto libre editable inline.
10. **Notas** — texto libre editable inline.
11. **row-actions** — papelera (hover, opacity 0→1).

### Filtros (barra superior)

- Buscador (cubre title, sub, reg, notas, comoAuto, est, dayLabel, owner names).
- 8 chips de Responsable (multi-toggle).
- 3 toggles excluyentes acumulables: **Solo impacto cliente** · **Solo fechas fijas** 🔒 · **Solo automatizables** ⚡.

### Comportamiento por URL × sesión (actualizado 2026-05-13)

| URL | Sin sesión | Sesión authenticated no-admin | Sesión admin |
|---|---|---|---|
| `/playbook/` (sin id) | **Gate modal** "Acceso restringido" → CTA → `/comunidad/entrar/?next=/playbook/` | **Gate modal** "Tu cuenta no tiene acceso" → CTA "Cambiar de cuenta" (limpia localStorage + login) | Editor maestro completo (plantilla de 84 tareas) |
| `/playbook/<bubble_id>` con id válido | Timeline cliente read-only (RPC `playbook_publico` SECURITY DEFINER, anon-safe) | Idem (sesión irrelevante en este path) | Vista cliente con progreso editable + barra de progreso teórico |
| `/playbook/<bubble_id>` con id inválido | `showAnonError()` dentro del `<main>` ("Enlace privado o no disponible") | Idem | Idem |

**Anti-flicker guard inline (`<head>`):**
- `parts[1]` truthy → `html.anon-mode` (oculta auth-bar interactiva, filtros y vistas no-timeline).
- `parts[1]` ausente → `html.locked-mode` (oculta `.app` completa, muestra modal `.gate`).
- Admin retira la clase correspondiente al confirmar sesión.

**Cambio histórico (2026-05-13):** antes el caso "anon entra a `/playbook/`" hacía `window.location.replace('/')` sin explicación. Reportado por Ben como "te saca y ya" → sustituido por gate amable consistente con `/fichas-de-producto/`. Detalle en log-cambios.md entrada `2026-05-13 [WORK][UX]`.

### Auth flow

- Botón "Entrar como editor" → redirige a `/comunidad/entrar/?next=/playbook/`.
- `/comunidad/entrar/` ya gestiona Google OAuth + captcha "No soy un robot".
- Tras OAuth, Supabase guarda sesión en localStorage clave `thenucleo-comunidad-auth`.
- `init()` detecta hash `#access_token=...`, espera (max 3s, polls 100ms) hasta que la sesión esté en localStorage, limpia el hash con `history.replaceState`.
- `onAuthStateChange` listener actualiza UI en login/logout posterior (login en otra pestaña, refresh token).
- Comparación `EDITOR_EMAILS.has(lower(email))` → si match, modo editor. Si no, viewer.

### Edit / save flow

Todo editable en vista Tabla:

| Campo | UI | Trigger |
|---|---|---|
| `title`, `sub`, `reg`, `notas` | `contenteditable="plaintext-only"` | blur del span |
| `est` | `contenteditable` con normalización `min` | blur del span dentro de la pill |
| `owners[]` | popover multi-select | click en celda Responsable |
| `day` / `dayKey` / `dayLabel` / `daySub` / `phase` (de la tarea) | day-picker (lista de días existentes) | click en celda Día (bloqueado si `fechaFija`) |
| `daySub` (compartido del grupo) | `contenteditable` inline en cabecera del grupo | blur — propaga a todas las filas del día |
| `phase` (compartida del grupo) | phase-picker (7 fases) | click en pill "F#" en cabecera del grupo |
| `client` | toggle | click en celda Impacto |
| `fechaFija` | toggle | click en celda 🔒 |
| `automatizable` + `comoAuto` | auto-picker (toggle + textarea) | click en celda ⚡ |
| `delete row` | papelera hover | click ✕ |
| `add task` | botón "+ Añadir tarea a Día X" | click |
| `add day` | botón "+ Añadir nuevo día / fase" | prompt() |

- Cambios → `scheduleSave()` con debounce 600ms → `PATCH /rest/v1/playbook_onboarding?slug=eq.default` con `Authorization: Bearer <access_token>`.
- Viewer mode: `body.viewer` clase global, oculta todos los affordances de edición vía CSS.
- Botón "Exportar CSV" disponible para viewer + editor (12 columnas: ahora incluye Fecha fija, Automatizable, ¿Cómo automatizar?).

### Estado JS

```js
const STATE = {
  view: 'tabla',                 // 'tabla' | 'timeline' | 'kanban'
  activeOwners: new Set(...),    // filtro por chip de responsable
  clientOnly: false,             // toggle "Solo impacto cliente"
  fijaOnly: false,               // toggle "Solo fechas fijas" (2026-05-11)
  autoOnly: false,               // toggle "Solo automatizables" (2026-05-11)
  search: '',
  sortBy: 'day',                 // 'day' | 'title' | 'owner' | 'est' | 'client' | 'fija' | 'auto'
  sortDir: 'asc',
  collapsedDays: new Set(),
  selectedIds: new Set(),
  density: 'comfy',              // 'comfy' | 'dense'
  lastSaved: null,
  canEdit: false,                // bool, derivado de STATE.user + EDITOR_EMAILS
  user: null                     // { id, email, ... } o null
};
```

---

## Cómo modificar

### Añadir un editor más

**6 cambios, deben hacerse a la vez** (allowlist hardcoded en 4 policies SQL + 1 gate dentro de RPC + 1 Set JS). Si se olvida alguna, la UI mostrará affordances al usuario pero el UPSERT/UPDATE será rechazado silenciosamente por RLS:

1. **Supabase** (DROP + CREATE las **4** policies con email añadido al ARRAY):
   ```sql
   -- 1. Plantilla maestra
   DROP POLICY IF EXISTS playbook_update_editors ON public.playbook_onboarding;
   CREATE POLICY playbook_update_editors ON public.playbook_onboarding
     FOR UPDATE
     USING (lower(auth.jwt() ->> 'email') = ANY(ARRAY[...,'nuevo@email.com']))
     WITH CHECK (lower(auth.jwt() ->> 'email') = ANY(ARRAY[...mismo...]));

   -- 2. Checks de progreso por cliente
   DROP POLICY IF EXISTS playbook_progreso_write ON public.playbook_progreso;
   CREATE POLICY playbook_progreso_write ON public.playbook_progreso
     FOR ALL
     USING (lower(auth.jwt() ->> 'email') = ANY(ARRAY[...,'nuevo@email.com']))
     WITH CHECK (lower(auth.jwt() ->> 'email') = ANY(ARRAY[...mismo...]));

   -- 3. Servicios contratados por cliente
   DROP POLICY IF EXISTS pcs_editor_all ON public.playbook_cliente_servicios;
   CREATE POLICY pcs_editor_all ON public.playbook_cliente_servicios
     FOR ALL
     USING (lower(auth.jwt() ->> 'email') = ANY(ARRAY[...,'nuevo@email.com']))
     WITH CHECK (lower(auth.jwt() ->> 'email') = ANY(ARRAY[...mismo...]));

   -- 4. Feedback ⚠ Duda + 📝 Nota
   DROP POLICY IF EXISTS ptf_editor_all ON public.playbook_task_feedback;
   CREATE POLICY ptf_editor_all ON public.playbook_task_feedback
     FOR ALL
     USING (lower(auth.jwt() ->> 'email') = ANY(ARRAY[...,'nuevo@email.com']))
     WITH CHECK (lower(auth.jwt() ->> 'email') = ANY(ARRAY[...mismo...]));
   ```

2. **RPC `playbook_cliente_detalle`** (SECURITY DEFINER, bypasea RLS) — `CREATE OR REPLACE FUNCTION` con el array `v_email NOT IN (...)` actualizado dentro del body. La RPC alimenta el panel "Ficha del cliente" del Timeline; si falta el email, devuelve `NULL` y el panel no carga (la UI no muestra error explícito).

3. **Frontend** `playbook/index.html` — añadir al `Set EDITOR_EMAILS`:
   ```js
   const EDITOR_EMAILS = new Set([
     "benjamin.sanchis@thenucleo.com",
     "alejandro.lopez@thenucleo.com",
     "marketing.thenucleo@gmail.com",
     "mel.dalmazo@thenucleo.com",
     "nuevo@email.com",
   ]);
   ```

**Síntoma típico de allowlist desincronizada (frontend SÍ, RLS NO):** el editor pulsa el control, no aparece error visible, pero al recargar la página el cambio no está. Causa: el UPSERT salió con `Authorization: Bearer <jwt>` pero el RLS lo rechazó (PostgREST devuelve `0 rows affected` sin error 401). Caso registrado 2026-05-15 con Mel y los checks de `playbook_progreso`.

**Síntoma específico de gate RPC desincronizado:** el panel "Ficha del cliente" del Timeline aparece vacío / no carga aunque el cliente exista. Causa: `playbook_cliente_detalle` devuelve `NULL` porque el email no pasa el gate hardcoded en el body. Caso registrado 2026-05-15 con Mel.

Si crece a 5+ editores, migrar a tabla `playbook_editors(email)` y RLS con `IN (SELECT email FROM playbook_editors)` para no hardcodear.

### Añadir una columna nueva a las tareas

Ej: añadir campo `dependencias` (array de IDs de tareas previas).

1. **Schema JSON** — sin migration Supabase (jsonb es flexible). Solo añadir el campo a `DEFAULT_TASKS` y a la doc del schema.
2. **Frontend** — varios sitios:
   - `DEFAULT_TASKS` array: añadir `dependencias: []` a cada tarea
   - `renderTaskRow()`: añadir `<td>` nuevo
   - Header `<thead>`: añadir `<th>` con label + posible `sortable`
   - `colspan` en day-group rows, add-task-row, add-day-row, empty state (actualmente 8)
   - `matchesFilters()` si se quiere buscar por este campo
   - `exportCSV()`: añadir a headers + row
   - Si hay sort: añadir caso en el sort en `renderTabla()`
   - CSS: `td.dependencias-cell` si necesita estilo

3. **Sembrar datos existentes** — para no perder tareas creadas previamente, hacer un `UPDATE` que parchee el jsonb:
   ```sql
   UPDATE public.playbook_onboarding
   SET data = (
     SELECT jsonb_agg(t || jsonb_build_object('dependencias', '[]'::jsonb))
     FROM jsonb_array_elements(data) AS t
   )
   WHERE slug = 'default';
   ```

### Añadir más datos / reemplazar todo el array

Si tienes CSV nuevo con más tareas (como pasó en sesión 2026-05-11 con el CSV V1):

1. Si el CSV viene de Excel con encoding raro ("DÃ­a", "Â¿"): es Latin1→UTF-8 mal interpretado. Decodificar con `Buffer.from(s,'binary').toString('utf8')` antes de parsear.
2. Convertir CSV → array JS de tareas (objeto con los 16 campos del schema).
3. Para preservar `daySub` de días que ya existen: hacer lookup por `dayKey` del dataset actual y reusar. Días nuevos → generar subtítulo coherente con la fase.
4. Reemplazar `DEFAULT_TASKS` en frontend.
5. Sobrescribir la fila Supabase (preferible con $dollar quoting$ por los caracteres unicode):
   ```sql
   UPDATE public.playbook_onboarding
   SET data = $playbook$[...nuevo array json...]$playbook$::jsonb,
       updated_by = 'benjamin.sanchis@thenucleo.com'
   WHERE slug = 'default';
   ```
6. Verificar:
   ```sql
   SELECT jsonb_array_length(data) FROM public.playbook_onboarding WHERE slug='default';
   ```
7. Commit + push frontend, esperar deploy Vercel.

> ⚠️ **Vercel se ha quedado pichando deploys 2 veces en sesiones previas** — si tras push no propaga en 5 min, hacer un commit dummy con cambio real (no empty) para forzar rebuild. Comprobar dashboard Vercel.

Script de generación reutilizable: `c:/tmp/playbook/build.mjs` (sesión 2026-05-11). Parsea CSV mojibake, mapea responsables Y/O del CSV, preserva `daySub` por `dayKey`, infiere `phase` por rango de `day`, genera array literal JS + JSON compactado + SQL `$playbook$` quoted.

### Sacar de cuarentena (futuro)

Cuando decidas integrarlo "oficialmente":

- **Opción A — Mantener en work.thenucleo.com**: enlace desde portal Bubble interno (sidebar Operaciones), nada que tocar técnicamente.
- **Opción B — Migrar al portal Bubble**: data type nuevo `Plantilla_Onboarding_Tarea` + RG + workflow n8n `KSBwigoSEpHl5OG1` (Aplicar Plantilla a Cliente) extendido. Más coherente con el resto del portal pero ~1-2 días de trabajo.

---

## Reversión total (cuando ya no se use)

5-10 minutos. Cero daño colateral.

```sql
-- Supabase
DROP TABLE public.playbook_onboarding CASCADE;
```

```bash
# Frontend
cd thenucleo-landing
git rm -rf playbook
# Quitar línea `addPassthroughCopy("playbook")` de .eleventy.js
git commit -m "chore: retire playbook prototype"
git push
```

Sin afectar `bub_*`, `v_tareas_panel`, workflows n8n, ni Bubble.

---

## Histórico de commits relevantes

| Commit | Cambio |
|---|---|
| `1bb9d22` | Despliegue inicial /playbook/ + Supabase + auth Ben |
| `dd4df86` | Botón global Plegar/Desplegar todos |
| `2c99aaa` | Quitar Reset + chevrons decorativos de cabecera |
| `8cfdf39` | Toggle tema claro/oscuro |
| `76672b5` | Ampliar a 78 tareas hasta Día 95 + columna Estim. + Valeria |
| `d01a666` | Añadir Alex como editor |
| `97705f5` | Añadir marketing.thenucleo@gmail.com como editor |
| `e629c81` | Viewer mode oculta affordances + hero compacto |
| `4a8b8c6` | Fix login OAuth sin requerir refresh manual |
| `7c5bfaa` | **CSV V1 (84 tareas) + 3 cols nuevas + todo editable en Tabla** (2026-05-11) |

Migrations Supabase: `create_playbook_onboarding`, `playbook_add_alex_editor`, `playbook_add_marketing_gmail_editor`. El reemplazo de 78→84 tareas + 3 campos nuevos NO requirió migration (schema jsonb es libre).

Detalle por sesión: [[log-cambios|docs/log-cambios]] entradas 2026-05-11.

---

## Para arrancar nuevo chat / handoff

Si vas a iterar el playbook en un nuevo chat (ej. nueva versión del Excel con más columnas), pasar este doc + la entrada del log + la sección de `supabase-schema.md`. Con eso tendrá:

- Schema actual de la tabla y del JSON
- Allowlist de editores
- Convención de slugs de owners + colores
- Estructura del frontend (vistas, render, save flow)
- Cómo añadir columnas sin romper datos existentes (UPDATE con `jsonb_agg`)
- Cómo forzar redeploy si Vercel se atasca
