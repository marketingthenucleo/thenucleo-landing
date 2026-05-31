# Branding & Sistema de Diseño — TheNucleo

> Guía de referencia del branding: paleta de colores, tipografía, tipologías de elementos y tokens de diseño usados en `work.thenucleo.com`.
> Para el detalle operativo del rollout dark/light en Portal Bubble y las recetas para generar piezas nuevas, ver [`docs/design-tokens.md`](./docs/design-tokens.md).

## ⚠️ Importante: hay DOS paletas distintas

TheNucleo no usa una sola paleta. Conviven dos sistemas de color según la superficie:

| Superficie | Identidad de color | Archivo fuente |
|---|---|---|
| **Landing pública** (`index.html`, legales) | **Cálida** — fondo casi negro + acento **amarillo lima** `#F3F959` + beige `#C7B299` | CSS inline en `index.html` |
| **Comunidad + páginas admin + Portal** (`/comunidad/*`, `/ficha-cliente/`, `/playbook/`, etc.) | **Fría** — fondo azulado oscuro + **verde marca** `#22C55E` + azul `#3B82F6` | `assets/css/comunidad.css` + `docs/design-tokens.md` |

Lo común a ambas: **tipografía única NewBlack**, dark-first, glassmorphism, animaciones con `cubic-bezier(.16,1,.3,1)`, espaciado en múltiplos de 4px.

---

# PARTE 1 — Landing pública (`index.html`)

Tema oscuro monocromático con acentos **amarillo lima + verde**. Glassmorphism, animaciones spring, scroll-jacking 3D (Three.js).

## 1.1 Paleta de colores (`:root`)

### Fondos y superficies
| Token | Valor | Para qué sirve |
|---|---|---|
| `--bg` | `#171717` | Fondo principal de la página |
| `--bg-card` | `rgba(30,30,30,.85)` | Tarjetas con glassmorphism (translúcidas) |
| `--card-solid` | `#1e1e1e` | Versión opaca de tarjeta |
| `--border` | `#2a2a2a` | Bordes por defecto, líneas, divisores |
| `--border-hover` | `#3a3a3a` | Borde al pasar el ratón |

### Texto
| Token | Valor | Para qué sirve |
|---|---|---|
| `--text` | `#E8EAE9` | Texto de cuerpo estándar |
| `--text-bright` | `#ffffff` | Títulos / máximo contraste |
| `--subtle` | `#c8c8c8` | Texto secundario (gris claro-medio) |
| `--muted` | `#8a8a8a` | Hints, labels pequeños, texto desactivado |

### Acentos
| Token | Valor | Para qué sirve |
|---|---|---|
| `--yellow` | `#F3F959` | **Color primario / CTA.** Botones, badges, énfasis `<em>`, nav activo, cursor custom |
| `--yellow-dim` | `rgba(243,249,89,.10)` | Fondo suave amarillo |
| `--yellow-glow` | `rgba(243,249,89,.25)` | Glow / sombras de botón |
| `--yellow-mid` | `rgba(243,249,89,.50)` | Estados intermedios |
| `--accent` | `#C7B299` | **Color secundario (beige).** Kickers, subtítulos, texto "alt", headers de footer |
| `--accent-dim` | `rgba(199,178,153,.12)` | Fondo suave beige |
| `--accent-glow` | `rgba(199,178,153,.25)` | Glow beige |

### Semántica (estados)
| Token | Valor | Para qué sirve |
|---|---|---|
| `--green` | `#22c55e` | Positivo, tendencias ↑, status "online" |
| `--red` | `#ef4444` | Crítico, tendencias ↓, precio tachado |
| `--orange` | `#f59e0b` | Advertencia, estados intermedios |

## 1.2 Tipografía

Familia **única**: `NewBlack` (self-hosted woff2). Las tres variables apuntan a la misma fuente:
- `--mono: 'NewBlack', monospace`
- `--sans: 'NewBlack', sans-serif`
- `--display: 'NewBlack', sans-serif`

| Archivo `@font-face` | Peso |
|---|---|
| `NewBlackTypeface-Medium.woff2` | 500 |
| `NewBlackTypeface-SemiBold.woff2` | 600 |
| `NewBlackTypeface-Bold.woff2` | 700 |

Todas con `font-display: swap`.

