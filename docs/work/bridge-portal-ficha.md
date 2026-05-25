---
title: Bridge Portal Bubble → Ficha de Cliente (Work)
dominio: ficha-cliente
estado: vivo
actualizado: 2026-05-25
tags: [ficha-cliente, work, portal, bubble, supabase, auth, edge-function, sso, magic-link]
---

# Bridge Portal → `/ficha-cliente/` — deep-link sin doble login

Desde el portal Bubble (portal.thenucleo.com), un botón "Ver ficha en Work" abre `work.thenucleo.com/ficha-cliente/?id=<bubble_id>` con la sesión Supabase ya creada. Sin que el admin pase por Google OAuth otra vez.

Patrón: **HMAC + magic link single-use de Supabase**. Mismo que Linear/Vercel/Notion usan para deep-links autenticados.

## Diagrama de secuencia

```
[Admin en Bubble portal]
    │ click "Ver ficha en Work" (bubble_id en context)
    ▼
[Bubble Backend Workflow `bridge_to_work_ficha`]
    │ email = Current User.email
    │ ts    = unix now
    │ sig   = HMAC-SHA256(BRIDGE_SHARED_SECRET, `${email}|${bubble_id}|${ts}`)
    ▼
[POST https://<project>.supabase.co/functions/v1/bridge_from_portal]
    │ Body: { email, bubble_id, timestamp: ts, signature: sig }
    │ Header: apikey: <SUPABASE_ANON_KEY>
    ▼
[Edge Function `bridge_from_portal` (verify_jwt=false)]
    │ 1. Validar HMAC (timing-safe)
    │ 2. Validar timestamp (±5 min)
    │ 3. Validar email ∈ allowlist x5
    │ 4. supabase.auth.admin.generateLink({
    │      type: 'magiclink', email,
    │      options: { redirectTo: '…/comunidad/entrar/?next=/ficha-cliente/?id=<bubble_id>' }
    │    })
    │ 5. INSERT en bridge_audit_log
    ▼
[Bubble recibe { action_link: "…" }]
    │ Action "Go to external website" → action_link
    ▼
[Browser navega al magic link de Supabase]
    │ Supabase consume el link → redirige a /comunidad/entrar/?next=…#access_token=…
    ▼
[/comunidad/entrar/ — handler ya existente]
    │ supabase.auth detectSessionInUrl=true procesa el hash
    │ onAuthStateChange dispara SIGNED_IN
    │ location.replace(getNextUrl()) → /ficha-cliente/?id=<bubble_id>
    ▼
[/ficha-cliente/?id=<bubble_id>] — autenticado, sin parpadeos del captcha
```

**1 sólo redirect visible (~300ms).** El captcha de "No soy un robot" en `/entrar/` está ocultado por `comunidad-entrar.js` cuando detecta `#access_token=` en el hash.

## Componentes

| Componente | Ubicación |
|---|---|
| Edge Function `bridge_from_portal` | Supabase project `cbixhqjsnpuhcrcjppah`. Código en `supabase/functions/bridge_from_portal/index.ts` |
| Tabla auditoría `bridge_audit_log` | Supabase `public.bridge_audit_log`. Migration `20260525_bridge_portal_audit_log.sql` |
| Backend workflow `bridge_to_work_ficha` | Bubble portal (sin código en este repo) |
| Botón en Bubble | Sección Cliente del portal. Trigger del backend workflow con `bubble_id = Current Cliente.bubble_id` |
| Patch del flicker | `assets/js/comunidad-entrar.js` — oculta captcha si hash trae `access_token=` |

## Setup inicial

### 1. Generar el shared secret
```bash
openssl rand -hex 32
```

Pegar el mismo valor en:
- **Supabase Dashboard** → Edge Functions → `bridge_from_portal` → Secrets → `BRIDGE_SHARED_SECRET`.
- **Bubble portal** → Settings → Privacy & Security → Private API keys (o App Constant privada con visibilidad solo backend).

### 2. Deploy de la Edge Function
Vía MCP Supabase (`deploy_edge_function`) o por dashboard pegando `supabase/functions/bridge_from_portal/index.ts`. Config: **`verify_jwt: false`**.

### 3. Aplicar migration
```
supabase/migrations/20260525_bridge_portal_audit_log.sql
```
Vía MCP Supabase (`apply_migration`) o `supabase db push`.

### 4. Allowlist de redirect URLs en Supabase Auth
**Supabase Dashboard → Authentication → URL Configuration → Redirect URLs:**
```
https://work.thenucleo.com/comunidad/entrar/**
```
Sin esto, el magic link redirige al Site URL por defecto y se pierde el deep-link.

### 5. Configurar Bubble portal
- Instalar plugin **Toolbox** (gratis, para `Server Script` con Node.js — Bubble nativo no expone `crypto`).
- Crear backend workflow `bridge_to_work_ficha`:
  - Input: `bubble_id` (text).
  - Step Server Script:
    ```js
    const crypto = require('crypto');
    const msg = `${properties.email}|${properties.bubble_id}|${properties.timestamp}`;
    return crypto.createHmac('sha256', properties.secret).update(msg).digest('hex');
    ```
  - Step API Connector POST a `https://cbixhqjsnpuhcrcjppah.supabase.co/functions/v1/bridge_from_portal` con `Content-Type: application/json`, `apikey: <SUPABASE_ANON_KEY>`, body `{ email, bubble_id, timestamp, signature }`.
  - Step "Go to external website" → `Result of API Call's action_link`.
