---
title: Casuísticas — Tablero clasificación de peticiones
dominio: work
estado: vivo
actualizado: 2026-05-15
tags: [casuisticas, work, admin, kanban, operaciones, supabase]
---

# Casuísticas — `/casuisticas/`

Tablero kanban admin-only en `work.thenucleo.com/casuisticas/` para clasificar peticiones de cliente que caen fuera (o dentro) del alcance contratado. Sirve de referencia compartida para Operaciones al decidir cómo cobrar/asignar cada petición entrante.

## Para qué sirve

Cuando un cliente pide algo que no está claramente dentro del servicio contratado (un flujo extra, un email puntual, una integración nueva), el equipo necesita saber rápido si:
- Se cobra contra **Bolsa de Horas** (montaje en CRM).
- Cuenta como **Newsletter** (copies sueltos).
- Es **Híbrido** (mezcla copy + montaje, pendiente definir cómo cobrar).
- O está **Dentro de los servicios contratados** (sin coste extra).

El tablero recoge las casuísticas reales observadas, con descripción narrativa y posibilidad de marcar "Duda abierta" para los casos sin decisión consensuada.

## Columnas

| Columna | Color | Descripción |
|---|---|---|
| Bolsa de Horas | Verde (`--accent-primary`) | Montaje y automatización en el CRM (GHL, Meta, calendario, WhatsApp post-campaña). |
| Cantidad Newsletter | Azul (`--accent-secondary`) | Copies de email sueltos o ampliaciones más allá del pack contratado. |
| Híbrido | Ámbar (`--status-warning`) | Mezcla copy + montaje · pendiente de criterio definitivo. |
| Dentro de los servicios contratados | Gris (`--status-neutral`) | Peticiones cubiertas por el contrato, sin coste extra. |

## Funcionalidad

- **Drag & drop** entre columnas — cambiar la clasificación de un caso arrastrando la tarjeta.
- **Edición inline** — clic sobre el título o la descripción para editar (`contenteditable`).
- **Marcar duda** — botón en cada card que añade badge ámbar "⚠ Duda abierta" (`flag: 'duda'`). Sirve para señalizar casos sin consenso.
- **+ Nota** — botón en cada card (entre "Marcar duda" y "Borrar") que despliega un cuadrito "Notas" dentro de la card. Autosave on input (mismo debounce de `queueSave()`). El botón pasa a "📝 Nota" con tinte azul cuando hay contenido guardado. Persiste en Supabase junto al resto del board en el campo `item.nota`.
- **Añadir caso** — botón "+ Añadir caso" al pie de cada columna.
- **Borrar caso** — botón en cada card.
- **Exportar JSON** — descarga `casuisticas-YYYY-MM-DD.json` con el estado completo.
- **Importar JSON** — restaura desde un export previo.
- **Restaurar original** — vuelve al `SEED` hardcoded en el HTML.
- **Tema claro/oscuro** — toggle en la auth bar.

## Persistencia

**Supabase** — tabla `casuisticas_board` (single-row `id='global'`) con columna `data jsonb` que guarda `{bolsa, newsletter, hibrido, dudas}` + `updated_at` + `updated_by` (email del último editor).

Migrado desde `localStorage` el 2026-05-15 tras incidente de pérdida de cambios — cada navegador/dispositivo tenía su propio estado y no había forma de recuperar cambios escritos en otro device.

### Flujo cliente

1. **Carga**: al pasar el gate de auth, `initBoard()` hace `SELECT data, updated_at, updated_by FROM casuisticas_board WHERE id='global'`. Pinta el estado y muestra "Última edición hace X · &lt;email&gt;" en el header.
2. **Edición**: cualquier cambio (drag, edit, flag, nota, add, delete) llama a `queueSave()`. Cache local (`localStorage[nucleo_casuisticas_v1]`) síncrono + `flushSave()` debounced (600 ms) hace `UPSERT` en Supabase con `updated_by = auth.email()`.
3. **Concurrencia**: last-writer-wins. Si dos miembros editan a la vez, gana el último guardado (debounce 600 ms). Sin realtime — para 4 admins editando documentación operativa es suficiente.
4. **Offline / fallo Supabase**: si la red falla, cae a cache `localStorage` en modo lectura con toast "Sin conexión Supabase". El editor sigue funcionando localmente pero el `Guardado ✓` no aparece hasta recuperar conexión.
5. **Export/Import**: siguen disponibles. Export descarga el estado actual (lo que viene de Supabase). Import sube el JSON cargado a Supabase (overwrite, afecta a todos los miembros).
6. **Restaurar**: descarta el estado actual en Supabase y vuelve al `SEED` hardcoded en el HTML. Confirmación explícita porque afecta a todos los miembros.

