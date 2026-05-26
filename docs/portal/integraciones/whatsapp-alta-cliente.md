---
title: WhatsApp — Alta Cliente desde Ventas (Evolution API)
dominio: integracion
estado: inactivo
actualizado: 2026-05-24
tags: [whatsapp, evolution-api, alta-cliente, ventas, n8n, ia]
---

# WhatsApp — Alta Cliente desde Ventas

> Primer uso productivo de Evolution API en TheNucleo. Los comerciales mandan un audio (o texto) a un número de WhatsApp interno, la IA estructura la información del cliente y los servicios contratados, repregunta los huecos, y al confirmar crea el cliente en Bubble + servicios en Supabase.

## Qué es

Bot conversacional 1:1 entre el comercial y la IA por WhatsApp. Sustituye al alta manual de cliente que hoy hace Account en el Portal — el comercial captura mientras está fresco (recién cerrada la venta) en lugar de pasarse notas por chat o esperar al lunes.

**Diferencia clave con el "Análisis Estratégico" o "Cerebro IA":** ahí el chat sirve para que la IA ayude a pensar al equipo. Aquí la IA solo estructura datos que el comercial ya tiene (no aporta criterio).

## Quién puede usarlo

Allowlist hardcoded en el workflow n8n (`Filtro whitelist + fromMe`):

| Teléfono | Comercial | Email TheNucleo |
|---|---|---|
| `+34627755036` | Benja | `benjamin.sanchis@thenucleo.com` |
| `+34675525001` | Alex | `alejandro.lopez@thenucleo.com` |

Cualquier mensaje desde otro número se ignora silenciosamente (el webhook responde 200 OK por si Evolution reintenta, pero no se procesa). El filtro también descarta `fromMe=true` para no entrar en bucles infinitos cuando la IA responde.

Para añadir/retirar comerciales hay que editar 2 sitios del workflow:
1. `Filtro whitelist + fromMe` — array de teléfonos en la condición.
2. `Normalizar texto entrada` — dict `COMERCIALES = { telefono: {nombre, email} }`.

Cuando la lista crezca (≥4 comerciales) migrar a tabla Supabase `ventas_comerciales (telefono pk, email, nombre, activo)` y leerla en el Code node — pero hoy es overkill.

## Flujo

```
Comercial WhatsApp ─audio/texto─▶ Evolution API ─webhook─▶ n8n
                                                            │
                          ┌─────────────────────────────────┘
                          ▼
                  Respond 200 OK   (ack inmediato)
                          +
                  ┌─── If whitelist + fromMe=false
                  ▼
                  If audio?
                  ├─ sí → Descargar audio → Gemini File API → Gemini 2.5 Flash (transcribir)
                  └─ no → texto directo
                          │
                          ▼
                  Normalizar texto entrada (Code)
                  ├─ mapea teléfono → {nombre, email} del comercial
                  └─ devuelve { texto, telefono_e164, comercial_email, ... }
                          │
                          ▼
                  GET intake abierto (alta_cliente_wip)  [alwaysOutputData=true]
                          │
                          ▼
                  UPSERT intake (PostgREST POST con on_conflict=id)
                  ├─ idempotency inline: si existing.last_msg_in_id===meta.msg_in_id → return existing (no-op)
                  ├─ si existe (con id real) → UPDATE con mensaje nuevo appended
                  └─ si no existe → INSERT (Postgres genera id con gen_random_uuid)
                          │ fan-out paralelo
                          ▼
                  3 lookups en paralelo:
                  ├─ GET fichas catalogo (fichas_de_producto)        ──┐
                  ├─ GET categorias (fichas_categorias)                ─┼─→ Merge (3 inputs)
                  └─ GET clientes existentes (bub_clientes agencia)   ──┘
                                                                          │
                                                                          ▼
                                                              Normalizar datos (Code)
                                                              arma body Claude completo
                                                              (system+messages) en una variable
                                                              body_claude usando template literals
                                                                          │
                                                                          ▼
                  Claude Sonnet 4.6 (jsonBody: {{ $json.body_claude }})
                  system: catálogo + categorías + clientes existentes + comercial actual + reglas
                  user:   estado actual del intake + último mensaje
                  output: JSON { accion, mensaje_para_comercial, payload_actualizado, servicios_finales }
                          │
                          ▼
                  Parsear y validar ficha_id (Code, anti-alucinación)
                          │
                          ▼
                  PATCH intake (append mensaje del asistente)
                          │
                          ▼
                  Switch por accion:
                  ├─ "crear"      → Crear cliente Bubble (nodo nativo bubbleApi) → Expandir servicios →
                  │                  Loop servicios (SplitInBatches) →
                  │                  INSERT playbook_cliente_servicios → nextBatch →
                  │                  onDone → PATCH intake (confirmado) → Evolution sendText "Cliente creado"
                  ├─ "cancelar"   → PATCH intake (rechazado) → Evolution sendText "OK, descartado"
                  └─ "preguntar"  → Evolution sendText con la pregunta de la IA
                  └─ "resumir"    → Evolution sendText con el resumen (espera OK del comercial)

                  (sendText usa nodo nativo Evolution API community node con cred evolutionApi)
```

