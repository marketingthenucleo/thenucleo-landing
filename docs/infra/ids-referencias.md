---
title: IDs y Referencias
dominio: referencias
estado: activo
actualizado: 2026-05-21
tags: [ids, credenciales, tokens]
---

# IDs, Tokens y Referencias del Proyecto TheNucleo

**Última verificación:** 2026-05-07.

## Supabase

### Proyecto activo único
- **Project ID:** `cbixhqjsnpuhcrcjppah` (cbi)
- **Región:** eu-west-1
- **URL:** `https://cbixhqjsnpuhcrcjppah.supabase.co`
- **Agencia UUID Supabase (TheNucleo Agency):** `e748c7d4-5823-413d-8cb3-532896f6e41d`
- **Agencia bubble_id (TheNucleo Agency):** `1769513105728x555492736219132700` ← **canónico para Bubble Data API y filtros de vistas cbi**

### Agencia Demo Quasar (creada 2026-05-25 — multitenant convivencia en LIVE)
- **Agencia UUID Supabase:** `bea972de-6499-4086-b8de-57e8ed2d42a7` ← usado en `agencia_id uuid` de tablas operativas cbi (analisis_wip, clockify_time_entries, holded_facturas, holded_metricas, chat_conversations)
- **Agencia bubble_id:** `1779722662984x539340237197417400` ← usado en `agencia_id text` de `bub_clientes`, `bub_user` y filtros Bubble
- **Admin user bubble_id:** `1779723909317x283075801175347600` (email Google `mvplowcost@gmail.com`, Nombre "Demo Admin", `rol=[Admin_agencia]`, `nivel_acceso=4`). Login en `portal.thenucleo.com`.
- **Clientes Demo (3 — todos con `agencia_id` bubble_id Demo):**
  - **Quasar Software** (SaaS) — bubble_id `1779722839720x580126292749689300`, notion_id fake `e83410ee-2eeb-4e87-87f4-260ebbffab83`, CIF `B12345674`
  - **Quasar Shop** (Infoproductos) — bubble_id `1779722940492x447696635447994750`, notion_id fake `b5ddc58a-1956-4f61-bbfa-f79efd5465ae`, CIF `B98765431`
  - **Quasar Studio** (Agencia de Marketing) — bubble_id `1779722945472x798638472515837600`, notion_id fake `b97dcd3e-5c36-4a65-8a68-e053f3d3f4ee`, CIF `B45678912`
- **NO añadir `mvplowcost@gmail.com` a allowlists work.com.** Ni `EDITOR_EMAILS` en HTMLs admin (5 sitios), ni RLS policies `playbook_*` / `casuisticas_board` (4 sitios), ni RPCs `ficha_cliente_*` (2 sitios). La cuenta Demo opera EXCLUSIVAMENTE en Bubble. work.com queda bloqueado por allowlist intencional.
- **Doc operacional + reset/rollback + protocolo refresh fechas:** `docs/portal/demo-quasar.md`.

### Histórico (sunset)
- ~~`mawpgbtdvskmneqqcqag`~~ — proyecto anterior, **INACTIVE** desde mayo 2026. Cualquier ref a maw en docs es histórica.

---

## Bubble

- **Entorno Live:** `portal.thenucleo.com`
- **Entorno Dev:** `app-the-nucleo-agency.bubbleapps.io` (path `/version-test/...` = dev, sin path = live)
- **API Bearer Token:** `088a20b5465b6fa2cb8fbba67f250a79`
- **Base URL API:** `https://app-the-nucleo-agency.bubbleapps.io/api/1.1`

---

## n8n

- **Host:** `n8n-n8n.irzhad.easypanel.host`
- **URL base:** `https://n8n-n8n.irzhad.easypanel.host`
- **Tag canónico Portal:** `portal` (id `8JEzIL3gJwyclObr`) — todos los workflows del Portal lo llevan; los de otros clientes (Iruelas, Freexday, etc.) NO. Se usa para filtrar el backup automático del repo `marketingthenucleo/n8nthenucleo`.

