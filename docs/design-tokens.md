---
title: Design Tokens — Espejo Bubble ↔ Work
dominio: cross
estado: vivo
actualizado: 2026-05-27 (Fase N+1 light theme portal — categoría Button en curso)
tags: [design, tokens, theme, light, dark, bubble, work]
---

# Design Tokens TheNucleo — paleta dual dark/light

Doc canónico cross-domain de la paleta. Mismo set de tokens semánticos aplicado en **portal Bubble** (vía Conditionals sobre Styles) y en **work.thenucleo.com** (vía CSS variables + `[data-theme="light"]` overrides). El propósito: cuando se crea algo nuevo en cualquiera de los dos sitios, esta tabla manda.

## Por qué tokens semánticos y no hex raw

- Un cambio de paleta = editar 1 fila aquí + 1 push a CSS + N Conditionals Bubble. Sin tokens = cazar `#22c55e` por todo el código.
- Nombres semánticos (`bg-card`, `text-primary`) sobreviven re-coloraciones; nombres por color (`bg-dark-181818`) no.
- Mismo nombre en ambos sitios → conversación más limpia: "el bg-card light queda raro en X" en vez de "el blanco roto del fondo de la tarjeta".

## Decisión de arquitectura: dos sistemas paralelos con mapping de equivalencia

Portal Bubble y work tienen **nomenclaturas distintas** de tokens, creadas en momentos distintos y con criterios distintos. No se fuerza equivalencia 1:1 — cada uno preserva su propio sistema, y este doc mantiene la tabla de equivalencia para que cuando trabajemos en uno sepamos qué pintar en el otro.

- **Portal Bubble:** Color variables definidas en `Design → Styles → Color variables` (24 variables custom + 8 built-in Bubble). Snapshot: 2026-05-27.
- **Work:** CSS variables en `:root` + `[data-theme="light"]` en los 3 HTML (`ficha-cliente`, `estrategia`, `timeline`).

## Tabla maestra — Portal Bubble (fuente de verdad para el portal)

Snapshot 2026-05-27. **Las dark son las que ya existen.** Las light se crean en la Fase N+1 (nomenclatura sugerida: suffix `-light`).

### Custom variables (las que Ben definió)

| Token portal | Dark (actual) | Light (Fase N+1 propuesta) | Rol semántico | Equivalencia work |
|---|---|---|---|---|
| `bg-base` | `#090A0F` | `#F5F6F8` | Fondo página global | `--bg` |
| `bg-card` | `#12141B` | `#FFFFFF` | Fondo de cards, panels | `--bg-2` |
| `bg-elevated` | `#1A1D27` | `#FFFFFF` | Card elevado, modal, popover | (sin equiv directo, usa `--bg-2`) |
| `bg-hover` | `#1E2130` | `#EEF0F4` | Hover de rows, items | `--bg-hover` |
| `bg-active` | `#252836` | `#E4E7EB` | Item activo / pressed | (sin equiv, work usa pill `#1a1434`) |
| `border-subtle` | `#1E2130` | `#E4E6EC` | Borde discreto | `--line` |
| `border-default` | `#2A2D3E` | `#D0D3DC` | Borde estándar | `--line-2` |
| `border-strong` | `#363A4E` | `#9CA3AF` | Borde de énfasis | (sin equiv directo) |
| `text-primary` | `#EDEEF3` | `#111827` | Body copy, headings | `--text` |
| `text-secondary` | `#8B8FA8` | `#4B5563` | Labels, subtítulos | `--text-2` |
| `text-tertiary` | `#5C6078` | `#9CA3AF` | Placeholders, metadatos | `--text-3` |
| `text-inverse` | `#090A0F` | `#FFFFFF` | Texto sobre accents claros | (sin equiv directo) |
| `accent-primary (green)` | `#22C55E` | `#16A34A` | CTA primario, brand verde | `--accent` |
| `accent-primary-hover` | `#16A34A` | `#15803D` | Hover del primario | `--accent-dim` |
| `accent-secondary (blue)` | `#3B82F6` | `#2563EB` | CTA secundario azul | `--info` |
| `accent-secondary-hover` | `#2563EB` | `#1D4ED8` | Hover del azul | (sin equiv) |
| `success` | `#22C55E` | `#16A34A` | Éxito | `--ok` |
| `warning` | `#F59E0B` | `#D97706` | Avisos ámbar | `--warn` |
| `error` | `#EF4444` | `#DC2626` | Errores, destructivo | `--bad` |
| `info` | `#3B82F6` | `#2563EB` | Estados info | `--info` |
| `neutral` | `#6B7280` | `#9CA3AF` | Gris medio | (sin equiv) |
| `violet` | `#8B5CF6` | `#7C3AED` | Plantilla, badge violeta | `--violet` |
| `pink` | `#EC4899` | `#DB2777` | Pink accent | (sin equiv) |

