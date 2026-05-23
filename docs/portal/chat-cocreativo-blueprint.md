---
title: Blueprint Chat Co-creativo
dominio: ia
estado: activo
actualizado: 2026-05-14
tags: [ia, chat, blueprint, claude, gemini]
---

# Blueprint — Chat Co-creativo

Patrón estándar para construir chats IA en TheNucleo donde, en paralelo a la conversación, la IA **produce un artefacto** (email, documento, tarea, diseño, etc.) que el usuario puede ver evolucionar en tiempo real y entregar al final.

> **Skill complementaria:** `chat-ia-builder` contiene el detalle profundo (system prompts, JSON de tools, nodos concretos de n8n, código JS del HTML WebSocket). Este doc es el índice ejecutivo y mapea el estado actual de TheNucleo.

---

## 1. Chats co-creativos en TheNucleo

| Chat | Tabla WIP | `tipo` canónico (esperado) | `tipo` real (cbi 2026-04-23) | Workflows n8n | DB |
|---|---|---|---|---|---|
| **Análisis Estratégico Cliente** ✅ operativo | `analisis_wip` | `analisis_<notion_id>` | `analisis_<bubble_id>` 🔴 bug | `dtgF0G35aeJQVVfn` (entrada) + `FFhkdTFCjTtfyvhP` (tool loop) + `Cfs3NFEE1enu1jTx` (kb_fetch) + `JtXdkXHm6RyGOJft` (trigger entrega) + `QW8VZ9cV5ECsSKvZ` (entrega) + `V60MieFkQzOszxhh` (cron reset) | cbi |
| **Newsletter IA** ✅ operativo (E2E 2026-04-30) | `newsletter_wip` | `newsletter_<notion_id>` | `newsletter_<cliente_notion_id>` ✅ | `inWFSAEDLCH1kx5P` (entrada) + `SfwR7gqs1hBIOV7i` (tool loop) + `9wnB9NI8Capa4b8s` (generar HTML/Word) + `kZE3W2ae0upyGt2E` (RAG CRON) + `w6Gqo8B6Sqp6Mq9x` (indexar Drive) + `UBYXNKZ1HHFTZyDX` (init greeting) + `u9DsFadbpb7QiLaP` (trigger entrega) | cbi |
| **Cerebro IA** (consulta, NO co-creativo) | N/A | `cerebro_<notion_id>` | `cerebro_<notion_id>` ✅ | `JI5Tr7IogqXgaI7a` + `7yjLwl4cEJa7XAYY` + `NI1oUwIY99TGk496` (indexar Drive) + `BqNTrwoQ2iJIcAB4` (reindexar manual) + `ZnJSkoWlSusmEjhO` (RAG CRON) | cbi |
| ~~Chat Tareas~~ | 🗑 DROPPEADA | — | — | ELIMINADO 2026-05-14. Tabla `tarea_en_progreso` droppeada (CASCADE), workflows `RPdNg5ZNXK0VrOhG` + `aGML9yyMsoAQ6ZGL` archivados, API Connector `chat_creacion_mensajes` borrada (0 usos). Página Bubble `Chat_tareas_general` pendiente revisar (consume `obtener_mensajes`) | — |

> Las tareas se crean desde botones Bubble vía workflow `eHyXBETcaGSNXqLk` (OPS TAREAS — Crear desde Formulario Bubble), NO desde un chat co-creativo.

> Cerebro IA no es co-creativo: conversa sobre el cliente, no produce artefacto. Se lista aquí para diferenciación.

> ⚠️ **Bugs Page Loaded `tipo` activos** — Análisis usa `analisis_<bubble_id>` y Newsletter usa `newsletter` sin sufijo. La convención canónica es `<sector>_<notion_id>`. Pendiente arreglo en Page Loaded de Bubble. Detalle en `project_analisis_estrategico.md` y `project_newsletter_pendientes.md`.

---

## 2. Arquitectura base (Pull-on-Signal)

```
Bubble (UI) → n8n webhook → Claude API (tool_use loop) → Supabase
     ↑                                                         |
     └──────────── Supabase Realtime (3 canales) ─────────────┘
```

**Regla clave:** n8n nunca responde datos a Bubble. Guarda en Supabase y emite una **señal** (cambio en `estado` o `metadata`). Bubble escucha vía Realtime y hace pull cuando detecta la señal.

---

## 3. Componentes requeridos (resumen)

### Supabase
- [ ] Tabla `<nombre>_wip` con FK `conversation_id` → `chat_conversations(id) ON DELETE CASCADE` + campo `estado` (`borrador`/`completado`/`entregado`).
- [ ] Trigger `updated_at`.
- [ ] Realtime habilitado en `chat_messages`, `chat_conversations`, `<nombre>_wip`.
- [ ] RLS policies anon por `agencia_id` (3 tablas).

