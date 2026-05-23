---
title: Addons + Onboarding
dominio: addons
estado: en-construccion
actualizado: 2026-05-20
tags: [hub, addons, onboarding, stripe]
---

# Addons + Onboarding TheNucleo

Plan maestro: `~/.claude/plans/thenucleo-addons-onboarding-master-plan.md`

## Estado

**FASE 0 — SQL + docs preparación: ✅ COMPLETADA (2026-05-04)**
- Tabla `agencia_integraciones_config` (Supabase nativo, pgcrypto, RLS service_role) + funciones `aic_set` / `aic_get` / `aic_set_test_result`. Round-trip verificado.

**FASE 1 — Bubble + sync: ✅ COMPLETADA (2026-05-04)**
- 2 Option Sets: `categoria_addon` (6) + `estado_implementacion_addon` (4)
- 3 Data Types: `Addons_Catalogo` (10 fields, 34 filas), `Addons_Agencia` (12 fields), `Addons_Codigos_Descuento` (10 fields, 1 fila CodigoZenyx)
- 3 DB Triggers Bubble → SYNC ESPEJO — Bubble → Supabase
- 3 tablas espejo Supabase: `bub_addons_catalogo`, `bub_addons_agencia`, `bub_addons_codigos_descuento` con triggers `trg_set_synced_at`
- Workflow `FGxG67I24POOUeHW` (SYNC ESPEJO — Bubble → Supabase) con 22 tablas en `ALLOWED_TABLES` (added: `bub_addons_catalogo`, `bub_addons_agencia`, `bub_addons_codigos_descuento`)

**FASE 2 — Workflow Stripe Coupons sync: ✅ COMPLETADA E2E (2026-05-10)**
- ✅ Workflow `bDYIpOSZ7Ge01Fqt` (`SYNC ADDONS — Bubble → Stripe (Cupones)`) activo. 10 nodos. Tag `portal`. errorWorkflow asignado.
- ✅ Migrado 2026-05-10 a 3 nodos `n8n-nodes-base.bubble` v1 nativos (cred `bubbleApi`). Stripe + Activity Log siguen HTTP por excepciones documentadas (Stripe nativo no cubre Update/Delete coupons; Supabase nativo arriesga stringificar `detalle` jsonb).
- ✅ Credenciales asignadas: `bubbleApi` (Bubble account `i8UMJM5KZOGBRf5z`) en 3 nodos Bubble; `httpHeaderAuth` `Stripe (pendiente)` (`zTpdojVvsrjyK74p`) en 3 nodos Stripe; `httpHeaderAuth` Supabase service_role en Activity Log.
- ✅ DB Trigger Bubble `addons_codigo_descuento_changed` deployado a Live, llama a API Connector `addons_descuento_sync` → webhook n8n. Validado en producción (execution `117729` 2026-05-10).
- ✅ Cred Stripe corregida (Header `Authorization: Bearer sk_test_...`).
- ✅ Test E2E exitoso (executions `117745` create + `117746` update). Coupon `codigozenyx` en Stripe TEST. `stripe_coupon_id` poblado en Bubble. Loop antirebote limitado a 1 vuelta (esperado).
- ⚠️ Pendiente menor (en curso): nodo `Activity Log Creado`. Cred Supabase ya con `apikey`+`Authorization`. Body del nodo reescrito al schema real de `activity_log` (`clase`, `accion`, `entidad_id`, `entidad_nombre`, `metadata`). Pendiente smoke final para confirmar inserción.
- 🔮 F2.5 (post-Stripe Products): añadir `applies_to[product]` por cada slug en `addon_slugs_aplicables`
- Decisión pendiente: crear Stripe Products + Prices para los 28 addons de pago

**Bug documentado en proceso (afecta a futuras calls Bubble):** primer trigger Bubble llegó con doble comillas en `operation` (template `"<operation>"` + value `"update"` literal). Ver memoria persistente `feedback_bubble_quotes_jsonsafe_rules.md` con decision tree determinista.