### Built-in Bubble (las que vienen con el sistema)

Bubble define 8 tokens semánticos que usa internamente para widgets default. **No se pueden borrar.** En el portal hoy varios tienen valores incoherentes con el resto del sistema dark (ej. `Surface = #FFFFFF` en un portal dark) — herencia de los defaults de Bubble. Sub-fase A del rollout: reasignarlas para que apunten al sistema custom.

| Token built-in | Valor hoy | Reasignar a (dark) | Reasignar a (light) | Por qué |
|---|---|---|---|---|
| `Primary` | `#EDEEF3` | `#22C55E` (= `accent-primary`) | `#16A34A` | "Primary" en Bubble = botón primario; debe matchear el verde brand |
| `Primary contrast` | `#FFFFFF` | `#FFFFFF` o `#090A0F` (= `text-inverse`) | `#FFFFFF` | Texto sobre el accent verde |
| `Text` | `#EDEEF3` | `#EDEEF3` (= `text-primary`) | `#111827` | Texto default |
| `Surface` | `#FFFFFF` | `#12141B` (= `bg-card`) | `#FFFFFF` | Fondo de containers — en dark debe ser dark, no blanco |
| `Background` | `#FFFFFF` | `#090A0F` (= `bg-base`) | `#F5F6F8` | Fondo de página |
| `Destructive` | `#B0200C` | `#EF4444` (= `error`) | `#DC2626` | Unificar con `error` custom |
| `Success` | `#1E6C30` | `#22C55E` (= `success`) | `#16A34A` | Unificar con `success` custom |
| `Alert` | `#DCA114` | `#F59E0B` (= `warning`) | `#D97706` | Unificar con `warning` custom |

## Tabla maestra — Work (fuente de verdad para work)

17 CSS variables en `ficha-cliente/index.html`, `estrategia/index.html`, `timeline/index.html`. Sin cambios respecto al rollout 2026-05-26.

| Token work | Dark | Light | Uso típico |
|---|---|---|---|
| `--bg` | `#0A0A0A` | `#f5f6f8` | `body`, Page Style |
| `--bg-2` | `#181818` | `#ffffff` | Cards, modales |
| `--bg-3` | `#1f1f1f` | `#f5f6f8` | Filas pares, listings |
| `--bg-hover` | `#242424` | `#eef0f4` | Hover items |
| `--line` | `#232323` | `#e4e6ec` | Separators, bordes |
| `--line-2` | `#2e2e2e` | `#d0d3dc` | Bordes hover |
| `--text` | `#edeef3` | `#111827` | Body, headings |
| `--text-2` | `#8b8fa8` | `#4b5563` | Labels |
| `--text-3` | `#5c6078` | `#9ca3af` | Placeholders |
| `--accent` | `#22c55e` | `#16a34a` | CTA primario |
| `--accent-dim` | `#16a34a` | `#15803d` | Hover primario |
| `--warn` | `#f59e0b` | `#d97706` | Avisos |
| `--bad` | `#ef4444` | `#dc2626` | Destructivo |
| `--ok` | `#22c55e` | `#16a34a` | Éxito |
| `--info` | `#3b82f6` | `#2563eb` | Estados info |
| `--violet` | `#8b5cf6` | `#7c3aed` | Plantilla violeta |
| `--header-bg-rgba` | `rgba(10,10,10,0.92)` | `rgba(245,246,248,0.92)` | Header sticky |

