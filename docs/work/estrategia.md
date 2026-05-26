---
title: Estrategia (admin-only) — `/estrategia/`
dominio: ficha-cliente
estado: vivo
actualizado: 2026-05-25
tags: [ficha-cliente, work, admin, supabase, pipelines, estrategia, subseccion]
---

# Estrategia — `work.thenucleo.com/estrategia/`

Subsección hermana de `/ficha-cliente/` que expone **solo el módulo Pipelines y Campañas** del cliente. Clon temporal del monolito `/ficha-cliente/` (Sprint 1 de la migración a subsecciones por verbo en lugar de paneles dentro de una ficha-saco).

> ✅ **Vivo desde 2026-05-25** en `work.thenucleo.com/estrategia/?id=<bubble_id>`. Mismo allowlist 5 emails, mismo gate auth, mismo client picker, mismo `PIPELINES_MODULE` que `/ficha-cliente/` panel Pipelines.

## URL y entrada

| Recurso | Ubicación |
|---|---|
| URL deep-link | `https://work.thenucleo.com/estrategia/?id=<bubble_id>` |
| URL sin id | `https://work.thenucleo.com/estrategia/` → estado vacío con listado inline de clientes + buscador (mismo patrón que `/ficha-cliente/`) |
| Código frontend | `estrategia/index.html` (raíz del repo, ~4.220 líneas inline) |
| Backend | Supabase project `cbixhqjsnpuhcrcjppah` — RPCs `ficha_cliente_listar`, `ficha_cliente_get`, `ficha_pipelines_get`, + 6 RPCs de write de pipelines (mismo set que ficha-cliente) |

## Motivación de la subsección

`/ficha-cliente/` agrupa 5 paneles (Datos, Servicios, Pipelines, Catálogos, Anomalías) en una sola página. Decisión 2026-05-25: el mental model más limpio es **una subsección por verbo del Cliente**, accesible desde el submenú del Cliente en el portal Bubble. Datos se elimina (su fuente real está en Bubble). Pipelines pasa a ser "Estrategia" como subsección independiente.

Migración por **clone-first**: cada subsección nace como copia pelada de `/ficha-cliente/` con solo su módulo. Cero riesgo de regresión sobre el monolito. Cuando todas las subsecciones (Estrategia + Catálogo + Servicios + Timeline) estén vivas y validadas, `/ficha-cliente/` se eliminará o se convertirá en hub.

## Qué tiene esta página

- Mismo **auth gate** (allowlist 5 emails, redirige a `/comunidad/entrar/?next=/estrategia/...`)
- Mismo **client picker** (sheet bottom + listado inline en estado vacío)
- Mismo **theme switch** (clave `thenucleo-ficha-cliente-theme` compartida con la ficha — un solo theme switch para todas las subsecciones)
- Mismo **nav dropdown** con accesos a Playbook · Ficha de Cliente · **Estrategia (activa)** · Timeline · Fichas de Producto · Casuísticas · Disponibilidades
- Status strip (estado, sector, plan, Google Chat, facturación) — sin chip "Anomalías mockup"
- Panel único: `PIPELINES_MODULE` con árbol Pipelines → Campañas → (Triggers · Emails · WhatsApp · Creatividades)

## Qué NO tiene

- Panel Datos (eliminado del flujo — Datos vive en Bubble)
- Panel Servicios contratados (irá a `/servicios/?id=X` en un sprint posterior)
- Panel Catálogos (irá a `/catalogo/?id=X` en un sprint posterior)
- Panel Anomalías (era mockup, eliminado del flujo de nuevas subsecciones)
- Info-pop con tooltips de PIPELINES_MODULE (presente — el módulo lo necesita)

## Convención de mantenimiento mientras coexista con `/ficha-cliente/`

`ficha-cliente/index.html` (5.261 líneas) sigue siendo la **fuente de verdad** de `PIPELINES_MODULE`. Cualquier cambio funcional al módulo se hace primero ahí y luego se propaga al clon de `/estrategia/`. Esto es deuda técnica explícita (ver [[deuda-tecnica]] entrada "Extraer infra compartida de admin pages"). El plan de cierre:

1. Cuando el 3er panel se clone (`/catalogo/?id=X`), extraer `_includes/admin-base.njk` + `assets/js/admin-shared.js` con auth gate + client picker + helpers genéricos (`rpc()`, `tableRequest()`, `openSheet()`, `showToast()`, handler `[data-coll-toggle]`).
2. Refactorizar `/ficha-cliente/`, `/playbook/`, `/fichas-de-producto/`, `/estrategia/`, `/catalogo/`, `/timeline/`, `/servicios/` para usar la infra compartida.
3. Eliminar `/ficha-cliente/index.html` o convertirla en hub que linka las 4-5 subsecciones.

Hasta entonces: **`PIPELINES_MODULE` está duplicado bit-a-bit entre `/ficha-cliente/` y `/estrategia/`**. Editar uno → propagar al otro en el mismo commit.

## Acceso desde Bubble (deep-link autenticado)

La Edge Function `bridge_from_portal` acepta parámetro opcional `next_path`. Para que un botón en el submenú Cliente del portal Bubble aterrice en esta página autenticado:

```
next_path = "/estrategia/?id=<Current Cliente's bubble_id>"
```

Detalle del setup Bubble en [[bridge-portal-ficha]].

## Referencias

- Plan de la migración: `~/.claude/plans/habr-a-alguna-forma-ingeniosa-polished-island.md`
- Origen del clon: [[ficha-cliente|docs/work/ficha-cliente]]
- Bridge Portal → Work: [[bridge-portal-ficha|docs/work/bridge-portal-ficha]]
- Deuda técnica: [[deuda-tecnica|docs/work/deuda-tecnica]] entrada "Extraer infra compartida"
- Schema Pipelines (`cliente_pipelines`, `cliente_campanias`, `cliente_triggers`, `cliente_emails`, `cliente_mensajes_whatsapp`, `cliente_creatividades`): [[../infra/supabase-schema|docs/infra/supabase-schema]]
