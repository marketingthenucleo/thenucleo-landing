---
title: Sector — Chat Newsletter IA
dominio: sectores
estado: activo
actualizado: 2026-05-08
tags: [sector, chat, newsletter, ia]
---

# Sector 4 — Chat Newsletter IA (CHAT CO-CREATIVO v2)

**Estado (2026-04-30):** 🟢 Refactor Fase 1+2+3 ✅ E2E completo validado. Conv test `ce5efad2-...` con 3 emails aprobados + Doc generado en Drive. Realtime, edición manual popup, ciclo agent y entrega Doc — todo operativo. Pendiente cleanup post-E2E menor (Run JS temporales [RC] del workflow `refresh_chat event`, activar cron `kZE3W2ae0upyGt2E`, rename workflows legacy si aplica). Detalle E2E en `docs/log-cambios.md` 2026-04-30.

**Carpeta n8n:** `FtudBADA2EnKMR43` (Newsletter IA).

**Scope:** chat conversacional con Claude Sonnet 4.6 que captura el brief de una serie de emails (parámetros), propone una estrategia narrativa, y entra en bucle generar/aprobar email N hasta completar la cantidad solicitada. Output: Google Doc en `<cliente>/Análisis y estrategia/Estrategia/Historico_newsletters/`, generado bajo demanda por botón UI.

**Plan de refactor:** `~/.claude/plans/tomando-como-referencia-la-deep-curry.md` (path externo al vault).

---

## Legacy — DEPRECADO 2026-04-29

El motor anterior (chat_conversations.metadata + newsletter_emails_wip + Claude inline en el Chat Generador) está deprecado. Los workflows en n8n se refactorizaron in-place (mismos IDs) al patrón Análisis (Pull-on-Signal). Mientras Bubble Fase 3 no esté lista, el sector está fuera de servicio en producción.

---

## Arquitectura v2 — Chat co-creativo

```
Usuario en /clientes/{empresa_id}/newsletter
         │
         │ envía mensaje
         ▼
┌────────────────────────┐
│ Bubble                 │
│  - Input + Send        │
│  - Page realtime WS    │
│  - Botones Generar Doc │
│  - Reusable preview    │
└────┬────────┬──────────┘
     │        │
     │ POST /chat-newsletter
     │        │ POST /entregar-newsletter (bajo demanda)
     ▼        │
┌─────────────────────────┐
│ n8n IA Newsletter Entrada│
│  - Respond 200          │
│  - get_or_create_conv   │
│  - UPSERT newsletter_wip│
│  - Save user msg        │
│  - Call tool_loop async │
└────────┬────────────────┘
         │ executeWorkflow
         ▼
┌────────────────────────────┐
│ n8n IA Newsletter Tool Loop│
│  - Set estado (collecting/ │
│    generating/…)           │
│  - Get WIP fresh + history │
│  - Build prompt c/ fase    │
│  - Agent Claude Sonnet 4.6 │
│  - Loop tool_use:          │
│      7 tools del agent     │
│  - Save assistant msg      │
└────────────────────────────┘
        │
        │ tool cargar_contexto_cliente (sin store o stale)
        ▼
┌──────────────────────────────┐
│ n8n IA Newsletter KB Fetch   │
│  Webhook /indexar_contexto_  │
│   newsletter (async)         │
│  - Lista Drive cliente       │
│  - Crea fileSearchStore Gem  │
│  - Indexa archivos           │
│  - UPSERT rag_stores         │
│  - UPDATE newsletter_wip     │
│       .kb_text + estado      │
└──────────────────────────────┘

[Ruta entrega — fuera del chat]
Bubble Click "Generar Doc" → POST /entregar-newsletter
        ▼
┌────────────────────────────────┐   ┌──────────────────────────────┐
│ IA Newsletter Trigger Entrega  │──▶│ IA Newsletter Entrega        │
│  (webhook shim, 200 inmediato) │   │  - Get newsletter_wip        │
└────────────────────────────────┘   │  - Get cliente Drive         │
                                     │  - Render Markdown del Doc   │
                                     │  - Drive createFromText en   │
                                     │    Histórico_newsletters/    │
                                     │  - PATCH wip.estado=entregado│
                                     │  - INSERT chat msg con link  │
                                     └──────────────────────────────┘
```

### Estados (11)

| Estado | Significado |
|---|---|
| `borrador` | inicial — fila WIP creada, sin actividad |
| `collecting` | recopilando los 4 parámetros con el usuario |
| `indexing` | esperando que `kb_fetch` indexe el Drive del cliente |
| `ready_to_generate` | parámetros completos, agent va a proponer estrategia |
| `waiting_strategy_approval` | estrategia propuesta, esperando OK del usuario |
| `generating` | agent está produciendo un email |
| `waiting_email_approval` | email N producido, esperando OK del usuario |
| `completado` | todos los emails aprobados, listo para Doc |
| `entregando` | generando Google Doc |
| `entregado` | Doc creado, `doc_url` disponible |
| `error` | algo falló |

**Estados "stuck" (cron `newsletter_cron_reset_stuck` libera):** `indexing`, `generating`, `entregando`. Los `waiting_*` NO se tocan — son espera humana legítima.

### Tools del agent (8)

| Tool | Función | Persiste en `newsletter_wip` | Estado resultante |
|---|---|---|---|
| `guardar_parametros` | Captura los 4 parámetros del brief | `parametros = {objetivo_secuencia, etapa_leads, segmento, cantidad_emails}` | `ready_to_generate` (o `collecting` si parcial) |
| `cargar_contexto_cliente` | Query Gemini RAG con el `store_id` del cliente | `kb_text` (resumen) | si store no existe → dispara `IA Newsletter — KB Fetch [SUB]` async, estado=`indexing` |
| `cargar_url` | Carga el contenido textual de una URL via Jina Reader (`https://r.jina.ai/<url>`) y lo añade a `kb_links_text`. El agent la llama automáticamente cuando el user menciona/pega una URL. | append a `kb_links_text` (cap 30000 chars, FIFO trim) | sin cambios de estado |
| `generar_estrategia` | Genera narrativa de la serie completa | `estrategia_texto` | `waiting_strategy_approval` |
| `confirmar_estrategia` | Usuario aprueba la estrategia | sin cambios de payload | `generating`, `email_actual=1` |
| `generar_email` | Produce email del índice `email_actual` | UPSERT por `numero` en `emails` jsonb[] | `waiting_email_approval` |
| `aprobar_email` | Usuario aprueba el email | `emails[idx].estado_aprobacion = 'aprobado'`, `email_actual++` | si quedan → `generating`; si no → `completado` |
| `completar_newsletter` | Cierra la conversación | sin cambios | `completado` (no renombra `tipo`) |

### Schema email canónico (objeto dentro del array `emails`)

```json
{
  "numero": 1,
  "asunto": "Tu primera lección de meditación está aquí",
  "preheader": "5 minutos al día pueden cambiar tu mañana",
  "from_name": "María de Actualízate",
  "contenido_html": "<html>...</html>",
  "contenido_md": "# Tu primera lección...",
  "estado_aprobacion": "borrador",
  "imagen_hero_url": null,
  "cta_text": "Empieza ahora",
  "cta_url": "https://..."
}
```

---

## Invariantes duros (contrato)

1. **1 chat = N emails (serie). Tope `cantidad_emails` ≤ 6.**
2. **Tipo conversación con sufijo timestamp en CREATE:** `tipo = 'newsletter_<notion_id>_<unix_seconds>'`. Bubble construye el sufijo. Permite N newsletters por cliente sin colisionar con `UNIQUE(agencia_id, tipo)` de `chat_conversations`.
3. **`completar_newsletter` NO renombra `tipo`** — el sufijo timestamp ya viene desde CREATE.
4. **El Doc se genera bajo demanda** (botón UI), no automático.
5. **Los drafts NO se borran post-entrega.** Cliente puede seguir consultando emails con `estado=entregado`.
6. **Newsletter mantiene Gemini fileSearchStore** (no migra al kb_text plano de Análisis). Indexación filtra por `tipo='newsletter'` en `rag_stores`.