### Credenciales internas (IDs de credencial en n8n)
| Credencial | ID n8n | Notas |
|---|---|---|
| **Espejo Supabase** | `13dKSjEd2XZCYpJa` | supabaseApi cbi. Cred canónica desde 2026-04-21 |
| ~~Supabase legacy~~ | `pmc312jjJKdPClmj` | maw, sin uso activo |
| Bubble Data API | `i8UMJM5KZOGBRf5z` | httpHeaderAuth `Authorization: Bearer 088a20b5...` |
| Bubble Data API (alt) | `IFAeIvEVDbrPBZIW` | httpHeaderAuth equivalente, usado por workflows pre-existentes |
| ClickUp App The Nucleo | (n8n UI) | clickUpApi nativa con token `pk_99714283_BRQ4SRULGHFECRBII0U224EKQC2T4VP5` |
| ClickUp Zenyx (header Authorization) | `Eq9YFJvJi97v9o44` | httpHeaderAuth con mismo token CU. Para HTTP Request `genericCredentialType` |
| Notion | `TSyrz731ipmxXktD` | |
| Anthropic | `LLL40Z5TPEIiWZkM` | |
| Google Drive | `8TLgzFMaYDPtqgo6` | |
| Clockify | `GFyjrb81bcVHERhP` | |
| **Bot Log Actividad - Service Acount** | `nJOGize9nY0rINy4` | googleApi (Service Account `chat-token-thenucleo@app-thenucleo.iam.gserviceaccount.com`). Scopes `chat.app.messages.readonly`, `chat.app.memberships.readonly`, `chat.app.spaces.readonly`. Toggle "Set up for use in HTTP Request node" ON. Creada 2026-05-08 para `NMZA404s1agKcHau` (CRON LOG — Renovar Subscriptions). Reutilizada por `gJfDb3Gwrf7fJ8Li` (OPS LOG — Crear Subscription por Cliente). Reutilizable para futuros workflows Workspace Events / Chat API. ⚠️ El nombre tiene un typo ("Acount") pero es lo que existe live; el ID es lo canónico. |

### Variables de entorno (Easypanel — servicio n8n)

Definidas en **Easypanel → servicio n8n → Environment**. Tras añadir/cambiar, **Deploy/Restart** del contenedor para que las recoja. Accesibles desde Code nodes como `$env.NOMBRE` (NO `process.env.NOMBRE` — el task runner no expone `process`).

| Variable | Para qué | Notas |
|---|---|---|
| `GEMINI_API_KEY` | RAG Cerebro + Newsletter + Análisis (fileSearchStores + generateContent) | Vinculada a service account TheNucleo (formato `AQ.Ab8...` 53 chars, NO `AIzaSy...`). Restringida en GCP a Generative Language API. Rotada 2026-05-24 tras revocación automática del scanner de Google (la vieja `AIzaSyBWk-...` se filtró por estar hardcoded en JS). Header preferido: `x-goog-api-key`. |
| `SUPABASE_SERVICE_ROLE_KEY` | Auth Supabase desde Code nodes (sustituye `httpRequestWithAuthentication` que no funciona en task runner sub-workflow) | JWT 219 chars. Usar como `apikey` + `Authorization: Bearer ...` headers. Patrón canónico en `n8n-workflows.md` lección 15. |
| `BUBBLE_API_TOKEN` | Auth Bubble Data API desde nodos HTTP Request con header explícito (alternativa a la credential `i8UMJM5KZOGBRf5z`) | Mismo token que `088a20b5...` arriba — está repetido en env var como fuente unificada para evitar hardcoded en parameters de HTTP nodes. Usar como `Authorization: ={{ "Bearer " + $env.BUBBLE_API_TOKEN }}`. |
| `AIC_KEY` | Clave de cifrado pgcrypto para `agencia_integraciones_config` (`aic_set` / `aic_get` RPCs) | 32 chars. Set por sesión n8n vía `SET LOCAL app.aic_key = $env.AIC_KEY;`. |
| `TZ` + `GENERIC_TIMEZONE` | Timezone del contenedor + scheduler n8n | `Europe/Madrid` ambos. Sin esto los CRON triggers usan UTC y desfasan 2h en verano. |
| `WEBHOOK_URL` | URL base que n8n usa al construir URLs públicas de webhooks | `https://n8n-n8n.irzhad.easypanel.host` |
| `N8N_BLOCK_ENV_ACCESS_IN_NODE` | Permite que Code nodes lean `$env.*` | `false` (= permitido). Por defecto en versiones nuevas viene `true` y `$env` queda vacío en Code nodes. **CRÍTICO** — sin esta variable a `false`, todos los patches con `$env.GEMINI_API_KEY` etc. fallarían con error de undefined. |
| `N8N_RUNNERS_MAX_OLD_SPACE_SIZE` | Heap V8 por Task Runner process en MB | `1536`. Subido desde 512 el 2026-05-24 tras OOM en `IA Cerebro — Indexar Drive [SUB]` procesando clientes con >50 PDFs. Si vuelve a haber OOM con clientes muy grandes, subir a 2048 o refactor a chunks. |