28 nodos. Workflow n8n: `Q99fjZWhA8tlofVr` — `OPS VENTAS — Alta Cliente WhatsApp`.

Los 2 nodos extra respecto a la versión inicial son:
- **`Merge`** (`n8n-nodes-base.merge` v3.2, `numberInputs: 3`) — sincroniza las 3 ramas de lookups paralelos.
- **`Normalizar datos`** (Code) — arma el body Claude completo (`system` + `messages`) en una variable JS limpia usando template literals (en vez de incrustar JSON.stringify gigante en el HTTP node). Output: `{ body_claude: { model, max_tokens, system, messages } }`. Claude Sonnet 4.6 luego solo hace `jsonBody: {{ $json.body_claude }}`.

## Tabla WIP — `alta_cliente_wip`

Persistencia conversacional. Una fila por sesión activa con un comercial. Mismo patrón que `analisis_wip` y `newsletter_wip` (otros chats co-creativos del Portal).

| Columna | Tipo | Notas |
|---|---|---|
| `id` | uuid PK | `gen_random_uuid()` |
| `agencia_id` | text NOT NULL | UUID Supabase de TheNucleo (`e748c7d4-...`) |
| `comercial_email` | text NOT NULL | derivado del teléfono vía dict en Code |
| `comercial_nombre` | text | Benja / Alex |
| `telefono_e164` | text NOT NULL | `+34627755036` etc. |
| `estado` | text NOT NULL | CHECK IN `abierto/confirmado/rechazado` |
| `mensajes` | jsonb | array `[{rol:user|assistant, texto, ts, audio_msg_id}]` |
| `payload` | jsonb | borrador de ficha en construcción `{nombre_empresa, contacto, email, telefono, sector, servicios:[]}` |
| `last_msg_in_id` | text UNIQUE | ID del último msg Evolution. Idempotencia: si Evolution reenvía el mismo msg por timeout, el upsert mergea en vez de crear duplicado |
| `cliente_bubble_id` | text | NULL hasta confirmar; entonces se llena con el `bubble_id` del cliente creado |
| `created_at`, `updated_at` | timestamptz | `update_updated_at()` trigger |

### Constraints clave

- **`UNIQUE INDEX (telefono_e164) WHERE estado='abierto'`** — no permite 2 sesiones abiertas a la vez del mismo comercial. Si una se queda zombi, hay que pasarla a `rechazado` antes de poder abrir otra (no hay cron de reset stuck todavía — pendiente si pasa en producción).
- **`UNIQUE (last_msg_in_id)`** — idempotencia anti-reintentos de Evolution.
- **`CHECK estado IN (...)`** — no se aceptan estados ad-hoc.

### Seguridad

- RLS habilitada **sin policies** → solo `service_role` (n8n) puede acceder. `anon` y `authenticated` bloqueados a nivel Postgres.
- Sin `GRANT` para `anon`/`authenticated` → no expuesta vía Data API.

## Prompt del Agente

Claude Sonnet 4.6 con `max_tokens: 2000`. System prompt construido en runtime con:
- Listado completo del catálogo `fichas_de_producto` (id + título + unidad).
- Listado de categorías.
- Listado de clientes existentes (`bubble_id + nombre_empresas`) de TheNucleo. Permite que la IA detecte si el comercial está ampliando un cliente existente vs creando uno nuevo.
- Identidad del comercial actual (Benja/Alex + email).

