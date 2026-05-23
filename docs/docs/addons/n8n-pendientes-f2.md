---
title: Addons F2 — Pendientes n8n
dominio: addons
estado: en-construccion
actualizado: 2026-05-08
tags: [addons, n8n, stripe, fase-2]
---

# n8n — Cambios pendientes FASE 2

> Lo aplico yo automáticamente cuando termines FASE 1 (Bubble). Documentado aquí para revisión previa.

## 1. Ampliar `ALLOWED_TABLES` en SYNC ESPEJO — Bubble → Supabase

**Workflow:** `FGxG67I24POOUeHW` (SYNC ESPEJO — Bubble → Supabase)
**Nodo:** "Validar Payload" (tipo Code)
**Cambio:** añadir 3 entradas al array `ALLOWED_TABLES`.

```javascript
// Antes
const ALLOWED_TABLES = [
  'bub_agencia', 'bub_user', 'bub_clientes', /* ... 23 más ... */
];

// Después
const ALLOWED_TABLES = [
  'bub_agencia', 'bub_user', 'bub_clientes', /* ... 23 más ... */,
  'bub_addons_catalogo',
  'bub_addons_agencia',
  'bub_addons_codigos_descuento'
];
```

**Riesgo:** mínimo. Solo amplía whitelist, no modifica lógica.
**Rollback:** revertir el array.

## 2. Triggers `trg_set_synced_at` en las 3 nuevas tablas espejo

**Tabla destino:** Supabase (proyecto `cbixhqjsnpuhcrcjppah`).
**Aplico vía Supabase MCP `apply_migration`** una vez las tablas existan.

```sql
CREATE TRIGGER trg_set_synced_at_addons_catalogo
  BEFORE INSERT OR UPDATE ON bub_addons_catalogo
  FOR EACH ROW EXECUTE FUNCTION set_synced_at();

CREATE TRIGGER trg_set_synced_at_addons_agencia
  BEFORE INSERT OR UPDATE ON bub_addons_agencia
  FOR EACH ROW EXECUTE FUNCTION set_synced_at();

CREATE TRIGGER trg_set_synced_at_addons_codigos_descuento
  BEFORE INSERT OR UPDATE ON bub_addons_codigos_descuento
  FOR EACH ROW EXECUTE FUNCTION set_synced_at();
```

## 3. Workflow nuevo `SYNC ADDONS — Bubble → Stripe (Cupones)`

**Propósito:** sincronizar `Addons_Codigos_Descuento` (Bubble master) con Stripe Coupons API. Stripe = source of truth del cobro real.

**Trigger:** Webhook `POST /webhook/addons_descuento_sync` disparado por DB Trigger Bubble `A Addons_Codigos_Descuento is changed`.

**Payload entrante (Bubble):**
```json
{
  "bubble_id": "1709...x...",
  "operation": "create" | "update" | "deactivate"
}
```

**Flujo de nodos:**

```
[Webhook] → [GET Bubble Addons_Codigos_Descuento by bubble_id]
         → [Code: build Stripe coupon params]
         → IF (operation = create AND stripe_coupon_id IS empty)
             → [Stripe API: POST /v1/coupons]
             → [PATCH Bubble: stripe_coupon_id]
         → IF (operation = update AND stripe_coupon_id present)
             → [Stripe API: POST /v1/coupons/{id}] (update name + valid_to + max_redemptions)
         → IF (operation = deactivate OR activo=false)
             → [Stripe API: DELETE /v1/coupons/{id}]
             → [PATCH Bubble: stripe_coupon_id = empty]
         → [Activity log: codigo, accion, resultado]
```

**Mapeo Bubble → Stripe Coupon (simplificado):**

| Bubble | Stripe Coupon |
|---|---|
| `codigo` | `id` (lower-case + sanitized) |
| `nombre_interno` | `name` |
| `descuento_porcentaje` | `percent_off` (siempre %) |
| `validez_fin` | `redeem_by` (epoch) |
| `usos_max` (>0) | `max_redemptions` |
| `usos_max=0` | sin `max_redemptions` (ilimitado) |
| `addon_slugs_aplicables` no vacío | `applies_to.products = [stripe_product_ids...]` |
| solo `categorias_aplicables` | n/a en Stripe — el filtro vive en validate-coupon (frontend), Stripe acepta el coupon a nivel session. Si el carrito incluye addon fuera de categoría, validate-coupon lo rechaza antes de Stripe |

**Idempotencia:** `metadata.bubble_id` en cada coupon Stripe. Si workflow se dispara doble, segundo upsert no causa daño porque `id` Stripe = slug Bubble (también UNIQUE).

**Credencial Stripe:** la creo como nueva `Stripe API` en n8n con secret key (env var `STRIPE_SECRET_KEY`). Pendiente: confirmar si Ben usa misma cuenta Stripe que la landing (test mode) o crea nueva para producción.

**ENV vars a añadir en n8n** (lo pides tú al admin del self-hosted):
- `STRIPE_SECRET_KEY` (test mode para dev, live tras MVP)
- `JWT_ADDONS_SECRET` (random 64 chars, lo genero al crear workflow F3)

## 4. DB Trigger Bubble que llama al webhook

Workflow Bubble `A Addons_Codigos_Descuento is changed`:

- **When**: `Addons_Codigos_Descuento is created or modified`
- **Step 1**: API Connector call → `n8n /webhook/addons_descuento_sync`
  - body: `{"bubble_id": "Codigo's unique id", "operation": "update"}`
  - (en `created` mandar `"operation": "create"`)

(Esto va dentro del set de Database Triggers que crearás en FASE 1, sec. 4.)

## 5. Lo que YO hago en FASE 2

Una vez digas "FASE 1 lista":

1. **Verifico** que las 3 tablas espejo `bub_addons_*` aparecen en Supabase con datos correctos.
2. **Aplico migración SQL** con los 3 triggers `trg_set_synced_at`.
3. **Edito workflow `FGxG67I24POOUeHW`** (SYNC ESPEJO — Bubble → Supabase) añadiendo las 3 tablas a `ALLOWED_TABLES`.
4. **Creo workflow nuevo `SYNC ADDONS — Bubble → Stripe (Cupones)`** vía n8n SDK con la estructura de arriba.
5. **Test E2E**: edito `CodigoZenyx` en Bubble (cambio `nombre_interno`) → debe aparecer en Stripe TEST como coupon nuevo (en primer trigger, ya estará creado) → `stripe_coupon_id` poblado en Bubble.

## 6. Riesgos / mitigaciones

- **Stripe credenciales no disponibles aún** → workflow se crea pero queda inactivo hasta tener las keys. No bloquea F1.
- **Bubble workflow trigger se dispara antes de que workflow n8n exista** → primera ejecución falla silenciosa. Capturado por error handler global `HRDQ9Ju4NAIUV0qyhKzlz`.
- **Slug del código contiene caracteres no válidos para Stripe coupon `id`** → sanitizar en Code node (`coupon_id = codigo.toLowerCase().replace(/[^a-z0-9_-]/g,'')`).
