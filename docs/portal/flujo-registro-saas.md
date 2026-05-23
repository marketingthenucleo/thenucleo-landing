---
title: Flujo Registro SaaS
dominio: saas
estado: en-construccion
actualizado: 2026-05-10
tags: [saas, signup, stripe, onboarding]
---

# Flujo Registro SaaS — TheNucleo Portal

**Estado:** En construcción | **Última sesión:** 2026-05-10 | **Verificación schema:** 2026-04-25

---

## Contexto

Portal multiagencia (SaaS). Cada agencia es un tenant con múltiples usuarios. El owner de la agencia paga en Stripe (tarifa recurrente + addons one-shot combinados) desde `/onboarding/` y configura su equipo. **Bubble es master de datos** — Supabase espejo es read-only sin rol operativo en este flujo.

**Decisiones cerradas (2026-05-10):**
- `/onboarding/` (work.thenucleo.com/onboarding) es la **puerta de entrada principal** del nuevo owner. Combina tarifa + addons en un único Stripe Checkout (`mode: subscription`).
- Modelo pricing: 1 plan ("Plan Base TheNucleo") con 3 periodos (mensual / trimestral / anual). 1 fila Bubble + 3 stripe_price_ids (no 3 productos separados).
- Acceso al portal: **gate puro por pertenencia** (`User.agencia_id is not empty`). NO hay gate por status de pago. Gestión de impagos fuera del MVP.
- Admin Agencia: campo `Admin` (List of Users) ya existe en Bubble. El owner se añade a la lista al registrarse. Múltiples admins posibles.

---

## Arquitectura decidida

```
Landing (work.thenucleo.com)
  → /onboarding/?periodo=mensual|trimestral|anual (entry unificado)
      Visitante elige tarifa (1 obligatoria) + N addons opcionales
  → Stripe Checkout (mode: subscription, line_items mixto recurring + one_time)
  → Webhook → n8n "Stripe → Provision" (F4, pendiente)
      → Crea Agency en Bubble (stripe_customer_id, stripe_subscription_id, onboarding_completado=false)
      → Crea Pagos_Agencia_Tarifa (status=active)
      → Crea N Addons_Agencia (uno por addon comprado)
      → Crea Invitacion (rol=owner, token=UUID, aprobada=false)
      → PATCH Addons_Codigos_Descuento.usos_actuales += 1 si hubo cupón
      → Llama GHL crear_contacto_invitacion (mismo endpoint que invitaciones de equipo)
  → GHL envía email con link: portal.thenucleo.com/registro-invitacion?token=TOKEN

Owner llega, se registra (Google OAuth, email/pass, lo que sea)
  → Workflow Bubble "Acceder":
      Step 1: Log the user in
      Step 2: Make changes to current user (agencia_id + rol dinámico desde invitacion)
      Step 3: Make changes to Invitacion (aprobada = true)
      Step 4: Make changes to Agencia (miembros_agencia add Current User + owner = Current User si rol = owner)
      Step 5: Go to page dashboard
```

---

## Reutilización del sistema de invitaciones existente

El flujo del owner **reutiliza la página `registro-invitacion` y workflow "Acceder"** ya existentes.
La diferencia es el campo `rol` en la Invitacion:
- Invitaciones de equipo → `rol = PM` (u otro)
- Invitacion del owner que paga → `rol = owner`

---

## Modelo de datos Bubble — cambios necesarios

### Tabla `Invitacion`
- [x] ✅ Campo `rol` (text) confirmado en `bub_invitacion` (cbi). Verificado 2026-04-25 — schema real: `bubble_id, email, agencia, aprobada (boolean), token, rol (text), slug, creator_id, _synced_at, created_date, modified_date`.

### Tabla `Agencia`
Schema actual de `bub_agencia` (cbi, verificado 2026-04-25):
`bubble_id, nombre, admin (array), miembros_agencia (array), clientes_ids (array), tarifas_contratadas_ids (array), logo_agencia, pagina_web, telefono_contacto_agencia, uuid_supabase, creator_id, _synced_at, created_date, modified_date`.

Faltantes confirmados:
- [ ] Añadir campo `owner` (→ User) — **NO existe en bub_agencia hoy**
- [ ] Añadir campos Stripe: `stripe_customer_id`, `stripe_subscription_id`, `status` (active / past_due / cancelled / trialing) — **ninguno existe hoy**
- [ ] Añadir campo `onboarding_completado` (boolean, default false) — **no existe hoy**

---

## Pasos pendientes

### Bubble