### n8n
- [ ] **Workflow principal** (~19 nodos): webhook `responseMode: responseNode` → Respond 200 OK inmediato en paralelo → Claude loop → guardar mensaje → branch por estado.
- [ ] **Tool Loop subworkflow** (~7 nodos recursivos): `Execute Workflow Trigger` **typeVersion: 1** (NO 2, rompe recursión). Preparar Recursión obligatorio. Contador anti-loop máx 10.
- [ ] **Entrega subworkflow** (si genera doc Drive): Drive API con `supportsAllDrives: true`, usar `$json.id` (NO `$json.documentId`).

### Bubble
- [ ] Página `/chat-<nombre>` con layout 3 columnas (chat | mensajes | artefacto WIP).
- [ ] **4 Custom States**: `current_conversation_id`, `conv_metadata_estado`, `enviando` (semáforo), `last_subscribed_conversation` (anti-duplicación).
- [ ] **6 API Connectors como Action** (nunca Data source): `get_or_create_conversation`, `insert_chat_message`, `get_messages`, `get_conversation`, `get_wip_items`, `trigger_n8n_chat`.
- [ ] Elemento **HTML con 3 canales Supabase Realtime** (mensajes + estado conv + WIP).
- [ ] **3 `bubble_fn_*`**: `refresh_chat(msg_id)`, `refresh_chat_state(estado)`, `refresh_items(trigger)`.

---

## 4. Estados del flujo

```
chat_conversations.metadata.estado:
  borrador    → usuario + IA iterando brief
  completado  → IA marcó tool "completar" → dispara rama de entrega
  entregando  → subworkflow de entrega en curso
  entregado   → artefacto final creado, UI bloquea edición
  error       → algo falló, Bubble muestra aviso y permite reintentar
```

**Transiciones de UI por estado:**
- `borrador` → input enviar visible, botón "Entregar" oculto
- `completado` → botón "Entregar" visible
- `entregando` → spinner, todo deshabilitado
- `entregado` → enlace al doc visible, input deshabilitado

---

## 5. Gestión de errores

| Capa | Qué puede fallar | Cómo manejarlo |
|---|---|---|
| **Webhook n8n** | Payload mal formado, conv_id inválido | Validar en nodo "Normalizar Input" → PATCH `chat_conversations.metadata.estado = 'error'` + insertar mensaje asistente con explicación |
| **Claude API** | Rate limit, timeout, 5xx | Retry con backoff en nodo. Si falla tras 3 intentos → mensaje error + estado `error` |
| **Tool execution** | Tool falla (Supabase down, datos inválidos) | Devolver `tool_result` con `is_error: true` + mensaje; Claude decide cómo seguir |
| **Tool loop infinito** | Claude entra en bucle sin llegar a texto final | Contador anti-loop (máx 10) → corta, inserta mensaje asistente con aviso |
| **Entrega Drive** | Drive API 403, folder no encontrado | Capturar error → estado `error` + conservar WIP para reintento manual |
| **Bubble WebSocket** | Conexión cae (60s inactividad) | JS reconecta automáticamente; al reconectar, re-pull manual de `get_messages` para recuperar lo perdido |
| **Semáforo enviando** | Doble-click del usuario | Custom state `enviando=yes` → workflow `enviar` condicionado a `enviando is no` |
| **Suscripción duplicada** | Usuario refresca y se duplican listeners | Comprobar `last_subscribed_conversation ≠ current_conversation_id` antes de suscribir |

---

## 6. Errores de producción al logging (Ops Monitor)

Cualquier fallo en n8n → workflow `HRDQ9Ju4NAIUV0qyhKzlz` (ERRORES — Capturar y Registrar Plataforma) registra en `n8n_incidencias` (Supabase). Panel cerrado en `work.thenucleo.com/incidencias`. El nodo `Limpiar workflow_executions` del mismo flujo reconcilia oportunamente runs colgados en `workflow_executions`.

```
Campos reales de workflow_executions:
  id (uuid), agencia_id, user_bubble_id, workflow_name, status,
  context (jsonb — input/contexto serializado), cliente_ref,
  url_analizar, link_drive, link_drive_analisis, error_message,
  created_at, updated_at
```

⚠️ NO existen `payload`, `started_at`, `finished_at` en esta tabla (esos sí están en `holded_sync_log`). El input/contexto se guarda en `context` (jsonb).

---

## 7. Checklist de réplica (pegar al crear uno nuevo)