---

## Capa Supabase cbi — IMPLEMENTADA (Fase 1, 2026-04-29)

Proyecto `cbixhqjsnpuhcrcjppah` (eu-west-1).

### Tabla `newsletter_wip` (15 cols)

```sql
CREATE TABLE public.newsletter_wip (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id   uuid REFERENCES chat_conversations(id) ON DELETE CASCADE,
  agencia_id        uuid,
  cliente_id        text,                         -- notion_id
  kb_links_text     text,
  kb_text           text,
  parametros        jsonb DEFAULT '{}'::jsonb,
  estrategia_texto  text,
  emails            jsonb DEFAULT '[]'::jsonb,
  email_actual      int   DEFAULT 0,
  estado            text  DEFAULT 'borrador',
  doc_url           text,
  error_msg         text,
  created_at        timestamptz DEFAULT now(),
  updated_at        timestamptz DEFAULT now()
);

-- CHECK estado IN (los 11 valores)
-- UNIQUE (conversation_id)
-- FK conversation_id → chat_conversations(id) ON DELETE CASCADE
-- 3 índices: cliente_id, agencia_id, estado
-- Trigger newsletter_wip_updated_at BEFORE UPDATE → public.update_updated_at()
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.newsletter_wip
```

**RLS** (clonada de `analisis_wip`):
- `anon_select_newsletter_wip` — FOR SELECT TO anon USING `agencia_id = 'e748c7d4-...'::uuid`.
- `service_role_all_newsletter_wip` — FOR ALL TO service_role USING (true) WITH CHECK (true).

### RPCs (6)

Todas `SECURITY DEFINER SET search_path = public`. GRANT `anon, authenticated` excepto `newsletter_reset_stuck` (`service_role` only).

| RPC | Returns | Volatility | Uso |
|---|---|---|---|
| `newsletter_get_parametros(p_conversation_id)` | TABLE(objetivo_secuencia, etapa_leads, segmento, cantidad_emails int, estado) | STABLE | Chip "Parámetros" del panel derecho |
| `newsletter_get_estrategia(p_conversation_id)` | TABLE(estrategia_texto, estado, cantidad_emails int) | STABLE | Chip "Estrategia" del panel derecho |
| `newsletter_get_email(p_conversation_id, p_idx int)` | TABLE(idx int, numero int, asunto, preheader, from_name, contenido_html, contenido_md, estado_aprobacion) | STABLE | 1 email por idx — al clickar chip Email → popup con ese email |
| `newsletter_get_emails(p_conversation_id)` | TABLE(numero int, asunto, preheader, from_name, contenido_html, contenido_md, estado_aprobacion, cta_text, cta_url) | STABLE | N filas — source del RG Email Cards. Aplicada 2026-04-29. |
| `newsletter_update_email(p_conversation_id, p_idx int, p_asunto text, p_contenido_html text, p_contenido_md text DEFAULT NULL)` | json `{ok, idx}` | VOLATILE | Botón "GUARDAR CAMBIOS" del popup edición. Aplicada 2026-04-29. |
| `newsletter_reset_wip(p_conversation_id)` | json `{ok:true}` | VOLATILE | Botón "Reiniciar" |
| `newsletter_reset_stuck(p_ttl_minutes int DEFAULT 15)` | TABLE(conversation_id, wip_id, msg_id, estado_anterior) | VOLATILE | Cron 15 min — solo libera `indexing/generating/entregando` |

**Lección 42702:** las columnas OUT del `RETURNS TABLE` colisionan con columnas de la tabla en `FOR ... LOOP` interno. Fix: aliasear con `w.` (`SELECT w.id AS wip_id, w.conversation_id, w.estado FROM public.newsletter_wip w`). Patrón ya documentado.

---

## Capa n8n — Workflows del sector (Fase 2, 2026-04-29)

Proyecto `cehv5Dib1J6eKwYQ` ("Benjamin THe Nucleo"). Folder `FtudBADA2EnKMR43`.

| Workflow | ID | Rol | Estado | Nodos |
|---|---|---|---|---|
| `newsletter_cron_reset_stuck` | `4rGLGT37BORP3xab` | Schedule 15min → RPC `newsletter_reset_stuck(15)` en cbi. | ✅ Activo | 2 |
| `CRON IA Newsletter — Reindexar RAG (3:30)` (legacy name "Newsletter IA — CRON Reindexar RAG Nocturno") | `kZE3W2ae0upyGt2E` | Schedule 03:30 Madrid. Lee `bub_clientes` con `link_drive`, cruza con `rag_stores tipo=newsletter`, dispara reindex de los stale (>24h) o nunca indexados. Multi-tenant. | ❌ Inactivo (espera E2E) | 14 |
| `IA Newsletter — KB Fetch [SUB]` (legacy name "Newsletter IA — Indexar Contexto Drive [Subworkflow]") | `w6Gqo8B6Sqp6Mq9x` | 12 nodos. 2 triggers: `Execute Workflow Trigger` (cron) + Webhook `/indexar_contexto_newsletter` (tool_loop async). Crea fileSearchStore Gemini + indexa Drive + UPSERT `rag_stores` + UPDATE `newsletter_wip.kb_text`. | ✅ Activo | 12 |
| `IA Newsletter — Entrada` | `inWFSAEDLCH1kx5P` | 20 nodos. Webhook `/chat-newsletter`. get_or_create_conv (con `tipo` dinámico desde body, sufijo timestamp incluido) → UPSERT newsletter_wip → save user msg → executeWorkflow tool_loop async. Loop tool_use Claude inline mantenido temporalmente para casos de continuidad de conv (estado != completado). | ❌ Inactivo (espera Bubble) | 20 |
| `IA Newsletter — Tool Loop [SUB]` | `SfwR7gqs1hBIOV7i` | 7 tools del agent adaptadas al schema `newsletter_wip`. Lectura fresca de WIP cada iteración. Execute Workflow Trigger typeVersion 1 (recursión). | ✅ Activo (subworkflow) | 7 |
| `IA Newsletter — Entrega [SUB]` | `9wnB9NI8Capa4b8s` | 15 nodos. Bajo demanda. Get newsletter_wip + Get cliente Drive + Render Markdown + 4 niveles Drive (Cliente/Análisis y estrategia/Estrategia/Historico_newsletters) + createFromText + PATCH wip.estado=entregado + INSERT chat msg con link. **Sin DELETE post-entrega.** | ✅ Activo (subworkflow) | 15 |
| `IA Newsletter — Trigger Entrega` | `u9DsFadbpb7QiLaP` | 3 nodos. Webhook `/entregar-newsletter` → Respond 200 paralelo + executeWorkflow newsletter_entrega async. | ❌ Inactivo (espera UI Bubble) | 3 |

### Detalles clave

- **Multi-tenant:** `agencia_id` llega desde Bubble en el body del webhook y se persiste en cada fila. CRON reindex también dinámico (lee `bub_clientes.agencia_id`).
- **`rag_stores`:** PK compuesto `(notion_id, tipo)` con CHECK `tipo IN ('cerebro','newsletter')`. UPSERT con `Prefer: resolution=merge-duplicates` + `?on_conflict=notion_id,tipo` en URL.
- **Hardcode JWT cbi inline en jsCode** (deuda técnica anotada). n8n Code nodes no inyectan credenciales nativas. Pendiente futuro: env vars o nodos HTTP separados con cred.
- **Distinción cron vs tool_loop dentro de `IA Newsletter — KB Fetch [SUB]`:** prefijo `conversation_id = "cron-nl-*"` evita actualizar `newsletter_wip` cuando el indexer corre desde el cron (no hay conv real).
- **Webhook `/indexar_contexto_newsletter`:** invocado por la tool `cargar_contexto_cliente` cuando el cliente tiene `link_drive` pero no hay store. Async — el agent no espera; la WIP cambia a `estado=indexing` y al terminar se actualiza vía Realtime.
- **Lectura fresca de WIP cada iteración** en el tool_loop (regla skill /n8n).
- **Execute Workflow Trigger typeVersion: 1** mantenido en tool_loop (recursión).
- **Anthropic streaming** `enableStreaming: true` explícito.