### Carpetas n8n (project `cehv5Dib1J6eKwYQ` — Personal de Ben)
```
The Nucleo Agency
└── App TheNucleo Agency (id 6NKOF15ZtIVs52l2)
    ├── AutoSYNC (id q3rr4KiKriY4bcfi)
    │   ├── SYNC Tareas (id ssWdt6XeqVPONq9i)
    │   ├── SYNC Clientes (id kvmzEDLMrWrFEW9J)
    │   └── SYNC Otros (id 1hjN7TvawJZkXqdu)
    ├── CHAT_Bubble (id UWoO4e8UcbtxrsvN)
    ├── Dashboard Ads - Media Buyer (id 7385fgdwtPtzx4hR)
    └── Analisis Cliente Final (id HagpPx2csHyH7Dao)
```

---

## Vercel — proyecto `app-landing-thenucleo`

- **Project ID:** `prj_QSnQBAmBM9hlfzPjbs50OHXhdt9D`
- **Cuenta/team:** `marketingthenucleo`
- **Branch producción:** `main`
- **Dominio público:** `https://work.thenucleo.com`
- **Fallback Vercel:** `https://app-landing-thenucleo.vercel.app`
- **Repo:** `marketingthenucleo/thenucleo-landing` (GitHub, push origin/main = deploy automático)

### Deploy Hooks
| Hook | Disparado por | Notas |
|---|---|---|
| `bubble-catalogo-changed` | Bubble DB Triggers `A addons_catalogo is modified` + `A Pagos_Tarifa_Catalogo is modified` (Step 2 API Connector `Vercel Deploy Hook - trigger_rebuild_landing`) | URL semi-secreta. **NO se documenta aquí**; vive en Bubble API Connector y en el setting Vercel del hook. Validar con `POST https://api.vercel.com/v1/integrations/deploy/<hook>` → 201 `{"job":{"id":"...","state":"PENDING"}}` |

### Env vars críticas (Production + Preview)
- `SUPABASE_URL` = `https://cbixhqjsnpuhcrcjppah.supabase.co`
- `SUPABASE_ANON_KEY` = anon JWT del proyecto cbi (público, también inyectado al cliente)
- `SUPABASE_SERVICE_ROLE_KEY` = service_role JWT (server-only, usado por `/api/checkout` y `/api/validate-coupon`)
- `STRIPE_SECRET_KEY` = `sk_test_...` TEST mode actual (cambiar a `sk_live_...` cuando Ben finalice Stripe PROD)
- `PUBLIC_ORIGIN` = `https://work.thenucleo.com` (usado para `success_url` y `cancel_url` del Stripe Checkout)

### MCP
- **Vercel MCP oficial:** `https://mcp.vercel.com` añadido scope user (file `~/.claude.json`). Auth OAuth interactivo via `/mcp`. Read-only (no permite redeploy/cancel/delete via MCP — usar Vercel CLI para escritura).

---

## Google Drive

- **Shared Drive ID:** `0AHG_M2zse8nOUk9PVA`

---

## Notion

- **DB Tareas:** `b67f8416-322f-4761-ba36-40b938ae9387`
- **DB Empresas:** `fd1652ef-2456-4b77-b44c-005b69b0e240`

---

## ClickUp

Acceso vía **MCP server** (no API directa). Configurado en scope user de Claude Code (`~/.claude.json`). Tools disponibles en sesión: `mcp__clickup__*` (requiere reiniciar Claude Code tras instalar).

