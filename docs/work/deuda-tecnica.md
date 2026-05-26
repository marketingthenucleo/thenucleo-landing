---
title: Deuda técnica — work.thenucleo.com
dominio: work
estado: vivo
actualizado: 2026-05-24
tags: [deuda-tecnica, work, landing, backlog]
---

# Deuda técnica — work.thenucleo.com

Inventario de items pendientes del landing y páginas admin (`/playbook/`, `/ficha-cliente/`, `/fichas-de-producto/`, `/casuisticas/`, `/disponibilidades/`, `/comunidad/`, `/conocimiento-zenyx/`, `/arquetipo/`). Fuente primaria: `thenucleo-landing/CLAUDE.md` (raíz del repo). Este doc lo refleja para que esté consultable desde Obsidian / desde el flujo de docs/.

> **Convención drift (post-unificación 2026-05-23):** cuando se cierre un item de aquí, marcarlo `~~tachado~~ ✅ <fecha>` o moverlo a la sección "Cerrados". Si el item nace de un cambio en el código del landing, registrarlo aquí en el mismo PR.

## Críticos abiertos

1. **Stripe TEST → PROD.** Links de Stripe en modo TEST (`buy.stripe.com/test_...`). Decisión 2026-04-19: se mantiene TEST hasta que Ben finalice la cuenta Stripe PROD. Mitigación sugerida: banner "Modo prueba" sobre `.pricing-grid` en `index.html`.
2. **`prefers-reduced-motion` no aplica a Three.js / partículas / cursorLoop.** La media query CSS solo neutraliza animaciones CSS; los `requestAnimationFrame` (Scene1, Scene2, particles, cursorLoop) siguen corriendo. Riesgo vestibular para ~15-20% del tráfico móvil con la opción activa. Fix: gate global `if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;` en cada loop de render del `index.html`.

## No críticos abiertos

- **OG image v2.** `Media/og-image.png` (1200×630) usa el logo con fondo blanco. Choca con la identidad dark del site y no lleva tagline. Rehacer con fondo `#171717` + logotipo dark theme + hook textual.
- **Extraer infra compartida de admin pages** (Sprint X). `/ficha-cliente/`, `/playbook/`, `/fichas-de-producto/`, `/estrategia/`, `/timeline/` (y futuras `/catalogo/`, `/servicios/`) duplican bit-a-bit el auth gate, client picker, theme switch, nav dropdown, helpers `rpc()`/`tableRequest()`/`openSheet()`/`showToast()`/handler `[data-coll-toggle]`. Extraer a `_includes/admin-base.njk` (HTML shell) + `assets/js/admin-shared.js` (lógica). Activador: cuando se clone el 3er panel (`/catalogo/`), bloquear más clones hasta extraer. Sin esto, cada cambio al gate o al picker se propaga a N archivos a mano. Tracked desde la migración a subsecciones 2026-05-25.
- **Bridge magic link aterriza en `/comunidad/entrar/`** en vez de un endpoint dedicado (`/auth/callback/`). Decisión 2026-05-25 al diseñar el bridge: reusar el handler de Supabase Auth ya montado en `/comunidad/entrar/` (`detectSessionInUrl:true` + `onAuthStateChange` + `getNextUrl()` redirect) en lugar de duplicarlo. El patch en `assets/js/comunidad-entrar.js` oculta el captcha "No soy un robot" cuando la URL trae `#access_token=` en el hash. Funciona — el usuario solo ve `/comunidad/entrar/` ~300ms antes del `location.replace(next)` — pero conceptualmente "entrar a la comunidad" y "procesar callback de magic link" son flujos distintos compartiendo página por casualidad de timing. Limpieza futura: crear `/auth/callback/index.html` standalone con solo el handler de Supabase, cambiar `redirectTo` en la Edge Function `bridge_from_portal`, actualizar el redirect URL en Supabase Auth, retirar el patch del captcha. ~15 min mecánicos, sin cambio de comportamiento. Hasta entonces el Site URL allowlist tiene `https://work.thenucleo.com/comunidad/entrar/**`.
- ~~**Magnetic buttons en touch.**~~ ✅ **Cerrado 2026-05-23** — el bloque `MAGNETIC BUTTONS` en `index.html` (líneas ~2776) ahora va envuelto en `if (matchMedia('(hover: hover) and (pointer: fine)').matches)`. En touch no se registran handlers `mousemove`/`mouseleave`.
- ~~**Touch targets < 44 px** en `.btn-sm` (32 px) y `.pdot` (8 px).~~ ✅ **Cerrado 2026-05-23** — `.btn-sm` mobile (≤600px) lleva `min-height: 44px`. `.pdot` mantiene su visual de 8px pero extiende hit area a 44×44 vía pseudo-elemento `::after` con `inset: -18px`. WCAG 2.5.5 AA cumplido.
- **CSP sin `report-to` / `report-uri`.** Violaciones inline pasan silenciosas. Añadir endpoint de reporte en `vercel.json` para telemetría.
- **RLS de tablas `comunidad_*` no auditada** en pase 2026-04-29 (solo lectura cliente verificada). Verificar en Supabase Dashboard que UPDATE/DELETE estén restringidos a `comunidad_admins` o a filas propias en estado `pendiente`.
- **Bundle Three.js + addons localmente** con esbuild/rollup en un solo archivo. Hoy hay cadena de 12 requests en cascada a jsDelivr (3119 ms critical path). Medio riesgo (cambio de build). Alternativa más simple: self-host individual, mismo dominio.
- **Lazy-load GLB** con `IntersectionObserver` en `.phase-showcase`. El MacBook está en Phase 3 — cargar el `.glb` solo cuando el usuario se acerque (ahorra ~330 KB del initial transfer). Bajo riesgo. Scene #2 ya tiene `if (!isVisible) return` en el render loop, pero el `fetch` del GLB ocurre al load.

