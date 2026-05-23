---
title: Sector — Chat Cerebro IA
dominio: sectores
estado: activo
actualizado: 2026-05-08
tags: [sector, chat, cerebro, ia, rag]
---

# Sector 5 — Chat Cerebro IA (consulta)

**Estado:** ✅ MIGRADO A CBI (2026-04-21). Chat de consulta sobre clientes con RAG. NO co-creativo (no produce artefacto).

Campos RAG (`store_id` Gemini + `indexed_at`) viven en tabla `rag_stores(notion_id, tipo, store_id, indexed_at, agencia_id)` en cbi. Bootstrap inicial desde `notion_empresas` (maw, hoy INACTIVE) completado en 2026-04-21 — 37 stores migrados; las lecturas activas hoy son contra `bub_clientes` (cbi).

> **Nota 2026-05-07:** las menciones a `maw` y a la cred legacy `pmc312jjJKdPClmj` que aparecen abajo son **históricas** (checklists del bootstrap ya completados). El proyecto maw está INACTIVE; toda operación viva del sector usa cbi y la cred `13dKSjEd2XZCYpJa`.

---

## Arquitectura del sector

```
Usuario en /clientes/{empresa_id}/cerebro
         │
         │ (hace pregunta sobre el cliente)
         ▼
┌──────────────────┐   POST webhook /chat-cerebro
│ Bubble (UI)      │────────────────────────────────────────┐
│ Chat simple      │                                        │
└────────▲─────────┘                                        ▼
         │                                         ┌────────────────┐
         │ escucha via Realtime                    │ n8n JI5Tr7...  │
         │                                         │ Cerebro IA     │
┌────────┴─────────┐                               │ Chat entrada   │
│ Supabase cbi:    │                               └────────┬───────┘
│ chat_messages    │◄──INSERT msg user + assistant          │
│ chat_conversat.. │                                        │
│                  │                                        ▼
│ RAG: contexto    │                               ┌────────────────┐
│ tareas + clientes│                               │ n8n 7yjLwl...  │
│ + docs Drive     │                               │ Tool Loop RAG  │
└──────────────────┘                               │ Claude API     │
                                                   └────────────────┘
```

---

## Capa Bubble

### Página
- **`/clientes/{empresa_id}/cerebro`** — chat fullscreen de consulta.

### UI
- **Single column**: chat historial con mensajes + input.
- SIN panel derecho (no es co-creativo).

### Custom States
- `current_conversation_id`
- `enviando` (semáforo)
- `last_subscribed_conversation`

### API Connectors (2+)
- `chat_send_message_cerebro` → webhook n8n `chat-cerebro`
- `chat_get_or_create_conversation` → RPC genérico
- `chat_get_messages` → GET chat_messages por conversation_id

### Realtime
- `chat_messages` INSERT
- `chat_conversations` UPDATE (para metadata/estado si aplica)

---

## Capa Supabase cbi

### Tablas
- **`chat_conversations`** — genérica. `tipo='cerebro_{empresa_id}'`. Campo `metadata jsonb` guarda `contexto_cargado`, `contexto_resumen`, `rag_store_id`.
- **`chat_messages`** — genérica, trigger FIFO 100.
- **`rag_stores`** — `(notion_id, tipo, store_id, indexed_at, agencia_id)`. PK `(notion_id, tipo)`. `tipo ∈ {cerebro, newsletter}`. Reemplaza las columnas `rag_*` que vivían en `notion_empresas` en maw.
- **`bub_clientes`** — lectura de `nombre_empresas`, `link_drive`, `pagina_web`, `sector`, `descripcion_plan`, `estado`, `agencia_id`. Reemplaza las lecturas que antes se hacían a `notion_empresas` en maw.
- **`bub_tareas_notion`** — lectura vía vistas `v_tareas_*`.

### Vistas para RAG
- **`v_tareas_cerebro_ia`** — tareas últimos 90 días sobre `bub_tareas_notion`, con `vencida` y `dias_hasta_entrega` calculados.
- **`v_tareas_contexto_ia`** — últimos 10 días sobre `bub_tareas_notion`.

### RPCs
- `get_or_create_conversation(p_agencia_id, p_tipo)` — genérico.
- `cerebro_consulta_ia(query text) → jsonb` — ejecutor SQL SELECT genérico (solo SELECT). Usado por el Tool Loop.

### RAG — fuentes externas
- Google Drive del cliente (indexado por workflow `NI1oUwIY99TGk496`, disparado por CRON `ZnJSkoWlSusmEjhO` o webhook manual `BqNTrwoQ2iJIcAB4`).
- Gemini fileSearchStore (una por cliente). `store_id` persistido en `rag_stores`.

---

## Capa n8n — Workflows del sector