- **MCP endpoint:** `https://mcp.clickup.com/mcp` (HTTP transport)
- **Auth header:** `Authorization: Bearer pk_99714283_BRQ4SRULGHFECRBII0U224EKQC2T4VP5`
- **Workspace ID Zenyx:** `9008203585`
- **Spaces auditados Zenyx (2026-05-01):**
  - `90080425524` Wikipedia A1M (9 statuses) — **default smoke test**
  - `90127153555` Plantilla Wikipedia Nivel 1 (3 statuses)
  - `90127153580` Plantilla Operaciones Nivel 1 (7 statuses)
  - `90127153591` Plantilla Operaciones Nivel 2 (3 statuses)
  - `90125984063` Consultoría Nivel 3 (3 statuses)
  - `90124170149` Equipo A1M (3 statuses)

Reinstalar (si se borra el config):

```bash
claude mcp add --transport http --scope user clickup https://mcp.clickup.com/mcp \
  --header "Authorization: Bearer pk_99714283_BRQ4SRULGHFECRBII0U224EKQC2T4VP5"
```

---

## APIs Externas

- **Gemini API Key:** `AIzaSyBWk-gPMdM6fOaWj2bpZKlN2iJZqc-lfSk`
- **Clockify Workspace ID:** `68e22513cb6c3d1db549ca50`

---

## Google Cloud — TheNucleo Log Bot (Chat App)

Detalle completo en [[google-chat-log|docs/portal/integraciones/google-chat-log]].

- **GCP Project ID:** `app-thenucleo`
- **GCP Project Number:** `817779477263`
- **Chat App nombre:** `TheNucleo Log Bot`
- **Chat App service account (system, Google-managed):** `service-817779477263@gcp-sa-gsuiteaddons.iam.gserviceaccount.com`
- **Pub/Sub topic:** `projects/app-thenucleo/topics/gchat-events-thenucleo`
- **Pub/Sub push subscription:** `projects/app-thenucleo/subscriptions/sub-gchat-events-to-n8n`

### Service Accounts custom (creadas 2026-05-08)
| SA | Email | Rol |
|---|---|---|
| `chat-token-thenucleo` | `chat-token-thenucleo@app-thenucleo.iam.gserviceaccount.com` | App auth para Workspace Events API + Chat API. JSON key local: `C:\tmp\gchat-bot-assets\chat-token-key.json`. Marketplace OAuth client ID: `104465876387432355478` |
| `push-thenucleo-log-bot` | `push-thenucleo-log-bot@app-thenucleo.iam.gserviceaccount.com` | OIDC token signer del Pub/Sub push (sin JSON key — Pub/Sub la firma internamente) |

### Workspace Events Subscriptions activas
| Space | Cliente Bubble | Subscription name | Expira |
|---|---|---|---|
| `spaces/AAQAThLQ5ck` (E\|BENJA) | TheNucleo (`1772195822486x737945880292517000`) | `subscriptions/chat-spaces-czpBQVFBVGhMUTVjazotMToxMTE5NTMxNDkwMDk1MjI2MTYwOTg` | 2026-05-09T14:05:40Z |

### Endpoints n8n
| Path | Función | Workflow |
|---|---|---|
| `/webhook/gchat_log_inbound` | Lifecycle events (ADDED/REMOVED_FROM_SPACE) | `xzNDkDNiUOYOA2Ku` |
| `/webhook/gchat_pubsub_push` | Mensajes vía Pub/Sub OIDC push | `8snJvdNsmRM2yI2y` |

---

## Comunidad pública (work.thenucleo.com/comunidad)

Detalle completo en [[comunidad|docs/comunidad-publica]].

- **Edge Function:** `https://cbixhqjsnpuhcrcjppah.supabase.co/functions/v1/comunidad_admin_action` (verify_jwt)
- **Google OAuth Client ID (público):** `817779477263-gkjj21peahulv2srkpfnnuqb2p8ighoh.apps.googleusercontent.com`
- **Google OAuth Client Secret:** **NO se documenta**, vive solo en Supabase Auth → Provider Google.
- **Vercel Deploy Hook URL:** **NO se documenta**, vive solo como secret `VERCEL_DEPLOY_HOOK_URL` en Edge Function.
- **Vercel Env Var build:** `SUPABASE_ANON_KEY` (legacy anon JWT, público por diseño).