**Escala tipográfica (fluida con `clamp`):**
| Uso | Tamaño |
|---|---|
| Título hero | `clamp(46px, 8vw, 96px)` — peso 700 |
| Título de sección | `clamp(28px, 4.5vw, 52px)` |
| Display pequeño | `clamp(24px, 3.5vw, 40px)` |
| Subtítulo largo | `clamp(16px, 2vw, 20px)` |
| Kicker / subtítulo | `clamp(15px, 1.8vw, 18px)` — peso 500 |
| Cuerpo | 14–16px |
| Labels / small | 10–13px |

## 1.3 Border-radius

| Valor | Uso |
|---|---|
| `100px` | Pills / badges / dropdowns |
| `24px` | Caja CTA final |
| `20px` | Tarjetas de pricing |
| `16px` | Tarjetas glass estándar, nav |
| `14px` | FAQ items |
| `12px` | Iconos, elementos pequeños |
| `10px` | Botones (`.btn-primary`, `.btn-ghost`) |
| `8px` | Burger, menú móvil |

## 1.4 Sombras y efectos

- **Nav:** `0 4px 24px rgba(0,0,0,.3)` + borde interior 1px. Al hacer scroll: sombra más profunda.
- **Glass card hover:** `0 20px 48px rgba(0,0,0,.4)` + glow amarillo interior 8%.
- **Laptop showcase (Fase 3):** halo amarillo `0 0 120px -40px rgba(243,249,89,.28)`.
- **Pricing popular:** doble glow amarillo `0 0 36px` + `0 0 80px`.
- **Glassmorphism:** `backdrop-filter: blur(24px) saturate(1.3)` → `blur(28px) saturate(1.6)` en hover.

## 1.5 Animaciones y transiciones

- **Easing default:** `cubic-bezier(.16,1,.3,1)` (spring snappy).
- **Duraciones:** UI `.2–.3s` · estado `.4–.5s` · reveal `.6–.8s` · ambient `2s`.
- **Keyframes:** `fadeUp`, `pulse` (opacidad 1↔.35), `scrollPulse`, `marqueeScroll` (carrusel logos 20s), `seal-shift` (sello holográfico plan anual 5s).
- **Stagger móvil:** delays `0 / .08 / .16 / .24s` por item.

## 1.6 Gradientes

| Gradiente | Definición | Uso |
|---|---|---|
| Progress bar (top) | `linear-gradient(90deg, --yellow, --accent)` | Barra de progreso de scroll |
| Shimmer card | `linear-gradient(90deg, transparent, --yellow, transparent)` | Barrido en hover |
| Glow pricing/CTA | `radial-gradient(circle, rgba(243,249,89,.08), transparent 70%)` | Aura amarilla difusa |
| Sello anual | `linear-gradient(110deg, amarillo↔verde…)` | Efecto prisma holográfico (5s) |

## 1.7 Tipologías de elementos (componentes landing)

- **Progress bar** — fija arriba, 2px, gradiente amarillo→beige, glow.
- **Cursor custom** (solo desktop `hover:hover`) — dot 8px + anillo 36px amarillos; el anillo expande a 56px en hover.
- **Botones** — `.btn-primary` (relleno amarillo), `.btn-ghost` (contorno), `.btn-sm` (nav "Acceder"), `.pricing-cta`. Efecto magnético + lift `translateY(-2px)`.
- **Badges / section-label** — pills amarillas con dot pulsante.
- **Glass cards** — tarjetas de funcionalidades/resultados con blur y shimmer.
- **Pricing cards** — 3 planes (€79 / €205 / €700). La "popular" lleva borde amarillo + glow radial + top line.
- **Laptop showcase** — chrome MacBook 3D (Three.js GLB) con halo amarillo.
- **FAQ** — items expandibles, icono `+` que rota a 45°.
- **Hero scroll hint** — triángulo + "SCROLL" + línea pulsante.
- **Nav burger** — 3 barras → X animado, dropdown glass top-right (móvil ≤900px).

---

# PARTE 2 — Comunidad / Admin / Portal (`comunidad.css` + `design-tokens.md`)

Sistema de design tokens **dual dark/light** unificado entre `work.thenucleo.com` y el Portal Bubble. Identidad: **verde marca `#22C55E`**, fondo azulado oscuro, acento azul secundario.

## 2.1 Paleta de colores — tokens `:root` (DARK por defecto)

