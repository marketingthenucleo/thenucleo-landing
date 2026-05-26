---
title: Bridge Portal Bubble → Ficha de Cliente (Work)
dominio: ficha-cliente
estado: vivo
actualizado: 2026-05-26
tags: [ficha-cliente, work, portal, bubble, supabase, auth, edge-function, sso, magic-link]
---

# Bridge Portal → `/ficha-cliente/` — deep-link sin doble login

Desde el portal Bubble (portal.thenucleo.com), un botón "Ver ficha en Work" abre `work.thenucleo.com/ficha-cliente/?id=<bubble_id>` (o `/estrategia/`, `/timeline/`, …) con la sesión Supabase ya creada. Sin que el admin pase por Google OAuth otra vez.

Patrón: **shared-secret bearer + magic link single-use de Supabase**. Mismo que Linear/Vercel/Notion usan para deep-links autenticados.

## Dos modos de autenticación

La Edge Function (v6+, ACTIVE desde 2026-05-26) soporta **dos modos**, ambos sobre el mismo `BRIDGE_SHARED_SECRET`. La replay window (timestamp ±5 min) es idéntica en los dos casos — la diferencia es solo el transporte de la prueba de posesión del secret.

| Modo | Cuándo usar | Bubble necesita | Sección |
|---|---|---|---|
| 🟢 **Bearer (recomendado)** | Default desde 2026-05-26 — desbloqueo del bug Toolbox. | API Connector con `Authorization: Bearer <secret>` header. **Sin Toolbox, sin Server Script, sin crypto.** 2 steps en el page workflow. | "Setup Bubble — modo bearer" |
| 🟡 **HMAC (legacy)** | Solo si quieres que la firma esté criptográficamente ligada al payload exacto (defensa adicional contra "interceptación + replay con payload alterado"). | Toolbox plugin + Server Script con `crypto.createHmac` firmando `(email\|bubble_id\|timestamp)`. 3 steps. | "Setup Bubble — modo HMAC (legacy)" |

**Por qué bearer es preferible en este caso.** El secret vive en backend privacy de Bubble (header del API Connector, nunca sale al cliente) en ambos modos. El delta de seguridad real lo da la replay window timestamp ±5 min, presente en ambos modos. La mejora de HMAC sobre bearer (firma vinculada al payload) sólo tendría valor si el secret pudiera leakear de Bubble por separado del tráfico HTTPS — escenario en el que el resto de la infra ya estaría comprometida. El coste (debugging Toolbox BETA, ver "Bug Server Script — cerrado 2026-05-26") superaba el beneficio.

## Diagrama de secuencia (modo bearer — primario)

```
[Admin en Bubble portal]
    │ click botón Estrategia/Timeline/Ficha (bubble_id en context)
    ▼
[Bubble page workflow — 2 steps]
    │ Step 1: API Connector call `Config - Supabase Bridge`
    │   POST https://<project>.supabase.co/functions/v1/bridge_from_portal
    │   Headers: apikey + Authorization: Bearer <BRIDGE_SHARED_SECRET>
    │   Body:    { email, bubble_id, timestamp, next_path }
    ▼
[Edge Function `bridge_from_portal` v6 (verify_jwt=false)]
    │ 1. Body sin `signature` → rama bearer
    │ 2. Verificar Authorization header == BRIDGE_SHARED_SECRET (timing-safe)
    │ 3. Validar timestamp (±5 min)
    │ 4. Validar email ∈ allowlist x5
    │ 5. Validar next_path ∈ ALLOWED_NEXT_PATHS
    │ 6. supabase.auth.admin.generateLink({
    │      type: 'magiclink', email,
    │      options: { redirectTo: '…/comunidad/entrar/?next=<next_path>' }
    │    })
    │ 7. INSERT en bridge_audit_log
    ▼
[Bubble recibe { action_link: "…" }]
    │ Step 2: Navigation → "Open an external website" → action_link
    ▼
[Browser navega al magic link de Supabase]
    │ Supabase consume el link → redirige a /comunidad/entrar/?next=…#access_token=…
    ▼
[/comunidad/entrar/ — handler ya existente]
    │ supabase.auth detectSessionInUrl=true procesa el hash
    │ onAuthStateChange dispara SIGNED_IN
    │ location.replace(getNextUrl()) → <next_path>
    ▼
[<next_path>] — autenticado, sin parpadeos del captcha
```

