---
title: Bridge Portal Bubble → Ficha de Cliente (Work)
dominio: ficha-cliente
estado: vivo
actualizado: 2026-05-26
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

#### 5.1 Prerequisites Bubble
- Instalar plugin **Toolbox** (gratis, expone `Server Script` con Node.js — Bubble nativo no incluye `crypto`).
- **Option Set `Config`** con un campo `secret` (text) y **una opción** (p.ej. `bridge`) que tenga ese campo relleno con el shared secret hex. Decisión 2026-05-26: se eligió Option Set en lugar de App Constant porque es accesible desde dynamic data en cualquier page workflow sin permisos extra.
- **API Connector call `Config - Supabase Bridge`** (Action, no Data source) inicializada contra `https://cbixhqjsnpuhcrcjppah.supabase.co/functions/v1/bridge_from_portal`:
  - Method: POST
  - Headers: `Content-Type: application/json`, `apikey: <SUPABASE_ANON_KEY>`
  - Body (JSON):
    ```json
    {
      "email": "<email>",
      "bubble_id": "<bubble_id>",
      "timestamp": <timestamp>,
      "signature": "<signature>",
      "next_path": "<next_path>"
    }
    ```
  - Response: la call expone `action_link` (string) del JSON devuelto por la Edge Function.

#### 5.2 Patrón inline por botón (recomendado, en uso desde 2026-05-26)
Cada botón del portal lleva su propio page workflow con 3 steps. **No** se usa backend workflow — se descartó porque para que un page workflow llame a un backend workflow y reciba un return value hay que crear otra API Connector call apuntando al propio Bubble endpoint, manejar la cookie de sesión, parsear la respuesta wrapped… 30 min más vs los 5 min del inline. La seguridad es la misma (Server Script de Toolbox corre server-side en Bubble, no en el browser).

Receta del **page workflow** (replicar en cada botón cambiando solo el `next_path`):

**Step 1 — Server Script (Toolbox plugin):**
```js
const crypto = require('crypto');
const ts = Math.floor(Date.now() / 1000);
const msg = properties.email + '|' + properties.bubble_id + '|' + ts;
output1 = ts;
output2 = crypto.createHmac('sha256', properties.secret).update(msg).digest('hex');
```

⚠️ **Sin `return`. Sin `const` delante de `output1`/`output2`.** Toolbox lee variables globales (ver "Gotchas Toolbox" abajo).