### Admins (allowlist `comunidad_admins`)
| UID | Email |
|---|---|
| `67e17245-a7d3-4ce8-8530-ad31dcff6f67` | marketing.thenucleo@gmail.com |
| `9d76957f-5ff4-4ee2-89cf-b71ffbe6b000` | benjamin.sanchis@thenucleo.com |

---

## n8n — Workflow IDs

Verificado 2026-05-07. Detalle completo en [[n8n-workflows|docs/n8n-workflows]]. Todos llevan tag `portal`.

Leyenda: ✅ activo · ⏸ inactivo intencional · ⏳ inactivo pendiente · 🗄 archivado

### SYNC
| Workflow | ID | Estado |
|---|---|---|
| SYNC TAREAS — Notion → Bubble | `GjijIDEUyiH05Mg0` | ✅ |
| SYNC TAREAS — ClickUp → Bubble | `eR5SWFkxJmjMT1VI` | ✅ |
| SYNC ESPEJO — Bubble → Supabase | `FGxG67I24POOUeHW` | ✅ |
| SYNC CLIENTES — Notion → Bubble | `FcTmv78nLjbCb2Ea08qbt` | ✅ |
| SYNC CLIENTES — Bubble → Notion + Drive | `wvHcgVqqjkWJcJDu` | ✅ |
| SYNC CLIENTES — ClickUp → Bubble | `SjqnIOJYPAkFMFfW` | ✅ |
| SYNC FINANZAS — Holded → Supabase | `vI3TbyxtFM6wjhBS` | ✅ |
| SYNC TIEMPO — Clockify → Supabase (CRON 23:00) | `ccPQuZmH7DGYRRbe` | ✅ |
| SYNC ADDONS — Bubble → Stripe (Cupones) | `bDYIpOSZ7Ge01Fqt` | ✅ (F2 cerrada 2026-05-10, pendiente header `Authorization` correcto en cred Stripe) |
| ~~SYNC Tarea Bubble → Notion~~ | `9mEU2MzE14mGpry2` | 🗄 (2026-04-27) |
| ~~Sync Miembros Notion → Supabase~~ | `cXewmXMQ8xhKmN8f` | 🗄 (2026-04-27) |
| ~~Sync Tareas v1~~ | `gKhvS7eP1B169bhbtc44a` | 🗄 |

### CRON
| Workflow | ID | Schedule | Estado |
|---|---|---|---|
| CRON TAREAS — Reconciliar Huérfanas Notion | `ZqccS38F2Lz8WFwX` | cada 30 min | ✅ |
| CRON TAREAS — Reconciliar Huérfanas ClickUp | `kbUqzdSOrV7e2lS0` | cada 1h | ✅ |
| CRON ANTI-REBOTE — Limpiar Sync Suppress | `ek5veFfwbeSB0bW3` | cada 5 min | ✅ |
| CRON IA Análisis — Reset Stuck | `V60MieFkQzOszxhh` | cada 15 min | ✅ |
| CRON IA Cerebro — Reindexar RAG | `ZnJSkoWlSusmEjhO` | 3:00 Madrid | ✅ |
| CRON IA Newsletter — Reindexar RAG | `kZE3W2ae0upyGt2E` | 3:30 Madrid | ✅ |
| CRON BLOG — Zenyx Diario | `CNlBtiFCwY69I6Wl` | 18:00 Madrid | ✅ |
| CRON TIEMPO — Calcular Horas Reales | `1f6IGS3cGPMVhQInlG7nX` | schedule | ✅ |
| CRON LOG — Renovar Subscriptions Google Chat | `NMZA404s1agKcHau` | cada 6h | ✅ |
| CRON DEMO — Rolling Refresh Fechas | `Z9Mp78CHNeuEwtCc` | Lunes 03:00 Madrid | ✅ (tag `portal` pendiente UI) |
| ~~Reconciliación tareas v1~~ | `aX4Zo7SCTl45R4H5` | — | 🗄 |

