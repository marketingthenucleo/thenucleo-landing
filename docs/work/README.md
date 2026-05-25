---
title: work/ — Cara pública (work.thenucleo.com)
dominio: work
estado: vivo
actualizado: 2026-05-23
tags: [hub, work, publico]
---

# work/ — Cara pública (work.thenucleo.com)

Todo lo que vive en `work.thenucleo.com`. Repo independiente en `thenucleo-landing/` (Vercel). Stack: HTML + Three.js + Eleventy v3.

## Subdominios funcionales

| Subdominio | Estado | Doc | Cuándo consultarlo |
|---|---|---|---|
| **Landing** (`/`) | Vivo | (no doc dedicado — código en `thenucleo-landing/index.html`) | Al tocar hero, pricing, copy. SEO base en `thenucleo-landing/CLAUDE.md` |
| **Pricing** (`/`, parte de landing) | Vivo, reestructurado 2026-04-25 | (no doc dedicado — código en `thenucleo-landing/`) | Al tocar tiers, addons display, Stripe TEST |
| **Blog Zenyx** (`/conocimiento-zenyx`) | Operativo desde 2026-04-19 | [[blog-zenyx]] | Workflow n8n `CNlBtiFCwY69I6Wl`, tabla `blog_videos`, Eleventy |
| **Comunidad** (`/comunidad`) | Vivo desde 2026-04-28 | [[comunidad]] | Tablas `comunidad_*`, Edge Function `comunidad_admin_action`, Auth Google |
| **Playbook** (`/playbook/<bubble_id>`) | Vivo (cuarentena) | [[playbook]] | Tabla `playbook_onboarding`, allowlist editores, modo viewer/editor |
| **Fichas de Producto** (`/fichas-de-producto/`) | Vivo desde 2026-05-13 (admin-only) · rewrite mobile-first 2026-05-22 | [[fichas-de-producto]] | Tablas `fichas_categorias` + `fichas_de_producto`, editor inline tipo Playbook, gate `is_comunidad_admin()` en lectura y edición. Mobile-first 2026-05-22: tabs por categoría (en vez de sidebar), FAB, sheet bottom para nueva cat. |
| **Ficha de Cliente** (`/ficha-cliente/`) | Vivo desde 2026-05-22 (admin-only). **Módulo Pipelines y Campañas** vivo desde 2026-05-23 con seed F1 | [[ficha-cliente]] | Vista mobile-first cableada a `bub_clientes` vía RPCs `ficha_cliente_listar()` + `ficha_cliente_get(p_bubble_id)`. Selector con buscador (sheet bottom). URL deep-link `?id=<bubble_id>`. Allowlist 5 emails TheNucleo. **Pipelines/Campañas** con nomenclatura PxCx, seed F1 hardcoded de Dra. Neuss hasta backend F2. Chip "Pipelines · mockup" retirado 2026-05-23 (el módulo ya no es mockup). Catálogos y Anomalías siguen MOCKUP. |
| **Casuísticas** (`/casuisticas/`) | Vivo desde 2026-05-14 (admin-only) | [[casuisticas]] | Tablero kanban 4 columnas (Bolsa de Horas / Newsletter / Híbrido / Servicios contratados). Persistencia `localStorage`. Sin backend Supabase |
| **Disponibilidades** (`/disponibilidades/`) | Vivo desde 2026-05-20 (admin-only) | [[disponibilidades]] | Calendario disponibilidad laboral del equipo (3 capas: AHORA + HOY + SEMANA). Tablas `disponibilidad_franjas_base` + `disponibilidad_overrides` + `festivos_es`. RLS vía `is_comunidad_admin()`. Pendientes v2: enlace Notion/Google Calendar + self-service con push al PM |

## Nav admin unificado

Las páginas internas de `work.thenucleo.com` comparten un dropdown común en la auth bar (icono 👤) con 5 entradas:

- `/playbook/` — Playbook de onboarding
- `/ficha-cliente/` — Ficha de Cliente (vivo desde 2026-05-22, mobile-first, cableado a `bub_clientes`)
- `/fichas-de-producto/` — Fichas de Producto
- `/casuisticas/` — Tablero de Casuísticas
- `/disponibilidades/` — Calendario disponibilidad equipo

Cualquier página admin-only nueva debe replicar este dropdown (CSS `.nav-user-*` + HTML + JS de toggle). Patrón canónico vive en `casuisticas/index.html` y `playbook/index.html`.

## Repo separado

`thenucleo-landing/` es un repo git independiente con su propio `CLAUDE.md`. Deploy en Vercel. **No mezclar contextos** — al tocar la landing, abrir el repo aparte.

## Cambios recurrentes

- **Blog Zenyx falla:** abre [[blog-zenyx]] → sección "Operaciones comunes".
- **Comunidad: propuesta aprobada no aparece:** abre [[comunidad]] → tabla "Troubleshooting".
- **Stripe TEST → PROD:** ⚠️ bloqueado intencional. No tocar hasta que Ben finalice cuenta Stripe de producción.

## Cross-refs

- **Infraestructura técnica que alimenta Work:** [[supabase-schema]] (tablas `comunidad_*`, `playbook_onboarding`, `blog_videos`), [[n8n-workflows]] (workflow `CNlBtiFCwY69I6Wl` Blog Zenyx).
- **SEO/GEO:** [[ids-referencias]] → Google Search Console + sitemap.
- **Deuda técnica abierta del landing:** [[deuda-tecnica]] — items pendientes (Stripe TEST→PROD, prefers-reduced-motion en Three.js, touch targets, OG image v2, etc.).