Reglas que pasa el system prompt:
1. Devuelve SIEMPRE un único objeto JSON con la forma: `{accion, mensaje_para_comercial, payload_actualizado, servicios_finales}`.
2. Si dudas o el cliente parece duplicado de uno existente, **preguntar** antes de crear.
3. Solo `crear` si en el historial hay un resumen previo Y el último mensaje del comercial lo confirma (típicamente "OK", "vale", "confirmado").
4. **NUNCA inventar `ficha_id`** que no esté en el catálogo. El Code `Parsear y validar` valida esto downstream: si Claude alucina un `ficha_id`, fuerza `accion=preguntar` con un mensaje pidiendo más contexto. Defensa en profundidad.
5. Si el usuario dice cancelar, cancelar.
6. **Una pregunta por mensaje, corta y directa.** Cuando aplique, ofrece opciones cerradas (`1/2/3`) — es WhatsApp, no un formulario.

## Commit final — qué pasa al confirmar

Cuando `accion=crear` y el `Parsear y validar` lo deja pasar:

1. **`Crear cliente Bubble`** (nodo nativo `n8n-nodes-base.bubble` v1, operation `create`, typeName `bub_clientes`, credencial `bubbleApi`) con:
   - `nombre_empresas`, `sector`, `contacto_principal`, `correo_principal`, `telefono_principal`
   - `estado: "Activo"`
   - `agencia_id: "1769513105728x555492736219132700"` (unique id Bubble de TheNucleo, NO el uuid Supabase)
2. Bubble crea el cliente. Su DB Trigger dispara `wvHcgVqqjkWJcJDu` (SYNC CLIENTES — Bubble → Notion + Drive) que automáticamente:
   - Crea carpeta raíz Drive con estructura L1/L2/L3.
   - Crea página en Notion DB Empresas.
   - Actualiza Doc Maestro.
   - Espeja a Supabase `bub_clientes` vía `FGxG67I24POOUeHW`.
3. **`Expandir servicios`** convierte el array `servicios_finales` en N items para iterar.
4. **`Loop servicios`** (SplitInBatches v3, batchSize 1) itera cada servicio:
   - **`INSERT playbook_cliente_servicios`** con `cliente_bubble_id` (FK al recién creado, leído de `$("Crear cliente Bubble").first().json.id`), `ficha_id`, `ficha_titulo`, `categoria_nombre`, `categoria_color`, `unidades`, `periodo`, `notas`, `orden`.
   - SYNC `ewu5A5E05T4tz5CD` (FICHAS — Supabase → Bubble) lo espeja a Bubble en el próximo polling.
5. **`PATCH intake`** marca `estado='confirmado'` + guarda `cliente_bubble_id`.
6. **`Evolution sendText cliente creado`** (nodo nativo `n8n-nodes-evolution-api.evolutionApi` v1, resource `messages-api`, operation `send-text`, credencial `evolutionApi` ID `XHvfdN2BRxBlsRLR`): *"Cliente creado en Bubble. Drive y Notion llegan en ~30s."*

## Env vars + credenciales requeridas

### En EasyPanel (variables de entorno n8n)
- `GEMINI_API_KEY` — para Upload + Transcribe. **Ya configurada** (rotación 2026-05-24).
- (No hacen falta `EVO_URL` / `EVO_INSTANCE` / `BUBBLE_BASE_URL` — desde la v2 del workflow los nodos nativos Evolution+Bubble leen URL/instance/Bubble app directamente de sus credenciales.)

> **Cómo añadir env vars en EasyPanel** (para futuras): EasyPanel → tu servicio `n8n-n8n` → pestaña **Environment** → añadir `KEY=VALUE` una por línea → **Save** → click **Restart** del contenedor (sin restart no las recoge n8n). Verificable desde dentro de n8n via `{{ $env.NOMBRE }}` en cualquier expresión.

### En n8n (Credentials UI)

Tras el SDK update (`v2` 2026-05-24), n8n autoasignó las 4 credenciales nativas que ya tenías:

- ✅ **Crear cliente Bubble** → cred nativa "Bubble account" (`bubbleApi`).
- ✅ **Evolution sendText cliente creado / cancelado / pregunta** (3 nodos) → cred nativa "Evolution account" (`evolutionApi`, ID `XHvfdN2BRxBlsRLR`).

Pendientes manuales (11 nodos HTTP genéricos que sí necesitan credencial predefinida pero el SDK no puede autoasignar):