**1 sólo redirect visible (~300ms).** El captcha de "No soy un robot" en `/entrar/` está ocultado por `comunidad-entrar.js` cuando detecta `#access_token=` en el hash.

> El modo HMAC legacy es idéntico salvo que añade un Step 0 con Server Script Toolbox firmando `(email|bubble_id|timestamp)` y manda `signature` dentro del body (header `Authorization` opcional). La Edge Function v6 sigue aceptándolo si el body trae `signature`.

## Componentes

| Componente | Ubicación |
|---|---|
| Edge Function `bridge_from_portal` (v6+) | Supabase project `cbixhqjsnpuhcrcjppah`. Código en `supabase/functions/bridge_from_portal/index.ts` |
| Tabla auditoría `bridge_audit_log` | Supabase `public.bridge_audit_log`. Migration `20260525_bridge_portal_audit_log.sql` |
| API Connector call `Config - Supabase Bridge` | Bubble portal — Plugins → API Connector (sin código en este repo) |
| Page workflow del botón (×3: Estrategia, Timeline, Ficha) | Bubble portal — submenú Cliente, 2 steps por botón en modo bearer |
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

### 5. Configurar Bubble portal — modo bearer (recomendado)

Pre-requisitos Bubble: NINGUNO. No hay que instalar Toolbox. No hay que crear Option Sets (aunque si ya existe `Config (bridge)` del intento anterior con HMAC, vale igual — solo cambia cómo se consume).

Lo único que necesitas es **el shared secret hex** (`BRIDGE_SHARED_SECRET`) accesible en Bubble. Dos formas equivalentes:

- **A) Como App Constant privada** (privacy: backend workflows only). Setup → General → App data → "Add a new App Constant" `bridge_secret` (Text). Pegar el hex. ➜ Disponible como `Get App data:bridge_secret` desde page/backend workflows. Esta es la forma más limpia.
- **B) Como header fijo en el API Connector** (sin dynamic data — pegar el hex literal en el header value). Aún más simple, pero rotar implica editar la call y volver a inicializar.

> Decisión 2026-05-26: durante el rollout se eligió **B** porque es el setup de menor fricción y la rotación es un evento raro. Si más adelante alguna call más necesita el secret, migrar a A.

#### 5.1 API Connector — call `Config - Supabase Bridge`

Plugins → API Connector → la call existente (o crear nueva, Action no Data source) contra `https://cbixhqjsnpuhcrcjppah.supabase.co/functions/v1/bridge_from_portal`:

- **Method:** POST
- **Headers** (3, los tres fijos):
  - `Content-Type: application/json`
  - `apikey: <SUPABASE_ANON_KEY>` (la anon key de cbi — la misma que ya consume `comunidad-supabase.js`)
  - `Authorization: Bearer <BRIDGE_SHARED_SECRET>` — pegar el hex literal aquí, **sin `<>`** y con un espacio detrás de `Bearer`
- **Body (JSON)** — ⚠️ **quitar el campo `signature`** si quedó del intento HMAC:
  ```json
  {
    "email": "<email>",
    "bubble_id": "<bubble_id>",
    "timestamp": <timestamp>,
    "next_path": "<next_path>"
  }
  ```
  - `email`, `bubble_id`, `next_path` → tipos **Text** (parameters).
  - `timestamp` → tipo **Number** (parameter).
- **Response:** la call expone `action_link` (string) del JSON devuelto por la Edge Function.

##### Inicializar la call
La Edge Function exige bearer válido + timestamp fresco + email allowlisted. Para que el Initialize devuelva 2xx (Bubble lo necesita para detectar el response schema):
1. En los Body parameters, hardcodear temporalmente: `email = benjamin.sanchis@thenucleo.com`, `bubble_id = test`, `next_path = /ficha-cliente/?id=test`.
2. Para `timestamp` poner el unix actual (mac/linux: `date +%s` en terminal — pegar el número).
3. Verificar que el header `Authorization` está bien (`Bearer <hex>`).
4. Click **Initialize call** ➜ debe devolver 200 con `action_link`. Bubble guarda.
5. Vaciar de nuevo los Body parameters (en runtime se sobreescriben). El hardcoded del Initialize no afecta a producción.

> El magic link single-use generado por el Initialize **expira en 5 min y vale 1 uso**. Si no lo clickeas, se invalida solo.

