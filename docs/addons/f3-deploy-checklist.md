---
title: Addons F3 — Checklist Deploy
dominio: addons
estado: en-construccion
actualizado: 2026-05-08
tags: [addons, deploy, fase-3, vercel, stripe]
---

# FASE 3 — Onboarding standalone — Checklist de despliegue

**Estado al 2026-05-06:** código frontend + endpoints serverless + vista pública Supabase ya en `thenucleo-landing/`. Pendiente: env vars + DB Triggers + Deploy Hook + creación de Stripe Products.

---

## 1. Variables de entorno en Vercel

Proyecto `app-landing-thenucleo` → Settings → Environment Variables.

| Variable | Scope | Valor |
|---|---|---|
| `SUPABASE_URL` | Production, Preview, Development | `https://cbixhqjsnpuhcrcjppah.supabase.co` |
| `SUPABASE_ANON_KEY` | Production, Preview, Development | Anon key del proyecto cbi (ya configurada para `comunidad`) |
| `SUPABASE_SERVICE_ROLE_KEY` | **Production, Preview** (NO Development) | service_role key — `Settings → API → service_role` en el dashboard Supabase. **Solo backend**, no se filtra al cliente. |
| `STRIPE_SECRET_KEY` | Production, Preview | `sk_test_...` (TEST) o `sk_live_...` (PROD). Empezar en TEST. |
| `PUBLIC_ORIGIN` | Production | `https://work.thenucleo.com` |

Tras añadirlas, **redeployar** (push o Vercel UI → Redeploy) para que el build las recoja.

## 2. Stripe — Products + Prices (28 addons de pago)

Antes de F3 esté operativo, hay que crear en Stripe TEST (y luego PROD):

```
1 Stripe Product por slug (28 totales)
1 Stripe Price (one_time) por Product, en EUR, con el precio del catálogo
```

Después: **rellenar `Addons_Catalogo.stripe_price_id`** en Bubble (28 filas). El SYNC ABSOLUTO replica a `bub_addons_catalogo`. Endpoint `/api/checkout` rechaza addons sin `stripe_price_id`.

Opciones:
- **Manual** (UI Stripe + Bubble) — viable para 28 filas.
- **Script automático** (no creado todavía) — leer Supabase, crear en Stripe, escribir `stripe_price_id` de vuelta a Bubble. Ideal pero requiere ratos extra.

Decisión sugerida: hacerlo manual la primera vez para validar mapping, automatizar si añadimos más addons en el futuro.

## 3. DB Triggers Bubble — rebuild Vercel al cambiar catálogo

Vercel Project → Deploy Hooks → "Create Hook" en branch `main` → copiar URL.

Bubble → Backend Workflows nuevos:

| Trigger | Cuándo | Acción |
|---|---|---|
| `A Addons_Catalogo is changed` | `Addons_Catalogo is created or modified` | API Connector POST a Vercel Deploy Hook URL |
| `A Addons_Codigos_Descuento is changed (deploy)` | `is created or modified` | Mismo POST + (en F2) webhook de sync Stripe Coupons |

Esto regenera el SSG cada vez que cambia el catálogo o un código.

## 4. Vista pública Supabase

Ya creada (`v_addons_catalogo_publico`). Verificar:
```sql
SELECT count(*) FROM v_addons_catalogo_publico;  -- 34
```

## 5. Validación end-to-end (TEST)

Una vez los pasos 1-3 estén hechos:

```bash
# Local: build con ANON_KEY de Vercel exportada
SUPABASE_URL=https://cbixhqjsnpuhcrcjppah.supabase.co \
SUPABASE_ANON_KEY=... \
npm run build
# Verificar _site/onboarding/index.html: contiene 6 secciones de categoría con N cards
```

En Vercel Preview/Prod:
1. `https://work.thenucleo.com/onboarding/` — el catálogo se renderiza.
2. Selección de un addon de pago + click "Continuar al pago".
3. Modal abre. Email + agencia + click "Pagar".
4. Endpoint `api/checkout` → URL Stripe Checkout TEST.
5. Tarjeta TEST `4242 4242 4242 4242` → success.
6. Redirect a `/onboarding/ok/?sid=...` (success page).
7. Code descuento `CodigoZenyx` debería rebajar 100%.

⚠️ Hasta que F2 sincronice los coupons de Bubble a Stripe, el código `CodigoZenyx` validará en Supabase pero el endpoint `/api/checkout` devolverá 503 ("código existe pero aún no sincronizado con Stripe").

## 6. Endpoints expuestos

- `POST /api/validate-coupon` — `{codigo, addon_slugs[]}` → `{valido, descuento_porcentaje, stripe_coupon_id, mensaje_error?}`
- `POST /api/checkout` — `{email, agencia_nombre, addon_slugs[], codigo_descuento?}` → `{url}` o `{gratis: true}` o `{error}`

Ambos rate-limit cero (de momento). Si abuso → añadir middleware de rate-limit a Vercel Edge Functions.

## 7. Pendiente F4 (Provisión)

- Webhook Stripe `checkout.session.completed` → workflow n8n `addons_stripe_provision`
- Verifica firma Stripe, idempotencia por `session_id`, crea `Addons_Agencia` en Bubble por cada line_item.
- Si hay `metadata.codigo_descuento` → PATCH Bubble `Addons_Codigos_Descuento.usos_actuales += 1`.
- JWT HS256 → email GHL → portal con sesión.

## Archivos creados en F3

```
thenucleo-landing/
├── _data/addons.js                       (build-time fetch a v_addons_catalogo_publico)
├── _includes/onboarding-base.njk         (layout dedicado, noindex)
├── onboarding/index.njk                  (página principal /onboarding/)
├── onboarding/ok.njk                     (success page /onboarding/ok/)
├── assets/css/onboarding.css             (paleta lima #D9FF00 sobre dark)
├── assets/js/onboarding.js               (selección + carrito + localStorage + checkout)
├── api/validate-coupon.js                (Vercel Function, lee Supabase service_role)
├── api/checkout.js                       (Vercel Function, crea Stripe Checkout Session)
├── vercel.json                           (CSP form-action ampliado a checkout.stripe.com)
└── robots.txt                            (Disallow /onboarding/ y /api/)
```

Supabase:
- Vista `v_addons_catalogo_publico` (migración `create_v_addons_catalogo_publico`)