- **Keys and values** (las tres son obligatorias — si falta una el script recibe `undefined`):

  | key | value (dynamic data Bubble) |
  |---|---|
  | `email` | `Current User's email` |
  | `bubble_id` | `Current Cliente's bubble_id` (ajustar al data source real de la página: Parent group's Cliente, Current Page Cliente, etc.) |
  | `secret` | `Get an option Config (bridge)'s secret` |

- **Multiple Outputs: ON** · `output1: Number` (timestamp unix) · `output2: Text` (firma hex).
- Toggles: async OFF, ignore errors OFF, log errors ON.

**Step 2 — API Connector call `Config - Supabase Bridge`:**

| Body field | Value |
|---|---|
| `email` | `Current User's email` |
| `bubble_id` | `Current Cliente's bubble_id` (mismo que Step 1) |
| `timestamp` | `Result of step 1's output1` |
| `signature` | `Result of step 1's output2` |
| `next_path` | depende del botón (ver tabla 5.3) — composer Bubble: texto literal `/estrategia/?id=` + dynamic data `Current Cliente's bubble_id` |

**Step 3 — Navigation → "Open an external website":**
- Destination: `Result of step 2 (Config - Supabase Bridge)'s action_link`
- Open in a new tab: ❌ OFF (mismo tab, transición fluida ~300ms).

#### 5.3 next_path por botón
3 botones en el submenú Cliente del portal Bubble. Mismo workflow, distinto `next_path`:

| Botón | `next_path` en Step 2 | Allowlist Edge Function |
|---|---|---|
| **Estrategia** | `/estrategia/?id=` + `Current Cliente's bubble_id` | ✅ |
| **Timeline** | `/timeline/?id=` + `Current Cliente's bubble_id` | ✅ |
| **Ficha (legacy)** | vacío (no incluir la key) → fallback `/ficha-cliente/?id=<bubble_id>` | ✅ |

> ⚠️ La Edge Function valida `next_path` contra una **allowlist** hardcoded: `/ficha-cliente/`, `/estrategia/`, `/timeline/`, `/catalogo/`, `/servicios/`. Fuera de esa lista → 403 con `failure_reason='next_path_not_allowed'` en `bridge_audit_log`. Anti open-redirect: aunque Bubble se comprometa, no puede generar magic links a `/evil/`. Para añadir paths (Catálogo, Servicios, …) tocar el array `ALLOWED_NEXT_PATHS` en `supabase/functions/bridge_from_portal/index.ts` y re-deploy.

#### 5.4 Alternativa archivada: backend workflow
El diseño original era 1 botón "Ver ficha en Work" disparando un **backend workflow** `bridge_to_work_ficha` (API Event con auth "This user" + Detect data) con los mismos 3 steps internos. Se descartó 2026-05-26 cuando se decidió tener 3 botones. La receta detallada vivió en este doc hasta el commit anterior — si en algún momento se vuelve a centralizar lógica (Custom Event reusable o backend workflow llamado por API), reusar:
- Server Script idéntico al Step 1 inline.
- API Connector call `Config - Supabase Bridge` igual.
- Auth del API Event = "This user" (no "None required") para que solo users autenticados puedan invocar.

### 5.bis Gotchas Bubble Toolbox `Server Script`

Aprendidos a base de errores 2026-05-26. Cuando reuses el patrón en otros workflows que necesiten `crypto`:

1. **`return` NO devuelve valores.** El script se evalúa como bloque, no como función. Para exponer valores al siguiente step, **asignar a variables globales `output1`, `output2`, …** sin `const`/`let` ni `var`. Toolbox las lee del scope global y las mapea a los outputs declarados en el panel del action.

   ```js
   //  ❌ NO HACE NADA
   return [ts, sig];

   //  ❌ TAMPOCO — const las hace locales al bloque
   const output1 = ts;
   const output2 = sig;

   //  ✅ CORRECTO
   output1 = ts;
   output2 = sig;
   ```

2. **`properties.<key>` solo existe si el par Key/Value está rellenado completamente** en el panel "Keys and values" del action. Si dejas el value vacío o el dynamic data no resuelve (p.ej. Option Set sin opción seleccionada), llega `undefined` y `crypto.createHmac` revienta con `TypeError [ERR_INVALID_ARG_TYPE]: The "key" argument must be of type string …`.

3. **Multiple Outputs OFF por defecto** — si no lo enciendes, los `output1`/`output2` se ignoran. Encenderlo y declarar el tipo de cada output (Number / Text / etc.) antes de mapear al siguiente step.

4. **`require('crypto')` funciona** (es Node nativo) pero **`require('https')` y `require('http')` están bloqueados** por la sandbox del task runner. Si necesitas HTTP saliente desde Toolbox, usar la API Connector como step separado, no `https` dentro del Server Script.

5. **Dynamic data del Option Set: `Get an option <SetName> (<OpcionEspecifica>)'s <campo>`** — no basta con elegir el Option Set, hay que **elegir una opción concreta** dentro del set. Si pulsas solo "Config" sin pickar la opción, Bubble devuelve el set entero (no el field) y el value llega como objeto serializado, no como string → HMAC falla.

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

Las clones `/estrategia/index.html` y `/timeline/index.html` (Sprint 1 de la migración, 2026-05-25) reusan el mismo `EDITOR_EMAILS` que `/ficha-cliente/`, no añaden sitio nuevo — vienen heredados del monolito en el clone-first.

Al añadir/quitar admin, sincronizar los 9 sitios + propagar a los 2 clones (estrategia/timeline). Casuísticas + disponibilidades tienen sus propios sets independientes.

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

## Estado actual del rollout (2026-05-26 — cierre de 2ª sesión)

Sesión iniciada el 2026-05-25 (Supabase + decisión inline) y reanudada el 2026-05-26 tras un crash de Claude Code (error 400 `text content blocks must be non-empty`). Contexto perdido recuperado vía dump local + screenshots del usuario.

### Lado Supabase ✅ (cerrado 2026-05-25; v5 debug temporal 2026-05-26)
- Edge Function `bridge_from_portal` **ACTIVE, `verify_jwt: false`**, pero **actualmente desplegada en version 5 con debug echo** — devuelve `{ error, debug: { stage, content_type, body_length, body_sample, parse_err, … } }` en el body de las respuestas 403 cuando falla `invalid_json` o `missing_fields`. ⚠️ **REVERTIR a version 3 (limpia) cuando se cierre el bug abierto** — la v5 filtra body sample en errores, lo cual es info que un atacante con el secret podría usar para fingerprinting. Código v3 vive en `supabase/functions/bridge_from_portal/index.ts` del repo.
- Tabla `bridge_audit_log` + RLS + índices aplicados via migration `20260525_bridge_portal_audit_log.sql`.
- `BRIDGE_SHARED_SECRET` configurado en Edge Function Secrets (hex 256 bits — el valor NO se commitea ni a docs ni a repo).
- Redirect URL `https://work.thenucleo.com/comunidad/entrar/**` añadido a Supabase Auth → URL Configuration.
- Patch `assets/js/comunidad-entrar.js` mergeado a main (oculta captcha cuando llega `#access_token=` en hash).

### Lado Bubble ⚠️ (en curso)
- ✅ **Option Set `Config`** con campo `secret` creado, opción `bridge` con el hex pegado y verificado (SHA256 del valor coincide con el SHA que muestra Supabase Dashboard).
- ✅ **API Connector call `Config - Supabase Bridge`** inicializada y guardada con response schema correcto (`action_link` como string). Lo certificó una llamada `success=true` registrada a las 07:40:48 UTC del 2026-05-26.
- ✅ **Backend workflow `bridge_to_work_ficha`** creado y luego borrado — se cambió a patrón inline por botón (más simple, ver sección 5.2/5.4).
- ✅ **Botón Estrategia** montado con 3 steps inline + deploy LIVE.
- ✅ **Botón Timeline** montado con 3 steps inline + deploy LIVE.
- ⏳ **Botón Ficha (legacy)** pendiente de cablear.

### Bug abierto al cierre de sesión 2026-05-26 — `properties.secret` llega `undefined` al Server Script

Al pulsar **Estrategia** desde portal LIVE el Server Script del page workflow revienta con:

```
TypeError [ERR_INVALID_ARG_TYPE]: The "key" argument must be of type string or
an instance of ArrayBuffer, Buffer, TypedArray, DataView, KeyObject, or CryptoKey.
Received undefined
    at prepareSecretKey (node:internal/crypto/keys:684:11)
    at new Hmac (node:internal/crypto/hash:166:9)
    at Object.createHmac (node:crypto:163:10)
```

**Lo que SE ha verificado durante la sesión y NO arregla el bug:**

1. ✅ El Option Set `Config` existe con la opción `bridge`. El picker del workflow muestra correctamente `Option set: config` / `Option: bridge` cuando se inspecciona.
2. ✅ El value del key `secret` en "Keys and values" del Server Script muestra `bridge's secret` — sintaxis correcta de Bubble cuando ya pickeaste `config → bridge → 's secret`.
3. ✅ El SHA del secret en Supabase Dashboard coincide con el SHA256 del valor que tiene Bubble en el Option Set (descartado desfase de claves).
4. ✅ Step 1 del workflow es un **Custom State**, no otro Server Script — el Server Script crypto es Step 2 únicamente.
5. ✅ **Hardcodear el secret como texto plano** en el value del key `secret` (eliminando todo dynamic data, escribiendo el hex literal) + Deploy → **SIGUE saliendo el mismo TypeError**. Esto descarta que el problema sea del dynamic data del Option Set.
6. ✅ Deploy a LIVE confirmado tras cada cambio.

**Conclusión parcial:** el problema NO está en cómo se mapea el secret al Option Set ni en el deploy. El Server Script de Toolbox **no recibe `properties.secret`** aunque el value esté hardcodeado. Causas posibles a investigar en próxima sesión:

- La versión instalada del plugin Toolbox (BETA según el badge del UI) podría requerir otra sintaxis para exponer las keys al script (e.g., `context.secret`, `inputs.secret` en lugar de `properties.secret`).
- Bubble podría estar re-ejecutando una versión cacheada del workflow pese a Deploy (probar incógnito + force reload).
- El botón en LIVE podría estar en un reusable element con override que no se actualiza.
- "Multiple Outputs" o algún toggle del action podría estar mal y bloquear el paso de properties.

### Próximo paso preparado para la sesión que viene

Sustituir el contenido del Server Script por una versión **sin `crypto`** que exponga lo que hay en `properties` y mande ese contenido como `signature` del body, para que llegue a Supabase y se vea en el `body_sample` del debug echo. Snippet listo:

```js
const ts = Math.floor(Date.now() / 1000);
output1 = ts;
output2 = 'DEBUG'
  + '|secret_type=' + (typeof properties.secret)
  + '|secret_len=' + (properties.secret ? String(properties.secret).length : 'NIL')
  + '|secret_first10=' + (properties.secret ? String(properties.secret).slice(0,10) : 'NIL')
  + '|email=' + (properties.email || 'NIL')
  + '|bubble_id=' + (properties.bubble_id || 'NIL')
  + '|all_keys=' + Object.keys(properties || {}).join(',');
```

Save → Deploy → click Estrategia desde el portal LIVE. La Edge Function v5 devolverá en el body 403 el `body_sample` con esa cadena DEBUG, mostrando exactamente qué keys ve Bubble y qué tipo/longitud tienen.

**Cuando esté verde:** revertir el Server Script al código real, replicar el patrón en el botón **Ficha (legacy)** sin `next_path`, **revertir Edge Function a version 3 limpia** (sin debug echo), y registrar el cierre en log-cambios.

### Telemetría de la sesión (`bridge_audit_log`)

15+ intentos durante el 2026-05-26 entre 06:10 UTC y 07:49 UTC. Distribución:
- `invalid_json` × ~10: causa identificada, **comilla extra pegada al value del Body parameter `email` del API Connector** (ver "Lecciones aprendidas" abajo).
- `bad_signature` × ~3: clicks del Initialize call con signature dummy `0000...` (esperado, no es bug).
- `success=true` × 1 a las 07:40:48: confirmación de que el flow Supabase está correcto.
- 0 llamadas desde las 07:40:48 → todas las clicks posteriores al botón "Estrategia" murieron en Bubble antes de llegar a la Edge Function (TypeError).

## Lecciones aprendidas (2026-05-26)

### L1 — Comilla extra al hacer copy-paste en Body parameters del API Connector

**Síntoma:** `failure_reason='invalid_json'` en `bridge_audit_log`. El cliente Bubble recibe `{"error":"forbidden"}` sin más info.

**Causa raíz:** el value del key `email` (o cualquier otro string del body) tenía una comilla doble `"` pegada al final por un copy-paste accidental del template:
```
benjamin.sanchis@thenucleo.com"   ← con comilla extra invisible al final
```
Como el body template del API Connector envuelve el placeholder con comillas (`"email": "<email>"`), el resultado serializado era:
```json
"email": "benjamin.sanchis@thenucleo.com"",
```
JSON inválido (doble comilla `""` antes de la coma) → `req.json()` revienta en la Edge Function.

**Fix:** click en el value del Body parameter, cursor al final, borrar cualquier carácter extra. Validar character-by-character. Nunca confiar en visualmente "se ve igual".

**Diagnóstico:** desplegar Edge Function con debug echo (ver L3) para ver el `body_sample` con el `parse_err` exacto (`SyntaxError: Expected ',' or '}' after property value in JSON at position N`).

### L2 — Supabase Dashboard muestra SHA del secret, no el valor raw

Cuando comparas el secret entre Bubble (Option Set, muestra valor raw) y Supabase (Edge Function Secrets, muestra checksum/fingerprint), parecen no coincidir. Pero Supabase Dashboard enseña un SHA256 del valor por seguridad, no el valor.

Para verificar coincidencia:
```bash
echo -n "<valor del Option Set Bubble>" | sha256sum
```
Debe coincidir con el fingerprint que muestra Supabase. Si coincide, los secrets están alineados aunque visualmente sean strings distintos.

### L3 — Patrón de diagnóstico: debug echo en Edge Function

Cuando un error opaco como `invalid_json` impide saber qué está enviando Bubble, desplegar **versión temporal** de la Edge Function que incluya un campo `debug` en el body de la respuesta 403 (NO en `bridge_audit_log`, que está pensada para auditoría limpia).

Pattern aplicado en v5:
```ts
function forbidden(extra?: Record<string, unknown>): Response {
  const payload: Record<string, unknown> = { error: "forbidden" };
  if (extra) payload.debug = extra;
  return new Response(JSON.stringify(payload), { status: 403, headers: { "content-type": "application/json" } });
}

// En el catch del parse:
return forbidden({
  stage: "json_parse",
  content_type: contentType,
  body_length: rawBody.length,
  body_sample: rawBody.slice(0, 500),
  parse_err: String(err),
});
```

Bubble enseña el body completo en su modal "Unable to initialize" cuando Initialize falla, lo que permite ver el `body_sample` y el `parse_err` directamente sin tener que mirar logs.

⚠️ **Revertir SIEMPRE a la versión limpia** (sin debug) cuando se cierre el bug. Filtrar body samples en respuestas 403 es info que un atacante con el secret podría usar para fingerprinting del payload Bubble.

### L4 — Initialize call de Bubble requiere respuesta 2xx, no 4xx

Para que Bubble guarde una API Connector call inicializada (detecta el response schema), la respuesta debe ser 2xx. Un 4xx hace que Bubble pop-up "Unable to initialize" y NO guarda la call.

Workaround para inicializar contra una Edge Function que requiere HMAC + email allowlisted: generar localmente una firma válida con timestamp fresco:

```bash
SECRET="<el hex secret>"
EMAIL="benjamin.sanchis@thenucleo.com"
BUBBLE_ID="test123"
TS=$(date +%s)
SIG=$(printf "%s" "${EMAIL}|${BUBBLE_ID}|${TS}" | openssl dgst -sha256 -hmac "$SECRET" | awk '{print $2}')
echo "timestamp=$TS signature=$SIG"
```

Pegar esos valores en los Body parameters del API Connector → click Initialize call dentro de la ventana de 5 min (TIMESTAMP_WINDOW_SECONDS). Devuelve 200 con `action_link` válido (single-use, expira en 5 min). El user puede ignorar el magic link generado (no clickear). Bubble detecta el schema y guarda la call.

Después de Initialize, los valores del Body parameter son **solo placeholders** — en runtime se sobreescriben con dynamic data desde el page workflow.

## Troubleshooting

| Síntoma | Causa probable | Fix |
|---|---|---|
| Bubble recibe 403 sin info | Edge Function devuelve `{error: 'forbidden'}` genérico por diseño. | Mirar `bridge_audit_log.failure_reason` para el motivo real. |
| Bubble recibe 200 pero el link redirige al Site URL en lugar de a `/ficha-cliente/` | Falta el wildcard `https://work.thenucleo.com/comunidad/entrar/**` en Supabase Auth Redirect URLs. | Añadirlo en dashboard. |
| `/ficha-cliente/` muestra "cliente no encontrado" | `bubble_id` no existe en `bub_clientes` o el cliente está `estado='No Activo'`. | Verificar el bubble_id en el portal. |
| Captcha "No soy un robot" parpadea al llegar de Bubble | El parche `arrivingFromMagicLink` no se aplicó. | Verificar `assets/js/comunidad-entrar.js` líneas iniciales. |
| `bridge_audit_log` vacío tras llamadas | Falta el `SUPABASE_SERVICE_ROLE_KEY` en la Edge Function o RLS bloquea el insert. | Revisar logs Edge Function en Supabase Dashboard. |
| `TypeError [ERR_INVALID_ARG_TYPE]: The "key" argument must be of type string … Received undefined` al pulsar el botón | `properties.secret` (o `email`/`bubble_id`) llega `undefined` al Server Script. | Verificar los 3 pares Key/Value del Step 1 — value relleno con dynamic data válido. Para `secret`: composer debe leer `Get an option Config (bridge)'s secret`, no `Get option Config`. Verificar que la opción `bridge` existe en el Option Set y tiene el hex en el field `secret`. |
| `bad_signature` repetido en `bridge_audit_log` | Secret de Bubble (Option Set) ≠ secret de Supabase Edge Function. | Comparar letra por letra. Si rotaste, hacerlo en paralelo en ambos lados (ver "Rotación"). |
| Bubble alerta "Plugin action Server script error" sin más info | Toolbox no propaga el stack al UI por defecto. | Habilitar "log errors" en el toggle del action + mirar Bubble Server Logs (Logs tab → Server logs). |
| Step 1 OK pero Step 2 (API Connector) no recibe `timestamp`/`signature` | Toolbox tiene "Multiple Outputs" OFF, o `output1`/`output2` se asignaron con `const`. | Encender Multiple Outputs + declarar tipos (Number/Text) + reescribir como `output1 = …; output2 = …;` sin `const`/`let`/`var`. |
| `failure_reason='invalid_json'` repetido con `Got it` modal en Bubble sin info útil | Body del POST no es JSON parseable. Causa habitual: **comilla extra `"` pegada por copy-paste al final del value de algún Body parameter del API Connector** (típico en el value de `email`). El template `"email": "<email>"` se serializa como `"email": "valor""` → JSON inválido. | Click en cada value de los Body parameters, cursor al final, borrar caracteres extra. Desplegar Edge Function con `debug` echo (ver L3 en "Lecciones aprendidas") para ver `body_sample` + `parse_err` con la posición exacta del error. |
| Bubble "Unable to initialize" 403 forbidden sin guardar la API Connector call | Bubble requiere respuesta 2xx en Initialize para detectar response schema. La Edge Function rechaza con 403 si la firma HMAC no es válida. | Generar firma válida + timestamp fresco con `openssl dgst -sha256 -hmac "$SECRET"` (ver L4 en "Lecciones aprendidas"). Pegar en Body parameters → Initialize dentro de la ventana 5 min → Bubble guarda. |
| Secret de Bubble y secret de Supabase parecen no coincidir en el Dashboard | Supabase Dashboard muestra **SHA256 del secret**, no el valor raw, por seguridad. Bubble Option Set muestra el valor raw. Visualmente parecen distintos pese a estar alineados. | Verificar coincidencia con `echo -n "<valor Bubble>" \| sha256sum` y comparar con el fingerprint que muestra Supabase. Ver L2 en "Lecciones aprendidas". |

## Referencias

- Plan original: `~/.claude/plans/habr-a-alguna-forma-ingeniosa-polished-island.md`
- Migration: `supabase/migrations/20260525_bridge_portal_audit_log.sql`
- Código Edge Function: `supabase/functions/bridge_from_portal/index.ts`
- Doc auth/allowlist de la ficha: [[ficha-cliente|docs/work/ficha-cliente]]
- Schema general: [[../infra/supabase-schema|docs/infra/supabase-schema]]