---

## Capa Bubble — SPEC FASE 3 (PENDIENTE IMPLEMENTAR)

Página `/clientes/{empresa_id}/newsletter`. Plantilla base: clonar la página `/clientes/{empresa_id}/analisis` (sector 7) y adaptar.

**Cliente test:** Actualízate Psicología (bubble_id `1772815116826x630388853372878800`, notion_id `31de4743-b0ae-8165-aa1c-c14e6387385c`, Drive folder `https://drive.google.com/drive/folders/136baB98ana-6NWEl6ISPWxSpW7L-cgBH`).

### 7.1 Custom States (11)

> **Decisión cerrada 2026-04-29:** 1 newsletter por cliente, sin sufijo timestamp en `tipo`. Reset (`newsletter_reset_wip`) sobrescribe la activa; el histórico vive en Drive `Historico_newsletters/`. Patrón idéntico a Análisis. Resultado: NO hay `current_tipo` (era el state #12 — eliminado).

**Base (6) — clonar de `/analisis`:**
- `cliente_notion_id` (text, default `Current Page Clientes's notion_id`)
- `current_conversation_id` (text)
- `conv_metadata_estado` (text — los 11 estados, default `borrador`)
- `enviando` (yes/no, default no)
- `last_subscribed_conversation` (text)
- `chip_activo` (text, default `parametros`)

**Específicos del dominio (3):**
- `emails_count` (number, default 0)
- `email_idx_activo` (number, default 0 — 1-based; 0 = no email seleccionado; lo controla el usuario al clickar chip Email N)
- `email_actual_remoto` (number, default 0 — espejo de `newsletter_wip.email_actual`, lo controla el agent vía Realtime)

> **Mejoras futuras pendientes con `email_actual_remoto`** (state preservado pero NO cableado a UI todavía — decisión Ben 2026-04-29):
> 1. **Auto-highlight chip current:** marcar el chip cuyo número = `email_actual_remoto` con un pulso o badge "el agente está aquí".
> 2. **Auto-navegación:** cuando Realtime cambia `email_actual_remoto`, auto-trigger `cargar_email(email_actual_remoto)` para mostrar el email recién generado sin click manual.
> 3. **Indicador "esperando aprobación":** mostrar texto "esperando tu OK del email N" cuando `conv_metadata_estado = "waiting_email_approval"` usando `email_actual_remoto` como N.

**Cache RPCs (3):**
- `parametros_result` (list of `newsletter_get_parametros`)
- `estrategia_result` (list of `newsletter_get_estrategia`)
- `email_actual_result` (list of `newsletter_get_email`)

**Popup (1):**
- `preview_open` (yes/no, default no)

### 7.2 API Connectors (10) — TODOS Action, NUNCA Data source ✅ CREADAS 2026-04-29

**Estado:** las 9 calls del grupo Newsletter v2 + las 2 reusadas del grupo Análisis están **creadas e inicializadas en Bubble**. Detalle canónico en [[bubble-api-connectors#newsletter-v2-9-calls--refactor-2026-04-29--creadas-e-inicializadas|docs/bubble-api-connectors]].

**Conv inicializadora:** `922cfab0-c9f7-4d65-9e5b-62b2764c0d74` (cliente_id `30de4743-b0ae-81e2-835a-dcb7ca7d38d2` "Actualízate Psicología") — fila `newsletter_wip` con datos completos creada en cbi para que Bubble tipe los RPC correctamente. Mantenida tras inicialización.

**Workflow n8n activado:** `inWFSAEDLCH1kx5P` (`IA Newsletter — Entrada`) ACTIVO desde 2026-04-29 (paso 7.1 adelantado para validar Initialize del `newsletter_send_message`).

**Cleanup legacy 2026-04-29 ✅ completo:** grupo "Actualizar email editado manual" (5 calls) + call `N8n - Trigger_newsletter chat` del grupo "Newsletter" — **6 calls legacy eliminadas** con Issue Checker X=0 en todas. Newsletter ya 100% sobre Newsletter v2 + reuso del genérico Análisis.


Crear nuevo grupo `Newsletter` en API Connector Bubble. Usar plugin Supabase ya existente para los 8 que llaman a Supabase (heredan headers `apikey` + `Authorization: Bearer <anon_key>`). Webhooks n8n usan API Connector "Generic" con `Content-Type: application/json` y patrón `JSON-safe`.

> **⚠️ Bodies y paths verificados contra `inWFSAEDLCH1kx5P` y `u9DsFadbpb7QiLaP`** (2026-04-29). Nombres de campo y paths reales:
> - Webhook entrada: path `/webhook/chat_newsletter` (**underscore**, no hyphen).
> - Body entrada: campos reales son `cliente_notion_id` y `mensaje` (NO `cliente_id` ni `message`).
> - Webhook entrega: path `/webhook/entregar-newsletter` (**hyphen**).
> - RPC `get_or_create_conversation`: 4 params `(p_agencia_id, p_tipo, p_user_bubble_id, p_estado)`. Returns row completa de `chat_conversations`.

| Nombre | Tipo | URL | Body / Returns |
|---|---|---|---|
| `newsletter_send_message` | POST webhook fire-and-forget | `https://n8n-n8n.irzhad.easypanel.host/webhook/chat_newsletter` | Body raw JSON: `{"conversation_id":"<conv_id>","agencia_id":"<agencia_id>","cliente_notion_id":"<cliente_notion_id>","tipo":"<tipo>","mensaje":<mensaje_json_safe>}`. Data type **Empty**. |
| `newsletter_get_wip` | GET | `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/newsletter_wip?conversation_id=eq.<conv_id>&select=*` | Array 1 fila. Use as Action. |
| `newsletter_get_messages` | GET | `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/chat_messages?conversation_id=eq.<conv_id>&order=created_at.asc&select=id,role,content,created_at` | Array de mensajes ordenados ASC. Use as Action. (Reutilizar el connector equivalente de `/analisis` si ya existe — Análisis lo llama `obtener_mensajes` o similar.) |
| `newsletter_get_or_create_conversation` | POST RPC | `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/get_or_create_conversation` | Body `{"p_agencia_id":"<uuid>","p_tipo":"<tipo>","p_user_bubble_id":"<bubble_id>","p_estado":"active"}`. Returns row `chat_conversations` (id, agencia_id, tipo, metadata, created_at, …). Use as Action. **Reutilizar el connector que `/analisis` ya tiene si lo hay** — el RPC es genérico, solo cambia el `p_tipo` que pasamos. |
| `newsletter_reset_wip` | POST RPC | `.../rpc/newsletter_reset_wip` | Body `{"p_conversation_id":"<conv_id>"}`. Returns `{ok:true}`. |
| `newsletter_trigger_entrega` | POST webhook fire-and-forget | `https://n8n-n8n.irzhad.easypanel.host/webhook/entregar-newsletter` | Body raw JSON: `{"conversation_id":"<conv_id>"}`. Data type **Empty**. |
| `newsletter_get_parametros` | POST RPC table | `.../rpc/newsletter_get_parametros` | Body `{"p_conversation_id":"<conv_id>"}`. Returns 1 fila tipada (5 campos). Use as Action. |
| `newsletter_get_estrategia` | POST RPC table | `.../rpc/newsletter_get_estrategia` | Body `{"p_conversation_id":"<conv_id>"}`. Returns 1 fila (3 campos). Use as Action. |
| `newsletter_get_email` | POST RPC table | `.../rpc/newsletter_get_email` | Body `{"p_conversation_id":"<conv_id>","p_idx":<idx>}`. Returns 1 fila (8 campos) o vacía si fuera de rango. Use as Action. |
| `newsletter_update_email` | POST RPC | `.../rpc/newsletter_update_email` | Body `{"p_conversation_id":"<conv_id>","p_idx":<idx>,"p_asunto":"<asunto>","p_contenido_html":"<contenido_html>"}`. Returns `{ok, idx}`. Use as Action. **Botón GUARDAR CAMBIOS del popup edición.** |

**⚠️ Inicialización RPCs (memoria `feedback_bubble_patterns` #9):** los 3 RPC table connectors (`newsletter_get_parametros`, `newsletter_get_estrategia`, `newsletter_get_email`) **deben inicializarse con una conv que tenga datos completos** (parametros poblada + estrategia_texto != null + emails con al menos 1 elemento). Sin esto, Bubble los marca como raw text y los Set state fallan al asignar tipos. Procedimiento:
1. Crear manualmente una fila WIP de prueba en cbi con datos sintéticos completos:
   ```sql
   INSERT INTO newsletter_wip (conversation_id, agencia_id, cliente_id, parametros, estrategia_texto, emails, email_actual, estado)
   SELECT
     id, 'e748c7d4-5823-413d-8cb3-532896f6e41d', 'test-init',
     '{"objetivo_secuencia":"test","etapa_leads":"test","segmento":"test","cantidad_emails":3}'::jsonb,
     'Estrategia inicializadora para Bubble RPC introspect.',
     '[{"numero":1,"asunto":"Test","preheader":"Test","from_name":"Test","contenido_html":"<p>x</p>","contenido_md":"x","estado_aprobacion":"borrador","cta_text":"x","cta_url":"https://x.com"}]'::jsonb,
     1, 'waiting_email_approval'
   FROM chat_conversations WHERE tipo LIKE 'newsletter_%' LIMIT 1;
   ```
2. En Bubble, click "Initialize call" en cada uno de los 8 connectors Supabase con el `conversation_id` de esa fila.
3. Después borrar la fila de prueba.

**Patrón homogéneo webhooks fire-and-forget** (heredado del sector 7):
- **Data type:** `Empty` (n8n responde 200 sin body via `Respond to Webhook`).
- **Body template:** UUIDs/strings entre comillas; campo de texto libre `<mensaje>` SIN comillas envolventes; en el caller del workflow Bubble usar `Input Mensaje's value:formatted as JSON-safe` para escapar y añadir comillas. Detalle en `docs/infra/bubble-api-connectors.md` "Patrón homogéneo".

### 7.3 Realtime WebSocket (HTML element, 2 canales)

Clonar el HTML element de `/analisis` y reemplazar:
- Canal 1: `chat_msgs_<uuid>` — INSERT en `chat_messages` filtrado por `conversation_id` → `bubble_fn_refresh_chat`.
- Canal 2: `newsletter_wip_<uuid>` — INSERT/UPDATE en `newsletter_wip` filtrado por `conversation_id` → `bubble_fn_refresh_emails`.

Pseudo-código JS dentro del HTML (adaptar el de Análisis):
```js
const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

window.subscribeToConversation = function(convId) {
  if (window._chatChannel) supabaseClient.removeChannel(window._chatChannel);
  if (window._wipChannel) supabaseClient.removeChannel(window._wipChannel);

  window._chatChannel = supabaseClient
    .channel(`chat_msgs_${convId}`)
    .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'chat_messages',
        filter: `conversation_id=eq.${convId}` },
      () => window.bubble_fn_refresh_chat())
    .subscribe();

  window._wipChannel = supabaseClient
    .channel(`newsletter_wip_${convId}`)
    .on('postgres_changes', { event: '*', schema: 'public', table: 'newsletter_wip',
        filter: `conversation_id=eq.${convId}` },
      () => window.bubble_fn_refresh_emails())
    .subscribe();
};
```

### 7.4 Custom Events (naming en español)

**`cargar_parametros`** (sin parámetros) — 3 steps:
1. Set state `chip_activo = "parametros"`.
2. Call `newsletter_get_parametros` (`p_conversation_id = current_conversation_id`).
3. Set state `parametros_result = Result of step 2`.

**`cargar_estrategia`** (sin parámetros) — 4 steps:
1. Set state `chip_activo = "estrategia"`.
2. Call `newsletter_get_estrategia` (`p_conversation_id`).
3. Set state `estrategia_result = Result of step 2`.
4. Run JS `renderAllMessages();` — re-procesa el HTML element `#msg-estrategia` (markdown→HTML vía parser global del header). Sin este step, el contenido se ve con `**`/`#` crudos.

**`cargar_email`** (parámetro `idx: number`) — 5 steps:
1. Set state `chip_activo = "email" + This cargar_email's idx:formatted as 1234.56`.
2. Set state `email_idx_activo = This cargar_email's idx`.
3. Call `newsletter_get_email` (`p_conversation_id`, `p_idx = This cargar_email's idx`).
4. Set state `email_actual_result = Result of step 3`.
5. (Opcional) Set state `preview_open = no` (cierra popup si estaba abierto al cambiar email).

**`refresh_chat event`** (5 steps) — clonar de Análisis:
1. Call `newsletter_get_messages` (`conv_id = current_conversation_id`).
2. Display list result step 1 en RG Chat.
3. Run JS `renderAllMessages`.
4. Scroll to entry RG (last item).
5. Set state `enviando = no`.

**`refresh_emails event`** (8 steps) — el más extenso:
1. Call `newsletter_get_wip` (`conv_id = current_conversation_id`).
2. Set state `conv_metadata_estado = Result of step 1 :first item's estado`.
3. Set state `emails_count = Result of step 1 :first item's emails :count`.
4. Set state `email_actual_remoto = Result of step 1 :first item's email_actual`.
5. Trigger `cargar_parametros` — Only when `chip_activo is "parametros"`.
6. Trigger `cargar_estrategia` — Only when `chip_activo is "estrategia"`.
7. Trigger `cargar_email` con `idx = chip_activo:truncated from start to 5:converted to number` — Only when `chip_activo contains "email"`.
   - **NOTA:** `truncated from start to 5` quita el prefijo `"email"` (5 chars) y deja el número. Ej: `"email3" → "3"`. (Cheatsheet en `feedback_bubble_patterns` #11.)
8. (Opcional) Set state `enviando = no` si `conv_metadata_estado is not "generating" and is not "indexing"`.

**Triggers:**
- Button Chip Parámetros on-click → `Trigger cargar_parametros`.
- Button Chip Estrategia on-click → `Trigger cargar_estrategia`. **Only when** `estrategia_result is not empty` (clickable lock).
- Button Chip Email N (RG cell) on-click → `Trigger cargar_email` con `idx = Current cell's index`. **Only when** `Current cell's index ≤ emails_count`.
- Page Loaded último step → `Trigger cargar_parametros`.

### 7.5 UI panel derecho

**Element tree** (mismo enfoque que Análisis, adaptado):

```
Group columna newsletter (contenedor del panel derecho)
├── Group Cabecera Newsletter
│   ├── Pill estado (background/text por conv_metadata_estado, ver §7.6 mapping)
│   └── Botones cabecera (ver §7.7)
├── Group Selectores Newsletter (chips dinámicos)
│   ├── Button Chip "Parámetros" (siempre clickable)
│   ├── Button Chip "Estrategia" (lock si estrategia_result vacío)
│   └── RG Chips Email (source = list 1..6 estática, 1 cell por número)
│       cell: Button "Email N" — Conditional: `Current cell's index > emails_count` → not clickable + opacity 0.4
├── Group parametros brief y estrategia (wrapper — oculto hasta tener contenido)
│   │  Visible on page load = no
│   │  Conditional: When parametros_result:first item's objetivo_secuencia is not empty → visible = yes
│   ├── Group Contenido Parametros (visible si chip_activo is "parametros")
│   │   └── 4 Text rows label/value alimentados de parametros_result:first item:
│   │       Objetivo / Etapa leads / Segmento / Cantidad emails
│   └── Group Contenido Estrategia (visible si chip_activo is "estrategia")
│       └── HTML element (height fixed 250) con patrón msg-/tpl-/role- para reusar parser global:
│           <div id="msg-estrategia" style="height: 100%; overflow-y: auto;">
│             <script type="text/template" id="tpl-estrategia">[estrategia_result:first item's estrategia_texto]</script>
│             <script type="text/template" id="role-estrategia">assistant</script>
│           </div>
│           El `cargar_estrategia` (§7.4) llama a `renderAllMessages()` para que marked+DOMPurify rendericen el contenido.
└── Group Contenido Email (visible si chip_activo contains "email")
    ├── Group Cabecera Email
    │   ├── Pill "EMAIL N de M" → "EMAIL " + email_idx_activo + " de " + parametros_result:first item's cantidad_emails
    │   ├── Pill estado_aprobacion (badge, color por borrador/aprobado)
    │   └── Button "Previsualizar / Editar" (set preview_open=yes)
    ├── Text Asunto (h3) → email_actual_result:first item's asunto
    ├── Text Preheader (italic, gris) → email_actual_result:first item's preheader
    ├── Text From-name → email_actual_result:first item's from_name
    ├── Group HTML preview (compacto, sin chrome de cliente mail — ese va en el popup)
    │   └── HTML element src=`<div>` con email_actual_result:first item's contenido_html
    └── Group CTA preview
        ├── Text → email_actual_result:first item's cta_text
        └── Link → email_actual_result:first item's cta_url
```

**Chips Email N — Opción A (RG con static list):** patrón usado en Análisis para los 4 chips Seg1-4. RG horizontal con source = `1,2,3,4,5,6`, 1 cell por número. Conditional en cell: `When Current cell's index > Current Page's emails_count → not clickable + opacity 0.4`.

### 7.6.0 Agrupación de estados en pasos macro (`Group Indicador Pasos` cabecera)

5 pasos macro para step indicator visual tipo wizard. Cada estado del backend mapea a uno de los 5:

| Paso UI | Estados que entran |
|---|---|
| 1. Brief | `borrador`, `collecting`, `indexing` |
| 2. Estrategia | `ready_to_generate`, `waiting_strategy_approval` |
| 3. Emails | `generating`, `waiting_email_approval` |
| 4. Cierre | `completado` |
| 5. Doc | `entregando`, `entregado` |
| ⚠️ Error (overlay) | `error` (badge rojo sobrepone los pasos) |

Para resaltar el paso activo, conditional Bubble por cada paso (ej. paso 1):
```
When Current Page's conv_metadata_estado is "borrador"
  OR is "collecting"
  OR is "indexing"
  → background = active (verde TheNucleo) + opacity 1
Otherwise → background = card + opacity 0.5
```

### 7.6 Mapping color estado pill

| Estado | Background | Text |
|---|---|---|
| `borrador` | `#1e2130` (gris card) | `#a1a4b1` |
| `collecting` | `#1e2130` | `#a1a4b1` |
| `indexing` | `#3b3017` (amber dim) | `#fbbf24` |
| `ready_to_generate` | `#10261e` (verde dim) | `#22c55e` |
| `waiting_strategy_approval` | `#1e2a3b` (azul dim) | `#60a5fa` |
| `generating` | `#1e2a3b` | `#60a5fa` |
| `waiting_email_approval` | `#1e2a3b` | `#60a5fa` |
| `completado` | `#10261e` | `#22c55e` |
| `entregando` | `#3b3017` | `#fbbf24` |
| `entregado` | `#10261e` | `#22c55e` |
| `error` | `#3b1a1a` | `#ef4444` |

(Tomado de la paleta de TheNucleo en `CLAUDE.md`. Si hay un Style ya creado en Bubble, reusarlo.)

### 7.7 Botones cabecera

| Botón | Visible si | Acción |
|---|---|---|
| `Reiniciar` | `conv_metadata_estado is "completado" or "entregado" or "error"` | Confirm popup → `newsletter_reset_wip(p_conversation_id)` → `refresh_chat` + `refresh_emails`. |
| `Ver Doc` | `conv_metadata_estado is "entregado"` | Open external URL: `Result of newsletter_get_wip:first item's doc_url`. **NO** abrir la carpeta Drive del cliente — el `doc_url` apunta al Doc específico generado. |
| `Generar Doc` | `conv_metadata_estado is "completado"` | Call `newsletter_trigger_entrega` (`conv_id`) → toast "Generando…" → set `enviando=yes` (UI lock 30s). El cambio a `entregando` y luego `entregado` llega vía Realtime. |
| `Previsualizar Email` | `chip_activo contains "email" and email_actual_result is not empty` | Set state `preview_open = yes`. |

### 7.8 Reusable element `PopupPreviewEmail` (modo edición directa)

> **Decisión cerrada 2026-04-29:** popup único, **siempre editable** (sin toggle). Asunto y contenido editables. Edición disponible en cualquier estado. Patrón heredado del legacy + ampliado (legacy solo permitía editar contenido; ahora también asunto).

Reusable element sin properties. Lee `Current Page's email_actual_result` y `Current Page's email_idx_activo` directamente. Visible vía `preview_open=yes` en la página caller.

```
Group Popup Overlay (z-index alto, fondo #00000080, click fuera = cerrar)
└── Group Mail Client Card (max-width 720, sombra, fondo dark mockup como tu screenshot, radius 8)
    ├── Group Cabecera Mail (fondo #2a2a2a, padding 12)
    │   ├── Text "Mensaje nuevo" :small grey
    │   ├── Row "De":  Text Current Page Clientes's contacto_principal + " <" + Current Page Clientes's correo_principal + ">"
    │   ├── Row "Para": Text "Cliente de " + Current Page Clientes's nombre_empresas + " <ejemplo@gmail.com>"
    │   └── Row "Asunto": **Input editable** ← initial content = email_actual_result:first item's asunto
    ├── RichTextInput "texto editable" (toolbar Sans Serif/B/I/U/H1-H4/listas/links)
    │   initial content = email_actual_result:first item's contenido_html
    ├── Group Footer (padding 12)
    │   ├── Button GUARDAR CAMBIOS (verde, full-width)  ← workflow §7.8.1
    │   ├── Button Cerrar (X arriba derecha) → Set state preview_open=no en página parent
    │   └── (opcional) Button Copiar HTML → Copy to clipboard contenido_html
```

**§7.8.1 Workflow Botón GUARDAR CAMBIOS** (3 steps — réplica de tu screenshot del legacy, apuntando al RPC nuevo):
1. Call `newsletter_update_email`:
   - `p_conversation_id = Current Page's current_conversation_id`
   - `p_idx = Current Page's email_idx_activo`
   - `p_asunto = Input asunto editable's value`
   - `p_contenido_html = RichTextInput texto editable's value`
2. Hide PopupPreviewEmail (Set state `preview_open = no` en página parent).
3. (Opcional) Trigger `cargar_email` con `idx = email_idx_activo` para refresh inmediato. **No es necesario** — el WebSocket `newsletter_wip_<id>` dispara `refresh_emails` automáticamente al UPDATE de `newsletter_wip.emails`. Solo añadir si quieres feedback < 200ms sin esperar el round-trip Realtime.

**Iframe / RichTextInput:** el RichTextInput Bubble nativo soporta HTML básico (h1-h4, b, i, u, listas, links). Si tu HTML viene con CSS embebido + tags exóticos del agent, considerar plugin "Rich Text Editor (Tiny)" o "Quill" que preservan más HTML. Verificar al primer test E2E.

**Estado_aprobacion sin tocar:** confirmado contra workflow legacy. La edición manual NO modifica `estado_aprobacion`. Si era `aprobado`, sigue `aprobado`. Si el agent regenera el email después con `generar_email`, ahí sí se reinicia.

### 7.9 Page Loaded — `p_tipo = newsletter_<notion_id>` (sin sufijo timestamp)

> **Bug heredado resuelto:** la página actual construye `p_tipo = "newsletter"` sin sufijo de cliente. Fix: añadir el `notion_id` como sufijo. **NO hay timestamp** (decisión cerrada B 2026-04-29) — paridad con Análisis (`p_tipo = "analisis_<notion_id>"`).

**Steps Page Loaded (13):**
1. Set Menu_lateral sección activa = `Newsletter`.
2. Set state `cliente_notion_id = Current Page Clientes's notion_id`. **Only when** `notion_id is not empty` (guard, evita conv huérfana tipo `newsletter_`).
3. Call `newsletter_get_or_create_conversation`:
   - `p_agencia_id = Current User's agencia_id's Uuid Supabase`
   - `p_tipo = "newsletter_" + cliente_notion_id`
   - `p_user_bubble_id = Current User's unique id` (o equivalente — verificar lo que usa `/analisis`)
   - `p_estado = "active"`
4. Set state `current_conversation_id = Result of step 3's id`.
5. Call `newsletter_get_messages` (`conv_id = current_conversation_id`).
6. Display list result step 5 in RG Chat.
7. Run JS `renderAllMessages()`.
8. Call `newsletter_get_wip` (`conv_id`).
9. Set states de la WIP en bloque (1 step Bubble múltiple):
   - `conv_metadata_estado = Result step 8 :first item's estado`
   - `emails_count = Result step 8 :first item's emails :count`
   - `email_actual_remoto = Result step 8 :first item's email_actual`
10. Scroll to entry RG (last item).
11. Run JS `subscribeToConversation(current_conversation_id)`.
12. **Call `newsletter_init`** (POST webhook fire-and-forget, body `{conversation_id, agencia_id, cliente_notion_id}`). **Only when** `Result of step 5's count is 0` (conv recién creada, sin mensajes). Detalle del flujo y branches en §7.13.
13. Trigger `cargar_parametros`.

### 7.10 Lock progresivo de chips Email N

Patrón ya usado en Análisis (`feedback_bubble_patterns` #15). Los chips Email N se desbloquean progresivamente conforme `emails_count` aumenta.

- **Custom state ya existe:** `emails_count` (number).
- **Update state:** ya cubierto en `refresh_emails event` step 3 + Page Loaded step 9.
- **Conditional en cell del RG Chips Email** (1 condition con 2 properties):
  - When `Current cell's index > Current Page's emails_count` → `This element isn't clickable = yes` + `Opacity = 0.4`.

Cell visualmente diferenciada permite ver de un vistazo cuántos emails hay generados sin tener que clickearlos.

### 7.11 Estado del input chat (semáforo `enviando` + lock por estado WIP)

Patrón base de Análisis + extensión por estados de procesamiento del agent:
- `enviando=yes` desactiva botón Send + cambia opacity (visual).
- `enviando=no` restaurado por `refresh_chat event` (cuando llega assistant msg via Realtime).
- Backup: si `enviando=yes` por más de 60s → reset manual via JS o botón "Cancelar envío".

**Lock extendido (2026-04-30) — bloqueo por estado WIP:** el botón Send también queda bloqueado mientras el agent está procesando, no solo entre Send y respuesta. Cubre el chain de tools internos (ej. `aprobar_email` → `generar_email`) donde no hay assistant text msg intermedio que libere `enviando`.

Conditional final del Send (mismo en `Only when` del workflow + Conditional visual del botón):

```
enviando is yes
OR conv_metadata_estado is "indexing"
OR conv_metadata_estado is "generating"
OR conv_metadata_estado is "entregando"
```

Casos cubiertos:
- (a) Branch B kb_fetch indexa por primera vez (~30s) → estado=indexing.
- (b) User aprueba email N → tool_loop ejecuta chain `aprobar_email` + `generar_email` → estado=generating mientras tanto.
- (c) Click Generar Doc → estado=entregando.
- (d) Send normal en cualquier momento → enviando=yes hasta llegar respuesta.

**Lock adicional separado para greeting Branch A** (~3-5s mientras newsletter_init genera el primer mensaje sin tocar `newsletter_wip`):
```
RG Chat's count is 0
```

### 7.12 Botón Send (5 steps clonados de Análisis)

1. Only when `Input Mensaje's value is not empty and enviando is no and conv_metadata_estado is not "indexing" and is not "generating" and is not "entregando" and RG Chat's count is not 0`.
2. Set state `enviando = yes`.
3. (Fallback) Call `newsletter_get_or_create_conversation` con los 4 params si `current_conversation_id is empty`. Set state.
4. Call `newsletter_send_message` con body:
   ```
   conversation_id    = current_conversation_id
   agencia_id         = Current User's agencia_id's Uuid Supabase
   cliente_notion_id  = cliente_notion_id            ← ⚠️ campo NO `cliente_id`
   tipo               = "newsletter_" + cliente_notion_id   ← sin timestamp
   mensaje            = Input Mensaje's value:formatted as JSON-safe   ← ⚠️ campo NO `message`
   ```
5. Reset Input Mensaje value.

> **Sin custom state `current_tipo`:** el `tipo` es deterministic (`"newsletter_" + cliente_notion_id`), se construye inline en cada send. No hay timestamp dinámico, no hay riesgo de divergencia entre Page Loaded y sends.

### 7.13 Greeting inicial con resumen del RAG (2026-04-30)

**Objetivo:** al abrir el chat sin mensajes previos, el agente envía como primer mensaje un resumen breve del contexto cargado en su RAG (Google fileSearchStore Gemini). Sin esto el chat queda vacío y el usuario tiene que adivinar qué pedir.

**Trigger:** Page Loaded step 12 (`Call newsletter_init` only when `count(chat_messages)=0`).

**Workflow n8n:** `IA Newsletter — Init` (`UBYXNKZ1HHFTZyDX`, ✅ activo). Webhook POST `/init-newsletter`.

```
Webhook → Normalizar → Respond 200 (paralelo)
                     → Get Messages Count (race guard)
                       ↓
                       Has Messages? (IF) — TRUE: abort. FALSE:
                       ↓
                       Get RAG Store (rag_stores) + Get Cliente Drive (bub_clientes)
                       ↓
                       Build Context (Code) → decide branch A/B/C
                       ↓
                       Has Store? (IF)
                         ├─ TRUE → Branch A
                         └─ FALSE → Has Link Drive? (IF)
                                     ├─ TRUE → Branch B
                                     └─ FALSE → Branch C
```

**Branches:**

| Branch | Precondición | Acción | Mensaje resultante |
|---|---|---|---|
| **A** | `rag_stores.store_id` existe para `(cliente_notion_id, tipo='newsletter')` | Gemini RAG query (resume cliente en 2-3 frases) + Format Greeting + INSERT `chat_messages` | `Hola. Antes de empezar — esto es lo que tengo en el RAG de <cliente>: • <N> archivos indexados (último update: <fecha>) • Categorías: <breakdown> • <narrativa Gemini> • Drive: <link> Cuéntame: objetivo, etapa, segmento, cuántos emails (máx 6).` |
| **B** | Sin store, pero `bub_clientes.link_drive` existe | INSERT msg "⏳ Indexando…" + UPSERT `newsletter_wip.estado=indexing` + executeWorkflow `IA Newsletter — KB Fetch [SUB]` async con `init_followup=true, background=true` | Mensaje 1: `⏳ Indexando el contexto del cliente desde Drive (~30s)... En cuanto termine te paso el resumen.` Mensaje 2 (~30s): el greeting híbrido completo (formato Branch A) emitido por kb_fetch. |
| **C** | Sin store y sin link_drive | INSERT msg genérico (incluye instrucciones inline para vincular Drive) | `Hola. Todavía no tengo contexto del cliente cargado (no hay carpeta Drive vinculada).\n\n📁 Para activar el RAG: edita la ficha del cliente → sección Conexiones → pega la URL de Drive en "Carpeta General del Cliente" → Guardar datos. Vuelve aquí y empezaré a indexar.\n\n✍️ Si prefieres seguir sin RAG, cuéntame el brief: objetivo de la secuencia, etapa de leads, segmento y cuántos emails (máx 6).` |

**Schema `rag_stores.metadata`** (cache poblado por `IA Newsletter — KB Fetch [SUB]` al final de cada indexación):
```json
{
  "file_count": 24,
  "categories": {
    "Onboarding": 5,
    "Análisis y estrategia": 8,
    "Reuniones": 6,
    "Informes": 5
  }
}
```
Categorías = nombres de carpetas L1 del Drive del cliente. Cada archivo se mapea a su L1 ancestor escalando por `parents[0]` a través de los listings L1/L2/L3 (todos cargan ahora `parents` en su Drive query).

**Cambios concretos en `IA Newsletter — KB Fetch [SUB]` (`w6Gqo8B6Sqp6Mq9x`)** para soportar greeting follow-up:
- Queries Drive (`Listar Archivos Drive` + L1/L2/L3) extienden `fields` con `parents`.
- `Normalizar Input` extrae `init_followup` del body.
- `Guardar Resumen Background` computa `metadataComputed` (file_count + categorías) + lo añade al UPSERT `rag_stores` + propaga al return (`kb_text`, `link_drive`, `nombre_cliente`, `conversation_id`, `metadata`, `init_followup`).
- 4 nodos nuevos al final: `If Init Followup` → `Format Greeting Followup` → `Insert Greeting Msg` → `Patch WIP Borrador`. Solo se ejecutan si `init_followup === true`. Cron de reindex (`kZE3W2ae0upyGt2E`) y tool_loop (`cargar_contexto_cliente`) NO disparan greeting.

**Bubble: API Connector** `newsletter_init`:
- POST webhook fire-and-forget.
- URL: `https://n8n-n8n.irzhad.easypanel.host/webhook/init-newsletter`.
- Headers: `Content-Type: application/json`.
- Body raw: `{"conversation_id":"<conv_id>","agencia_id":"<agencia_id>","cliente_notion_id":"<cliente_notion_id>"}`.
- Data type: **Empty**. Use as: **Action**.
- **Initialize obligatorio** (en Bubble TODA call requiere Initialize). Usar UUIDs literales para los 3 placeholders (las comillas ya están en el template). Recomendado usar `ce5efad2-...` (conv test, 15 msgs) — el race guard del workflow aborta sin insertar nada porque `count(chat_messages) > 0`.

**Reset disparará greeting de nuevo:** `newsletter_reset_wip` borra `chat_messages` → al recargar `/newsletter`, Page Loaded ve `count=0` → call `newsletter_init` → greeting fresco.

**Race guard:** `newsletter_init` re-verifica `count(chat_messages)` justo antes de insertar. Previene doble-disparo de Bubble (dev mode reload, F5 rápido).

**Smoke test 2026-04-30:** Branch A validado con cliente The Nucleo (conv test temporal). Greeting insertado en <5s con narrativa Gemini correcta. `file_count=0 / categorías=—` esperado porque el store se indexó antes del ALTER TABLE — se rellenará al próximo reindex.

---

## Verificación E2E (cuando Fase 3 esté lista)

**Cliente test:** Actualízate Psicología (bubble_id `1772815116826x630388853372878800`).

1. **Page Loaded:** abrir `/clientes/<id>/newsletter` → conv creada con `tipo=newsletter_<notion_id>` (sin sufijo timestamp). Ver `current_conversation_id` set en custom state. Verificar SQL:
   ```sql
   SELECT id, tipo FROM chat_conversations WHERE tipo = 'newsletter_31de4743-b0ae-8165-aa1c-c14e6387385c';
   ```
2. **Mensaje 1:** "newsletter de bienvenida 3 emails para nuevos suscriptores que vienen de Instagram". Realtime debe pintar respuesta IA + parametros poblada en chip Parámetros en <8s. Estado pasa a `ready_to_generate` o `waiting_strategy_approval`.
3. **Mensaje 2:** "ok con la estrategia". Estado `generating` → `waiting_email_approval`, `email_actual=1`. Chip Email 1 desbloqueado.
4. Click chip Email 1 → carga meta + html. Click Previsualizar → popup muestra cabecera tipo cliente mail + body.
5. **Mensaje 3:** "ok email 1". `email_actual=2`, chip Email 2 desbloqueado.
6. **Mensaje 4:** "cambia el asunto del email 2 a algo más corto" → `emails_patch` aplicado al idx 2, `email_actual` no incrementa. Estado vuelve a `waiting_email_approval`.
7. **Mensaje 5:** "ok email 2", **Mensaje 6:** "ok email 3". Tras último: estado=`completado`. Aparece botón Generar Doc.
8. Click Generar Doc → trigger webhook → 200 inmediato → ~30s después `entregando` → `entregado`, link Drive y botón Ver Doc.
9. Click Ver Doc → abre `doc_url` → ver Doc en `Análisis y estrategia/Estrategia/Historico_newsletters/`.
10. **Probar cron reset:** forzar `estado=generating` con `updated_at` 20 min atrás (UPDATE manual) → en 15 min cron lo marca `error` + msg sistema.
11. **Probar Reiniciar:** click → `chat_messages` borrados, WIP a `borrador`. La conv NO se borra (su `id` y `tipo` persisten). Page Loaded reusa la misma conv (idempotente vía `get_or_create_conversation`). Para verificar UI fresca, recargar la página tras click Reiniciar.

13. **Probar edición manual:** tras generar email 1, abrir popup → modificar `Input asunto` y `RichTextInput contenido` → click GUARDAR CAMBIOS. Verificar SQL:
    ```sql
    SELECT emails->0->>'asunto' AS asunto, length(emails->0->>'contenido_html') AS html_len, emails->0->>'estado_aprobacion' AS estado_aprob
    FROM newsletter_wip
    WHERE conversation_id = '<conv_id>';
    ```
    Deben aparecer los valores editados. `estado_aprobacion` no cambia. WebSocket debe disparar `refresh_emails` y la UI sin recargar muestra los nuevos valores.
12. **Logs:** revisar n8n executions por workflows `newsletter_*` y `chat_messages` ordenados.

---

## Migración de datos legacy (Fase 4) ✅ COMPLETADA

Tabla legacy `newsletter_emails_wip` **DROPPED** en cbi. La tabla canónica actual es `newsletter_wip` (creada durante refactor 2026-04-29). Re-onboarding aplicado a las conversaciones afectadas.

Razones para descartar:
- Los datos viejos no tienen `preheader`/`from_name`/`contenido_md` ni parámetros estructurados.
- Reconstruirlos con valores sintéticos corrompería la utilidad histórica.
- El histórico real de newsletters ya entregados está en Drive (`Historico_newsletters/`).

---

## Decisiones clave (2026-04-29)

1. **1 newsletter activa por cliente** (decisión revisada 2026-04-29 tras sesión Bubble spec): `tipo='newsletter_<notion_id>'` sin sufijo timestamp. Reset sobrescribe la activa. Histórico de Docs entregados vive en Drive `Historico_newsletters/`. Paridad con Análisis. **Anula la decisión original "N newsletters por cliente con sufijo timestamp"** del plan §3 — Bubble no manejaba bien los timestamps y la complejidad no aportaba valor (el histórico real está en Drive).
2. **WIP unificada en 1 fila.** `chat_conversations.metadata` + `newsletter_emails_wip` fusionados en `newsletter_wip`.
3. **Sin DELETE post-entrega.** Drafts persistentes con `estado=entregado`.
4. **Lógica Claude en tool_loop, no en entrada.** Simetría con Análisis.
5. **Multi-tenant real** en CRON reindex y entrada.
6. **`rag_stores` discriminado por `tipo`** (`cerebro`/`newsletter`). Sin tocar `bub_clientes`.
7. **`completar_newsletter` no renombra `tipo`.**
8. **Estados stuck = `indexing|generating|entregando`.** Los `waiting_*` son humanos, no se tocan.
9. **No abstracción de blueprint canónico.** Cada chat su tabla y workflows; lo común es la topología y los estados.
10. **Edición manual de copys preservada del legacy + ampliada.** Asunto + contenido editables (legacy solo permitía contenido). `estado_aprobacion` no se toca al editar manualmente. Editable en cualquier estado. RPC `newsletter_update_email` aplicada 2026-04-29.

---

## Estados WIP — mapa completo (validado E2E 2026-04-30)

`newsletter_wip.estado` (text) recorre 10 estados a lo largo del flujo. Útil para reusar en futuras co-creaciones (otros chats con misma topología tipo Cerebro / Tareas / Análisis):

| # | Estado | Cuándo se setea | Disparador |
|---|---|---|---|
| 1 | `borrador` | Inicial al crear WIP (primer mensaje del usuario al agent). | Webhook `newsletter_send_message` crea WIP por primera vez. |
| 2 | `ready_to_generate` | Los 4 params completos (objetivo, etapa, segmento, cantidad). | Tool `guardar_parametros`. |
| 3 | `indexing` | Mientras Gemini indexa RAG del cliente. | Tool `cargar_contexto_cliente` (cuando `link_drive` no es null). |
| 4 | `waiting_strategy_approval` | Tras generar la estrategia (texto narrativo en `estrategia_texto`). | Tool `generar_estrategia`. |
| 5 | `generating` | Brevemente entre confirmar estrategia y emitir el primer email. | Tool `confirmar_estrategia`. |
| 6 | `waiting_email_approval` | Email N generado en estado `borrador`, esperando "ok email N". | Tool `generar_email`. |
| 7 | `completado` | Todos los `cantidad_emails` emails tienen `estado_aprobacion = aprobado`. | Tool `aprobar_email` (último). |
| 8 | `entregando` | Click Generar Doc, n8n procesando. | Webhook `IA Newsletter — Trigger Entrega`. |
| 9 | `entregado` | n8n completó: Doc creado en Drive, `doc_url` poblado. | Workflow `IA Newsletter — Entrega [SUB]` (final). |
| 10 | `error` | Algo falló en cualquier paso (mensaje en `error_msg`). | Cualquier tool con error / cron `CRON IA Análisis — Reset Stuck (15min)` para stuck. |

**Estado de los emails individuales** — `emails[N].estado_aprobacion`:

| # | Estado | Cuándo |
|---|---|---|
| 1 | `borrador` | Email recién generado por `generar_email` o tras `newsletter_update_email` (edición manual no cambia este estado). |
| 2 | `aprobado` | Tras tool `aprobar_email` (cuando user dice "ok email N"). |

**Reglas:**
- `estado_aprobacion` se preserva en edición manual (`newsletter_update_email` modifica `asunto` + `contenido_html` solo). Si el usuario edita, sigue en `borrador` hasta que apruebe explícitamente.
- Estados "stuck candidate" para cron reset: `indexing`, `generating`, `entregando` (los demás son humanos o terminales).
- Estados terminales: `entregado`, `error`. Los demás son intermedios.

---

## Pendientes

1. **Fase 3 Bubble** — implementar §7 completa. ~2h en sesión Bubble.
2. **Fase 4 migración data** — ~30 filas legacy `newsletter_emails_wip` → re-onboarding (§9 plan).
3. **Activación atómica final:**
   - Activar `inWFSAEDLCH1kx5P` (entrada) cuando Bubble Fase 3 cerrada y testeada.
   - Activar `u9DsFadbpb7QiLaP` (trigger_entrega) cuando UI Bubble tenga botón Generar Doc.
   - Activar `kZE3W2ae0upyGt2E` (cron reindex) tras E2E que confirme indexación escribe en `rag_stores`.
4. **Renombrar workflows con nombres legacy:**
   - `kZE3W2ae0upyGt2E` "Newsletter IA — CRON Reindexar RAG Nocturno" → `CRON IA Newsletter — Reindexar RAG (3:30)`.
   - `w6Gqo8B6Sqp6Mq9x` "Newsletter IA — Indexar Contexto Drive [Subworkflow]" → `IA Newsletter — KB Fetch [SUB]`.
5. **Inicialización Bubble RPCs** con conv de prueba completa (§7.2 procedimiento).
6. **Auditoría RAG por cliente** (memoria `project_rag_archivos_pendiente.md`): qué archivos del Drive alimentan cada `rag_stores.tipo` por cliente. Antes de cerrar refactor.
7. **Decisión abierta `bub_clientes.bb_link_drive_newsletter`:** hoy hay `bb_link_drive_analisis`. Mi recomendación: NO crear campo nuevo — usar `newsletter_wip.doc_url` (último Doc generado). Acceso al histórico va por carpeta Drive desde navegador.

---

## Gotchas y referencias

- `feedback_n8n_antipatterns.md` — jsonb objetos directos, executeWorkflow ResourceLocator, Anthropic streaming, JSON truncado.
- `feedback_postgrest_gotchas.md` — schema cache, `eq.` duplicado, jsonb storage.
- `feedback_bubble_patterns.md` — Action vs Data source, RPC re-init, JSON-safe + Data type Empty para webhooks, lock progresivo (#15), cheatsheet operadores (#11).
- `feedback_bubble_data_api_conventions.md` — URLs (path /version-test=dev), agencia_id usa `bubble_id` no `uuid_supabase` para Bubble Data API (no aplica aquí porque hablamos directo a Supabase).
- `feedback_naming_espanol.md` — Custom Events, states, workflows en español.
- `project_analisis_estrategico.md` — patrón referencia.

---

## Cliente test

- **Actualízate Psicología**
  - bubble_id: `1772815116826x630388853372878800`
  - cliente_notion_id: `31de4743-b0ae-8165-aa1c-c14e6387385c`
  - Drive folder: `https://drive.google.com/drive/folders/136baB98ana-6NWEl6ISPWxSpW7L-cgBH`

---

## Mejoras futuras (parking lot)

Ideas evaluadas y pospuestas. Consultar antes de empezar nuevo trabajo en el sector.

### Adjuntar imágenes al chat (vision Claude)
- **Stack:** Bubble ImageUploader → Supabase Storage (bucket privado, signed URL) → `newsletter_send_message` extiende body con `attachments: [{type:"image", url:"..."}]` → `Build Claude Body` inyecta image block `{type:"image", source:{type:"url", url:"..."}}` en el último user msg → Claude Sonnet 4.6 vision lee directamente.
- **Persistencia:** URL en `chat_messages.metadata` para re-render en siguientes turnos.
- **Coste estimado:** ~3-5h. Tokens vision Claude (~1k por imagen).
- **Use cases:** branding/logo del cliente, packshot de producto, screenshot landing competidor.

### Adjuntar documentos PDF/DOCX al chat
- **Stack:** Bubble FileUploader → Supabase Storage → parser inline (Code node con pdf-parse / mammoth, o Gemini `inline_data` con base64 que acepta PDF nativo) → texto plano se concatena en `kb_links_text` o columna nueva `kb_attachments_text`.
- **Decisiones cerradas:** per-conv (no contaminar RAG persistente del cliente), borrar al `newsletter_reset_wip`.
- **Coste estimado:** 1-2 días. Storage Supabase + parser + límite (max ~50KB texto extraído).
- **Use cases:** brief externo del cliente, especificaciones de producto, transcripción de reunión.

### Otras
- **Branch A con `file_count=0`** → caer a Branch C msg adaptado ("Drive vinculado pero sin archivos indexables"). Trivial, 1 IF en `Build Context` de `newsletter_init`. Edge case raro.
- **Verificar SPA navigation Bubble** (cambio de cliente sin F5) — comprobar que Page Loaded re-dispara y greeting funciona en la nueva conv.
- **Caso B real con cliente nuevo** (sin store + con `link_drive`) — el smoke test del greeting solo cubrió Branch A. Validar Branch B end-to-end la primera vez que un cliente nuevo abra `/newsletter`.
