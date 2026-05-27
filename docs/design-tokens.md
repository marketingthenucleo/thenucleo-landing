---
title: Design Tokens — Espejo Bubble ↔ Work
dominio: cross
estado: vivo
actualizado: 2026-05-27 (Fase N+1 light theme portal — Text cerrada + Link saltada. Añadida sección "Recetas reutilizables" con 4 patrones canónicos (zebra+hover / nav-item / botón / plugin terceros Quill RTE) + regla del salto de jerarquía + anti-patrones + checklist para IA. Único pendiente Bubble: 8 built-in)
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

Snapshot 2026-05-27 post-renombre ES. **Custom variables ya creadas con sus pares `-claro`.** Built-in Bubble pendientes de reasignar valor.

### Custom variables (nombres ES finales, 23 dark + 23 claras)

| Token portal | Dark | Claro | Rol semántico | Equivalencia work |
|---|---|---|---|---|
| `fondo-base` | `#090A0F` | `#F5F6F8` | Fondo principal de la página | `--bg` |
| `fondo-tarjeta` | `#12141B` | `#FFFFFF` | Fondo de tarjetas y contenedores | `--bg-2` |
| `fondo-elevado` | `#1A1D27` | `#FFFFFF` | Modales, popovers, dropdowns | (usa `--bg-2`) |
| `fondo-hover` | `#1E2130` | `#EEF0F4` | Hover sobre filas/items | `--bg-hover` |
| `fondo-activo` | `#252836` | `#E4E7EB` | Item seleccionado/pressed | (sin equiv) |
| `borde-sutil` | `#1E2130` | `#E4E6EC` | Separadores discretos | `--line` |
| `borde-medio` | `#2A2D3E` | `#D0D3DC` | Borde estándar inputs/cards | `--line-2` |
| `borde-fuerte` | `#363A4E` | `#9CA3AF` | Focus, énfasis visual | (sin equiv) |
| `texto-primario` | `#EDEEF3` | `#111827` | Body, headings | `--text` |
| `texto-secundario` | `#8B8FA8` | `#4B5563` | Labels, subtítulos | `--text-2` |
| `texto-terciario` | `#5C6078` | `#9CA3AF` | Placeholders | `--text-3` |
| `texto-inverso` | `#090A0F` | `#FFFFFF` | Texto sobre fondos coloreados | (sin equiv) |
| `acento-primario` | `#22C55E` | `#16A34A` | CTA principal, brand verde | `--accent` |
| `acento-primario-hover` | `#16A34A` | `#15803D` | Hover del primario | `--accent-dim` |
| `acento-secundario` | `#3B82F6` | `#2563EB` | CTA azul, identidad sutil | `--info` |
| `acento-secundario-hover` | `#2563EB` | `#1D4ED8` | Hover del azul | (sin equiv) |
| `exito` | `#22C55E` | `#16A34A` | Confirmaciones | `--ok` |
| `aviso` | `#F59E0B` | `#D97706` | Ámbar, pendientes | `--warn` |
| `error` | `#EF4444` | `#DC2626` | Destructivo | `--bad` |
| `info` | `#3B82F6` | `#2563EB` | Informativo | `--info` |
| `neutro` | `#6B7280` | `#9CA3AF` | Disabled, decorativos | (sin equiv) |
| `violeta` | `#8B5CF6` | `#7C3AED` | Plantillas, badges especiales | `--violet` |
| `rosa` | `#EC4899` | `#DB2777` | Highlights ocasionales | (sin equiv) |

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
| **Work — CSS vars dark + light** | 17 tokens implementados en `ficha-cliente/index.html`, `estrategia/index.html`, `timeline/index.html`. Toggle persiste en `localStorage` (clave unificada `thenucleo-theme` desde 2026-05-27; migración one-shot desde el viejo `thenucleo-ficha-cliente-theme`). | ✅ Vivo desde 2026-05-26 |
| **Portal — Backend Fase 0** | Campo `User.theme` (yes/no) en Bubble + `bub_user.theme boolean` espejo + RPC `work_current_user_profile()` v3 con `theme`. | ✅ Cerrada 2026-05-27 |
| **Portal — Color variables ES** | 23 dark renombradas + 23 claras creadas (suffix `-claro`) + 8 built-in Bubble pendientes reasignar. Toggle Bubble cableado (`Make changes to Current User → theme = Current User's theme is "no"`). | ✅ Cerrada 2026-05-27 |
| **Portal — Conditionals por categoría** | 18 categorías cerradas: Button (5) · Date/Time Picker (3) · Dropdown · File Uploader · Floating Group · Group (10) · Group Focus (saltada) · Icon · Input · Multi dropdown · Multi-File · Multiline · Page · Picture Uploader · Popup · Progress Bar · Rich Text Input · Search Box · Shape (saltada) · Slider Input (saltada) · Radio Buttons (saltada) · Repeating Group (saltada) · Link (saltada — sin uso) · **Text** (cerrada 2026-05-27 sesión tarde). **Único pendiente: Built-in Bubble.** | 🔄 En curso |
| **Portal — Built-in Bubble reasignar** | Primary/Surface/Background/Destructive/Success/Alert/Text/Primary contrast con valores incoherentes (Surface=#FFFFFF en dark, etc.). Reasignar a custom equivalentes en pasada final. | ⏸ Pendiente |
| **Sincronización portal ↔ work** | RPC `work_set_my_theme(p_theme boolean)` (UPDATE Supabase con allowlist x5) + Edge Function `sync_theme_to_bubble` (PATCH Bubble Data API). Los 3 HTML work leen `theme` del response de `work_current_user_profile()` al boot, aplican el DB-value si difiere del localStorage, y persisten ambos lados al toggle (debounce 500ms, degradación graceful si Bubble falla). | ✅ Cerrada 2026-05-27 — pendiente `BUBBLE_API_TOKEN` en Supabase Dashboard para el rollout |

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

### ⚠️ Bug crítico recurrente — hex literal vs referencia a variable

Si un Style tiene una propiedad con **hex pintado directamente** (`#2A2D3E`) en vez de **referencia a variable** (`borde-medio`), el theme switch **no funciona** sobre esa propiedad por mucho Conditional `theme is "no"` que añadas. Bubble considera el hex literal "no temable".

**Cómo lo cazas:** abre cada Style y mira si el selector de color muestra un **nombre de variable** o un **hex con #**. Si es hex y coincide con una variable existente, reasigna (click sobre el selector → elige la variable). Si no coincide, decide: ¿es un valor único que merece variable nueva, o se aproxima a alguna existente?

Detectado primero en `Secciones Principales` (Group): tenía `#2A2D3E` (borde-medio) y `#252836` (fondo-activo) como literales. Aplica a cualquier categoría — verificar siempre antes de pintar Conditional.

### Inventario de Styles del portal (snapshot 2026-05-27)

Por categoría, en orden alfabético del Design tab. Formato compacto por Style: nombre ES + (nombre original si renombrado) + Visual targets + Conditionals.

**Notación corta:** `property: <token-dark> → <token-claro>`. Si el Conditional `theme is "no"` tiene varias properties, todas se reúnen bajo el mismo Conditional. Hover combinado va aparte como `hover + theme is "no"`.

#### Alert · CSS Tools · HTML · Image · Map · Material Icon · Video — saltadas

No se usan en el portal o no son Styles visuales.

#### Button (5 Styles) — ✅ cerrada

**Boton Peligro** *(antes Button_Danger)*
- Background: `error` → `error-claro` (solid, sin gradient)
- Text · Icon: `texto-inverso` → `texto-inverso-claro`
- Border: none

**Boton Fantasma** *(antes Button_Ghost)*
- Background: none
- Text · Icon: `texto-primario` → `texto-primario-claro`
- Border: 1px `borde-medio` → `borde-medio-claro`
- Hover bg: `fondo-hover` → `fondo-hover-claro`

**Boton Primario** *(antes Button_Primary)*
- Background: `acento-primario` → `acento-primario-claro`
- Text · Icon: `texto-inverso` → `texto-inverso-claro`
- Border: none
- Hover bg: `acento-primario-hover` → `acento-primario-hover-claro`

**Boton Secundario** *(antes Button_Secondary)*
- Background: `fondo-tarjeta` → `fondo-tarjeta-claro`
- Text · Icon: `texto-primario` → `texto-primario-claro`
- Border: 1px `borde-medio` → `borde-medio-claro`
- Hover bg: `fondo-hover` → `fondo-hover-claro`

**Boton Sutil** *(antes Premium Button — identidad azul)*
- Background: `fondo-elevado` → `fondo-elevado-claro`
- Text · Icon: `texto-primario` → `texto-primario-claro`
- Border: 1px `acento-secundario` → `acento-secundario-claro`
- Hover bg: `fondo-hover` → `fondo-hover-claro`

#### Checkbox — saltada (sin styles custom)

#### Date/Time Picker (3 Styles) — ✅ cerrada

**Selector Fecha/Hora** *(antes Standard date/time picker)*
- Background: `fondo-tarjeta` → `fondo-tarjeta-claro`
- Text: `texto-primario` → `texto-primario-claro`
- Icon: `texto-secundario` → `texto-secundario-claro`
- Border: 1px `borde-medio` → `borde-medio-claro`
- Focus/Hover border: `borde-fuerte` → `borde-fuerte-claro`

**Celda Calendario** *(antes date_table_cell)*
- Background: none
- Text: `texto-primario` → `texto-primario-claro`
- Hover bg: `fondo-hover` → `fondo-hover-claro`
- Selected/current day bg: `acento-primario` → `acento-primario-claro`
- Selected text: `texto-inverso` → `texto-inverso-claro`

**Selector Fecha/Hora Sutil** *(antes Premium date/time picker — identidad azul)*
- Igual que Selector Fecha/Hora + Border azul `acento-secundario` → `acento-secundario-claro`

#### Dropdown — ✅ cerrada

**Desplegable** *(antes Standard dropdown)*
- Background: `fondo-tarjeta` → `fondo-tarjeta-claro`
- Text: `texto-primario` → `texto-primario-claro`
- Icon (chevron): `texto-secundario` → `texto-secundario-claro`
- Border: 1px `borde-medio` → `borde-medio-claro`
- Focus/Hover border: `borde-fuerte` → `borde-fuerte-claro`

#### File Uploader — ✅ cerrada

**Subir Archivo** *(antes Standard file uploader)*
- Background: `fondo-tarjeta` → `fondo-tarjeta-claro`
- Text: `texto-primario` → `texto-primario-claro`
- Icon (upload): `texto-secundario` → `texto-secundario-claro`
- Border: 1px **dashed** `borde-medio` → `borde-medio-claro`
- Hover/drag bg: `fondo-hover` → `fondo-hover-claro`
- Hover/drag border: `borde-fuerte` → `borde-fuerte-claro`

#### Floating Group — ✅ cerrada

**Grupo Flotante** *(antes Standard floating group)*
- Background: `fondo-tarjeta` → `fondo-tarjeta-claro`
- Border: none o 1px `borde-sutil` → `borde-sutil-claro`

#### Group (10 Styles) — ✅ cerrada

Patrón compacto por Style. Todos llevan la misma estructura: 1 Conditional `theme is "no"` con las properties pintadas en claro.

| Style ES | Original | Background | Border | Text/Icon dentro |
|---|---|---|---|---|
| **Tarjeta Sutil** | `Cards Premium` | `fondo-elevado` → `fondo-elevado-claro` | 1px `acento-secundario` → `acento-secundario-claro` | — |
| **Columna Kanban** | `Col_kanban_tareas` | `fondo-tarjeta` → `fondo-tarjeta-claro` | 1px `borde-sutil` → `borde-sutil-claro` | — |
| **Encabezado Kanban** | `Encabezado Kanban` | `fondo-elevado` → `fondo-elevado-claro` | — | — |
| **Fondo Iconos** | `Fondo Iconos` | `fondo-elevado` → `fondo-elevado-claro` | — | — |
| **Fondo General** | `Fondo_General` | `fondo-base` → `fondo-base-claro` | — | — |
| **Tarjeta KPI Coloreada** | `Group_KPI_Tarjeta_Coloreada` | `acento-secundario` → `acento-secundario-claro` *(asumido azul)* | — | `texto-inverso` → `texto-inverso-claro` |
| **Panel** | `Group_Panel` | `fondo-tarjeta` → `fondo-tarjeta-claro` | 1px `borde-sutil` → `borde-sutil-claro` | — |
| **Panel Legacy** | `Group_Panel (Legacy)` | mismo Panel *(o borrar si "Find elements in use" = 0)* | mismo Panel | — |
| **Secciones Principales** | `Secciones Principales` | `fondo-elevado` → `fondo-elevado-claro` | 1px `borde-medio` → `borde-medio-claro` | — |
| **Tarjeta** | `Tarjeta` | `fondo-tarjeta` → `fondo-tarjeta-claro` | 1px `borde-sutil` → `borde-sutil-claro` | — |

#### Group Focus — saltada (sin styles custom)

#### Icon (1 Style) — ✅ cerrada

**Icono estandar** *(ya estaba en ES)*
- Color: `texto-primario` → `texto-primario-claro`

#### Input (1 Style) — ✅ cerrada

**Campo de Texto** *(refactor completo: hex → variables + Border `Gray 70 DELETED` huérfano reasignado a `borde-medio`)*
- Background: `fondo-elevado` → `fondo-elevado-claro` *(antes `#252836` raw)*
- Text: `texto-primario` → `texto-primario-claro` *(antes `#FFFFFF` raw)*
- Placeholder: `texto-terciario` → `texto-terciario-claro` *(antes `#FFFFFF 70%` raw)*
- Border: 1px `borde-medio` → `borde-medio-claro` *(antes `Gray 70 DELETED` huérfano)*
- Focus border: `borde-fuerte` → `borde-fuerte-claro`

#### Link — saltada (sin uso en el portal)

Ben no usa el Style Link en el portal a fecha 2026-05-27 (decisión sesión tarde). Sin elementos atados → no requiere Conditional. Plantilla canónica anotada por si en el futuro se introduce:

- Color base: `acento-secundario` → claro `acento-secundario-claro`
- Hover combinado: `acento-secundario-hover` → `acento-secundario-hover-claro`

#### Multi dropdown (1 Style) — ✅ cerrada

**Desplegable Múltiple** — coherente con `Campo de Texto`:
- Background: `fondo-elevado` → `fondo-elevado-claro`
- Text: `texto-primario` → `texto-primario-claro`
- Placeholder: `texto-terciario` → `texto-terciario-claro`
- Icon (chevron): `texto-secundario` → `texto-secundario-claro`
- Border: 1px `borde-medio` → `borde-medio-claro`
- Focus border: `borde-fuerte` → `borde-fuerte-claro`

> **Nota deuda menor:** `Desplegable` (single) quedó con `fondo-tarjeta` y `Desplegable Múltiple` con `fondo-elevado`. Decidir si unificar a `fondo-elevado` en próxima pasada (los inputs de formulario llevan `fondo-elevado`; Dropdown debería igualar). Aún no decidido.

#### Multi-File Uploader (1 Style) — ✅ cerrada

**Subir Archivos Múltiples** — idéntico a `Subir Archivo`:
- Background: `fondo-tarjeta` → `fondo-tarjeta-claro`
- Text: `texto-primario` → `texto-primario-claro`
- Icon: `texto-secundario` → `texto-secundario-claro`
- Border: 1px **dashed** `borde-medio` → `borde-medio-claro`
- Hover/drag bg: `fondo-hover` → `fondo-hover-claro`
- Hover/drag border: `borde-fuerte` → `borde-fuerte-claro`

#### Multiline Input (1 Style) — ✅ cerrada

**Área de Texto** — idéntico a `Campo de Texto`:
- Background: `fondo-elevado` → `fondo-elevado-claro`
- Text: `texto-primario` → `texto-primario-claro`
- Placeholder: `texto-terciario` → `texto-terciario-claro`
- Border: 1px `borde-medio` → `borde-medio-claro`
- Focus border: `borde-fuerte` → `borde-fuerte-claro`

#### Page (1 Style) — ✅ cerrada

**Página**
- Background: `fondo-base` → `fondo-base-claro`

#### Picture Uploader (1 Style) — ✅ cerrada

**Subir Imagen** — idéntico a `Subir Archivo`:
- Background: `fondo-tarjeta` → `fondo-tarjeta-claro`
- Text: `texto-primario` → `texto-primario-claro`
- Icon: `texto-secundario` → `texto-secundario-claro`
- Border: 1px **dashed** `borde-medio` → `borde-medio-claro`
- Hover/drag bg: `fondo-hover` → `fondo-hover-claro`
- Hover/drag border: `borde-fuerte` → `borde-fuerte-claro`

#### Popup (1 Style) — ✅ cerrada

**Modal**
- Background: `fondo-elevado` → `fondo-elevado-claro`
- Border (si tiene): 1px `borde-sutil` → `borde-sutil-claro`

#### Progress Bar (1 Style) — ✅ cerrada

**Barra de Progreso**
- Inactive bar (track): `fondo-elevado` → `fondo-elevado-claro`
- Active bar (fill): `acento-primario` → `acento-primario-claro`

#### Radio Buttons — saltada por Ben

#### Repeating Group — saltada por Ben

#### Rich Text Input (1 Style) — ✅ cerrada

**Editor Enriquecido** — coherente con `Campo de Texto` y `Área de Texto`:
- Background: `fondo-elevado` → `fondo-elevado-claro`
- Text: `texto-primario` → `texto-primario-claro`
- Placeholder: `texto-terciario` → `texto-terciario-claro`
- Border: 1px `borde-medio` → `borde-medio-claro`
- Focus border: `borde-fuerte` → `borde-fuerte-claro`

> ⚠️ Si la toolbar (B/I/U/list/link) es Style aparte, pendiente de documentar al retomar.

#### Search Box (1 Style) — ✅ cerrada

**Buscador** — coherente con `Campo de Texto` + icon lupa:
- Background: `fondo-elevado` → `fondo-elevado-claro`
- Text: `texto-primario` → `texto-primario-claro`
- Placeholder: `texto-terciario` → `texto-terciario-claro`
- Icon (lupa): `texto-secundario` → `texto-secundario-claro`
- Border: 1px `borde-medio` → `borde-medio-claro`
- Focus border: `borde-fuerte` → `borde-fuerte-claro`

#### Shape — saltada por Ben *(plantilla canónica documentada para uso futuro)*

Si vuelves a abrir Shape:
- Separator: bg `borde-sutil` → `borde-sutil-claro`
- Pill / Badge: bg `fondo-elevado` → `fondo-elevado-claro`, border opcional `borde-medio` → `borde-medio-claro`
- Dot neutral: `texto-terciario` → `texto-terciario-claro`
- Dot éxito: `acento-primario` → `acento-primario-claro`
- Dot warning: `aviso` → `aviso-claro`
- Dot error: `error` → `error-claro`
- Dot info: `acento-secundario` → `acento-secundario-claro`

#### Slider Input — saltada por Ben *(plantilla canónica documentada)*

**Deslizador** (si se crea):
- Inactive bar: `fondo-elevado` → `fondo-elevado-claro`
- Active bar: `acento-primario` → `acento-primario-claro`
- Slider handle: `acento-primario` → `acento-primario-claro`

#### Text — ✅ cerrada 2026-05-27 (sesión tarde)

Categoría densa con muchos Styles. Aplicado el patrón canónico en bloque (Visual con tokens semánticos + Conditional `Current User's theme is "no"` con variantes `-claro`). **Sin renombrado y sin fusión** — los Styles están ligados a cientos de elementos, decisión Ben de no tocar nombres ni consolidar duplicados para evitar reasignación masiva.

**Convención de colores aplicada por rol semántico:**

| Rol | Token base (dark) | Token claro |
|---|---|---|
| Body / cuerpo / heading | `texto-primario` | `texto-primario-claro` |
| Label / subtítulo | `texto-secundario` | `texto-secundario-claro` |
| Caption / pista / metadata / placeholder inline | `texto-terciario` | `texto-terciario-claro` |
| Texto sobre acentos coloreados | `texto-inverso` | `texto-inverso-claro` |
| Link inline / texto azul | `acento-secundario` | `acento-secundario-claro` |
| Texto destructivo | `error` | `error-claro` |
| Texto aviso | `aviso` | `aviso-claro` |
| Texto éxito | `exito` | `exito-claro` |
| Texto info | `info` | `info-claro` |

**Lote único documentado al detalle — Body pequeño (11/12/13px, 6 Styles):**

Snapshot del primer grupo que pasó Ben (screenshots panel Visual). El resto de Text (headings, body normal, badges) recibió el mismo tratamiento por rol pero sin inventario nombre-por-nombre. Si en el futuro se requiere auditar el detalle completo, pedir a Ben pase por categoría con screenshots.

| Visual base | Acción | Conditional `theme is "no"` |
|---|---|---|
| 12 · 400 · `#FFFFFF` literal | Reasignar a `texto-primario` *(bug recurrente hex literal)* | Color: `texto-primario-claro` |
| 13 · 400 · `texto-terciario` | — | Color: `texto-terciario-claro` |
| 12 · 500 · `texto-secundario` | — | Color: `texto-secundario-claro` |
| 12 · 400 · `texto-terciario` | — | Color: `texto-terciario-claro` |
| 11 · 400 · `texto-terciario` | — | Color: `texto-terciario-claro` |
| 12 · 600 · `texto-secundario` | — | Color: `texto-secundario-claro` |

**Deuda menor registrada:** 3 Styles funcionalmente idénticos en el lote pequeño (12 · 400 · `texto-terciario`, antes con tamaños distintos 11/12/13 que se mantienen separados). No se fusionan porque cada uno arrastra ~cientos de elementos. Si en limpieza futura se hace pase "Find elements in use", el menos usado se puede absorber.

#### Built-in Bubble (8) — ⏸ PENDIENTE SUB-FASE FINAL

Hoy siguen con sus valores iniciales incoherentes:
- `Primary = #EDEEF3` (debería ser `acento-primario` #22C55E)
- `Primary contrast = #FFFFFF` (OK, mantener)
- `Text = #EDEEF3` (OK, alias de `texto-primario`)
- `Surface = #FFFFFF` (⚠️ en dark debería ser `fondo-tarjeta` #12141B)
- `Background = #FFFFFF` (⚠️ debería ser `fondo-base` #090A0F)
- `Destructive = #B0200C` (debería alinear con `error` #EF4444)
- `Success = #1E6C30` (debería alinear con `exito` #22C55E)
- `Alert = #DCA114` (debería alinear con `aviso` #F59E0B)

Bubble usa estas built-in internamente para widgets default que NO tienen Style custom asignado. Si todos los elementos del portal tienen Style custom, las built-in nunca se ven. Pero si algún elemento queda "Style: none", Bubble cae a estos defaults y rompe el theme. **Sub-fase de cleanup pendiente.**

#### Built-in Bubble (8) — pendiente sub-fase final

Ver tabla más arriba en "Built-in Bubble (las que vienen con el sistema)". Reasignar a custom equivalente (`Primary` → verde, `Surface` → fondo-tarjeta, `Background` → fondo-base, etc.) tras pintar todas las categorías custom.

## Recetas reutilizables — patrones canónicos por componente

> Esta sección consolida los patrones validados durante el rollout para reutilizarlos al **crear nuevas piezas** (portal Bubble + páginas admin work). **Si una IA está generando algo nuevo, debería leer esta sección antes de empezar.** Las reglas aquí provienen de bugs reales cazados durante el rollout 2026-05-27.

### Regla de oro: la lógica de theme

| Estado del campo | Significado | Tokens a usar |
|---|---|---|
| `Current User's theme is "no"` | LIGHT theme activo | sufijo `-claro` (Bubble) o `[data-theme="light"]` (work) |
| `Current User's theme is "yes"` | DARK theme activo | tokens base sin sufijo |
| `empty / NULL` | Cae a DARK por defecto | tokens base sin sufijo |

**Mnemónico:** *"is no = -claro siempre"*. Si el token del THEN **no acaba en `-claro`** cuando el WHEN dice `theme is "no"`, está **invertido**. El error más recurrente del rollout.

### Patrón A — Repeating Group cell con zebra + hover

Usa cuando el cell tiene un Style global (ej. `Panel`) que ya maneja el theme del visual base. Las inline solo añaden estados especiales.

**Visual base (heredado del Style global):** no se toca.

**4 Conditionals inline, este orden exacto:**

| # | WHEN | THEN Background |
|---|---|---|
| 1 | `(Current cell's index modulo 2) is 1` | `fondo-hover` *(zebra dark)* |
| 2 | `((Current cell's index modulo 2) is 1) AND Current User's theme is "no"` | `fondo-hover-claro` *(zebra light)* |
| 3 | `This Group is hovered` | `fondo-activo` *(hover dark, ilumina)* |
| 4 | `This Group is hovered AND Current User's theme is "no"` | `fondo-activo-claro` *(hover light, oscurece)* |

**Por qué este orden:** Bubble evalúa top-down y gana la última coincidencia. Las combinadas con AND siempre AL FINAL de su par. Hover gana a zebra porque es estado más prioritario UX.

**Aplicado en:** "Group encabezados plantillas" (cell de Repeating Group) 2026-05-27.

### Patrón B — Nav item / Tab con activo + hover + theme

El Style global maneja el estado **inactivo** (visual base + Conditional theme). Las inline manejan **activo** y **hover**.

**Style global (`Text_Nav_Item` y equivalentes):**

- Visual base · Font color: `texto-secundario` *(gris medio dark, legible pero discreto)*
- Conditional `theme is "no"` · Font color: `texto-secundario-claro` *(no `texto-terciario-claro` — ver "Regla del salto de jerarquía" abajo)*

**4 Conditionals inline en el elemento (texto del tab):**

| # | WHEN | THEN Font color |
|---|---|---|
| 1 | `<condición de hover sobre este item>` | `texto-primario` |
| 2 | `<condición de item activo>` | `texto-primario` |
| 3 | `(<hover>) AND Current User's theme is "no"` | `texto-primario-claro` |
| 4 | `(<activo>) AND Current User's theme is "no"` | `texto-primario-claro` |

**Notas:**
- Hover y activo usan el mismo token (`texto-primario`). Si quieres diferenciar visualmente: hover → `texto-secundario` (intermedio), activo → `texto-primario` (fuerte). Decisión UX, no de theme.
- NO repitas `theme is "no"` sin más condiciones inline cuando el Style global ya lo cubre. Es redundante.

**Aplicado en:** "Text General" (tabs General/Tareas/Editar/Estrategia/Timeline del sidebar work) 2026-05-27.

### Patrón C — Botón / elemento simple con hover

Generalizable a cualquier elemento con hover sin lógica adicional.

**Visual base:** tokens dark (color base + hover si aplica).

**2 Conditionals inline:**

| # | WHEN | THEN |
|---|---|---|
| 1 | `Current User's theme is "no"` | properties → tokens `-claro` |
| 2 | `This Button is hovered AND Current User's theme is "no"` | property hover → token `hover-claro` |

**Orden:** la combinada AND siempre al final.

### Regla del salto de jerarquía (clave para textos en light)

Lo que en dark es `texto-terciario` (#5C6078 gris claro discreto sobre fondo oscuro) **NO mapea simétricamente** a `texto-terciario-claro` (#9CA3AF gris claro) en light. **El contraste no es simétrico sobre fondo blanco** — el mismo nivel de gris queda casi invisible.

**Mapeo correcto entre niveles de jerarquía:**

| Dark token | Light token correcto | Cuándo usar |
|---|---|---|
| `texto-primario` (#EDEEF3) | `texto-primario-claro` (#111827) | Body, headings, contenido principal |
| `texto-secundario` (#8B8FA8) | `texto-secundario-claro` (#4B5563) | Labels, subtítulos, items inactivos navegación |
| `texto-terciario` (#5C6078) | **`texto-secundario-claro`** (#4B5563) ⚠️ subir 1 nivel | Si el texto va sobre **fondo blanco puro** |
| `texto-terciario` (#5C6078) | `texto-terciario-claro` (#9CA3AF) | Solo si va sobre **fondos coloreados** (cards, panels, badges) — nunca sobre fondo blanco principal |

**Mnemónico:** *"discreción en light = gris medio, no gris claro"*. Los tonos terciarios solo funcionan en light sobre fondos no-blancos.

**Bug histórico:** tabs inactivos "Tareas / Editar" se veían blanquitos sobre fondo claro porque el Style `Text_Nav_Item` mapeaba dark `texto-terciario` → light `texto-terciario-claro` (#9CA3AF) — corregido a `texto-secundario-claro` (#4B5563).

### Patrón D — Plugin de terceros sin Conditionals (Quill Rich Text Editor)

Patrón para componentes que **no exponen styling via Bubble** (plugins que renderizan widgets propios con CSS/SVG hardcoded). Caso canónico: el plugin RichTextEditor (Quill Snow theme) usado en el popup "Crear notificación" y otros formularios con campos `<textarea>` enriquecidos.

**Diferencia clave con los 3 patrones anteriores:** aquí Bubble no controla nada. La solución es **inyectar CSS global** que reaccione a una clase en `<html>` y sincronizar esa clase manualmente con `Current User's theme`.

#### Arquitectura

```
[Toggle Bubble] → Make changes to User.theme → Run JS (Toolbox):
                                                  localStorage.setItem('thenucleo-theme', X);
                                                  window.dispatchEvent(new Event('thenucleo:theme-change'))
                                                                ↓
                                          Script global (SEO/metatags) escucha el evento
                                                                ↓
                                          document.documentElement.classList.toggle('theme-light' | 'theme-dark')
                                                                ↓
                                          CSS global (SEO/metatags) `html.theme-light .ql-*` aplica
```

#### Setup (3 pasos)

**1. Settings → SEO/metatags → "Script/meta tags in header"** (carga 1 vez, sin re-render):

```html
<script>
  (function () {
    function apply() {
      var t = localStorage.getItem('thenucleo-theme') || 'dark';
      var root = document.documentElement;
      root.classList.toggle('theme-light', t === 'light');
      root.classList.toggle('theme-dark',  t === 'dark');
    }
    apply();
    window.addEventListener('storage', apply);
    window.addEventListener('thenucleo:theme-change', apply);
  })();
</script>

<style>
  /* Quill RTE — theme-aware con !important para vencer estilos inline del plugin */
  html.theme-dark .ql-toolbar.ql-snow,
  html.theme-dark .ql-container.ql-snow {
    background: #12141b !important;          /* = fondo-tarjeta */
    border-color: rgba(255,255,255,.12) !important;
  }
  html.theme-dark .ql-editor              { color: #edeef3 !important; background: transparent !important; }
  html.theme-dark .ql-editor.ql-blank::before { color: rgba(255,255,255,.45) !important; font-style: normal !important; }
  html.theme-dark .ql-toolbar .ql-stroke,
  html.theme-dark .ql-toolbar .ql-stroke-miter { stroke: #edeef3 !important; }
  html.theme-dark .ql-toolbar .ql-fill    { fill: #edeef3 !important; }
  html.theme-dark .ql-toolbar .ql-picker  { color: #edeef3 !important; }
  html.theme-dark .ql-toolbar .ql-picker-options {
    background: #12141b !important; color: #edeef3 !important;
    border: 1px solid rgba(255,255,255,.12) !important;
  }

  html.theme-light .ql-toolbar.ql-snow,
  html.theme-light .ql-container.ql-snow {
    background: #ffffff !important;           /* = fondo-tarjeta-claro */
    border-color: #e5e7eb !important;
  }
  html.theme-light .ql-editor             { color: #1a1a1a !important; background: transparent !important; }
  html.theme-light .ql-editor.ql-blank::before { color: #9ca3af !important; font-style: normal !important; }
  html.theme-light .ql-toolbar .ql-stroke,
  html.theme-light .ql-toolbar .ql-stroke-miter { stroke: #1a1a1a !important; }
  html.theme-light .ql-toolbar .ql-fill   { fill: #1a1a1a !important; }
  html.theme-light .ql-toolbar .ql-picker { color: #1a1a1a !important; }
  html.theme-light .ql-toolbar .ql-picker-options {
    background: #ffffff !important; color: #1a1a1a !important;
    border: 1px solid #e5e7eb !important;
  }

  /* Hover + activo: acento verde brand en ambos temas */
  .ql-toolbar button:hover .ql-stroke,
  .ql-toolbar button.ql-active .ql-stroke,
  .ql-toolbar .ql-picker-label:hover .ql-stroke,
  .ql-toolbar .ql-picker-label.ql-active .ql-stroke { stroke: #85DB02 !important; }
  .ql-toolbar button:hover .ql-fill,
  .ql-toolbar button.ql-active .ql-fill { fill: #85DB02 !important; }
</style>
```

**2. Workflow "activar light tema"** (acción Run javascript del plugin Toolbox, al final):
```js
localStorage.setItem('thenucleo-theme', 'light');
window.dispatchEvent(new Event('thenucleo:theme-change'));
```

**3. Workflow "activar dark tema"** (idéntico con `'dark'`):
```js
localStorage.setItem('thenucleo-theme', 'dark');
window.dispatchEvent(new Event('thenucleo:theme-change'));
```

#### Por qué no funciona el patrón A/B/C aquí

- **El plugin envuelve un Quill** que renderiza SVG inline con `stroke="currentColor"` heredando el color del contenedor. En dark hereda blanco, en light también → invisible sobre fondo blanco.
- **Las Conditionals de Bubble no llegan** al interior del shadow del widget. Bubble solo controla wrapper, no contenido del plugin.
- **El `Current User's theme` no se propaga al DOM como clase** automáticamente. El portal aplica colores via Conditionals por elemento, no via clase global en `<html>` o `<body>`. Por eso necesitamos crear esa señal manualmente con localStorage + classList.

#### Reglas adicionales para este patrón

- **`!important` obligatorio** en propiedades visuales. El plugin inyecta inline styles que de otra forma ganan.
- **Selector con doble clase** (`.ql-toolbar.ql-snow`) para mayor especificidad sobre los defaults del tema Snow de Quill.
- **No mezcles con el viejo scope** `#editor-blanco` que apuntaba a un editor concreto: el nuevo enfoque es global. Si tienes leftovers de ese ID en CSS local del popup, bórralos para evitar conflictos de especificidad.
- **Único trade-off conocido:** en device nuevo con localStorage vacío, el primer paint cae al fallback `'dark'`. Si la DB dice light, hay flash de 1 frame antes de que el siguiente toggle (o un hidratador opcional en "Page is loaded") corrija. Aceptable para casos borde.

**Aplicado en:** popup "Crear notificación" (Quill RTE) y cualquier otro RTE del portal, desde 2026-05-27.

### Anti-patrones a evitar (cazados durante el rollout)

1. **Asociar `theme is "no"` con tokens DARK** (sin `-claro`). Inversión lógica clásica. La regla es siempre: `is no` ↔ `-claro`.
2. **Conditionals duplicadas** con misma WHEN. Bubble gana la última → las anteriores no aplican nunca. Limpiar.
3. **Repetir `theme is "no"` sin más condiciones inline** cuando el Style global ya lo cubre. Redundancia que confunde.
4. **Asumir simetría dark↔light** en niveles de jerarquía de texto. Ver regla del salto.
5. **Hex literal en propiedades** que se quieren temar. Bubble considera literal "no temable" y el Conditional no surte efecto. Reasignar a variable antes (click selector color → elegir variable de la lista).
6. **Fusionar Styles duplicados a lo bruto** cuando arrastran cientos de elementos. Renombrar es seguro (atado por ID interno) pero fusionar requiere reasignación manual elemento a elemento. Documentar deuda y dejar.
7. **Scopear CSS de plugin de terceros a un ID concreto** (`#editor-blanco .ql-...`). Solo arregla un editor — el resto siguen rotos al añadir nuevos popups. Patrón D va por inyección global `html.theme-*` para que cualquier instancia futura herede sin tocar nada.
8. **Asumir que Bubble propaga `Current User's theme` al DOM** como clase. No lo hace. Las Conditionals pintan elementos uno a uno pero no marcan `<html>` ni `<body>`. Para plugins/widgets externos hay que sincronizar manualmente (Patrón D).

### Para trabajar en work HTML admin (ficha-cliente, estrategia, timeline)

Las páginas admin standalone (HTML+CSS inline) usan el mismo patrón pero con CSS variables + `[data-theme="light"]`:

```css
:root {
  --bg: #0A0A0A;        /* dark base */
  --text: #edeef3;
  /* ... 17 tokens ... */
}
[data-theme="light"] {
  --bg: #f5f6f8;        /* overrides */
  --text: #111827;
  /* ... */
}
```

**Reglas al añadir CSS nuevo:**

1. **Usa `var(--token)` SIEMPRE.** Nunca hex literal. Mismo motivo que en Bubble.
2. **Si necesitas un valor nuevo,** añade primero el token a la tabla maestra de este doc + a los 3 archivos HTML (`ficha-cliente/index.html`, `estrategia/index.html`, `timeline/index.html`). Sin entrada en la tabla, no entra en el código.
3. **Aplica la regla del salto de jerarquía** para textos. `--text-3` (placeholder) sobre fondo blanco queda lavado — usa `--text-2` si requiere legibilidad de contenido.
4. **Estados de hover/active:** define ambos tonos en el bloque `[data-theme="light"]` aunque sea el mismo cambio. Consistencia con el rollout Bubble.
5. **Toggle persiste** en `localStorage.thenucleo-ficha-cliente-theme`. JS canónico en [`ficha-cliente/index.html:6009-6020`](../ficha-cliente/index.html). El header de cualquier página nueva debe incluir el `#theme-toggle` + actualización del `<meta name="theme-color">` para chrome del browser.
6. **Equivalencia Bubble↔Work** ya mapeada en la tabla "Discrepancias detectadas entre los dos sistemas" arriba. Cuando se pida algo "que tenga el mismo look que el portal", esa tabla es la fuente.

### Checklist al crear una pieza nueva con IA

Antes de generar HTML/CSS o Conditionals Bubble:

- [ ] ¿He leído la sección "Recetas reutilizables" + tabla maestra de tokens?
- [ ] ¿Estoy usando variables (Bubble) / `var(--token)` (CSS), nunca hex literal?
- [ ] ¿He identificado qué Patrón (A / B / C / D) aplica al componente?
- [ ] ¿He aplicado la regla del salto de jerarquía a los textos que van sobre fondo claro?
- [ ] ¿He ordenado los Conditionals top-down de menos específico a más específico (combinadas AND al final)?
- [ ] ¿He verificado que los WHEN con `theme is "no"` van con tokens `-claro` (sin invertir)?
- [ ] ¿Si es una pieza work, he añadido la toggle persistence + meta theme-color?

## Convenciones de actualización

- **Si tocas un token (cambia el hex)**: actualiza primero la tabla maestra aquí. Luego propaga: 3 archivos en work (`ficha-cliente`, `estrategia`, `timeline`) + N Conditionals en Bubble. Entrada en [[log-cambios]] con tag `[INFRA]` o `[PORTAL][WORK]`.
- **Si añades un Style nuevo en Bubble**: regístralo en el inventario de su categoría aquí (mismo PR/sesión).
- **Si añades una CSS variable nueva en work**: primero añade el token a la tabla maestra; sin entrada aquí, no entra en el código.
- **Si descubres que un valor del light se ve mal en un contexto concreto**: NO inventes un override puntual; ajusta el token aquí y revisa el efecto global. El propósito es coherencia.

## Enlaces

- **CSS en work:** [`ficha-cliente/index.html:19-82`](../ficha-cliente/index.html), [`estrategia/index.html`](../estrategia/index.html), [`timeline/index.html`](../timeline/index.html).
- **Backend Fase 0:** [`docs/infra/supabase-schema.md` — RPC `work_current_user_profile`](infra/supabase-schema.md#work_current_user_profile---perfil-del-user-logueado-avatar-shell).
- **Sync inverso (Fase final):** [`docs/infra/supabase-schema.md` — RPC `work_set_my_theme` + Edge Function `sync_theme_to_bubble`](infra/supabase-schema.md#work_set_my_themep_theme-boolean--escritura-inversa-work--bub_usertheme).
- **Plan completo:** `~/.claude/plans/si-vamos-a-planificarlo-peppy-karp.md`.
- **Log de la Fase 0:** [[log-cambios]] entrada 2026-05-27.