### Chat IA
| Workflow | ID | Función |
|---|---|---|
| IA Cerebro — Chat por Cliente | `JI5Tr7IogqXgaI7a` | ✅ Webhook entrada |
| IA Cerebro — Tool Loop [SUB] | `7yjLwl4cEJa7XAYY` | ✅ Subworkflow Claude |
| IA Cerebro — Indexar Drive [SUB] | `NI1oUwIY99TGk496` | ✅ Subworkflow RAG |
| IA Cerebro — Reindexar RAG Manual | `BqNTrwoQ2iJIcAB4` | ✅ Webhook |
| IA Newsletter — Entrada | `inWFSAEDLCH1kx5P` | ✅ Webhook |
| IA Newsletter — Tool Loop [SUB] | `SfwR7gqs1hBIOV7i` | ✅ Subworkflow |
| IA Newsletter — Entrega [SUB] | `9wnB9NI8Capa4b8s` | ✅ Genera HTML/Word |
| IA Newsletter — KB Fetch [SUB] | `w6Gqo8B6Sqp6Mq9x` | ✅ Subworkflow RAG |
| IA Newsletter — Init | `UBYXNKZ1HHFTZyDX` | ✅ Greeting RAG inicial (2026-04-30) |
| IA Newsletter — Trigger Entrega | `u9DsFadbpb7QiLaP` | ✅ Webhook trigger |
| ~~Chat Tareas (entrada)~~ | `RPdNg5ZNXK0VrOhG` | 🗑 huérfano (UI Bubble no existe). Pendiente archivar |
| ~~Chat Tareas (Tool Loop)~~ | `aGML9yyMsoAQ6ZGL` | 🗑 huérfano. Pendiente archivar |

### IA Análisis Estratégico (sector 7, cbi)
| Workflow | ID |
|---|---|
| IA Análisis — Entrada (webhook) | `dtgF0G35aeJQVVfn` |
| IA Análisis — Tool Loop [SUB] | `FFhkdTFCjTtfyvhP` |
| IA Análisis — KB Fetch [SUB] | `Cfs3NFEE1enu1jTx` |
| IA Análisis — Trigger Entrega | `JtXdkXHm6RyGOJft` |
| IA Análisis — Entrega [SUB] | `QW8VZ9cV5ECsSKvZ` |
| IA Análisis — Init | `8hAokf6zfQl0dMlR` |
| (CRON Reset Stuck — ver sección CRON) | `V60MieFkQzOszxhh` | |

### INTEGRACIONES (multi-provider F1)
| Workflow | ID | Función |
|---|---|---|
| INTEGRACIONES — Probar Conexión Provider [SUB] | `o32vrctYqibCA5C2` | ✅ Smoke test token CU/Notion |
| INTEGRACIONES — Registrar Webhooks Provider [SUB] | `QBLy4DWZ7mUPsfpg` | ✅ Crea webhooks CU + INSERT registry |
| INTEGRACIONES — Rotar Token Provider [SUB] | `4e9s6FpYlWiYlcI9` | ✅ Marca webhooks viejos deprecated |
| INTEGRACIONES — Descubrir Clientes Provider [SUB] | `SMOKYPAzGAYrgpLK` | ✅ Folders CU → bub_clientes + cliente_external_links |
| INTEGRACIONES — Obtener Estados Espacio ClickUp [SUB] | `jsAnENkkzfTs6Kzu` | ⏳ Subworkflow (consumido por wrapper webhook) |
| INTEGRACIONES — Wrapper Webhook Estados Espacio CU | `wHuKjIisVripuobE` | ✅ Webhook → invoca jsAnENkkzfTs6Kzu (Bubble cu_get_space_statuses) |

### Ads — Control de Campañas v2 (Meta + Google, activos 2026-05-12 → unificado 2026-05-21)
| Workflow | ID | Función |
|---|---|---|
| SYNC ADS — Meta Discovery Cuentas | `hwKBGC6QWP2dFObT` | ✅ Cron `*/30 8-21` Madrid. Descubre 23 ad accounts del System User + deriva alertas operativas |
| SYNC ADS — Meta Estructura | `VhlqAQ1vH9HldpH5` | ✅ Cron `30 5` daily. Itera cuentas `activa`, refresca campañas/adsets/anuncios via RPC `ads_upsert_estructura` |
| CRON ADS — Meta Daily 06:00 | `pIxC6RNqHISWvpoU` | ✅ Cron `0 6` daily. Insights día anterior por entidad → `ads_insights_diario` |
| CRON ADS — Google Y Meta Intra-día 30min | `Uqv3R3txzcg8GI1B` | ✅ Cron `*/30 8-21`. **Unificado 2026-05-21** — 2 ramas paralelas: Google (GAQL Snapshot LAST_7_DAYS) + Meta (Insights `last_7d`) → ambas a RPC `ads_actualizar_kpis_snapshot` + RPC `ads_calcular_scoring` |
| ~~CRON ADS — Meta Intra-día 30min~~ | `BCgSCKjzryYaFYMC` | ⏸ LEGACY desde 2026-05-21. Sustituido por `Uqv3R3txzcg8GI1B` (rama Meta unificada con Google) |
| OPS ADS — Acciones Bubble [WEBHOOK] | `sNpVWEkinc4g0KfA` | ✅ POST `/webhook/ads_action`. Switch 3 ramas (refresh / status_toggle / nota_crear) |