| ID | Nombre | Rol |
|---|---|---|
| `JI5Tr7IogqXgaI7a` | IA Cerebro — Chat por Cliente | Webhook entrada, guarda mensaje user, dispara Tool Loop, guarda respuesta |
| `7yjLwl4cEJa7XAYY` | IA Cerebro — Tool Loop [SUB] | Recursivo Claude + tools (`consultar_datos`, `describir_tabla`, `listar_tablas`, `cargar_contexto_cliente`) |
| `NI1oUwIY99TGk496` | IA Cerebro — Indexar Drive [SUB] | **Worker motor** de indexación: Drive → Gemini fileSearchStore → UPSERT `rag_stores` |
| `ZnJSkoWlSusmEjhO` | CRON IA Cerebro — Reindexar RAG (3:00) | Trigger CRON 3AM → llama a `NI1oUwIY99TGk496` para clientes con cambios en Drive |
| `BqNTrwoQ2iJIcAB4` | IA Cerebro — Reindexar RAG Manual [WEBHOOK] | Trigger manual POST `/reindexar_rag_cerebro` → llama a `NI1oUwIY99TGk496` |

**Nota:** `NI1oUwIY99TGk496` y `BqNTrwoQ2iJIcAB4` **no son duplicados**. Son 1 worker motor + 2 disparadores (manual + CRON). `ZnJSkoWlSusmEjhO` también invoca al mismo worker.

### Credencial Supabase
Todos los workflows del sector usan ahora credencial `13dKSjEd2XZCYpJa` ("Espejo Supabase", cbi). La credencial legacy `pmc312jjJKdPClmj` (maw) queda sin uso en este sector.

---

## Diferencias clave vs Chat Newsletter

| Aspecto | Newsletter | Cerebro |
|---|---|---|
| Tipo | Co-creativo (produce email) | Consulta (solo responde) |
| Tabla WIP | `newsletter_wip` (antes `newsletter_emails_wip`) | Ninguna |
| Artefacto entregado | Google Doc + HTML | Solo respuesta en chat |
| Estados | borrador/completado/entregado | No aplica |
| Panel UI | Chat + Preview derecha | Solo chat |
| Canales Realtime | 3 (chat + estado + WIP) | 2 (chat + estado) |

---

## Verificaciones completadas (2026-04-21)

- [x] URLs Supabase en los 5 workflows apuntan a cbi (`cbixhqjsnpuhcrcjppah`).
- [x] Vistas `v_tareas_cerebro_ia`, `v_tareas_contexto_ia` existen en cbi, leen `bub_tareas_notion`.
- [x] RPC `cerebro_consulta_ia(query text) → jsonb` existe en cbi y devuelve datos reales (probado con query sobre `v_tareas_cerebro_ia`).
- [x] Credenciales Gemini + Drive sin cambios (no tocan Supabase).
- [x] Credencial Supabase migrada: `pmc312jjJKdPClmj` (maw) → `13dKSjEd2XZCYpJa` (cbi) en todos los nodos del sector.
- [x] Bootstrap `rag_stores`: 37 filas migradas de `notion_empresas.rag_cerebro_store_id` (maw) → `rag_stores(tipo='cerebro')` (cbi). Cobertura 17/17 clientes activos con Drive.

## Task list de pruebas de validación (end-to-end)

Pruebas para ejecutar tras cualquier cambio en el sector (refactor, nuevo tool, cambio de modelo). Orden recomendado: capa de datos → componentes aislados → integración → UI.

### A. Capa de datos (Supabase cbi)

- [ ] **A1.** `rag_stores` tiene cobertura: `SELECT COUNT(DISTINCT c.notion_id)=COUNT(DISTINCT r.notion_id) FROM bub_clientes c LEFT JOIN rag_stores r ON c.notion_id=r.notion_id AND r.tipo='cerebro' WHERE c.estado='Activo' AND c.link_drive IS NOT NULL`.
- [ ] **A2.** `cerebro_consulta_ia` solo permite SELECT: `SELECT cerebro_consulta_ia('UPDATE bub_clientes SET nombre_empresas=''x''')` → debe lanzar excepción.
- [ ] **A3.** `v_tareas_cerebro_ia` devuelve datos con `cliente_nombre` poblado: `SELECT cerebro_consulta_ia('SELECT COUNT(*) FROM v_tareas_cerebro_ia WHERE cliente_nombre IS NOT NULL')` > 0.
- [ ] **A4.** `chat_conversations.metadata` es jsonb válido: `SELECT jsonb_typeof(metadata) FROM chat_conversations LIMIT 5` → todas `object`.

### B. Workflow Tool Loop aislado (`7yjLwl4cEJa7XAYY`)

- [ ] **B1.** Ejecución manual desde la UI n8n con un tool_use mock de `consultar_datos` (query `SELECT COUNT(*) FROM bub_tareas_notion WHERE agencia_id='e748c7d4-5823-413d-8cb3-532896f6e41d'`). Verificar que devuelve número > 0 en `tool_result`.
- [ ] **B2.** Igual con `listar_tablas` — debe incluir `bub_clientes`, `bub_tareas_notion`, `rag_stores`.
- [ ] **B3.** Igual con `describir_tabla` (tabla `rag_stores`) — debe devolver 6 columnas (notion_id, tipo, store_id, indexed_at, agencia_id, updated_at).
- [ ] **B4.** `cargar_contexto_cliente` con un `cliente_notion_id` que tiene `store_id` en `rag_stores` → devuelve resumen Gemini en `metadata.contexto_resumen` de la conversation.