### Fondos y superficies
| Token | Dark | Light | Para qué sirve |
|---|---|---|---|
| `--bg-base` | `#090a0f` | `#f5f6f8` | Fondo principal de página |
| `--bg-card` | `#12141b` | `#ffffff` | Tarjetas, contenedores |
| `--bg-elevated` | `#1a1d27` | `#ffffff` | Modales, popovers, dropdowns |
| `--bg-hover` | `#1e2130` | `#eef0f4` | Hover sobre filas/items |
| `--bg-active` | `#252836` | `#e4e7eb` | Item seleccionado / pressed |

### Bordes
| Token | Dark | Light | Para qué sirve |
|---|---|---|---|
| `--border-subtle` | `#1e2130` | `#e4e6ec` | Separadores discretos |
| `--border-default` | `#2a2d3e` | `#d0d3dc` | Borde estándar de inputs/cards |
| `--border-strong` | `#363a4e` | `#9ca3af` | Focus, hover de bordes, énfasis |

### Texto
| Token | Dark | Light | Para qué sirve |
|---|---|---|---|
| `--text-primary` | `#edeef3` | `#111827` | Cuerpo, headings, contenido principal |
| `--text-secondary` | `#8b8fa8` | `#4b5563` | Labels, subtítulos, items inactivos |
| `--text-tertiary` | `#5c6078` | `#9ca3af` | Placeholders, hints, metadata |
| `--text-inverse` | `#090a0f` | `#ffffff` | Texto sobre fondos coloreados (acento) |

> **⚠️ Regla del salto de jerarquía (light):** el contraste no es simétrico. `--text-tertiary` sobre fondo blanco queda casi invisible. En light, los textos sobre blanco puro deben usar `--text-secondary` (`#4b5563`); reserva `#9ca3af` solo para textos sobre fondos coloreados o tarjetas, nunca sobre blanco.

### Acentos
| Token | Dark | Light | Para qué sirve |
|---|---|---|---|
| `--accent-primary` | `#22c55e` | `#16a34a` | **Verde marca.** CTA principal, branding |
| `--accent-primary-hover` | `#16a34a` | `#15803d` | Hover del verde |
| `--accent-primary-muted` | `rgba(34,197,94,.12)` | — | Fondo suave verde |
| `--accent-secondary` | `#3b82f6` | `#2563eb` | **Azul.** CTA secundario, info, links |
| `--accent-secondary-hover` | `#2563eb` | — | Hover del azul |
| `--accent-secondary-muted` | `rgba(59,130,246,.12)` | — | Fondo suave azul |
| `--yellow` | `#F3F959` | — | Amarillo legado (solo gradiente del isotipo en nav) |

### Estados semánticos (cada uno con su `-bg` al 10%)
| Token | Valor | Para qué sirve |
|---|---|---|
| `--status-success` | `#22c55e` | Éxito, confirmación (= verde marca) |
| `--status-warning` | `#f59e0b` | Aviso, pendiente (ámbar) |
| `--status-error` | `#ef4444` | Error, destructivo, rechazo |
| `--status-info` | `#3b82f6` | Informativo (= azul) |
| `--status-violet` | `#8b5cf6` | Plantillas, badges especiales |

## 2.2 Tipografía

Misma familia que la landing: **`'NewBlack', sans-serif`** (Medium 500 / SemiBold 600 / Bold 700), self-hosted, `font-display: swap`. La misma fuente cubre rol UI y mono.

**Tamaños habituales:** 13px (nav, botones small, labels) · 14px (cuerpo, inputs) · 16px (títulos de propuesta) · 18px (`.section-h2`) · 20px (título de community card) · 24px (título login).

## 2.3 Border-radius

| Token | Valor | Uso |
|---|---|---|
| `--radius-sm` | `6px` | Botones pequeños, inputs |
| `--radius-md` | `8px` | Inputs, botones medios |
| `--radius-lg` | `12px` | Cards, panels, modales medianos |
| `--radius-xl` | `16px` | Community cards, modales grandes |
| — | `999px` | Pills (filtros, botones redondeados) |

## 2.4 Sombras

- **Nav glass:** `0 4px 24px rgba(0,0,0,.4)` + borde interior + `backdrop-filter: blur(28px) saturate(1.4)`.
- **Card hover:** `0 12px 40px rgba(0,0,0,.3)`.
- **Modal:** `0 24px 64px rgba(0,0,0,.5)`.
- **Botón hover:** `0 6px 20px rgba(34,197,94,.25)` (glow verde).
- **Overlay:** `rgba(0,0,0,.55)` + `backdrop-filter: blur(4px)`.

## 2.5 Animaciones y transiciones