```
SUPABASE
[ ] Migration: crear tabla <nombre>_wip (FK cascade a chat_conversations)
[ ] Trigger updated_at
[ ] ALTER PUBLICATION supabase_realtime ADD TABLE <nombre>_wip
[ ] RLS policies anon (SELECT/INSERT/UPDATE scoped a agencia_id)

N8N
[ ] Workflow principal: copiar Análisis `dtgF0G35aeJQVVfn` como plantilla (más reciente y limpio que Newsletter)
[ ] Renombrar, cambiar webhook path a /chat-<nombre>
[ ] Subworkflow tool loop: copiar `FFhkdTFCjTtfyvhP` — VERIFICAR typeVersion: 1
[ ] Subworkflow trigger entrega (shim async 200 OK): copiar `JtXdkXHm6RyGOJft`
[ ] Subworkflow entrega real (genera doc Drive): copiar `QW8VZ9cV5ECsSKvZ`
[ ] CRON reset stuck: copiar `V60MieFkQzOszxhh` (cada 15 min, llama RPC reset)
[ ] Ajustar system prompt + tools + Build Prompt para el caso nuevo
[ ] Tools "completar" → marca `estado = 'completado'` en la tabla WIP (cbi)
[ ] Activar workflows y probar con curl al webhook

BUBBLE
[ ] Duplicar página Análisis Cliente (`/clientes/{empresa_id}/analisis`) como plantilla — es el chat más limpio y reciente; Newsletter tiene bug Page Loaded sin resolver.
[ ] Renombrar, ajustar rutas y variables de contexto
[ ] Añadir API Connectors (copiar grupo "Analisis Cliente" — 9 calls auditadas). Todas las URLs deben apuntar a `https://cbixhqjsnpuhcrcjppah.supabase.co` (cbi).
[ ] Añadir elemento HTML con los 3 canales Realtime (sustituir nombre tabla WIP)
[ ] Definir 3 bubble_fn (JavascriptToBubble element)
[ ] Page Loaded workflow: init conversación + suscribir + cargar historial
[ ] ⚠️ Verificar el patrón `tipo`: usar `<sector>_<notion_id>` (canónico). Los chats existentes tienen bugs en este punto — NO replicar el bug.
[ ] Enviar mensaje workflow: semáforo + insert + trigger n8n
[ ] Body del trigger n8n: aplicar `:formatted as JSON-safe` a `<message>` (texto libre del usuario), placeholder SIN comillas en el template del API Connector
[ ] Workflows refresh_chat / refresh_chat_state / refresh_items
[ ] Botones dinámicos por estado
[ ] Test end-to-end con Ops Monitor abierto

DOCS
[ ] Añadir fila nueva a tabla "Chats co-creativos" en este doc
[ ] Actualizar docs/infra/bubble-api-connectors.md con las 6 calls nuevas
[ ] Actualizar docs/infra/n8n-workflows.md con los IDs nuevos
[ ] Actualizar docs/infra/supabase-schema.md con la tabla WIP nueva
```

---

## 8. Anti-patrones (NO hacer)

- ❌ `responseMode: lastNode` en webhook n8n → bloquea la respuesta hasta que Claude termine (Bubble ve timeout).
- ❌ `Execute Workflow Trigger` con `typeVersion: 2` → rompe la recursión del tool loop.
- ❌ API Connector como **Data source** → Bubble cachea. SIEMPRE **Action**.
- ❌ Incremento ciego de contadores en metadata → leer BD y contar real.
- ❌ Múltiples suscripciones Realtime al mismo canal → listeners duplicados, mensajes repetidos.
- ❌ Crear documento con Docs API v1 directamente (no tiene `parents`) → usar **Drive API**.
- ❌ Usar `$json.documentId` en el paso post-creación → el campo correcto es `$json.id`.
- ❌ RLS abierta sin constraint por `agencia_id` → riesgo de fuga cross-tenant.
- ❌ Insertar mensaje asistente antes de completar tool loop → UI muestra respuesta a medias.

---

## 9. Referencias

- **Skill completa:** `chat-ia-builder` en `C:\Users\Benjamin\.claude\skills\chat-ia-builder\` (incluye plantillas JSON, prompts, código JS del WebSocket).
- **Ejemplo operativo más limpio:** Análisis Estratégico Cliente (sector 7) — workflows `dtgF0G35aeJQVVfn`, `FFhkdTFCjTtfyvhP`, `Cfs3NFEE1enu1jTx`, `JtXdkXHm6RyGOJft`, `QW8VZ9cV5ECsSKvZ`, `V60MieFkQzOszxhh`. Auditado 2026-04-22/23 contra bug `cliente_id`.
- **Ejemplo legacy:** Newsletter IA — workflows `inWFSAEDLCH1kx5P`+. Tiene bug Page Loaded en patrón `tipo`. Útil como referencia pero **no replicar**.
- **Schema Supabase:** [[supabase-schema]] → tabla `analisis_wip` (cbi) como referencia canónica.
- **API Connectors Bubble:** [[bubble-api-connectors]] → grupo "Analisis Cliente" (9 calls) como plantilla.
- **n8n anti-patrones generales:** [[n8n-workflows]] → sección "Lecciones aprendidas".