### C. Workflow Chat entrada (`JI5Tr7IogqXgaI7a`)

- [ ] **C1.** POST `https://n8n-n8n.irzhad.easypanel.host/webhook/chat_cerebro` con payload `{conversation_id, agencia_id, cliente_notion_id, user_bubble_id, mensaje}`. Esperar respuesta 200 inmediata.
- [ ] **C2.** Tras 30s, verificar en cbi: `SELECT COUNT(*) FROM chat_messages WHERE conversation_id=X` incrementa en ≥2 (user + assistant).
- [ ] **C3.** Si es primera conversación: `chat_conversations.metadata` debe tener `estado='active'`, `cliente_notion_id`, `contexto_cargado` (true o false según si ya había store).
- [ ] **C4.** Si `cliente_notion_id` tiene `link_drive` pero NO `store_id`: workflow dispara `NI1oUwIY99TGk496` y aparece fila en `rag_stores` tras ~10 min.

### D. Workflow Indexar (`NI1oUwIY99TGk496`)

- [ ] **D1.** Disparar desde `BqNTrwoQ2iJIcAB4` con un cliente real. Confirmar status 200 y "Indexacion iniciada".
- [ ] **D2.** Tras ~10 min: `SELECT store_id, indexed_at FROM rag_stores WHERE notion_id=X AND tipo='cerebro'` → `indexed_at` debe estar actualizado a las últimas 15 min.
- [ ] **D3.** Bubble `rag_cerebro_last_updated` del cliente también se actualiza (vía PATCH API Bubble).

### E. Workflow CRON (`ZnJSkoWlSusmEjhO`)

- [ ] **E1.** Ejecución manual desde UI n8n (botón "Execute Workflow"). Esperar a que termine el Loop.
- [ ] **E2.** Verificar que solo reindexa clientes con cambios en Drive ≥ `rag_stores.indexed_at` (no debe reindexar todos).
- [ ] **E3.** `workflow_executions` (Ops Monitor) no tiene errores tras la ejecución.

### F. Webhook manual (`BqNTrwoQ2iJIcAB4`)

- [ ] **F1.** `curl -X POST https://n8n-n8n.irzhad.easypanel.host/webhook/reindexar_rag_cerebro -H 'Content-Type: application/json' -d '{"cliente_notion_id":"X","agencia_id":"e748c7d4-5823-413d-8cb3-532896f6e41d"}'` → 200 "Indexacion iniciada".
- [ ] **F2.** Falla controlada si falta `cliente_notion_id` (throw en Preparar Payload).
- [ ] **F3.** Falla controlada si el cliente no tiene `link_drive` en `bub_clientes`.

### G. UI Bubble end-to-end

- [ ] **G1.** Abrir `/clientes/{empresa_id}/cerebro` con un cliente con store. Hacer pregunta sobre tareas: "¿cuántas tareas urgentes tiene este cliente esta semana?". Comparar respuesta con conteo manual en cbi: `SELECT COUNT(*) FROM v_tareas_cerebro_ia WHERE cliente_nombre ILIKE '%X%' AND prioridad='Urgente' AND fecha_entrega BETWEEN ... AND ... AND agencia_id='...'`.
- [ ] **G2.** Hacer pregunta que requiera RAG: "¿qué estrategia tiene este cliente según sus documentos?". Respuesta debe citar contenido de documentos Drive.
- [ ] **G3.** Realtime: el mensaje assistant aparece sin refresh manual (Realtime channel `chat_messages` INSERT).
- [ ] **G4.** Cambiar de cliente y abrir otro chat Cerebro: contexto resetea a nuevo cliente (no mezcla clientes).

### H. Regresión / detección de fugas a maw

- [ ] **H1.** `curl -s https://n8n-n8n.irzhad.easypanel.host/healthz` OK (infraestructura viva).
- [ ] **H2.** Ninguno de los 5 workflows del sector contiene la string `mawpgbtdvskmneqqcqag` (grep en export JSON). Cualquier aparición = regresión.
- [ ] **H3.** Ningún Code node del sector tiene el JWT service_role de maw hardcoded (grep por `eyJ...HDQ`).

---

## Preguntas abiertas

- ¿El RAG se mantiene con Gemini fileSearchStore o migrará a pgvector en Supabase? (consideración futura).

---

## Decisiones arquitectónicas tomadas (2026-04-21)

- **`rag_stores` tabla nueva** (opción B del plan) en vez de columnas SUP_ en `bub_clientes`. Desacopla RAG del espejo Bubble y permite futura extensión a `tipo='newsletter'`.
- **Webhook manual `BqNTrwoQ2iJIcAB4` se mantiene** y se migra a cbi (no se elimina).
- **Credenciales hardcoded retiradas**: el service_role key de maw ya no aparece en ningún Code node del sector. Todos los nodos usan credencial `supabaseApi` nombrada vía `helpers.httpRequestWithAuthentication`.