- **Supabase API** (`supabaseApi` predefined, service_role) en 10 nodos: `GET intake abierto`, `UPSERT intake`, `GET fichas catalogo`, `GET categorias`, `GET clientes existentes`, `PATCH intake mensaje asistente`, `INSERT playbook_cliente_servicios`, `PATCH intake confirmado`, `PATCH intake rechazado`.
- **Anthropic API** (`anthropicApi` predefined) en 1 nodo: `Claude Sonnet 4.6`.
- **Sin credencial** (autenticación vía URL `?key=$env.GEMINI_API_KEY`) en 2 nodos: `Upload Gemini File API`, `Transcribir Gemini`.
- **Sin credencial** (URL firmada que viene en el webhook payload de Evolution) en 1 nodo: `Descargar audio Evolution` — primer smoke confirmará si Evolution requiere `apikey` header aquí.

## Tag pendiente

Añadir tag `portal` al workflow desde la UI (Settings → Tags). Sin él, no entra al backup automático `marketingthenucleo/n8nthenucleo`.

## Decisiones de diseño

### ¿Por qué Bubble como source para el cliente y no Supabase?

Porque crear el cliente en Bubble dispara `wvHcgVqqjkWJcJDu` que monta Drive + Notion + Doc Maestro + espejo. Si pasáramos a Supabase directo, perderíamos toda esa cadena y habría que reimplementarla. Bubble sigue siendo la fuente de verdad para clientes hoy (CLAUDE.md root).

### ¿Por qué los servicios sí van directo a Supabase nativo?

Porque ya existe el SYNC inverso `ewu5A5E05T4tz5CD` (Supabase → Bubble) que los espeja, y la fuente de verdad de los servicios sí es Supabase (`fichas_de_producto` + `playbook_cliente_servicios` son tablas nativas).

### ¿Por qué Gemini para audio y no Whisper?

- Gemini File API + `gemini-2.5-flash` transcribe español muy bien y barato.
- Ya tenemos `GEMINI_API_KEY` en n8n para el RAG (no añade dependencia nueva).
- Whisper requeriría cuenta OpenAI con créditos.

### ¿Por qué Claude Sonnet 4.6 y no Haiku?

- El razonamiento "este servicio que dice el comercial corresponde a qué ficha del catálogo" requiere matching semántico no trivial. Haiku alucina más.
- Sonnet maneja mejor el flujo conversacional (cuándo preguntar vs cuándo resumir vs cuándo confirmar).
- Coste por sesión: ~$0.05–0.15 con 5–10 turnos. Aceptable para un cliente cerrado (que vale €/mes).

### ¿Por qué hardcoded vs env var para la whitelist?

Decisión del 2026-05-24: hoy son 2 comerciales y la lista no cambia mes a mes. Editar el workflow es más visible que editar env vars (auditable en git si exportamos n8n; las env vars no). Si crece a 4+, migrar a tabla Supabase.

## Pendientes / TODOs

- [ ] Asignar las 11 credenciales pendientes en UI (10x Supabase + 1x Anthropic en los nodos HTTP genéricos listados arriba). Las 4 nativas (Bubble + Evolution x3) ya están autoasignadas.
- [ ] Añadir tag `portal` al workflow (UI manual).
- [ ] Configurar webhook Evolution apuntando a `/webhook/ventas_whatsapp_inbound`.
- [ ] Validar primer audio E2E con Benja o Alex en un cliente test.
- [ ] Confirmar si `Descargar audio Evolution` (HTTP GET a `mediaUrl`) necesita header `apikey` — si Evolution devuelve 401, cambiar el nodo por el `chat-api → get-media-base64` del nodo nativo Evolution + Code para convertir base64 → binary.
- [ ] **Considerar cron de reset stuck:** si una sesión queda en `estado=abierto` 24h sin actividad, pasarla a `rechazado` para no bloquear nuevas con el mismo teléfono. Patrón análogo al `analisis_reset_stuck_analyzing` (RPC + cron 15min). Pendiente si pasa en producción.
- [ ] **Considerar `activity_log`:** logar create/update de cliente con `source='whatsapp_alta'` para trazabilidad. Hoy ya queda log vía `wvHcgVqqjkWJcJDu` pero sin distinguir el canal de origen.
- [ ] **F2 — confirmación con resumen estructurado:** hoy la confirmación es texto libre del comercial. Mejora futura: cuando IA pasa a `accion=resumir`, podría devolver una tarjeta visual (number list con todos los campos + servicios) y esperar un literal "OK" para `crear`. Reduce errores.