**Cuenta de prueba marcada como `activa` para smoke test 2026-05-12:** `act_619783006508057` The Nucleo (owned, balance 167.39€, 1 campaña ACTIVE). Resto sigue `pendiente_asignar`.

### Ads — Legacy (en convivencia, archivar tras smoke verde)
| Workflow | ID | Función |
|---|---|---|
| OPS ADS — Oyente Meta Ads (Gmail) | `4gN3uGhH8NZX2BDU` | ⚠️ LEGACY. Gmail Trigger 1 min. Sustituido por workflow Discovery + alertas derivadas del polling. Archivar tras 2 semanas smoke verde |
| OPS ADS — Receptor Google Ads Script | `fdmkhBOua6pbZh6P` | ⚠️ LEGACY. Webhook desde Apps Script externo. Pendiente migrar a polling Google Ads API con OAuth (patrón paralelo Meta) |
| OPS CRM — Oyente GHL [PAUSADO] | `Ik2Tt3Dw5ivL8qk7` | ⏸ |

### Meta App (Ads Control Portal, F0 cerrada 2026-05-12)
| Item | Valor |
|---|---|
| App nombre | `Ads Control Portal` |
| App ID | `1626417301947904` |
| App Secret | guardado cifrado en `agencia_integraciones_config` (rotar antes de publicar) |
| Business Manager | The Nucleo · ID `459242169567605` |
| System User | `thenucleoadssync` · ID `122135715861053861` · rol Admin BM |
| Token Meta | never-expires, cifrado en `agencia_integraciones_config` (`addon_slug='meta-ads'`) |
| Permisos | `ads_read`, `ads_management`, `business_management` (Standard Access — sin App Review) |
| Webhook PROD endpoint Acciones | `POST https://n8n-n8n.irzhad.easypanel.host/webhook/ads_action` |

### Operaciones
| Workflow | ID | Función |
|---|---|---|
| OPS TAREAS — Crear desde Formulario Bubble | `eHyXBETcaGSNXqLk` | ✅ Crea tarea en Notion |
| OPS TAREAS — Aplicar Plantilla a Cliente | `KSBwigoSEpHl5OG1` | ✅ Crea N tareas/subtareas en Notion |
| OPS LOG — Captura desde Google Chat (lifecycle, HTTP) | `xzNDkDNiUOYOA2Ku` | ⏳ Skeleton inactivo (manejo ADDED/REMOVED_FROM_SPACE — refactor Fase 3) |
| OPS LOG — Mensajes Google Chat (Pub/Sub) | `8snJvdNsmRM2yI2y` | ✅ Activo desde 2026-05-08. Webhook `/gchat_pubsub_push` con validación JWT OIDC |

### Subworkflows compartidos
| Workflow | ID | Función |
|---|---|---|
| SUB — Carpetas Cliente Drive | `d0B4LokmPhHWdg6g` | ✅ Provider-agnóstico (invocado por wvHcgVqqjkWJcJDu) |

### Infraestructura
| Workflow | ID | Función |
|---|---|---|
| ERRORES — Capturar y Registrar Plataforma | `HRDQ9Ju4NAIUV0qyhKzlz` | ✅ Error handler general (configurado en la mayoría de workflows) |
| ERRORES — BOTgoogle [NO TOCAR] | `9WM__jEMrviSSC6KyJCT9` | ✅ Error workflow específico de bots Google externos |
| Background GitHub (backup workflows Portal) | `7OhqK68gIkHQilSlYDZlW` | ✅ CRON 06:00 → repo `marketingthenucleo/n8nthenucleo`, filtro tag `portal` |