#### 5.2 Page workflow del botón — 2 steps

Cada botón del submenú "Cliente" del portal lleva su page workflow:

**Step 1 — API Connector call `Config - Supabase Bridge`:**

| Body parameter | Value |
|---|---|
| `email` | `Current User's email` |
| `bubble_id` | `Current Cliente's bubble_id` (ajusta al data source real de la página: Parent group's Cliente, Current Page Cliente, etc.) |
| `timestamp` | `Current date/time:formatted as XXX:converted to number` (ver nota abajo) |
| `next_path` | composer Bubble: texto literal `/estrategia/?id=` + dynamic data `Current Cliente's bubble_id`. Tabla por botón en 5.3 |

> **`timestamp` desde Bubble nativo:** `Current date/time:formatted as` con format string `X` devuelve unix seconds (Moment.js). En el composer Bubble: pickar `Current date/time` → operator `formatted as` → format `X` → operator `converted to number`. Resultado: Number con el unix actual. La Edge Function también acepta string numérico (`"1747000000"`), así que `:converted to number` es opcional pero recomendado para que el body JSON sea consistente.

**Step 2 — Navigation → "Open an external website":**
- Destination: `Result of step 1 (Config - Supabase Bridge)'s action_link`
- Open in a new tab: ❌ OFF (mismo tab, transición fluida ~300ms).

Eso es todo. **2 steps. Sin Toolbox. Sin Server Script. Sin Option Set.** Si el botón Estrategia funcionaba antes del bug Toolbox solo en lo visual, ahora hay que rehacerlo con estos 2 steps (borrando el Server Script de Step 1 + la call HMAC de Step 2 si quedó).

#### 5.3 next_path por botón

3 botones en el submenú Cliente del portal Bubble. Mismo workflow, distinto `next_path`:

| Botón | `next_path` en Step 1 | Allowlist Edge Function |
|---|---|---|
| **Estrategia** | `/estrategia/?id=` + `Current Cliente's bubble_id` | ✅ |
| **Timeline** | `/timeline/?id=` + `Current Cliente's bubble_id` | ✅ |
| **Ficha (legacy)** | vacío (no incluir la key) → fallback `/ficha-cliente/?id=<bubble_id>` | ✅ |

> ⚠️ La Edge Function valida `next_path` contra una **allowlist** hardcoded: `/ficha-cliente/`, `/estrategia/`, `/timeline/`, `/catalogo/`, `/servicios/`. Fuera de esa lista → 403 con `failure_reason='next_path_not_allowed'` en `bridge_audit_log`. Anti open-redirect: aunque Bubble se comprometa, no puede generar magic links a `/evil/`. Para añadir paths (Catálogo, Servicios, …) tocar el array `ALLOWED_NEXT_PATHS` en `supabase/functions/bridge_from_portal/index.ts` y re-deploy.

### 5b. Setup Bubble — modo HMAC (legacy)

Conservado para retrocompatibilidad. La Edge Function lo sigue aceptando: si el body trae `signature`, salta a la rama HMAC; si no, intenta bearer. **No usar en setup nuevo** salvo razón concreta — el modo bearer hace lo mismo con menos piezas.

Cuando elegir HMAC: si necesitas que la firma esté vinculada al `(email|bubble_id|timestamp)` exacto, p.ej. porque el secret se va a manejar fuera de Bubble (otro backend que firma y manda a Bubble que reenvía sin tocar). Para el caso normal "Bubble llama a Supabase con el secret en backend privacy" no aporta valor real.

Setup completo:
1. Instalar plugin **Toolbox** (expone `Server Script` con Node.js).
2. Option Set `Config` con field `secret` + opción `bridge` con el hex.
3. API Connector como en 5.1 pero **incluir `signature` en el body** y **quitar el header `Authorization`** (o dejarlo, es inofensivo — la Edge Function ignora el header cuando hay signature).
4. Page workflow con **3 steps**: Server Script firmando + API Connector + Navigation.
5. Server Script payload:
   ```js
   const crypto = require('crypto');
   const ts = Math.floor(Date.now() / 1000);
   const msg = properties.email + '|' + properties.bubble_id + '|' + ts;
   output1 = ts;
   output2 = crypto.createHmac('sha256', properties.secret).update(msg).digest('hex');
   ```
   con **3 Keys/Values** (`email`, `bubble_id`, `secret`) + Multiple Outputs ON (Number, Text).

⚠️ Gotchas Toolbox (aprendidas a base de errores 2026-05-26, conservadas porque siguen aplicando si vuelves al Server Script):

1. **`return` NO devuelve valores.** Asignar a globals `output1 = …; output2 = …;` sin `const`/`let`/`var`.
2. **`properties.<key>` requiere Key/Value relleno por completo.** Vacío → `undefined`.
3. **Multiple Outputs OFF por defecto.** Encenderlo y declarar tipos.
4. **`require('crypto')` funciona; `require('https')`/`require('http')` no.**
5. **Dynamic data del Option Set:** `Get an option Config (bridge)'s secret` — hay que pickar la opción concreta, no el set entero.

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
   - **Bubble (modo bearer):** Plugins → API Connector → call `Config - Supabase Bridge` → editar el header `Authorization: Bearer <nuevo_hex>` → click "Reinitialize call" con bearer + timestamp fresh para que devuelva 2xx → Save & Deploy. Si conservaste el Option Set `Config (bridge)` por compatibilidad o uso futuro, actualizarlo también.
   - **Bubble (modo HMAC legacy, si en uso):** editar Option Set `Config (bridge)'s secret` con el nuevo valor → Deploy.
3. Smoke-test: click botón Estrategia/Timeline/Ficha desde el portal → debe abrir la subsección sin error.
4. Registrar la rotación en `docs/log-cambios.md` (fecha + motivo, NO el valor).

Si hay desfase entre ambos lados, las llamadas devolverán 403 con `failure_reason='bad_bearer'` (modo bearer) o `bad_signature` (modo HMAC) en `bridge_audit_log`.

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

## Estado actual del rollout (2026-05-26 — bug Toolbox resuelto by-pass)

Sesión iniciada el 2026-05-25 (Supabase + decisión inline HMAC) y reanudada el 2026-05-26 tras un crash de Claude Code (error 400 `text content blocks must be non-empty`). Contexto perdido recuperado vía dump local + screenshots. Cierre 2026-05-26 noche: switch arquitectónico a **bearer mode** que elimina la dependencia del Toolbox plugin (raíz del bug).

### Lado Supabase ✅ (cerrado 2026-05-26)
- Edge Function `bridge_from_portal` **ACTIVE, `verify_jwt: false`, version 6** — soporta `Authorization: Bearer <secret>` (bearer mode primario) Y `signature` en body (HMAC legacy). Sin debug echo (v5 retirada). Detalle del comportamiento en sección "Dos modos de autenticación".
- Tabla `bridge_audit_log` + RLS + índices aplicados via migration `20260525_bridge_portal_audit_log.sql`. Nueva `failure_reason` posible: `bad_bearer`.
- `BRIDGE_SHARED_SECRET` configurado en Edge Function Secrets (hex 256 bits — el valor NO se commitea ni a docs ni a repo). Mismo secret para ambos modos.
- Redirect URL `https://work.thenucleo.com/comunidad/entrar/**` añadido a Supabase Auth → URL Configuration.
- Patch `assets/js/comunidad-entrar.js` mergeado a main (oculta captcha cuando llega `#access_token=` en hash).

### Lado Bubble ⏳ (pendiente rehacer setup en modo bearer)
- ✅ **API Connector call `Config - Supabase Bridge`** existe, inicializada (response schema `action_link` correcto). **Pendiente:** añadirle el header `Authorization: Bearer <secret hex literal>` y **quitar `signature`** del Body. Reinicializar contra la Edge Function v6 (ver sección 5.1).
- ⚠️ **Option Set `Config (bridge)'s secret`** se puede ELIMINAR o conservar como histórico (ya no se consume desde el workflow bearer). El secret vive ahora en el header del API Connector.
- ⏳ **Botón Estrategia** — rehacer page workflow: eliminar Step 1 Server Script (Toolbox), dejar solo 2 steps: API Connector call → Open external website. Detalle en 5.2.
- ⏳ **Botón Timeline** — idem.
- ⏳ **Botón Ficha (legacy)** — montar de cero con los 2 steps bearer + `next_path` vacío (fallback a `/ficha-cliente/?id=<bubble_id>`).
- ❌ **Backend workflow** + **Server Scripts** del intento HMAC — eliminar / archivar.

### Bug Server Script Toolbox — cerrado 2026-05-26 by-pass arquitectónico

**Síntoma original:** `properties.secret` (y `email`/`bubble_id`) llegaban `undefined` al Server Script de Toolbox aunque los Key/Value estuvieran rellenos, incluso hardcodeando el hex literal. Toolbox revienta con:

```
TypeError [ERR_INVALID_ARG_TYPE]: The "key" argument must be of type string …
Received undefined
    at crypto.createHmac (node:crypto:163:10)
```

**Resolución:** se descarta seguir diagnosticando el plugin Toolbox BETA. La Edge Function v6 acepta **bearer mode** (sin crypto en Bubble), que es la ruta normal para llamar a Edge Functions con un shared secret. Los botones Bubble se rehacen con 2 steps puros de Bubble (API Connector + Open external website) sin tocar Toolbox.

**Causa raíz no diagnosticada (deuda técnica abierta — baja prioridad):** queda sin resolver qué provoca exactamente que `properties.<key>` sea `undefined` en el Server Script. Hipótesis no descartadas (si alguna vez se vuelve a necesitar crypto en Bubble):
- Versión BETA del plugin Toolbox con sintaxis distinta (`inputs.<key>`, `context.<key>`, variables locales directas sin prefijo).
- Bubble cacheando una versión vieja del workflow pese al Deploy.
- Botón en reusable element con override.
- Toggle "Multiple Outputs" mal configurado.

Para futuras necesidades de crypto en Bubble, alternativas en orden de preferencia: (1) **mover la lógica que requiere crypto a una Edge Function o a n8n**, llamada desde Bubble vía API Connector; (2) probar el plugin **"1T - Crypto" o "Bubble Native Crypto"** (alternativas a Toolbox); (3) diagnosticar Toolbox con el snippet debug del histórico (ver "Próximo paso preparado" archivado abajo).

<details>
<summary>Histórico: snippet de debug preparado para diagnosticar Toolbox (no aplicado)</summary>

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

Plan: pegarlo en el Server Script + Deploy + click botón LIVE + leer `body_sample` del debug echo v5 (cuando estaba desplegada) para descubrir si la sintaxis correcta era `inputs.x` / `context.x` / variable directa.

</details>

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

**Genéricos:**

| Síntoma | Causa probable | Fix |
|---|---|---|
| Bubble recibe 403 sin info | Edge Function devuelve `{error: 'forbidden'}` genérico por diseño. | Mirar `bridge_audit_log.failure_reason` para el motivo real. |
| Bubble recibe 200 pero el link redirige al Site URL en lugar del path destino | Falta el wildcard `https://work.thenucleo.com/comunidad/entrar/**` en Supabase Auth Redirect URLs. | Añadirlo en dashboard. |
| `/ficha-cliente/` (o subsección) muestra "cliente no encontrado" | `bubble_id` no existe en `bub_clientes` o el cliente está `estado='No Activo'`. | Verificar el bubble_id en el portal. |
| Captcha "No soy un robot" parpadea al llegar de Bubble | El parche `arrivingFromMagicLink` no se aplicó. | Verificar `assets/js/comunidad-entrar.js` líneas iniciales. |
| `bridge_audit_log` vacío tras llamadas | Falta el `SUPABASE_SERVICE_ROLE_KEY` en la Edge Function o RLS bloquea el insert. | Revisar logs Edge Function en Supabase Dashboard. |
| `failure_reason='next_path_not_allowed'` en el log | El `next_path` enviado por Bubble no empieza por un path de `ALLOWED_NEXT_PATHS` (`/ficha-cliente/`, `/estrategia/`, `/timeline/`, `/catalogo/`, `/servicios/`). | Corregir el composer Bubble. Si quieres habilitar un path nuevo, editar el array `ALLOWED_NEXT_PATHS` en `supabase/functions/bridge_from_portal/index.ts` + re-deploy. |
| `failure_reason='not_in_allowlist'` | El email del User no está entre los 5 admins hardcoded en la Edge Function. | Verificar `Current User's email` en Bubble. Añadirlo al `ALLOWLIST` (los 9 sitios — ver "Allowlist de admins"). |
| `failure_reason='stale_timestamp'` | El timestamp del body desvía más de ±5 min del reloj de Supabase. | Verificar que Bubble envía unix actual (`Current date/time:formatted as X`), no un valor cacheado / hardcoded. |

**Modo bearer (recomendado):**

| Síntoma | Causa probable | Fix |
|---|---|---|
| `failure_reason='bad_bearer'` repetido | El header `Authorization` falta, no empieza por `Bearer `, o el token no coincide con `BRIDGE_SHARED_SECRET`. | Verificar el header en el API Connector: `Authorization: Bearer <hex>` literal con espacio detrás de `Bearer`. Sin comillas. Comparar SHA256 del hex con el fingerprint del Supabase Dashboard (ver L2). |
| `failure_reason='missing_fields'` | Body sin `email` / `bubble_id` / `timestamp` (o tipos incorrectos). | Verificar los Body parameters del API Connector. `timestamp` debe ser numérico (Bubble nativo: `Current date/time:formatted as X:converted to number`). |
| `failure_reason='invalid_json'` con `Got it` modal sin info útil | Body del POST no es JSON parseable. Causa habitual: comilla extra `"` pegada por copy-paste al final del value de algún Body parameter del API Connector. El template `"email": "<email>"` se serializa como `"email": "valor""` → JSON inválido. | Click en cada value de los Body parameters, cursor al final, borrar caracteres extra. Si reaparece, desplegar Edge Function con `debug` echo temporal (ver L3) para ver `body_sample` + `parse_err`. |
| Bubble "Unable to initialize" 403 forbidden sin guardar la API Connector call | Bubble requiere respuesta 2xx en Initialize para detectar response schema. La Edge Function rechaza si el bearer está mal o el timestamp es stale. | Hardcodear temporalmente values válidos + timestamp fresco (`date +%s`) en los Body parameters → Initialize dentro de la ventana 5 min → Bubble guarda. Detalle en 5.1. |

**Modo HMAC (legacy):**

| Síntoma | Causa probable | Fix |
|---|---|---|
| `TypeError [ERR_INVALID_ARG_TYPE]: The "key" argument must be of type string … Received undefined` al pulsar el botón | `properties.secret` (o `email`/`bubble_id`) llega `undefined` al Server Script de Toolbox. Bug conocido del plugin BETA — ver sección "Bug Server Script Toolbox". | **Recomendación: migrar a modo bearer (ver 5.1+5.2).** Si quieres seguir en HMAC, intentar sintaxis alternativas (`inputs.<key>`, `context.<key>`, variable directa sin prefijo) o plugins crypto alternativos a Toolbox. |
| `failure_reason='bad_signature'` repetido | Secret de Bubble ≠ secret de Supabase Edge Function, O el mensaje firmado no es `${email}\|${bubble_id}\|${timestamp}` exactamente. | Comparar SHA256 del secret de Bubble con el fingerprint Supabase (L2). Verificar el orden y los separadores `\|` del mensaje firmado en el Server Script. |
| Bubble alerta "Plugin action Server script error" sin más info | Toolbox no propaga el stack al UI por defecto. | Habilitar "log errors" en el toggle del action + mirar Bubble Server Logs (Logs tab → Server logs). |
| Step 1 OK pero Step 2 (API Connector) no recibe `timestamp`/`signature` | Toolbox tiene "Multiple Outputs" OFF, o `output1`/`output2` se asignaron con `const`/`let`. | Encender Multiple Outputs + declarar tipos (Number/Text) + reescribir como `output1 = …; output2 = …;` sin `const`/`let`/`var`. |
| Secret de Bubble (Option Set) y secret de Supabase parecen no coincidir en el Dashboard | Supabase Dashboard muestra SHA256 del secret, no el valor raw, por seguridad. Bubble Option Set muestra el valor raw. Visualmente parecen distintos pese a estar alineados. | Verificar coincidencia con `echo -n "<valor Bubble>" \| sha256sum` y comparar con el fingerprint que muestra Supabase. Ver L2. |

## Referencias

- Plan original: `~/.claude/plans/habr-a-alguna-forma-ingeniosa-polished-island.md`
- Migration: `supabase/migrations/20260525_bridge_portal_audit_log.sql`
- Código Edge Function: `supabase/functions/bridge_from_portal/index.ts`
- Doc auth/allowlist de la ficha: [[ficha-cliente|docs/work/ficha-cliente]]
- Schema general: [[../infra/supabase-schema|docs/infra/supabase-schema]]