- [ ] **Tabla Invitacion**: confirmar que campo `rol` está creado en Bubble
- [ ] **Tabla Agencia**: añadir campos Stripe + `owner` + `onboarding_completado`
- [ ] **Workflow "Enviar invitación" Step 1**: añadir `rol = PM` al crear Invitacion (para invitaciones de equipo)
- [ ] **Workflow "Acceder" Step 2**: cambiar `rol add PM` hardcodeado → `rol add invitacion's rol` (con empty = no asignar nada)
- [ ] **Workflow "Acceder" Step 4**: 
  - Cambiar `Thing to change` de `Search for Agencias: first item` → `registro-invitacion's invitacion's agencia` ⚠️ bug multitenancy
  - Añadir `owner = Current User` con `Only when: invitacion's rol = "owner"`
- [ ] **Workflow "User logged in"**: gate de acceso según `Agencia.status`
- [ ] **Página `/sin-acceso`**: con botón Stripe reactivación. Mensaje diferente si el user no es owner ("contacta con tu administrador")
- [ ] **Página onboarding**: wizard post-registro (nombre agencia, invitar equipo). Se muestra si `onboarding_completado = false`

### n8n

- [ ] **Workflow nuevo "Stripe → Provision"**:
  - Trigger: webhook `checkout.session.completed`
  - Verificar idempotencia: buscar Agency existente por `stripe_customer_id` antes de crear
  - Step: crear Agency en Bubble API
  - Step: crear Invitacion en Bubble API (`rol = owner`, `token = UUID`, `aprobada = false`)
  - Step: llamar GHL `crear_contacto_invitacion` (mismo endpoint que invitaciones de equipo)
  - Manejo de error: si falla a mitad, alertar (no dejar Agency sin Invitacion)

- [ ] **Workflow "Stripe → Update status"**:
  - Trigger: `customer.subscription.deleted` + `invoice.payment_failed`
  - Step: actualizar `Agencia.status` en Bubble

- [x] ✅ **Workflow `sync_bubble_mirror` identificado:** `FGxG67I24POOUeHW` (SYNC ESPEJO — Bubble → Supabase). Webhook `/espejo_a_supabase` cbi. Verificado 2026-04-25.
  - **Mapping:** dinámico (lowercase + replace espacios/dashes con underscore). NO hace falta añadir `rol` manualmente — se mapea automático cuando Bubble lo envía en el body del webhook.
  - **Tablas en `ALLOWED_TABLES`:** `bub_invitacion` y `bub_agencia` ya están incluidas. Si se añaden los campos Stripe a `Agencia`, también se mirrorizarán automáticamente.

### Stripe

- [ ] Configurar webhook endpoint en Stripe → URL del workflow n8n "Stripe → Provision"
- [ ] Cambiar Payment Links de TEST a producción en la landing (`work.thenucleo.com`)
- [ ] Verificar que `customer_email` llega en el payload del webhook

### GHL

- [ ] Verificar/crear template de email para owner (puede ser el mismo que invitaciones, revisar copy)

---

## Edge cases a cubrir

1. **Compra doble** — mismo email compra dos veces → buscar Agency por `stripe_customer_id` antes de crear
2. **Email distinto en Stripe y en registro** — Pepito paga con `gmail` pero se registra con otro email → no matchea. Solución: página de activación permite cambiar `owner_email` en la Agencia antes de registrarse
3. **Token ya usado** — la página `registro-invitacion` debe filtrar `aprobada = false` al buscar por token
4. **Invitaciones antiguas sin campo `rol`** — tratar `rol = empty` como "no asignar rol" en el workflow
5. **n8n falla a mitad** — Agency creada pero Invitacion no → Pepito pagó pero no recibe email → necesita error handler + alerta
6. **Stripe webhook retry** — workflow debe ser idempotente (check por `stripe_customer_id`)
7. **Miembro de equipo cuya agencia cancela** — mensaje de acceso denegado diferente al del owner

---

## Pendiente documentar

- [x] ✅ ID del workflow `sync_bubble_mirror` → `FGxG67I24POOUeHW`.
- [x] ✅ Campos actuales de `Agencia` (Bubble Data Type) reflejados en `bub_agencia`: ver sección "Tabla Agencia" arriba.
- [ ] Workflow `Stripe → Provision` aún no creado en n8n.
- [ ] Workflow `Stripe → Update status` aún no creado en n8n.
- [ ] Schema de payload exacto del webhook Stripe `checkout.session.completed` que va a recibir n8n (campos requeridos del lado de TheNucleo).
