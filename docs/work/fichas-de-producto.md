---
title: Fichas de Producto (admin-only)
dominio: fichas-de-producto
estado: vivo
actualizado: 2026-05-22
version_dataset: V2 · 12 categorías (10 con fichas) · 57 fichas comerciales unificadas con Excel
tags: [fichas, eleventy, supabase, oauth, admin-only]
---

# Fichas de Producto — `work.thenucleo.com/fichas-de-producto/`

Catálogo editable inline del catálogo de servicios de la agencia: qué incluye cada servicio, qué NO incluye (anti-scope), unidad de medida, herramientas y dónde hay flexibilidad. Es **documentación interna** del equipo, no marketing público.

> 🔒 **Acceso admin-only en lectura y edición.** Sin público anon, sin link compartible, sin clientes. Solo cuentas en `comunidad_admins` ven la página. Decisión cerrada con Ben el 2026-05-13: "los mails que te he ido dando yo".

> ✅ **Migración v2 aplicada (2026-05-20):** 63 fichas operativas → 57 fichas comerciales unificadas con el Excel `Servicios vendidos en Onboarding.xlsx`. Source of truth: tablas `fichas_categorias` + `fichas_de_producto` en Supabase, replicadas a Bubble vía `ewu5A5E05T4tz5CD`. Detalle histórico de las 57 fichas con sus `[???]` y bloques "Pendiente aclarar" en [[fichas-de-producto_v2_draft]] (referencia, no editar — la verdad está en BD). Backup de las 63 previas en `c:\tmp\fichas_backup_pre_v2.json`.

---

## Resumen ejecutivo

- **Frontend:** HTML standalone en `thenucleo-landing/fichas-de-producto/index.html` (792 líneas, inline CSS+JS). Sin Eleventy templating (passthrough copy). Supabase JS desde jsdelivr.
- **Backend:** 2 tablas Supabase nuevas (`fichas_categorias` + `fichas_de_producto`) en proyecto `cbixhqjsnpuhcrcjppah`. **Sync a Bubble desde 2026-05-22:** se replican a Data Types Bubble con el mismo nombre (`fichas_categorias` 12 filas + `fichas_de_producto` 57 filas) vía workflow n8n `ewu5A5E05T4tz5CD` (SYNC FICHAS — Supabase → Bubble). Supabase sigue siendo master, Bubble lee.
- **Auth/Gate:** mismo flujo Google OAuth que `/comunidad/entrar/` (storageKey compartido `thenucleo-comunidad-auth`). Allowlist hardcoded en frontend **y** RLS Supabase con `is_comunidad_admin()` — la misma tabla `comunidad_admins` que comunidad e incidencias.
- **Admins actuales (4 cuentas):** Ben, marketing.thenucleo, Alex López, Mel Dalmazo.
- **Datos seed:** 12 categorías + 63 fichas parseadas del documento `.md` que envió Ben, con los huecos `[???]` conservados como texto literal editable. Todas en estado `borrador`.

---

## URLs y repos