> **Origen:** valores en [`ficha-cliente/index.html:19-82`](../ficha-cliente/index.html). Si añades un token nuevo en work, regístralo aquí antes de meterlo en otro archivo.

## Discrepancias detectadas entre los dos sistemas

Algunas convivirán por buenas razones; otras son deuda para alinear. Listado al 2026-05-27:

| Aspecto | Portal | Work | Acción |
|---|---|---|---|
| Fondo card | `#12141B` | `#181818` | Convive. Portal usa azul-grisáceo, work negro puro. Estética distinta intencional. |
| Border sutil | `#1E2130` | `#232323` | Convive. Misma razón. |
| Header sticky con alpha | No definido | `--header-bg-rgba` | Cuando el portal Bubble necesite header con alpha, crear `header-bg-rgba` + `-light`. |
| `bg-elevated`, `bg-active` | Sí | No | Work podría añadirlos si emerge un componente que los pida. No urgente. |
| `pink`, `neutral` extras | Sí | No | Solo portal los usa. No replicar en work salvo necesidad. |
| `--bg-3` sunken | No | Sí | Si portal necesita un tercer nivel de fondo, crear `bg-sunken`. No urgente. |

## Estado del rollout light theme

| Fase | Qué | Estado |
|---|---|---|
| **Work — CSS vars dark + light** | 17 tokens implementados en `ficha-cliente/index.html`, `estrategia/index.html`, `timeline/index.html`. Toggle persiste en `localStorage` (`thenucleo-ficha-cliente-theme`). | ✅ Vivo desde 2026-05-26 |
| **Portal — Backend Fase 0** | Campo `User.theme` (yes/no) en Bubble + `bub_user.theme boolean` espejo + RPC `work_current_user_profile()` v3 con `theme`. | ✅ Cerrada 2026-05-27 |
| **Portal — Fase N+1** Conditionals sobre Styles | Cableado del toggle ✅ (escribe `Current User's theme`). Pintar Conditionals categoría por categoría — ver inventario abajo. | 🔄 En curso 2026-05-27 |
| **Sincronización portal ↔ work** | RPC `work_set_my_theme()` + frontends work leen de la RPC al boot, persisten en Supabase además de localStorage. | ⏸ Pendiente sesión futura |

## Implementación en work (referencia rápida)

CSS variables vivas en `ficha-cliente/index.html`, `estrategia/index.html`, `timeline/index.html` (mismo bloque, duplicado por archivo standalone):

```css
:root {
  --bg: #0A0A0A;
  --bg-2: #181818;
  /* ... 17 tokens en total ... */
}
[data-theme="light"] {
  --bg: #f5f6f8;
  --bg-2: #ffffff;
  /* ... overrides ... */
}
```

Toggle button: `#theme-toggle` (icono moon ↔ sun). JS [`ficha-cliente/index.html:6009-6020`](../ficha-cliente/index.html). Persiste `localStorage.setItem('thenucleo-ficha-cliente-theme', 'dark'|'light')`. Actualiza `<meta name="theme-color">` para la chrome del browser.

**Cuando crees algo nuevo en work:** úsalas como `var(--bg-2)`, NUNCA hardcodees el hex. Si necesitas un valor nuevo (ej. tono de cyan inexistente), añade primero el token a la tabla maestra aquí, luego añade la pareja a los `:root` y `[data-theme="light"]` en los 3 archivos, luego úsalo.

## Implementación en Bubble (Fase N+1, en curso)

### Patrón canónico para cualquier Style