**FASE 3 — Onboarding standalone (`work.thenucleo.com/onboarding`): ✅ COMPLETADA E2E (2026-05-11)**
- ✅ Vista pública Supabase `v_addons_catalogo_publico` (34 filas, sin campos sensibles)
- ✅ `_data/addons.js` build-time fetch (Eleventy v3) con fallback empty + flag `es_comprable`
- ✅ Layout `_includes/onboarding-base.njk` (noindex, paleta lima `#D9FF00` sobre dark)
- ✅ Página `/onboarding/` con 6 categorías + selección radio + carrito sticky + modal pago
- ✅ Página `/onboarding/ok/` (success page tras Stripe Checkout)
- ✅ Endpoint `api/validate-coupon.js` (Vercel Function, service_role)
- ✅ Endpoint `api/checkout.js` (Vercel Function, fetch directo a Stripe sin SDK)
- ✅ `vercel.json` CSP `form-action` ampliado a `checkout.stripe.com`
- ✅ `robots.txt` Disallow `/onboarding/` y `/api/`
- ✅ Env vars Vercel: `SUPABASE_SERVICE_ROLE_KEY`, `STRIPE_SECRET_KEY` (TEST), `PUBLIC_ORIGIN`
- ✅ DB Trigger Bubble `A addons_catalogo is modified` → Step 1 webhook espejo n8n + Step 2 Vercel Deploy Hook
- ✅ 7 Stripe Products + Prices TEST creados (sesión 2026-05-11): ActiveCampaign €97, HubSpot €97, Clientify €289, Odoo €169, Google Sheets €97, Monday €169, OneDrive €97. Resto (21 addons de pago) pendiente — front los marca como "Solicitar" + "Próximamente" no clickables.
- ✅ Test E2E pasado por Ben con tarjeta TEST `4242 4242 4242 4242` + `CodigoZenyx` (100% off, total €0).
- 📋 Checklist completo en [[f3-deploy-checklist]]

**FASE 3 BIS — Plan recurrente (suscripción) + entry point unificado: ✅ COMPLETADA E2E (2026-05-11)**

Decisiones cerradas:
- `/onboarding/` = puerta de entrada principal del owner SaaS, combina tarifa recurrente + addons one-shot en un único Stripe Checkout (`mode: subscription`).
- Pricing legacy de la landing (3 botones "Empezar" en `index.html`) redirige a `/onboarding/?periodo=mensual|trimestral|anual` (no Payment Links Stripe directos).
- Modelo Bubble Pagos_Tarifa_Catalogo: 1 fila "Plan Base TheNucleo" con 3 columnas nuevas `stripe_price_id_mensual`/`_trimestral`/`_anual`.
- Modelo Stripe TEST: 1 Product + 3 Prices recurring (€79/mes, €205/trimestre, €700/año).

Trabajo completado 2026-05-11:
- ✅ Bubble: 3 columnas `stripe_price_id_*` añadidas + fila "Plan Base TheNucleo" creada en LIVE (`1778498879683x388828517142107100`) y DEV (`1778498831235x991829332063964400`).
- ✅ Stripe TEST: Product `prod_UUrt25rJ4bZnub` + 3 Prices recurring (`price_1TVsBaIEZBGRV7Xw1Qx6T51G` mensual, `price_1TVsBnIEZBGRV7Xwf5BKSL8A` trimestral, `price_1TVsBrIEZBGRV7XwGt8VFebn` anual). 3 productos legacy (`prod_UJfg*`) archivados con `active=false`.
- ✅ Supabase: vista `v_tarifas_catalogo_publico` creada con `GRANT SELECT TO anon, authenticated`. 3 columnas Stripe propagadas a `bub_pagos_tarifa_catalogo` via SYNC ESPEJO (lag 4s validado E2E).
- ✅ thenucleo-landing: `_data/tarifas.js`, sección Plan en `onboarding/index.njk` (3 cards + `?periodo=` query param), `state.tarifa` + `selectTarifa()` + validación CTA en `onboarding.js`.
- ✅ DB Triggers Bubble `A Pagos_Tarifa_Catalogo is modified` + `A addons_catalogo is modified` con Step 2 API Connector `Vercel Deploy Hook - trigger_rebuild_landing`. Bugs `tabla=bub_agencia` + `bub_pagos_agencia_tarifa.` (punto extra) corregidos.
- ✅ Vercel Deploy Hook `bubble-catalogo-changed` creado, env vars cargadas (SERVICE_ROLE + STRIPE_TEST + PUBLIC_ORIGIN).
- ✅ **Bug fix `api/checkout.js`** (commit `a715eaa`): `subscription_data.add_invoice_items` no existe en Stripe Checkout Sessions (solo en API directa de Subscriptions). Fix: addons como `line_items[1..N]` — Stripe acepta mix recurring (tarifa) + one-time (addons) en `mode=subscription` y mete los one-time en la primera factura del cycle.
- ✅ **UX fixes** (commits `4d39298` + `f32c819`):
  - Addons sin Stripe Price = `.is-unavailable` (opacity 0.55, `pointer-events:none`, `<input>` disabled, sin tabindex, chip gris "Próximamente", precio "Solicitar" en cursiva). `selectAddon()` early-return + `preselectStackDefault()` filtra slugs no comprables al restaurar de localStorage.
  - Modal click-outside con `e.target.closest('.onboarding-modal')` + `stopPropagation()` interno (antes el `e.target === overlay` no era robusto y cerraba con clicks interiores).
  - Cupón auto-apply en submit: `submitCheckout()` detecta input con valor no aplicado y llama `applyCoupon()` antes del checkout. Si invalido aborta + muestra feedback. Antes el usuario podía olvidar el botón "Aplicar" y perder el descuento silenciosamente.
  - Placeholder cupón `"CodigoZenyx"` → `"Introduce tu cupón"` (sugerir código real era confuso/promocional).