- En la página Cliente del portal, añadir botón "Ver ficha en Work" con `When clicked → Trigger bridge_to_work_ficha (bubble_id = Current Cliente's bubble_id)`.

## Seguridad

| Vector | Mitigación |
|---|---|
| **Bubble comprometido → atacante usa el secret para pedir magic links de cualquier admin** | Secret nunca expuesto al cliente (vive en backend workflow Bubble + Supabase secrets). Rotable. Auditoría detecta volumen anómalo. |
| **Replay attack del payload firmado** | Ventana ±5 min por timestamp + magic link single-use de Supabase. |
| **`action_link` filtrado vía referrer header / screenshot / historial** | Magic link single-use (Supabase invalida tras consumir) + TTL 5 min. Riesgo residual muy bajo. |
| **Atacante envía email random fuera de la allowlist** | Allowlist hardcoded x5 + respuesta genérica `403 forbidden` (no revela qué validación falló). |
| **Brute-force del HMAC** | Comparación timing-safe + secret de 256 bits + rate-limit a nivel Supabase Edge Functions (default). |

## Rotación del shared secret

1. Generar nuevo secret: `openssl rand -hex 32`.
2. **En paralelo** (downtime cero del bridge solo si se hace simultáneamente):
   - Supabase → Edge Functions → `bridge_from_portal` → Secrets → editar `BRIDGE_SHARED_SECRET`.
   - Bubble → editar la App Constant privada con el mismo valor.
3. Smoke-test: click "Ver ficha en Work" desde el portal → debe abrir la ficha sin error.
4. Registrar la rotación en `docs/log-cambios.md` (fecha + motivo, no el valor).

Si hay desfase entre ambos lados, las llamadas devolverán 403 (`bad_signature` en `bridge_audit_log.failure_reason`).

## Allowlist de admins

5 emails hardcoded **en 9 sitios ahora** (esta Edge Function añade el 9º):

1. `ficha-cliente/index.html` → `EDITOR_EMAILS`
2. `playbook/index.html` → `EDITOR_EMAILS`
3. `fichas-de-producto/index.html` → `EDITOR_EMAILS`
4. RLS `playbook_progreso`
5. RLS `playbook_task_feedback`
6. RLS `playbook_cliente_servicios`
7. RPC `ficha_cliente_listar` (body)
8. RPC `ficha_cliente_get` (body)
9. **Edge Function `bridge_from_portal` (`ALLOWLIST` const) + tabla `bridge_audit_log` (policy `admins_read_audit`)**

Al añadir/quitar admin, sincronizar los 9 sitios. Casuísticas + disponibilidades tienen sus propios sets independientes (ver `docs/work/ficha-cliente.md` para inventario completo).

**Deuda técnica abierta:** extraer la allowlist a una tabla `admin_emails` + helper RPC `is_work_admin(email)`. Fuera de alcance de este bridge. Tracked en `docs/work/deuda-tecnica.md`.

## Leer la auditoría

```sql
SELECT created_at, email, bubble_id, success, failure_reason, ip
FROM bridge_audit_log
ORDER BY created_at DESC
LIMIT 50;
```

Cualquier admin de la allowlist puede leerla con su JWT (RLS lo permite). Vía supabase-js o `psql` con `SUPABASE_SERVICE_ROLE_KEY`.

Indicadores de problema:
- `success=false` con `failure_reason='bad_signature'` repetido → secret desfasado entre Bubble y Supabase, o intento de fuzzing.
- `success=false` con `failure_reason='not_in_allowlist'` repetido para mismo email → un admin sacado del allowlist sigue intentando usar el bridge (limpiarle el botón Bubble o avisarle).
- Volumen anómalo (>50 success/h por mismo email) → posible Bubble comprometido. Rotar secret.

## Troubleshooting

| Síntoma | Causa probable | Fix |
|---|---|---|
| Bubble recibe 403 sin info | Edge Function devuelve `{error: 'forbidden'}` genérico por diseño. | Mirar `bridge_audit_log.failure_reason` para el motivo real. |
| Bubble recibe 200 pero el link redirige al Site URL en lugar de a `/ficha-cliente/` | Falta el wildcard `https://work.thenucleo.com/comunidad/entrar/**` en Supabase Auth Redirect URLs. | Añadirlo en dashboard. |
| `/ficha-cliente/` muestra "cliente no encontrado" | `bubble_id` no existe en `bub_clientes` o el cliente está `estado='No Activo'`. | Verificar el bubble_id en el portal. |
| Captcha "No soy un robot" parpadea al llegar de Bubble | El parche `arrivingFromMagicLink` no se aplicó. | Verificar `assets/js/comunidad-entrar.js` líneas iniciales. |
| `bridge_audit_log` vacío tras llamadas | Falta el `SUPABASE_SERVICE_ROLE_KEY` en la Edge Function o RLS bloquea el insert. | Revisar logs Edge Function en Supabase Dashboard. |

## Referencias

- Plan original: `~/.claude/plans/habr-a-alguna-forma-ingeniosa-polished-island.md`
- Migration: `supabase/migrations/20260525_bridge_portal_audit_log.sql`
- Código Edge Function: `supabase/functions/bridge_from_portal/index.ts`
- Doc auth/allowlist de la ficha: [[ficha-cliente|docs/work/ficha-cliente]]
- Schema general: [[../infra/supabase-schema|docs/infra/supabase-schema]]