1. Design tab → expande la categoría → click sobre el Style.
2. Pestaña **Conditional** del Style (no del elemento — el Style global, que propaga a todos los elementos que lo usan).
3. Default base = valores **dark** (estado actual del portal, no se toca).
4. **Define another condition**:
   - **When:** `Current User's theme is "no"`
   - **Property to change:** la property → valor **light** de la tabla maestra.
5. Si el Style ya tiene una conditional de **hover**, añade una conditional combinada AND y muévela al final:
   - **When:** `This <Element> is hovered and Current User's theme is "no"`
   - Property: `<hover light>`

### Por qué NULL es seguro

En Bubble, `Current User's theme is "no"` evalúa a **false** cuando el campo está vacío (NULL). Los users existentes (creados antes del campo, hoy 9 con `theme=NULL` en `bub_user`) ven el theme **dark** sin cambio visual. Solo migrarán a light cuando toquen el toggle (el cual escribe explícitamente `no`/`yes` con la action `theme = Current User's theme is "no"`).

### Inventario de Styles del portal (se va rellenando por categoría)

Convención por fila: `Style name` · `Property` · `Dark (base, no se toca)` · `Light (en Conditional)` · `Notas`.

#### Page

_Pendiente — categoría no abordada aún._

#### Group

_Pendiente._

#### Text

_Pendiente._

#### Button

_En curso — 2026-05-27. Esperando a Ben que liste sus Styles de Button con sus colores actuales._

| Style name | Property | Dark (base) | Light (conditional) | Notas |
|---|---|---|---|---|
| _por confirmar_ | _Background color_ | _por confirmar_ | _por confirmar_ | _por confirmar_ |

#### Icon

_Pendiente._

#### Shape

_Pendiente._

#### Input / Multiline Input / Search Box / Date Picker / Dropdown / Multi dropdown / Rich Text Input / Slider Input / Checkbox / Radio Buttons

_Pendiente — todos los controles de formulario en bloque._

#### File Uploader / Multi-File Uploader / Picture Uploader

_Pendiente._

#### Floating Group / Popup / Group Focus

_Pendiente — modales._

#### Repeating Group

_Pendiente._

#### Link / Progress Bar

_Pendiente._

#### Saltados intencionalmente

- **Alert**: no se usa en el portal.
- **CSS Tools, HTML**: no son Styles visuales.
- **Image, Picture Uploader, Video, Map**: transparentes al theme (assets son assets).
- **Material Icon**: deprecado por Iconify.

## Convenciones de actualización

- **Si tocas un token (cambia el hex)**: actualiza primero la tabla maestra aquí. Luego propaga: 3 archivos en work (`ficha-cliente`, `estrategia`, `timeline`) + N Conditionals en Bubble. Entrada en [[log-cambios]] con tag `[INFRA]` o `[PORTAL][WORK]`.
- **Si añades un Style nuevo en Bubble**: regístralo en el inventario de su categoría aquí (mismo PR/sesión).
- **Si añades una CSS variable nueva en work**: primero añade el token a la tabla maestra; sin entrada aquí, no entra en el código.
- **Si descubres que un valor del light se ve mal en un contexto concreto**: NO inventes un override puntual; ajusta el token aquí y revisa el efecto global. El propósito es coherencia.

## Enlaces

- **CSS en work:** [`ficha-cliente/index.html:19-82`](../ficha-cliente/index.html), [`estrategia/index.html`](../estrategia/index.html), [`timeline/index.html`](../timeline/index.html).
- **Backend Fase 0:** [`docs/infra/supabase-schema.md` — RPC `work_current_user_profile`](infra/supabase-schema.md#work_current_user_profile---perfil-del-user-logueado-avatar-shell).
- **Plan completo:** `~/.claude/plans/si-vamos-a-planificarlo-peppy-karp.md`.
- **Log de la Fase 0:** [[log-cambios]] entrada 2026-05-27.
