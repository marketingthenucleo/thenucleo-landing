---
title: Log Google Chat
dominio: integracion
estado: rollout-activo
actualizado: 2026-05-14
tags: [google-chat, log, actividad, n8n, pubsub, workspace-events]
---

# Actividad Diaria Log — captura vía Google Chat

Captura automática de **todos** los mensajes operativos escritos en los espacios cliente de Google Chat (`E | BENJA`, `E | Iruelas Activo`, `E | LASER SPACE`, …) → clasificación con LLM → persistencia en Bubble `actividad_diaria_log` → espejo Supabase `bub_actividad_diaria_log`.

> **Naming (2026-05-07):** se nombró `actividad_diaria_log` para evitar confusión con `bub_tareas_notion` y las tareas de ClickUp. "Tarea" en TheNucleo es siempre del gestor (Notion/ClickUp); "actividad" es contexto humano libre escrito en chat.

> **Fase 2 v2 (2026-05-08):** la primera versión (HTTP webhook directo) solo recibía mensajes con @mention al bot. La v2 usa **Workspace Events API + Pub/Sub** para captar TODO sin fricción. Esta doc refleja v2 ya en producción para el espacio piloto.

## Estado actual (2026-05-11)

| Componente | Estado | Detalle |
|---|---|---|
| Supabase `bub_actividad_diaria_log` | ✅ | PK `bubble_id`, UNIQUE `gchat_message_id`, RLS, trigger `set_synced_at` |
| Supabase `bub_clientes.gchat_space_id` | ✅ | columna text, indexada |
| Supabase `gchat_subscriptions` | ✅ | tracking de subscriptions activas |
| Bubble Data Type `actividad_diaria_log` | ✅ | 12 fields, Data API expuesta, deployed live. Desde 2026-05-09 trae `autor_email` + `autor_nombre` poblados. Desde 2026-05-11 incluye `oculto` (yes/no, default no) para soft-hide manual |
| Bubble `Clientes.gchat_space_id` | ✅ | text, deployed live |
| Bubble DB Trigger sync espejo | ✅ | sobre `actividad_diaria_log is modified` → `sync_bubble_mirror` |
| Bubble DB Trigger sobre Clientes (gchat_space_id changed) | ⏸ | Pendiente configurar Ben para activar el ciclo onboarding automático con `gJfDb3Gwrf7fJ8Li` |
| n8n SYNC ESPEJO `FGxG67I24POOUeHW` | ✅ | `bub_actividad_diaria_log` en `ALLOWED_TABLES` |
| n8n `8snJvdNsmRM2yI2y` (Pub/Sub push) | ✅ | Activo. Endpoint `/gchat_pubsub_push`. 17 nodos. Smoke E2E completo OK 2026-05-09 ejec `117247` (latencia 3.5s, autor_email + autor_nombre resueltos vía Admin SDK) |
| n8n `xzNDkDNiUOYOA2Ku` (lifecycle, auto-match) | ✅ | **Activo desde 2026-05-09** (Fase 3 #2). 10 nodos: Verify Token + JWT dual-issuer + Decode (parser moderno + fallback legacy) + IF ADDED + GET Clientes Agencia + Match Fuzzy + IF Match Único + PATCH cliente. Solo ADDED_TO_SPACE; REMOVED diferido a Fase 4 |
| n8n `gJfDb3Gwrf7fJ8Li` (SUB Crear Subscription) | ⏳ | Inactivo. Pendiente: tag `portal` + DB Trigger Bubble + activar |
| n8n `NMZA404s1agKcHau` (CRON renewal 3h) | ✅ | Activo. Intervalo bajado de 6h→3h 2026-05-14 tras observar gap real ~4.5h. Refactorizado 2026-05-09 a **POST CREATE idempotente** sobre `/v1/subscriptions` (en lugar de `:reactivate`, que daba 403 sobre subs expiradas). Body completo con `targetResource`+`eventTypes`+`pubsubTopic`+`includeResource`+`ttl=0s`. Google reutiliza la sub existente por `(target, pubsubTopic)` y devuelve la misma con `expireTime` nuevo |
| GCP Chat App "TheNucleo Log Bot" | ✅ | Visibility privada (thenucleo.com), Marketplace publicado |
| GCP Workspace Events API | ✅ | Habilitada |
| GCP Pub/Sub topic + subscription | ✅ | `gchat-events-thenucleo` + push OIDC |
| GCP SA `chat-token-thenucleo` | ✅ | Marketplace OAuth client + admin install autorizado. Client ID `104465876387432355478` |
| GCP SA `push-thenucleo-log-bot` | ✅ | OIDC token signer del Pub/Sub push |
| GCP Admin SDK API | ✅ | Habilitada 2026-05-09 en proyecto `app-thenucleo` (project number `817779477263`) |
| GCP Domain-Wide Delegation | ✅ | Admin Console allowlist: Client ID `104465876387432355478` + scope `admin.directory.user.readonly` |
| Cred n8n app-level `nJOGize9nY0rINy4` | ✅ | "Bot Log Actividad - Service Acount". Sin Impersonate. Scopes `chat.app.*.readonly`. Usada por CRON renewal y SUB Crear Subscription |
| Cred n8n DWD `aantW5sGVzfHR703` | ✅ | "Bot Log Actividad - Service Acount Acceso Emails". **Impersonate ON** + Subject `benjamin.sanchis@thenucleo.com` (User Management Admin) + scope `admin.directory.user.readonly`. Usada solo por GET Admin User en Pub/Sub workflow. ⚠️ Test connection del UI da falso negativo, validar con HTTP Request real |
| Workspace Events Subscriptions | ✅ | **24 subs activas** en `gchat_subscriptions` tras rollout 2026-05-09 (18:24–19:33 UTC). TTL 24h, renewal cubierto por `NMZA404s1agKcHau` |
| Clientes Bubble con `gchat_space_id` | ✅ | **23 clientes mapeados** (rollout 2026-05-09 — auto-match Fase 3 #2 cubrió el grueso, ajustes manuales en los pocos sin match único) |
| Smoke test E2E completo | ✅ | 2026-05-09 ejec `117247`: mensaje "Reunión cliente confirmada para mañana 11h" → fila `1778345372957x821891576127878300` con `clasificacion=decision`, `autor_email=benjamin.sanchis@thenucleo.com`, `autor_nombre=Benjamin Sanchis`, latencia 3.5s |
| Bubble UI Frontend Log Google | ✅ | **Construido 2026-05-11.** FloatingGroup `Log Google` con 2 filtros (Multidropdown Clientes + Multidropdown Responsables/User) + RG anidado: outer type `Clientes` que dedupea via `Search actividad_diaria_log:each item's cliente:unique elements` (sort `cliente's nombre_empresas` asc), inner type `actividad_diaria_log` scopeado a `cliente=Current cell's Cliente` (sort `fecha_chat` desc). Group Responsable muestra account manager del cliente desde `Current cell's Clientes's responsable(s)`. Patrón canónico filtro: `Ignore empty constraints` ON + `is in` (NO `:filtered` advanced ni `=:first item`). |
| Deep-link al mensaje en Google Chat | ✅ | **Cerrado 2026-05-11.** Cada cell del inner RG es clickable con URL construida al vuelo en Bubble: `https://chat.google.com/u/0/app/chat/[space_short]/topic/[message_short]`. Operadores Bubble: `gchat_space_id :find & replace "spaces/" → ""` para el space short, `gchat_message_id :split by "/messages/" :last item` para el message short. Formato verificado con "Copiar enlace al mensaje" real en GChat web. Abre el thread completo del mensaje (no el mensaje aislado — limitación del web client GChat). |
| Toggle expand/collapse por cliente | ✅ | **Cerrado 2026-05-11.** Headers de cliente siempre visibles + botón toggle que expande/colapsa el inner RG de mensajes. Patrón: custom state `clientes_expandidos` (List of Clientes) en `FloatingGroup Log Google` + conditional sobre el inner RG (`visible = yes when state contains Current cell's Cliente`) + `Collapse when hidden = yes` + workflow on-click con 2 Set state acciones (`:plus item` y `:minus item`) con `Only when` opuestos. Permite múltiples clientes expandidos simultáneos. Icono chevron también cambia via conditional. |
| Expandir/Contraer todos (acción global) | ✅ | **Cerrado 2026-05-11.** Botón `Text Desplegar` con 2 workflows separados sobre el mismo click event (estilo Bubble válido alternativo al patrón 1 workflow + 2 steps): (1) Expandir todos → `Set state clientes_expandidos = RepeatingGroup Log Conversacion Google Chat's List of Clienteses`, Only when `state:count < RG List:count`. (2) Contraer todos → `Set state clientes_expandidos = state :minus list state` (truco Bubble para lista vacía, no existe literal empty list), Only when `state:count is RG List:count`. Reactivo a los filtros aplicados (el `RG's List of Clienteses` refleja los items actualmente cargados respetando dropdowns + limit 500). |
| Soft-hide individual + "Limpiar todo" | ⏳ | **Schema listo 2026-05-11**, UI pendiente. Supabase y Bubble field `oculto` (boolean/yes-no, default false/no). RG filter: `oculto is no` + `Ignore empty constraints`. Por cell: checkbox/icon "ocultar" → WF `Make changes to Current cell's actividad_diaria_log → oculto = yes`. Botón "Limpiar todo" → WF `Make changes to a list of things → list = RepeatingGroup's List of actividad_diaria_log → oculto = yes` (respeta filtros activos del RG). Sin opción "deshacer" en MVP — cambio reversible solo desde Bubble admin. |

---

## Arquitectura v2

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Google Chat                                     │
│                                                                          │
│  Espacio cliente (E|BENJA, E|Iruelas, …)                                 │
│    │                                                                     │
│    ├─▶ MESSAGE event ─────────────────┐                                  │
│    │   (capturado por subscription)   │                                  │
│    │                                  ▼                                  │
│    │                    Workspace Events API                             │
│    │                                  │ delivery                         │
│    │                                  ▼                                  │
│    │              Pub/Sub topic: gchat-events-thenucleo                  │
│    │                                  │                                  │
│    │                                  │ push (OIDC JWT firmado          │
│    │                                  │  por push-thenucleo-log-bot)     │
│    │                                  ▼                                  │
│    │      n8n /gchat_pubsub_push (workflow 8snJvdNsmRM2yI2y)             │
│    │      ├─ Respond 204 inmediato                                       │
│    │      ├─ Verify Token (HTTP GET tokeninfo de Google → claims)        │
│    │      ├─ Validar JWT (claims: aud=URL, email=push-…, exp)            │
│    │      ├─ Decode envelope (base64 data + attributes ce-type)          │
│    │      ├─ Validar Evento (eventType MESSAGE? no bot? no vacío?)       │
│    │      ├─ GET Cliente Bubble by gchat_space_id                        │
│    │      ├─ IF Cliente Found → Anthropic Classify (Haiku 4.5)           │
│    │      └─ IF log_worthy → POST Bubble actividad_diaria_log            │
│    │                              │                                      │
│    │                              ▼ (Bubble DB Trigger)                  │
│    │                  SYNC ESPEJO (FGxG67I24POOUeHW)                     │
│    │                              │                                      │
│    │                              ▼                                      │
│    │                  bub_actividad_diaria_log (Supabase)                │
│    │                                                                     │
│    └─▶ ADDED/REMOVED_FROM_SPACE event ────┐                              │
│        (lifecycle, llega directo HTTP)    │                              │
│                                           ▼                              │
│                          n8n /gchat_log_inbound (xzNDkDNiUOYOA2Ku)       │
│                          (en MVP: ack 200 silent. Fase 3: auto-match)    │
└─────────────────────────────────────────────────────────────────────────┘
```

**Decisiones tomadas:**

| Decisión | Valor | Razón |
|---|---|---|
| Captura de mensajes sin @mention | Workspace Events + Pub/Sub | Única vía documentada por Google |
| Endpoints n8n | 2 separados (lifecycle vs Pub/Sub) | Auth/payload distintos por path |
| Payload subscription | `includeResource: true` | Mensaje en evento, sin GET extra |
| TTL subscription | 24h (lo asignado por Google sin DWD) | Renewal cron cada 12h en Fase 3 |
| Pilot | E\|BENJA → cliente TheNucleo | Cero riesgo a datos cliente reales |
| JWT validation | Activa desde día 1 en endpoint Pub/Sub | Endpoint público en internet |
| Anti-duplicado | UNIQUE `gchat_message_id` en Supabase | Defensa de último nivel ante reintentos Pub/Sub |
| Mapping cliente↔space | Manual en pilot, auto-match en Fase 3 | MVP-first |

---

## Schema

### Supabase `bub_actividad_diaria_log`
```
bubble_id text PK              -- bubble unique id
agencia_id text                 -- denormalizado, viene del Cliente
cliente text                    -- bubble id de bub_clientes
notion_id text                  -- denormalizado para joins rápidos
mensaje text                    -- raw del chat
mensaje_resumen text            -- 1 frase generada por Claude
autor_email text
autor_nombre text
gchat_space_id text
gchat_message_id text UNIQUE    -- defensa anti-duplicado en reintentos
gchat_thread_id text
clasificacion text              -- status|decision|incidencia|configuracion|entrega|solicitud|otro
fecha_chat timestamptz
created_date timestamptz
modified_date timestamptz
creator_id text                 -- mantenido por SYNC ESPEJO desde Bubble Created By
slug text                       -- mantenido por SYNC ESPEJO desde Bubble Slug
oculto boolean NOT NULL DEFAULT false  -- soft-hide manual desde UI (checkbox + Limpiar todo)
_synced_at timestamptz
```
Índices: `cliente`, `agencia_id`, `fecha_chat DESC`, UNIQUE `gchat_message_id`, `(agencia_id, oculto, fecha_chat DESC)`. RLS enabled (sin policies, mismo patrón que el resto de `bub_*`).

### Supabase `gchat_subscriptions` (tracking)
```
id text PK                      -- name de la subscription Workspace Events
                                -- formato: subscriptions/chat-spaces-XXX
space_id text NOT NULL          -- spaces/AAA…
cliente_bubble_id text          -- bubble unique id del cliente mapeado
status text NOT NULL            -- active | suspended | error
expire_time timestamptz         -- vence ~24h después de creación/renewal
last_renewed_at timestamptz
last_error text
created_at timestamptz NOT NULL
updated_at timestamptz NOT NULL
```
Verificado 2026-05-10 vía MCP: 24 filas con `status='active'`. La gran mayoría sin `last_renewed_at` aún (rollout fresco, primera renovación en 24h).

### Supabase `bub_clientes.gchat_space_id`
- text, opcional. Formato `spaces/AAAA…`. Indexado parcial.

### Bubble Data Type `actividad_diaria_log`
| Campo | Tipo Bubble | Notas |
|---|---|---|
| cliente | Clientes | obligatorio |
| agencia_id | Agencia | obligatorio (denormalizado) |
| mensaje | text | raw del chat |
| mensaje_resumen | text | resumen del classifier |
| autor_email | text | |
| autor_nombre | text | |
| gchat_space_id | text | |
| gchat_message_id | text | único — anti-duplicado |
| gchat_thread_id | text | nullable |
| fecha_chat | date | timestamp del mensaje |
| clasificacion | text | status\|decision\|incidencia\|configuracion\|entrega\|solicitud\|otro |
| oculto | yes / no | default `no`. Soft-hide manual desde UI. Filtro RG `oculto is no` esconde la fila sin borrarla |

DB Trigger: "Sync actividad_diaria_log a Supabase" → POST API Connector `sync_bubble_mirror` con body `{tabla: "bub_actividad_diaria_log", bubble_id: <id>}`.

---

## Workflow n8n principal — `8snJvdNsmRM2yI2y`

**Path webhook (live):** `https://n8n-n8n.irzhad.easypanel.host/webhook/gchat_pubsub_push`

**Modelo Anthropic:** `claude-haiku-4-5-20251001` con `tool_use` forzado. Garantiza JSON estructurado: `{ log_worthy: bool, clasificacion: enum, resumen: string }`.

**Detección de URLs (desde 2026-05-11):** mensajes con URL siempre se loguean — la decisión es determinista (regex en `Validar Evento`), no la toma el LLM. Función `classifyResource(url)` mapea dominios conocidos (Google Docs/Sheets/Slides/Drive/Meet/Calendar, Figma, Notion, ClickUp, Loom, YouTube, GitHub, Portal TheNucleo) a etiquetas legibles; el resto cae en `enlace (<hostname>)`. El classifier recibe metadata `has_url` + `tipos detectados` y solo genera la narrativa: `"Joaquín compartió un Google Doc"` o, si hay texto adicional, `"Joaquín compartió un archivo de Figma: mockups del onboarding"`. Placeholder `__AUTOR__` en el resumen (no `{{AUTOR}}`, conflicto con parser n8n) se sustituye en el POST a Bubble por `autor_nombre` resuelto vía DWD.

**Clasificación `solicitud` (desde 2026-05-11):** añadida tras incidencia Membersfy. Mensajes con menciones (`@usuario`) que piden acción/confirmación/acceso/revisión, o peticiones operativas sin mención con verbos de acción dirigidos al equipo ("necesito que...", "podéis...", "me avisan", "confirmadme", "hace falta..."), se clasifican como `solicitud` con `log_worthy=true`. Resumen formato: `"__AUTOR__ pidio {accion concreta} a {mencionados o equipo}"`. Solicitudes genéricas sin acción concreta ("hola equipo, alguna novedad?") siguen siendo noise. Cambios en nodo `Build Classify Body`: enum del schema, regla en system prompt, lista log-worthy ampliada, lista noise limpiada de "preguntas sin contexto".

**Anti-duplicado (doble defensa):**
1. **Pre-check n8n** (Fase 3 #6, 2026-05-08): nodos `GET Dup Check` + `IF Es Duplicado` entre `IF Cliente Found` y `Build Classify Body`. Si Pub/Sub reentrega, terminate ANTES de Claude. Posición temprana = ahorra coste de tokens además del POST Bubble.
2. **UNIQUE Supabase** `bub_actividad_diaria_log.gchat_message_id`: defensa de último nivel para race conditions (2 reintentos solapados llegan al pre-check antes de que el primero haya completado el POST a Bubble).

**Errors:** `errorWorkflow: HRDQ9Ju4NAIUV0qyhKzlz` → enriquece e inserta en `n8n_incidencias`. Visible en `work.thenucleo.com/incidencias`.

**Validación JWT (2 nodos):**
- **`Verify Token`** (HTTP Request): GET `https://oauth2.googleapis.com/tokeninfo?id_token={{ token }}`. Google verifica firma RSA y devuelve los claims parseados. Si firma inválida → 4xx → workflow aborta. Latencia ~50ms.
- **`Validar JWT PubSub`** (Code, sin crypto): valida claims devueltos por tokeninfo:
  - `iss = accounts.google.com` o `https://accounts.google.com`
  - `aud = https://n8n-n8n.irzhad.easypanel.host/webhook/gchat_pubsub_push`
  - `email = push-thenucleo-log-bot@app-thenucleo.iam.gserviceaccount.com`
  - `email_verified = "true"` (string, no boolean — tokeninfo lo devuelve como string)
  - `exp` no expirado

> **Por qué tokeninfo en lugar de verificar firma local:** el task runner de n8n bloquea `require('crypto')` y `require('https')` por allow-list, así que la verificación RSA local desde Code node es imposible. Delegar a tokeninfo es la solución oficial sin tocar config server. Ver memoria `feedback_n8n_task_runner_this.md`.

---

## Setup paso a paso GCP (probado 2026-05-08)

### 0. Pre-requisitos
- Proyecto GCP `app-thenucleo` (Project Number `817779477263`).
- Google Chat API habilitada y Chat App "TheNucleo Log Bot" creada con visibilidad privada (thenucleo.com).
- Acceso admin Google Workspace (`marketing.thenucleo@gmail.com`).

### 1. Habilitar APIs
```
https://console.cloud.google.com/apis/library/workspaceevents.googleapis.com?project=app-thenucleo
https://console.cloud.google.com/apis/library/appsmarket-component.googleapis.com?project=app-thenucleo
```
Habilitar: Workspace Events API + Google Workspace Marketplace SDK.

### 2. Configurar Marketplace SDK App Configuration
**URL:** https://console.cloud.google.com/apis/api/appsmarket-component.googleapis.com/googleapps-marketplace?project=app-thenucleo → tab "Configuración de la app".

| Campo | Valor |
|---|---|
| Visibilidad | **Privada** (NO Pública — irreversible si guardas Pública) |
| Configuración de la instalación | Instalación individual + de administrador |
| Integraciones de apps | ✅ Complemento de Google Workspace, ✅ HTTP u otras implementaciones, ✅ App de Chat independiente |
| Permisos OAuth | Los 5 scopes: `userinfo.email`, `userinfo.profile`, `chat.app.messages.readonly`, `chat.app.memberships.readonly`, `chat.app.spaces.readonly` |
| Información del desarrollador | Nombre/web/email obligatorios |

Tab "Ficha de Play Store" — campos obligatorios mínimos:
- Idioma + Nombre + Descripción corta y detallada
- Iconos 32×32, 48×48, 96×96, 128×128 + Banner 220×140 + ≥1 Captura de pantalla
- URL Condiciones, Privacidad, Asistencia
- Categoría (Productivity)

Pulsar **"Guardar como borrador"** (basta para apps Privadas — no requiere review Google).

### 3. Crear Service Accounts (DOS distintas)

#### 3.A. SA `push-thenucleo-log-bot` (firma OIDC del Pub/Sub push)
**URL:** https://console.cloud.google.com/iam-admin/serviceaccounts/create?project=app-thenucleo

- Nombre: `push-thenucleo-log-bot`
- Sin roles a nivel proyecto.
- **NO crear key JSON** (no se necesita — Pub/Sub la usa internamente para firmar OIDC tokens).

#### 3.B. SA `chat-token-thenucleo` (auth como Chat App)
- Nombre: `chat-token-thenucleo`
- Sin roles a nivel proyecto.
- **Tab "Claves" → Crear clave nueva → JSON** → guardar en sitio seguro como `chat-token-key.json`.
- **Configuración avanzada → "Crear cliente OAuth compatible con Google Workspace Marketplace"** → Continuar. Anotar el Client ID que aparece (será de tipo "Cliente de cuenta de servicio", número de ~21 dígitos).

> ⚠️ **Crítico:** sin este OAuth client, Google rechaza llamadas a Chat API y Workspace Events API con `ACCESS_TOKEN_SCOPE_INSUFFICIENT` aunque el token tenga los scopes correctos.

### 4. Pub/Sub topic + push subscription

**Topic:** https://console.cloud.google.com/cloudpubsub/topic/list?project=app-thenucleo
- Crear `gchat-events-thenucleo`. **Desmarcar** "Agregar suscripción predeterminada".
- Tab "Permisos" del topic → Agregar principal `chat-api-push@system.gserviceaccount.com` con rol **Pub/Sub Publisher**.

**Push subscription:** https://console.cloud.google.com/cloudpubsub/subscription/create?project=app-thenucleo
| Campo | Valor |
|---|---|
| ID | `sub-gchat-events-to-n8n` |
| Topic | `projects/app-thenucleo/topics/gchat-events-thenucleo` |
| Tipo de envío | Insertar (Push) |
| URL del extremo | `https://n8n-n8n.irzhad.easypanel.host/webhook/gchat_pubsub_push` |
| Habilitar autenticación | ✅ |
| Cuenta de servicio | `push-thenucleo-log-bot@app-thenucleo.iam.gserviceaccount.com` |
| Público (audience) | `https://n8n-n8n.irzhad.easypanel.host/webhook/gchat_pubsub_push` |
| Plazo de confirmación | 60 s |
| Retención de mensajes | 7 días |

### 5. Admin install
**URL:** `https://admin.google.com/ac/apps/gmail/marketplace/appdetails/817779477263`

1. Click app TheNucleo Log Bot → **Instalación de administrador**.
2. Aceptar los **5 scopes** (verificar que aparecen los 3 `chat.app.*`).
3. Instalar para **Toda la organización (thenucleo.com)**.

> ⚠️ **Crítico (debug 2026-05-08):** si el Marketplace OAuth client de la SA se crea DESPUÉS del primer admin install, su Client ID queda como **"No concedido"** en la ficha de la app. **Fix:** desinstalar app y reinstalar (no se puede dar acceso individual a un client desde el botón "Dar acceso" — está deshabilitado para Chat apps).

> Verificar tras install: https://admin.google.com/ac/apps/gmail/marketplace/appdetails/817779477263 → tab "Clientes De OAuth" → todos los clients (incluido el de la SA `chat-token-thenucleo`) deben aparecer **"Concedido"**.

### 6. Crear Workspace Events Subscription

Script Node `create-subscription.mjs` (usa `google-auth-library`):

```js
import { GoogleAuth } from 'google-auth-library';

const SCOPES = [
  'https://www.googleapis.com/auth/chat.app.messages.readonly',
  'https://www.googleapis.com/auth/chat.app.memberships.readonly',
  'https://www.googleapis.com/auth/chat.app.spaces.readonly',
];

const auth = new GoogleAuth({
  keyFile: './chat-token-key.json',
  scopes: SCOPES,
});
const client = await auth.getClient();

const r = await client.request({
  url: 'https://workspaceevents.googleapis.com/v1/subscriptions',
  method: 'POST',
  data: {
    targetResource: '//chat.googleapis.com/spaces/AAQAThLQ5ck',
    eventTypes: ['google.workspace.chat.message.v1.created'],
    notificationEndpoint: { pubsubTopic: 'projects/app-thenucleo/topics/gchat-events-thenucleo' },
    payloadOptions: { includeResource: true },
    ttl: '0s', // Google asigna 24h sin DWD
  },
});
console.log(JSON.stringify(r.data, null, 2));
```

Tras crear, persistir tracking en Supabase:
```sql
INSERT INTO gchat_subscriptions (id, space_id, cliente_bubble_id, status, expire_time, created_at, updated_at)
VALUES (
  '<subscription name devuelto>',
  '<spaces/XXX>',
  '<bubble_id del cliente>',
  'active',
  '<expireTime devuelto>'::timestamptz,
  now(), now()
);
```

### 7. Mapping Bubble ↔ Space
Para cada espacio cliente:
1. Bubble Editor → Data → App data → Live → Clientes → cliente correspondiente → editar → `gchat_space_id` = `spaces/XXX`.
2. Verificar en Supabase: `SELECT nombre_empresas, gchat_space_id FROM bub_clientes WHERE bubble_id = '<id>';`

### 8. Activar workflow n8n
n8n UI → workflow `8snJvdNsmRM2yI2y` → toggle Activo.

### 9. Smoke test
Enviar mensaje real al espacio → comprobar:
- n8n execution verde
- Fila nueva en `bub_actividad_diaria_log`

---

## Operación

### Renewal de subscription
TTL = 24h. Cron `NMZA404s1agKcHau` (cada 6h) recrea las subs ya expiradas (`status=active AND expire_time < now()`) vía **POST CREATE idempotente** a `https://workspaceevents.googleapis.com/v1/subscriptions` con cred Google SA `chat-token-thenucleo`. Google reutiliza la sub existente por `(targetResource, notificationEndpoint.pubsubTopic)` y devuelve la misma con `expireTime` nuevo. El `name`/`uid` de la sub se preserva. Gap worst-case ~6h al día (entre expiración real → siguiente tick del cron).

> **Histórico:** la primera versión del cron (2026-05-08) usaba `POST /v1/<id>:reactivate`. Falló en producción 2026-05-09 ejecución `117225` con `403 PERMISSION_DENIED — SUBSCRIPTION_ACCESS_DENIED — "(or it may not exist)"` sobre la sub ya expirada. Causa: Google elimina subs SUSPENDED rápido, y los scopes `chat.app.*.readonly` no autorizan reactivate sobre subs ya perdidas (asimetría — autorizan CREATE pero no `:reactivate` post-mortem). Refactor 2026-05-09 a POST CREATE — patrón validado manualmente con `create-subscription.mjs` el mismo día.

Override manual (testing):
```bash
curl -X POST \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "targetResource": "//chat.googleapis.com/<spaces/XXX>",
    "eventTypes": ["google.workspace.chat.message.v1.created"],
    "notificationEndpoint": {"pubsubTopic": "projects/app-thenucleo/topics/gchat-events-thenucleo"},
    "payloadOptions": {"includeResource": true},
    "ttl": "0s"
  }' \
  https://workspaceevents.googleapis.com/v1/subscriptions
```

### Auditoría de precisión del classifier
Durante las primeras 2 semanas post-activación monitorizar:
- ¿Cuántos mensajes log-worthy fueron descartados como noise? (FN — mirar mensajes en GChat sin entrada en `actividad_diaria_log`).
- ¿Cuántos mensajes noise fueron loguados? (FP — entradas en `actividad_diaria_log` que no deberían existir).
Si precisión baja, refinar system prompt en `Build Classify Body` o crear dataset few-shot.

### Coste
~1k mensajes/mes × 1 call Haiku × ~500 tokens input + 100 tokens output ≈ **<2 €/mes**. Marginal.

### Sin mapping
Si un espacio Google Chat no tiene `gchat_space_id` mapeado a ningún cliente Bubble, el workflow termina silenciosamente (rama false de `IF Cliente Found`). NO se postea reply al espacio. Para auditar espacios sin asignar, revisar las ejecuciones del workflow donde `IF Cliente Found` toma la rama false.

---

## Lecciones aprendidas (debug Fase 2 v2 — 2026-05-08)

### 1. Marketplace SDK Store Listing es OBLIGATORIO para apps internas
Aunque sean Privadas (no van al Marketplace público), Google exige completar la "Ficha de Play Store" con assets gráficos (4 iconos + banner + screenshot) + URLs (condiciones, privacidad, asistencia) + descripción. Sin esto, la app NO aparece en "Aplicaciones internas" del Admin Console y por tanto no se puede instalar.

**Mitigación:** assets generados con PowerShell + `System.Drawing` desde el isotipo TheNucleo en `Design/assets/logos/`. Script y outputs preservados en `C:\tmp\gchat-bot-assets\`.

### 2. La sección "Service account credentials" del Chat API config NO existe en el UI nuevo
Toda la doc oficial referencia esa sección. En 2026 la quitaron. Su función ahora la cubre el flujo "Marketplace-compatible OAuth client" (en Advanced settings de la SA) + admin install que autoriza ese client.

### 3. El admin install solo autoriza OAuth clients que existan EN ESE MOMENTO
Si creas el "Marketplace OAuth client" de una SA DESPUÉS del primer admin install, ese client queda con estado **"No concedido"**. La ficha de app lo refleja como "Estado: parcialmente concedido". El botón "Dar acceso" está deshabilitado para Chat apps.

**Fix obligado:** desinstalar la app desde Admin Console y reinstalar. La nueva install autoriza todos los clients existentes.

### 4. Service Account JSON keys se invalidan silenciosamente
Tras varias acciones en la SA (rotaciones, cambios de Marketplace OAuth, etc.), una key JSON descargada anteriormente puede empezar a devolver `Invalid JWT Signature` en `oauth2.googleapis.com/token` aunque sintácticamente sea válida.

**Fix:** borrar la key vieja en Tab Claves de la SA, generar una nueva, sobreescribir el JSON local.

### 5. Workspace Events API: scopes para CREATE ≠ scopes para GET/LIST
Con los 3 scopes `chat.app.*.readonly` se puede CREAR subscription y llamar `:reactivate`, pero GET y LIST devuelven `ACCESS_TOKEN_SCOPE_INSUFFICIENT`. Documentado por Google de forma confusa.

### 5.bis `:reactivate` no es fiable como mecanismo de renewal (validado 2026-05-08 + 2026-05-09)
Dos hallazgos sucesivos, mismo nodo del cron `NMZA404s1agKcHau`:

1. **2026-05-08:** llamar `subscriptions:reactivate` sobre una sub ya `ACTIVE` no extiende `expireTime`. Solo opera contra `SUSPENDED`.
2. **2026-05-09:** llamar `:reactivate` sobre subs ya **expiradas** devuelve `403 PERMISSION_DENIED — SUBSCRIPTION_ACCESS_DENIED — "(or it may not exist)"`. Google elimina rápido las subs en SUSPENDED, y los scopes `chat.app.*.readonly` autorizan CREATE pero NO reactivate sobre subs perdidas (asimetría documentada en lección 5).

**Solución definitiva:** `POST /v1/subscriptions` con body completo (`targetResource`, `eventTypes`, `notificationEndpoint`, `payloadOptions`, `ttl`). Google reutiliza la sub existente por `(targetResource, pubsubTopic)` y devuelve la misma con `expireTime` nuevo. Cron `NMZA404s1agKcHau` refactorizado a este patrón 2026-05-09. Gap worst-case bajado de ~6h a ~3h el 2026-05-14 (intervalo del cron, tras observar gap real ~4.5h entre expiración 10:00 UTC y próximo tick 15:22 UTC).

### 6. TTL real sin DWD = 24h (NO 4h)
El plan original asumía 4h y proponía renewal cada 3h. La realidad es que Google asigna 24h cuando se llama con `ttl: '0s'`. Renewal cada ~20h basta.

### 7. App-level OAuth client requiere TIPO "Cliente de cuenta de servicio"
Cuando creas el Marketplace OAuth client desde Advanced settings de la SA, aparece en "APIs & Services > Credentials" como tipo "Cliente de cuenta de servicio" (no "Aplicación web"). Esto lo distingue de los OAuth clients web que se usan para User auth.

### 8. El tipo de conexión del Chat App (HTTP vs Pub/Sub) es independiente de Workspace Events
El Chat App puede tener configuración de conexión HTTP (para recibir @mentions y lifecycle), y eso NO interfiere con Workspace Events API. Son canales separados.

---

## Riesgos conocidos

- **Pub/Sub push retries duplican eventos:** ✅ mitigado por **doble defensa** (Fase 3 #6, 2026-05-08): (1) pre-check en n8n vía GET Bubble por `gchat_message_id` antes de Claude — termina sin gastar tokens si ya existe la fila; (2) UNIQUE `gchat_message_id` en Supabase como fallback de race condition.
- **JWT no validado en endpoint lifecycle (`xzNDkDNiUOYOA2Ku`):** TODO antes de usar producción. Por ahora solo recibe lifecycle events propios de Google (no críticos en MVP).
- **Subscription expira a las 24h sin renewal:** ✅ resuelto por cron `NMZA404s1agKcHau` (Fase 3 #1, activo desde 2026-05-08, refactorizado a POST CREATE idempotente 2026-05-09).
- **Bubble Search case-sensitive:** el field `gchat_space_id` debe llamarse exactamente así en Bubble. Ver memoria `feedback_bubble_data_api_conventions.md`.
- **DB Trigger duplicado al copiar:** verificar que `body.tabla` no quede heredado. Ver memoria `feedback_bubble_db_trigger_duplicado.md`.
- **Auto-match cliente con falsos positivos:** N/A en MVP (mapping manual). Fase 3 implementa con safeguard `count != 1 → manual`.
- **Workspace admin policy bloquea Chat App scopes:** baja probabilidad (Ben es admin del dominio).

---

## Fase 3 (después del pilot OK)

| Componente | Detalle |
|---|---|
| ✅ Workflow n8n `OPS LOG — Crear Subscription Google Chat por Cliente` (Fase 3 #3) | **Implementado 2026-05-08, inactive pendiente activación + Bubble.** Workflow `gJfDb3Gwrf7fJ8Li`. Webhook `POST /gchat_subscription_create`. 10 nodos: Webhook → Respond 200 → Validar Body → IF Has Space → GET Existing Sub (idempotente) → IF Already Active → Build Body → Create Subscription (cred googleApi `nJOGize9nY0rINy4`) → Parse → INSERT `gchat_subscriptions`. **Pendientes:** tag `portal`, DB Trigger Bubble sobre Clientes (gchat_space_id changed), smoke con `curl`. Detalle en [[n8n-workflows\|docs/infra/n8n-workflows]]. |
| ✅ Workflow n8n `CRON LOG — Renovar Subscriptions Google Chat (6h)` (`NMZA404s1agKcHau`) | **Activo desde 2026-05-08, refactorizado 2026-05-09.** Cron 6h. SELECT subs en `gchat_subscriptions` con `status='active' AND expire_time < now()` → **POST CREATE idempotente** a `/v1/subscriptions` con body completo (cred Google SA `chat-token-thenucleo`) → UPDATE `last_renewed_at` + `expire_time`. Si falla, errorWorkflow `HRDQ9Ju4NAIUV0qyhKzlz` registra en `n8n_incidencias`. **Histórico:** la versión inicial usaba `:reactivate`, falló en producción 2026-05-09 ejec `117225` con `403 PERMISSION_DENIED` sobre subs expiradas (Google las elimina rápido al pasar a SUSPENDED). Refactor a CREATE — Google reutiliza la sub por `(target, pubsubTopic)` y devuelve `expireTime` nuevo. Detalle en [[n8n-workflows\|docs/infra/n8n-workflows]]. Tag `portal` ✅ aplicado. |
| ✅ Refactor `xzNDkDNiUOYOA2Ku` lifecycle + auto-match (Fase 3 #2) | **Activo desde 2026-05-09.** Workflow renombrado a `OPS LOG — Lifecycle Google Chat (Auto-Match Cliente)`. JWT vía tokeninfo. **Claims aceptados (dual issuer 2026-05-09):** `iss/email ∈ ['chat@system.gserviceaccount.com', 'service-817779477263@gcp-sa-gsuiteaddons.iam.gserviceaccount.com']` — el 2º es la SA `gcp-sa-gsuiteaddons` que firma JWT en apps publicadas vía Marketplace SDK (visible en el campo "Correo electrónico de la cuenta de servicio" del Chat API config en GCP). `aud=URL`. **Parser moderno (2026-05-09):** `Decode Lifecycle Event` extrae `body.chat.{addedToSpacePayload|removedFromSpacePayload|messagePayload}.space` con fallback `body.type`+`body.space` legacy. Bug encontrado en ejec `117276` cuando llegó un `removedFromSpacePayload` real y el parser viejo dejaba todo vacío → bot decía "no responde". ADDED_TO_SPACE → GET ALL clientes agencia → match fuzzy local (lowercase+sin diacritics+alfanum, exact-then-contains) → si único → PATCH `gchat_space_id`. Sin manejo de REMOVED ni DM al admin (Fase 4). Detalle en [[n8n-workflows\|docs/infra/n8n-workflows]]. |
| Bubble DB Trigger sobre `Clientes` (gchat_space_id changed) | Llama al webhook del workflow SUB Crear/Renovar. |
| Bubble UI ficha cliente | Repeating group con `Search for actividad_diaria_log` filtrado por cliente, ordenado fecha desc. Badge color por clasificacion. |
| ✅ Rollout multi-espacio (2026-05-09) | **23 clientes mapeados, 24 subs activas.** Verificado vía MCP 2026-05-10. Bot añadido manualmente a cada espacio, auto-match (Fase 3 #2) cubrió el grueso. |
| ✅ Pre-check anti-duplicado en n8n (Fase 3 #6) | **Implementado 2026-05-08, smoke E2E pendiente.** 2 nodos nuevos en `8snJvdNsmRM2yI2y` entre `IF Cliente Found(true)` y `Build Classify Body`: `GET Dup Check` (Bubble Search por `gchat_message_id`) + `IF Es Duplicado` (rama true → terminate). Posición temprana ahorra coste Claude además del POST Bubble. Doble defensa con UNIQUE Supabase. Detalle en [[n8n-workflows\|docs/infra/n8n-workflows]] sección OPS LOG Pub/Sub. |
| Métricas precisión classifier | Auditar 2 semanas: FN/FP. Refinar system prompt si necesario. |

---

## Referencias rápidas

- **GCP Project:** `app-thenucleo` (Project Number `817779477263`).
- **Supabase Project:** `cbixhqjsnpuhcrcjppah` (cbi).
- **n8n host:** `n8n-n8n.irzhad.easypanel.host`.
- **Pilot space:** `spaces/AAQAThLQ5ck` (E|BENJA) → cliente Bubble TheNucleo (`1772195822486x737945880292517000`).
- **JSON key local:** `C:\tmp\gchat-bot-assets\chat-token-key.json` (NO commitear, NO compartir).
- **Asset images:** `C:\tmp\gchat-bot-assets\icon-*.png` + `banner-220x140.png` + `screenshot.png`.

Detalle completo de IDs/credenciales en [[ids-referencias|docs/infra/ids-referencias]].