### Schema Supabase

```sql
CREATE TABLE public.casuisticas_board (
  id          text PRIMARY KEY DEFAULT 'global',
  data        jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  text
);
-- trigger update_updated_at() en BEFORE UPDATE
```

RLS habilitado. Policies SELECT/INSERT/UPDATE restringidas a `auth.email() IN (allowlist 4 emails)` — mismo set que `EDITOR_EMAILS` del HTML. GRANTs explícitos a `authenticated` (SELECT, INSERT, UPDATE) y `service_role` (ALL).

### Seed inicial

Casos precargados (octubre 2026) basados en el JSON `casuisticas-2026-05-14.json` aportado por Operaciones. 18 casos en total: 10 en Bolsa de Horas, 7 en Newsletter, 1 en Híbrido, 0 en "Dentro de servicios". 1 caso marcado como duda abierta ("Formulario Meta Ads" — pendiente decidir si entra en bolsa de horas o en servicio de campañas). Sembrados vía migration `casuisticas_board_init` con `updated_by='seed'`.

## Acceso

Misma allowlist que `/playbook/` y `/fichas-de-producto/`:

```js
const EDITOR_EMAILS = new Set([
  "benjamin.sanchis@thenucleo.com",
  "alejandro.lopez@thenucleo.com",
  "marketing.thenucleo@gmail.com",
  "mel.dalmazo@thenucleo.com",
]);
```

Sesión Supabase Auth compartida con `/comunidad/*` (`storageKey: thenucleo-comunidad-auth`). Login en `/comunidad/entrar/?next=/casuisticas/`. Si el email no está en la allowlist, gate "no-admin". Si no hay sesión, gate "anon".

## Nav admin unificado

La auth bar tiene un dropdown con las 4 páginas internas de `work.thenucleo.com`:

- Playbook · `/playbook/`
- Ficha de Cliente · `/ficha-cliente/` (pendiente crear)
- Fichas de Producto · `/fichas-de-producto/`
- **Casuísticas** · `/casuisticas/` (activo en esta página)

El mismo dropdown se replica en cada una de esas páginas marcando la activa con `.nav-active`.

## Arquitectura técnica

- HTML standalone en `casuisticas/index.html` (no pasa por Eleventy).
- Design tokens TheNucleo: NewBlack + paleta dark/light (idéntica a Playbook/Fichas).
- Patrón anti-flicker `locked-mode` para evitar parpadeo al cargar.
- Supabase JS via CDN jsdelivr (`@supabase/supabase-js@2`).
- Lectura de sesión directamente desde `localStorage` (bypass `getSession()` por el bug `GoTrueClient hang` documentado en memoria).

## Pendientes

- **Crear `/ficha-cliente/`** — el link en el dropdown apunta a una página que todavía no existe. El playbook ya tiene panel ficha cliente interno (sidebar 340px), pero falta la página dedicada `/ficha-cliente/` o decidir si se elimina el link.
- **Etiquetas / tags por caso** — sería útil filtrar por sub-categoría (countdown, campaña, fe de erratas, integración…). No prioritario.
- **Realtime (opcional)** — si se vuelve frecuente que 2+ miembros editen simultáneamente, suscribirse a `casuisticas_board` con Supabase Realtime para reflejar cambios en vivo sin recargar. Hoy basta con refrescar manualmente.

## Cross-refs

- [[work/README]] — hub work con todas las páginas internas.
- [[playbook]] — patrón de gate, allowlist y auth bar copiado de aquí.
- [[fichas-de-producto]] — mismo dominio admin, mismo nav unificado tras 2026-05-14.