## Operacionales / docs (drift)

- ~~**Chip "Pipelines · mockup" en `/ficha-cliente/`.**~~ ✅ **Cerrado 2026-05-23** — `ficha-cliente/index.html:1392` retirado. El módulo Pipelines ya no es mockup (seed F1 hardcoded de Dra. Neuss). Commit `48af7c8`.
- ~~**`docs/portal/ficha-cliente.md` describía Pipelines como placeholder anterior, no el v3.**~~ ✅ **Cerrado 2026-05-23** — §10 punto 4 marcado como hecho; Referencias línea 475 reformulada (Pipelines vivo con seed, solo Catálogos y Anomalías siguen MOCKUP).
- ~~**Convención drift no declarada en `CLAUDE.md` raíz tras unificación del vault.**~~ ✅ **Cerrado 2026-05-23** — bloque "Repo unificado" + tabla "Cuándo mirar qué" + sección "Convención para evitar drift" añadidos al inicio del `CLAUDE.md` raíz (commits `8647846`, `483fb4e`).

## Seguridad / config local

> Items de hygiene del setup local de Claude Code (`~/.claude/`) que no pertenecen al landing per se, pero se registran aquí por falta de mejor sitio y para que sean visibles al revisar deuda.

- **n8n JWT en plano en `~/.claude/settings.json` (PC1 Ben).** 2 entradas `Bash(curl -s -X PUT -H 'X-N8N-API-KEY: eyJ…IsyI' …)` contienen la API key de PROD literal dentro de la allowlist user-level. Riesgo bajo (archivo local), pero la key activa en plano = mal patrón (cualquier backup de `~/.claude/` la lleva). Acción: rotar el token desde n8n UI → reemplazar las 2 entradas por wildcard `Bash(curl * X-N8N-API-KEY: *)` (sin valor literal) o pasar la key a variable de entorno y usar `$N8N_API_KEY` en el curl. Detectado 2026-05-24.

## Backend Ficha Cliente — F2 (auditoría 2026-05-24)

> Nota: parte de este backlog ya está cerrado en main (allowlist ahora en 9 sitios, F2.7 Catálogos cerrada con 18 tablas, F2.8 panel contextual cerrado). Mantenido aquí como histórico del estado al 2026-05-24 + items aún abiertos (Anomalías, modales operativos pendientes de cableado completo).

Inventario detallado en [[ficha-cliente]]. Resumen:

1. **Pipelines y Campañas — cablear a Supabase.** ✅ Cerrado en F2.5d (5 tablas + RPCs). Brief original: [[../portal/ficha-cliente-pipelines-handoff-landing]].
2. **Campos MOCK del panel Datos.** Sigue abierto — Accesos (Meta BM, Google Ads, GHL, DNS) sigue MOCKUP. Decisión pendiente: columnas en `bub_clientes` vs tabla `cliente_accesos`.
3. **Catálogos.** ✅ Cerrado en F2.7 (17 tablas `cliente_catalogo_*` + RPC agregadora + Sprint 3 visibilidad por cliente).
4. **Anomalías — decidir fuente.** Sigue abierto. Hoy mock plano + chip hardcoded.
5. **Modales operativos en Pipelines.** Parcial — `new-trigger`/`new-email`/`np-create`/`nc-save` cableados; `tasks-send` (webhook n8n) sigue stub.
6. **Allowlist en 9 sitios hoy** (ampliada desde los 7 originales con catálogos + bridge). Cuando llegue a 12+, migrar a tabla `work_admins(email)`.

## Cerrados (histórico corto)

- ~~**Self-host Google Fonts.**~~ ✅ Eliminado — todo unificado en NewBlack (self-hosted woff2). Space Grotesk y JetBrains Mono removidos.
- ~~**Nav móvil sin hamburguesa** (≤860/900 px).~~ ✅ Resuelto 2026-04-30 — hamburguesa en los 4 navs (`index.html`, `comunidad-base.njk`, `blog.njk`, `conocimiento-zenyx/index.njk`).
- ~~**Header móvil desbordaba con sesión iniciada en `/comunidad/*`.**~~ ✅ Resuelto 2026-04-30 — a ≤600 px solo isotipo (`.nav-logotipo` ocultado), padding nav 10/14, dropdown auth-menu limitado a `calc(100vw - 24px)`.
- ~~**Nav header click handler aterrizaba en boundary de phase con animación vacía.**~~ ✅ Resuelto 2026-04-29 — ahora aterriza en `phaseEdges[idx] + 0.55 * span` para recorrer la animación durante el viaje (`index.html:2331-2346`).
- ~~**Botones "Empezar ahora" llevaban a Phase 4 (Precios).**~~ ✅ Resuelto 2026-04-29 — apuntan a `https://portal.thenucleo.com/` con `target="_blank" rel="noopener noreferrer"`.

## Referencias

- `thenucleo-landing/CLAUDE.md` — fuente primaria (raíz del repo), sección "Problemas críticos pendientes" + "Mejoras no críticas".
- `docs/archive/FULL-AUDIT-REPORT.md` y `docs/archive/ACTION-PLAN.md` — **eliminados 2026-05-23** (commit `0e81519`) antes de la importación del vault. Si se vuelven a necesitar: están en git history.
- Auditoría triple (UX/seguridad/responsive) 2026-04-29 — referenciada en `CLAUDE.md` raíz, sección "Auditoría 2026-04-29".
- [[../portal/ficha-cliente]] — visión PxCx + Pipelines (módulo F1 vivo, F2 pendiente).
- [[README|docs/work]] — hub del dominio.