| Recurso | Ubicación |
|---|---|
| URL | https://work.thenucleo.com/fichas-de-producto/ |
| Repo frontend | [`marketingthenucleo/thenucleo-landing`](https://github.com/marketingthenucleo/thenucleo-landing) — branch `main` |
| Archivo principal | `thenucleo-landing/fichas-de-producto/index.html` |
| Project Supabase | `cbixhqjsnpuhcrcjppah` (eu-west-1) |
| Tablas | `public.fichas_categorias`, `public.fichas_de_producto` |
| Migration | `fichas_de_producto_schema` (2026-05-13) |

---

## Schema

### `fichas_categorias`
| Columna | Tipo | Notas |
|---|---|---|
| `id` | uuid PK | `gen_random_uuid()` |
| `nombre` | text NOT NULL | Visible en sidebar y header |
| `slug` | text NOT NULL UNIQUE | URL-safe |
| `orden` | int | Orden de aparición |
| `icono` | text | Hint (no usado en UI todavía) |
| `color` | text | Hex color para dot + bar visual |
| `created_at`, `updated_at` | timestamptz | Trigger reusa `trg_comunidad_set_updated_at` |

**Seed (12 filas):** Onboarding · Google Ads · Meta Ads · CRM · Google My Business · Redes Sociales · Producción Audiovisual · Soporte · Consultoría · Canales Externos · Materiales · Desarrollo.

### `fichas_de_producto`
| Columna | Tipo | Notas |
|---|---|---|
| `id` | uuid PK | `gen_random_uuid()` |
| `categoria_id` | uuid FK → `fichas_categorias` ON DELETE RESTRICT | |
| `titulo` | text NOT NULL | Inline editable |
| `slug` | text NOT NULL | UNIQUE `(categoria_id, slug)` |
| `orden` | int | Reordenable con ↑↓ |
| `estado` | text CHECK `borrador|publicada|archivada` | Pill clicable → popover |
| `unidad`, `alcance`, `herramientas`, `no_incluye`, `flexibilidad` | text NOT NULL DEFAULT `''` | 5 bloques contenteditable |
| `sop_url` | text NOT NULL DEFAULT `''` | URL al SOP (Standard Operating Procedure). Editable inline + render como pill "↗ Abrir" cuando es URL `http(s)` válida. Añadido 2026-05-16 (migration `fichas_de_producto_add_sop_url`). |
| `created_at`, `updated_at` | timestamptz | Trigger compartido |

**Índice:** `(categoria_id, orden)`.

---

## RLS y permisos

Todas las operaciones (SELECT/INSERT/UPDATE/DELETE) en ambas tablas están gated por `public.is_comunidad_admin()`:

```sql
CREATE POLICY fp_select_admin ON public.fichas_de_producto
  FOR SELECT TO authenticated USING (public.is_comunidad_admin());
-- + fp_insert_admin, fp_update_admin, fp_delete_admin
-- + las 4 equivalentes en fichas_categorias
```

**GRANTs:**
- `authenticated`: SELECT/INSERT/UPDATE/DELETE (la RLS filtra por admin).
- `service_role`: ALL.
- `anon`: sin GRANT explícito (queda con grants default de PostgREST; RLS filtra → devuelve 200 + `[]`).

**Verificación post-deploy:** un `curl` con la anon key devuelve `200 OK + []` (no leak). Solo un JWT con `auth.uid()` perteneciente a `comunidad_admins` ve filas.

---

## Frontend — patrón

Clon del Playbook (`thenucleo-landing/playbook/index.html`). Diferencias principales:

| Aspecto | Playbook | Fichas |
|---|---|---|
| Lectura anon | Sí, con `bubble_id` en URL (RPC `playbook_publico` SECURITY DEFINER) | **No** — admin-only |
| Identificador en URL | `/playbook/<bubble_id>` | Sin path param — globales |
| Bloqueo si no admin | Vista read-only | **Gate modal completo** (no muestra contenido) |
| RPC | 1 lectura (`playbook_publico`) + tabla `playbook_onboarding` para PATCH | REST puro a las 2 tablas con JWT del user |
| Datos | jsonb único (`data`) en una fila | Filas individuales (relacional) |
| Edición | `contenteditable` + pickers + popovers | Idem (mismo patrón) |
| Save | Debounce 600ms, full data replace | Debounce 500ms, PATCH por `(id, field)` |

**Anti-flicker guard:** la página empieza con `<html class="locked-mode">` (CSS oculta `.app` y muestra `.gate`). Solo se quita la clase si la sesión + email pasan el check de admin.

**Filtro de estado (topbar):** toggle group con 4 pills (`Todas` / `Publicadas` / `Borrador` / `Archivadas`) y conteo en vivo. Filtra sidebar, vista tarjetas y vista tabla en cliente (sin reload). Categorías sin fichas del estado activo se ocultan; si todas quedan vacías muestra empty-state. En móvil colapsa a dot + número. Counts se recalculan en cada `renderAll()` (se actualizan al cambiar estado de cualquier ficha vía popover).

**Reordenamiento:** swap optimista local del `orden` numérico entre vecinas + 2 PATCHes en serie (no batch — UPDATE individual respeta RLS). Rollback al estado anterior si falla.

---

## Flujo de uso

1. Admin entra desde el dropdown del avatar (botón "Fichas de producto" presente en comunidad/incidencias/blog/zenyx) o tipea `/fichas-de-producto/` directamente.
2. Si no hay sesión → modal "Acceso restringido" + botón → `/comunidad/entrar/?next=/fichas-de-producto/`.
3. Si sesión pero no admin → modal "Tu cuenta no tiene acceso" + botón "Cambiar de cuenta" (limpia localStorage).
4. Si admin → sidebar con 12 categorías (click para scroll suave) + main con cards. Cada card es editable inline:
   - Click en título o cualquiera de los 5 bloques → contenteditable, escribe, debounce 500ms guarda.
   - Pill de estado → popover con 3 opciones (borrador / publicada / archivada).
   - Botones ↑↓ para reordenar dentro de la categoría.
   - ✕ para borrar (con confirm nativo).
   - "+ Nueva ficha" al cabezal de cada categoría.

---

## Operaciones comunes

| Necesidad | Acción |
|---|---|
| Añadir nuevo admin | INSERT en `comunidad_admins` con el `user_id` de `auth.users`. Sincronizar la constante `EDITOR_EMAILS` en `fichas-de-producto/index.html` (la lista hardcoded gate-keepea la UI; RLS filtra el server). |
| Cambiar nombre/color de una categoría | UPDATE directo en `fichas_categorias` (vía SQL editor o vía la UI cuando se añada — no hay editor de categorías por ahora). |
| Reordenar categorías | UPDATE `orden` en `fichas_categorias`. |
| Borrar una categoría con fichas dentro | Falla por FK ON DELETE RESTRICT — primero mover/borrar fichas. |
| Backup/export | `SELECT json_agg(...) FROM fichas_de_producto;` o vía `pg_dump` del schema. |

---

## Pendientes / siguientes pasos

- **UI:** editor inline para `categorias` (renombrar, reordenar, cambiar color). Hoy solo se editan vía SQL.
- **Filtros:** filtro por estado (mostrar solo `borrador`, solo `publicada`, etc.) y búsqueda full-text en la sidebar.
- **Cantidad de fichas por estado:** badge en cada categoría con conteo de `publicada` / `borrador`.
- **Auditoría de campos:** cuando se llenen los `[???]`, considerar un campo `responsable_ejecutor` enum (alex/mel/valentin/joaquin/camilo/damian/valeria) en lugar de mencionarlo en el texto de "Herramientas".
- **Exposición selectiva:** si un día Ben quiere que un cliente vea "sus fichas", crear un RPC `fichas_cliente(p_cliente_id uuid)` SECURITY DEFINER que filtre solo las relevantes (no abrir RLS general).

---

## Cross-refs

- Patrón base: [[playbook]] (fichas hereda anti-flicker, gate, allowlist, contenteditable, scheduleSave, picker popover).
- Auth/sesión compartida: [[comunidad]] (storageKey `thenucleo-comunidad-auth`, login `/comunidad/entrar/`).
- Schema completo: [[supabase-schema]] sección "Fichas de Producto".
- Allowlist admin (la misma para 3 secciones): tabla `comunidad_admins` + RPC `is_comunidad_admin()`.