- ✅ **Test E2E E2E con CodigoZenyx**: Stripe Checkout subscription generada con `subtotal=302€`, `amount_discount=302€`, `total=0€`, `coupon: codigozenyx`. Validado en producción por Ben.

Pendiente:
- ⏸ F4 (Provisión post-pago): webhook `checkout.session.completed` → crear `bub_agencia` + invitación owner (NUEVA SESIÓN, bloque 3 del plan).
- 🔮 Crear Stripe Products + Prices para los 21 addons de pago restantes (Xero, Asana, Zoho CRM, Dropbox, Harvest, etc.). Cada vez que se cree uno y se pegue su `stripe_price_id` en Bubble, el rebuild Vercel automático lo activa sin tocar código.
- 🔮 Mejoras UX/onboarding adicionales según feedback Ben (sesión post-cierre).

**FASE 4 — Webhook Stripe → Provision: ⏸ PENDIENTE**

**FASE 5 — Plantillas Notion + workflow `addon_iniciar_implementacion`: ⏸ PENDIENTE**

**FASE 6 — Wizard credenciales + página Bubble `/integraciones`: ⏸ PENDIENTE**

**FASE 7 — Cleanup `bub_integraciones`: ⏸ PENDIENTE**

## Archivos

| Archivo | Propósito |
|---|---|
| [[bubble-spec-f1]] | Spec mínima de Option Sets, Data Types, DB Triggers, código de prueba |
| `bubble-import-addons-catalogo.csv` | CSV catálogo (34 filas, 10 columnas, header `Slug` mayúscula). Local |
| [[n8n-pendientes-f2]] | Spec del workflow `SYNC ADDONS — Bubble → Stripe (Cupones)` (FASE 2) |

## Aprendizajes

1. **Bubble bulk import NO mapea al built-in `Slug`** — solo a fields custom. Crear field custom `slug` (text) en cada Data Type que necesite slug.
2. **Bubble Data Types deben tener "Privacy Rules" que permitan visibilidad** para que `bub_*` sync funcione (api_view).
3. **Bubble DB Triggers SÍ se disparan por bulk import** (contradice mi diagnóstico inicial — causa real era `campos_credenciales_json` con tab y field `slug` ausente).
4. **Bubble Data API omite fields vacíos** del response — si un field de tipo X no tiene valor, no aparece (no es null).
5. **`app_version=test` en header `baggage`** indica DB Trigger desde versión TEST. URL Data API correcta: `bubbleapps.io/version-test/api/1.1/obj/...`. SYNC ESPEJO — Bubble → Supabase actual usa siempre LIVE — Ben deployó a LIVE para resolver. (TODO opcional: hacer workflow detect version-aware).
6. **Stripe `subscription_data.add_invoice_items` NO existe en Checkout Sessions** — solo en API directa de Subscriptions. Para addons one-time en una subscription Checkout, mix recurring (tarifa) + one-time (addons) en `line_items` directamente (`mode=subscription` lo permite y mete los one-time en la primera factura). Memoria persistente: `feedback_stripe_addinvoiceitems_checkout.md`.
7. **Bubble Number field con valor borrado guarda como `0`**, no mantiene el valor anterior. Caso real: Ben editó Clientify para añadir `stripe_price_id`, segundo Save vació `precio_eur` accidentalmente y quedó a 0 en Supabase. Cuidado al editar dos veces seguidas; verificar en BD tras cada batch de Saves.
8. **Front del onboarding debe filtrar antes que el backend rechace** — la primera versión dejaba marcar cualquier addon y `/api/checkout` devolvía 503 "no disponibles" al final del flujo. Mejor UX: marcar addons no comprables (sin `stripe_price_id`) como `pointer-events:none` + chip "Próximamente" en build-time desde el flag `es_comprable`.
9. **Cupón auto-apply en submit** — exigir click manual en botón "Aplicar" antes del submit es un foot-gun: el usuario escribe el código, da directo a "Continuar al pago", y `state.coupon` queda null sin error visible. `submitCheckout()` debe detectar input con valor no aplicado y llamar `applyCoupon()` antes del checkout, abortando si es inválido.
10. **Modal click-outside debe usar `closest()` no `e.target === overlay`** — el filtro estricto falla cuando hijos del modal hacen bubble con target=overlay en algunos navegadores. Más robusto: `if (!e.target.closest('.onboarding-modal')) closeModal();` + `stopPropagation()` en el `.onboarding-modal` inner.

## Decisiones cerradas

- `bub_integraciones` se deprecará en F7 (vacía, rol original ya cubierto por `agencia_integraciones_config`).
- `agencia_integraciones_config` es genérica para TODAS las integraciones (nativas + addons de pago).
- Selección + pago = standalone Eleventy en `work.thenucleo.com/onboarding`.
- Stripe Coupons = source of truth del cobro real.
- Stripe → Holded automático pospuesto.
- 34 addons reales (no 29 como decía el plan original).