| Token | Valor | Uso |
|---|---|---|
| `--ease-out` | `cubic-bezier(0.16, 1, 0.3, 1)` | Easing estándar |
| `--duration-fast` | `150ms` | Hover rápido |
| `--duration-base` | `200ms` | Transición estándar |
| `--duration-slow` | `300ms` | Modales, entradas |

**Keyframes:** `fadeIn`, `popIn` (scale .95→1 + translateY), `fadeInUp`, `pulse`, `captchaSpin`.
Respeta `prefers-reduced-motion: reduce` (anula duraciones).

## 2.6 Spacing

No hay variables discretas; se usa una **escala en múltiplos de 4px**: `4 · 6 · 8 · 12 · 14 · 16 · 20 · 24 · 28 · 32 · 48 · 56 · 80`px. Valores frecuentes: `8px` (gaps), `14px` (padding inputs/botones), `16–24px` (padding de tarjetas), `48px` (lados de página / columnas footer).

## 2.7 Tipologías de elementos (componentes)

### Públicos (`/comunidad/*`)
- **Community card** (`.community-card`) — las 2 tarjetas de la landing de comunidad (Pool / Referidos). Border-xl, hover eleva sombra y borde.
- **Proposal card** (`.proposal-card`) — item de listado de propuesta: título, descripción 2 líneas, progress bar, footer con votos/comentarios. Estado "liked" (verde) y "disabled".
- **Modal** (`.modal`) — diálogos globales (crear propuesta, auth). Tamaños wide 760 / default 640 / narrow 480px. Body scrollable con scrollbar custom.
- **Auth menu** (`.auth-menu`) — avatar 26px + nombre + caret; dropdown glass con logout.
- **Nav burger** (`.nav-burger`) — hamburguesa móvil 3 barras → X.
- **Footer** — branding + social links 36×36 + columnas de links + status dot verde pulsante.
- **Badges/pills** — `.badge--done` (verde), `--progress` (azul), `--pending` (ámbar), `--blocked` (rojo), `--violet`, `--neutral` (gris).

### Páginas admin (heredan tokens + añaden)
- **Collapsible group** (`.coll-group`) — usado en `/ficha-cliente/`. Header con caret + dot de color + nombre + **badge contador inteligente** `X/N` (verde si completo, ámbar si faltan, `MOCKUP · N` si todo es placeholder).
- **Tab bar** (`.tab-bar`) — pestañas con subrayado azul `--accent-secondary` en activo.
- **Filter bar** (`.filter-bar`) — buscador con foco azul + pills de filtro.
- **Shell del portal** (`/ficha-cliente/`, `/estrategia/`, `/timeline/`) — sidebar fijo 245px (`#111111`) con strip lime `#85DB02` en el item activo, header top 40px con theme toggle + avatar que pinta iniciales/color del usuario.

## 2.8 Sistema dark/light — regla de oro

El tema se controla por `User.theme` (Bubble) ↔ `[data-theme]` (Work), sincronizado vía Supabase:

```
theme = "yes"  →  tokens base (sin sufijo)   →  DARK
theme = "no"   →  tokens con sufijo "-claro" →  LIGHT
NULL (legacy)  →  cae a DARK por defecto
```

Clave en `localStorage`: `thenucleo-theme`.

Para **crear piezas nuevas** con coherencia dark/light (Portal Bubble Conditionals o CSS Work), seguir los **4 patrones canónicos** (A: zebra+hover en listas · B: nav/tabs activo+hover · C: botón+hover · D: plugins sin Conditionals), los **8 anti-patrones** y el checklist documentados en [`docs/design-tokens.md`](./docs/design-tokens.md) → sección "Recetas reutilizables".

---

## Resumen rápido

| | Landing pública | Comunidad / Admin / Portal |
|---|---|---|
| **Fondo** | `#171717` | `#090a0f` (dark) / `#f5f6f8` (light) |
| **Color primario** | `#F3F959` amarillo lima | `#22C55E` verde |
| **Color secundario** | `#C7B299` beige | `#3B82F6` azul |
| **Texto base** | `#E8EAE9` | `#edeef3` (dark) / `#111827` (light) |
| **Tipografía** | NewBlack | NewBlack |
| **Tema** | Solo dark | Dual dark/light |
| **Easing** | `cubic-bezier(.16,1,.3,1)` | `cubic-bezier(.16,1,.3,1)` |
| **Spacing** | múltiplos de 4px | múltiplos de 4px |
