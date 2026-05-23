---
title: Sector — Análisis Cliente
dominio: sectores
estado: activo
actualizado: 2026-05-12
tags: [sector, chat, analisis, ia]
---

# Sector 7 — Análisis Estratégico Cliente (CHAT CO-CREATIVO v2)

**Estado:** 🚧 EN E2E — conversión chat iterativo (plan aprobado 2026-04-22).

**Carpeta n8n**: `HagpPx2csHyH7Dao` (Analisis Cliente Final).

**Scope:** Análisis estratégico de onboarding vía chat iterativo con Claude Sonnet 4.6. Output: Doc Drive con Briefing 12 secciones + 4 segmentos × {Empatía + Buyer Persona + Ángulos}, generado progresivamente y entregado bajo demanda por botón UI.

---

## Legacy — ARCHIVADO 2026-04-22

Los 3 workflows del pipeline legacy (Manus + OpenAI gpt-4o) están archivados en n8n desde el 2026-04-22 (verificado `isArchived: true` el 2026-04-23). Se mantienen listados como referencia histórica.

| ID | Nombre | Rol |
|---|---|---|
| `J47P_S-bmVe1O0FZycleK` | WORKFLOW 1: PRINCIPAL ANALISIS | Orquestador + sub-flow KB Drive (lista+extract docs). Patrón útil si retomamos Tanda B KB Drive. |
| `p8si62g4ai2rpLbb` | SUBWORKFLOW 1: Briefing Manus | Briefing con Manus API + OpenAI gpt-4o |
| `gSjzdBUuIWY0a5zI` | SUBWORKFLOW 2: Análisis por Segmento | Empatía + Buyer + Ángulos (gpt-4o paralelo) |

---

## Arquitectura v2 — Chat co-creativo

```
Usuario en /clientes/{empresa_id}/analisis
        │
        │ envía mensaje
        ▼
┌────────────────────────┐
│ Bubble                 │
│  - Input + Send        │
│  - Page realtime WS    │
│  - Button Generar Doc  │
└────┬────────┬──────────┘
     │        │
     │ POST /chat-analisis
     │        │ POST /entregar-analisis (bajo demanda)
     ▼        │
┌───────────────────────┐
│ n8n IA Análisis Entrada│
│  - Respond 200        │
│  - Save user msg      │
│  - Ensure WIP (insert │
│    con onError cont)  │
│  - Call tool_loop     │
└───────┬───────────────┘
        │ executeWorkflow (async)
        ▼
┌───────────────────────────┐
│ n8n IA Análisis Tool Loop │
│  - Set estado=analizando  │
│  - Get WIP + historial    │
│  - Build Prompt c/ fase   │
│  - Agent Claude (stream)  │
│  - Parse + Deep Merge     │
│  - Update WIP             │
│  - Save assistant msg     │
└───────────────────────────┘

[Ruta entrega — fuera del chat]
Bubble Click Button → POST /entregar-analisis
        ▼
┌────────────────────────────┐   ┌────────────────────────────┐
│ IA Análisis Trigger Entrega│──▶│ IA Análisis Entrega        │
│  (webhook shim)            │   │  - Get WIP + cliente       │
└────────────────────────────┘   │  - Render HTML + Multipart │
                                 │  - HTTP POST Drive API     │
                                 │    (multipart/related)     │
                                 │  - estado=entregado        │
                                 │  - doc_url Google Doc      │
                                 │  - chat msg con link       │
                                 └────────────────────────────┘
```

### Fases del agent (revisadas 2026-04-24 — Fase 3)

El prompt detecta la fase a partir del WIP actual, granular por `segmentos.length`:

| Fase | Condición | Salida esperada |
|---|---|---|
| `BRIEFING_INICIAL` | briefing vacío | `updates.briefing` completo (12 keys). Assistant pregunta "¿vamos con seg 1?". |
| `SEGMENTO_1` | briefing OK + 0 segmentos | `updates.segmento_nuevo` (1 objeto). Pregunta "¿ajustamos o seg 2?". |
| `SEGMENTO_2_O_REFINAR` | 1 segmento | Si afirmativo → `segmento_nuevo` (seg 2). Si pide ajustar → `segmentos_patch` sobre seg 0. |
| `SEGMENTO_3_O_REFINAR` | 2 segmentos | Ídem con seg 3. |
| `SEGMENTO_4_O_REFINAR` | 3 segmentos | Ídem con seg 4. |
| `REFINAMIENTO_COMPLETO` | 4 segmentos | Solo patches (briefing_patch o segmentos_patch). |

**Salida JSON del agent** (schema nuevo):
```json
{
  "assistant_message": "...",
  "updates": {
    "briefing": { ... },
    "briefing_patch": { "key": "value" },
    "segmento_nuevo": { /* 1 segmento, se append al array */ },
    "segmentos_patch": [ { "idx": 1, "patch": { "buyer_persona": { "Nombre": "..." } } } ]
  }
}
```

Parse + Merge (n8n Code node):
- `briefing_patch` → deep merge con briefing existente.
- `segmento_nuevo` → `segmentos.push(...)` si `segmentos.length < 4`.
- `segmentos_nuevos` (legacy, 4 de golpe) → solo aceptado si `segmentos.length === 0` (backward-compat).
- `segmentos_patch` → deep merge por idx.

**Desambiguación de intención** (system prompt del agent):
- Afirmativo ("sí", "ok", "vale", "continúa", "siguiente") → genera segmento siguiente.
- Pedido de ajuste ("cambia X", "ajusta Y") → patch sobre el último segmento. No avanza.
- Ambiguo o mixto ("sí pero X") → prioriza patch. No avanza. Pregunta confirmación.

---

## Invariantes duros (contrato)

1. **Briefing con EXACTAMENTE 12 secciones fijas.** IA no puede añadir, quitar ni renombrar.
2. **EXACTAMENTE 4 segmentos**, cada uno con Empatía (7 arrays × 5) + Buyer Persona (23 campos) + 5 Ángulos.
3. **El Doc Drive se genera bajo demanda** (Button UI), no automático. Antes requería estado=completado.
4. **Campos nunca vacíos ni "Información no encontrada"**. Infiere con contexto del sector (regla en system prompt).

---

## Capa Supabase cbi — IMPLEMENTADA

Proyecto `cbixhqjsnpuhcrcjppah` (eu-west-1).

### Tabla `analisis_wip`
```sql
CREATE TABLE public.analisis_wip (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid REFERENCES chat_conversations(id) ON DELETE CASCADE,
  agencia_id uuid,                        -- dinámico desde webhook (multitenant)
  cliente_id text,                        -- notion_id del cliente (homogeneizado 2026-04-22, antes `empresa_id`)
  url_analizar text,
  kb_links_text text,                     -- URL carpeta Drive cliente (hack temporal hasta Tanda B KB)
  kb_text text,
  kb_files jsonb NOT NULL DEFAULT '[]'::jsonb,  -- Inventario archivos Drive [{name,id,mime,link,status,chars_used}] (2026-04-30)
  briefing jsonb DEFAULT '{}'::jsonb,
  segmentos jsonb DEFAULT '[]'::jsonb,
  estado text DEFAULT 'borrador',
  doc_url text,
  error_msg text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Constraints:
-- CHECK estado IN ('borrador','analizando','completado','entregando','entregado','error')
-- UNIQUE (conversation_id)  ← añadido 2026-04-22 tras descubrir duplicados
```

### RPCs

**Mutación / control:**
- `analisis_reset_wip(p_conversation_id uuid) → json` — borra chat_messages + resetea WIP a borrador. Devuelve `{ok:true}`.
- `analisis_merge_update(p_conversation_id, p_briefing_patch, p_segmentos_patches) → json` — merge JSONB atómico server-side. Creado pero no usado aún (merge se hace client-side en n8n Code node).

**Safety net (migration `analisis_reset_stuck_analyzing`, 2026-04-23):**
- `analisis_reset_stuck_analyzing(p_ttl_minutes int DEFAULT 15) → TABLE(conversation_id, wip_id, msg_id)` — SECURITY DEFINER. Busca filas `estado=analizando` con `updated_at < now() - p_ttl_minutes min`, las marca `estado=error` + inserta mensaje assistant. Invocada por el cron `CRON IA Análisis — Reset Stuck (15min)`.

**Lectura panel derecho Bubble (migration `analisis_panel_rpcs`, 2026-04-22):**

Todas `STABLE SECURITY DEFINER SET search_path = public`, `GRANT EXECUTE` a `anon, authenticated`. `p_idx` es 1-indexed (seg1..seg4 → `segmentos->(p_idx-1)` internamente). Devuelven 0 filas sin error si conv no existe, idx fuera de rango, o JSONB vacío.

- `analisis_get_briefing(p_conversation_id uuid) → TABLE(seccion_num int, grupo text, titulo text, valor text)`
  - 12 filas fijas, orden del mockup. Arrays del briefing (`dolores_principales`, `resultados_prometidos`, etc.) se unen con `string_agg('• ', E'\n')` para render directo en un Text de Bubble. Campos string (`vision_general_negocio`, `oferta_actual`, `mecanismo_metodo`, `perfil_cliente_ideal`) se pasan tal cual. Grupos: Negocio y oferta / Cliente y dolores / Posicionamiento / Mensajes y copy / Próximos pasos.

- `analisis_get_segmento_meta(p_conversation_id, p_idx int) → TABLE(idx int, nombre, descripcion, problematica, oportunidad text)`
  - 1 fila con los metadatos del segmento (header del panel derecho).

- `analisis_get_segmento_empatia(p_conversation_id, p_idx) → TABLE(bloque_num int, bloque_key text, bloque_label text, item_num int, item text)`
  - 35 filas (7 bloques × 5 items). Orden fijo: problemas_externos → problemas_internos → puntos_dolor_concretos → motivaciones_inmediatas → deseos_aspiracionales → falsas_creencias → objeciones_compra_reales. `LEFT JOIN LATERAL jsonb_array_elements_text WITH ORDINALITY` conserva orden intra-bloque.

- `analisis_get_segmento_buyer(p_conversation_id, p_idx) → TABLE(row_num int, label text, value text)`
  - ~24 filas label/value del `buyer_persona`. `jsonb_each_text()` + `row_number() OVER ()`. Agnóstico a variaciones de keys entre segmentos (el agent puede usar "activo/activa" según género; para Bubble da igual, renderiza lo que haya).

- `analisis_get_segmento_angulos(p_conversation_id, p_idx) → TABLE(num int, titulo text, enfoque text, mensaje text)`
  - 5 filas. Mapea keys JSONB `"Ángulo de Venta"` → `titulo`, `"Enfoque Principal"` → `enfoque`, `"Mensaje Clave para Campañas"` → `mensaje`. `WITH ORDINALITY` para `num` 1..5.

---

## Capa n8n — Workflows activos

Carpeta `HagpPx2csHyH7Dao`.

| Workflow | ID | Role | Nodos |
|---|---|---|---|
| `IA Análisis — Init` | `8hAokf6zfQl0dMlR` | **Greeting inicial (2026-04-30).** Webhook `/init-analisis`. Race guard `count(chat_messages)=0` → lista Drive lite del `bb_link_drive_analisis` (sin descargar) → separa soportados/no soportados → Gemini 2.5 Flash narrativa → format greeting HTML (lista clicable + drive link + nota "no accedo a la web en directo") → upsert `kb_files` lite en `analisis_wip` → insert greeting en `chat_messages`. 3 branches (con drive+soportados / con drive sin soportados / sin drive). | 17 |
| `IA Análisis — Entrada` | `dtgF0G35aeJQVVfn` | Webhook `/chat-analisis`. Guarda user msg, asegura fila WIP (insert con `onError: continueRegularOutput` por UNIQUE constraint), dispara tool_loop async. | 5 |
| `IA Análisis — Tool Loop [SUB]` | `FFhkdTFCjTtfyvhP` | Agent conversacional. Set estado=analizando + Get WIP + **Has KB? (IF)** + [rama true: **Call IA Análisis — KB Fetch [SUB]**] + Get historial + Build Prompt (con fase + kb_text) + Agent Claude Sonnet 4.6 streaming + Parse + Deep Merge + **Resolve Citations** (`[fuente: X]` → `<a>` chips clicables vía lookup en `kb_files`) + Update WIP + Save assistant msg. System prompt incluye bloque "CITAS DE FUENTES". | 13 |
| `IA Análisis — KB Fetch [SUB]` | `Cfs3NFEE1enu1jTx` | **Tanda B (2026-04-23) + kb_files (2026-04-30)**. Sub-workflow que lee Drive cliente, filtra por extensión (pdf/txt/md/docx/json), descarga, extrae texto, empaqueta `kb_text` + `kb_links_text` (max 60k chars, 15k por archivo) **y persiste `kb_files` con status `incluido/truncado` + `chars_used`** (mergeado con `no_soportado` que metió IA Análisis — Init). Se invoca desde tool_loop solo si `kb_text` IS NULL/empty. | 16 |
| `IA Análisis — Entrega [SUB]` | `QW8VZ9cV5ECsSKvZ` | Bajo demanda. Get WIP + Get cliente + **Render HTML + Multipart** (HTML semántico H1/H2/H3, `<ul>`, `<table>` para Buyer, H4/H5 para Empatía y Ángulos + body multipart/related) + **Subir HTML a Drive** (HTTP Request POST Drive API multipart/related → Google Doc nativo) + estado=entregado + chat msg con link `docs.google.com/document/d/.../edit`. **Cambio 2026-05-12**: antes era Render Markdown + Drive createFromText (markdown crudo se veía literal en el Doc). | 8 |
| `IA Análisis — Trigger Entrega` | `JtXdkXHm6RyGOJft` | Shim webhook `/entregar-analisis`. Recibe conversation_id → llama analisis_entrega async → 200 OK. | 3 |
| `CRON IA Análisis — Reset Stuck (15min)` | `V60MieFkQzOszxhh` | **Safety net (2026-04-23)**. Schedule cada 15 min. Llama RPC `analisis_reset_stuck_analyzing(15)` → marca filas en `estado=analizando` con `updated_at > 15 min` como `estado=error` + inserta mensaje assistant explicativo en `chat_messages`. | 2 |

### Detalles clave

- **Multitenant**: `agencia_id` llega desde Bubble (`Current User's agencia_id's Uuid Supabase`) y se guarda en cada fila. No más hardcode del UUID TheNucleo.
- **executeWorkflow entre workflows**: usa formato ResourceLocator (`{__rl: true, value, mode: 'list', cachedResultName, cachedResultUrl}`). String plano falla al ejecutar.
- **Agent Claude**: `enableStreaming: true` explícito + `maxTokensToSample: 16000` para evitar error "Streaming is required for operations > 10 min".
- **jsonb storage**: Parse node devuelve objetos directos (no JSON.stringify); Update node con `fieldValue: '={{ $json.briefing }}'` — n8n envía JSON object, no string-JSONB.

---

## Capa Bubble — IMPLEMENTADO

Página `/clientes/{empresa_id}/analisis` (clonada de Newsletter IA, adaptada).

### Custom states (11)

**Chat + estado (6 originales):**
- `cliente_notion_id` (text, Current Page Clientes's unique id)
- `current_conversation_id` (text)
- `conv_metadata_estado` (text)
- `enviando` (yes/no, default no)
- `last_subscribed_conversation` (text)
- `chip_activo` (text, default 'briefing')

**Cache del panel derecho (5, 2026-04-22):**
- `briefing_result` (list of `analisis_get_briefing`)
- `seg_meta_result` (list of `analisis_get_segmento_meta`)
- `seg_empatia_result` (list of `analisis_get_segmento_empatia`)
- `seg_buyer_result` (list of `analisis_get_segmento_buyer`)
- `seg_angulos_result` (list of `analisis_get_segmento_angulos`)

### Page is loaded (11 steps)
1. Set Menu_lateral sección activa
2. Set `cliente_notion_id`
3. `chat_get_or_create_conversation` (p_tipo = `"analisis_" + cliente_notion_id`, p_agencia_id)
4. Set `current_conversation_id`
5. `obtener_mensajes`
6. Display list RG Chat
7. Run JS (renderAllMessages)
8. `analisis_get_wip`
9. Set `conv_metadata_estado` desde analisis_get_wip's estado
10. Scroll to entry RG
11. Run JS (subscribeToConversation)

### HTML WebSocket (2 canales)
- `chat_msgs_{uuid}` — INSERT chat_messages → dispara `bubble_fn_refresh_chat`
- `analisis_wip_{uuid}` — INSERT/UPDATE analisis_wip → dispara `bubble_fn_refresh_emails` (nombre heredado)

Canal `chat_conversations` eliminado (n8n no toca esa tabla en Análisis, era código muerto).

### API Connectors (9)

**Core chat + entrega (4):**
- `analisis_get_wip` (GET) — URL: `...?conversation_id=eq.[conv_id]&select=*`. Value del caller = UUID limpio.
- `analisis_send_message` (POST) — webhook `/chat-analisis`. Body: `{conversation_id, agencia_id, empresa_id, url_analizar, link_drive, message}`.
- `analisis_reset_wip` (POST) — RPC Supabase. Body: `{p_conversation_id}`.
- `analisis_trigger_entrega` (POST) — webhook `/entregar-analisis`. Body: `{conversation_id}`.

**Panel derecho granular (5, RPCs Supabase — Use as Action, Data type JSON, heredan headers del plugin cbi):**
- `analisis_get_briefing` (POST) — RPC. Body: `{p_conversation_id}`. Retorna 12 filas tipadas.
- `analisis_get_segmento_meta` (POST) — RPC. Body: `{p_conversation_id, p_idx}`. Retorna 1 fila.
- `analisis_get_segmento_empatia` (POST) — RPC. Body: `{p_conversation_id, p_idx}`. Retorna 35 filas.
- `analisis_get_segmento_buyer` (POST) — RPC. Body: `{p_conversation_id, p_idx}`. Retorna ~24 filas.
- `analisis_get_segmento_angulos` (POST) — RPC. Body: `{p_conversation_id, p_idx}`. Retorna 5 filas.

**Patrón homogéneo aplicado en los 2 webhooks fire-and-forget** (`analisis_send_message`, `analisis_trigger_entrega`):
- **Data type:** `Empty` (no `JSON` — el `Respond to Webhook` de n8n responde 200 sin body).
- **Body template:** UUIDs/URLs entre comillas, campo de texto libre `<message>` SIN comillas envolventes.
- **Value en workflow:** `Input Mensaje's value:formatted as JSON-safe` (escapa caracteres y añade comillas).
- Detalle completo en `docs/infra/bubble-api-connectors.md` sección "Patrón homogéneo para webhooks fire-and-forget a n8n".

### Workflows handlers
- `refresh_chat event` (5 steps) — refresca mensajes + scroll + enviando=no.
- `refresh mails event` (2 steps) — llama `analisis_get_wip` + Set state `conv_metadata_estado`.
- `Do every time` (2 steps) — resuscribe WebSocket cuando cambia conv_id.
- Button Send: 5 steps (icono + Enter) con fallback `chat_get_or_create_conversation` + Set state + POST webhook.

### Cabecera
- Estado pill con condicional background/text color por estado.
- Button Reiniciar (visible si completado/entregado/error) → confirm + RPC reset.
- Button Ver Doc (visible si estado=entregado) → abre carpeta Drive fija del cliente (`Current Page Clientes's bb_link_drive_analisis`).
- Button Generar Doc (visible si estado=completado) → llama `analisis_trigger_entrega`.

### Panel derecho granular (Group Panel Artifacts)

Chips `Briefing / Seg 1-4` + RGs que consumen las 5 RPCs panel. Reutiliza custom state `chip_activo` y añade 5 states de cache (`briefing_result`, `seg_meta_result`, `seg_empatia_result`, `seg_buyer_result`, `seg_angulos_result`) para evitar re-llamar al hacer toggle entre chips.

**Custom Events implementados (naming en español, memoria `feedback_naming_espanol`):**

`cargar_briefing` (sin parámetros) — 3 steps:
1. Set state `chip_activo = "briefing"`.
2. Call `analisis_get_briefing` (`p_conversation_id = current_conversation_id`).
3. Set state `briefing_result = Result of step 2`.

`cargar_segmento` (parámetro `idx: number`) — 9 steps (Set chip_activo + 4 pares Call/Set state):
1. Set state `chip_activo = "seg" + This cargar_segmento's idx:formatted as 1234.56` (formato 0 decimales para evitar `.0`).
2. Call `analisis_get_segmento_meta` (`p_conversation_id`, `p_idx = This cargar_segmento's idx`).
3. Set state `seg_meta_result = Result of step 2`.
4. Call `analisis_get_segmento_empatia` (mismos params).
5. Set state `seg_empatia_result = Result of step 4`.
6. Call `analisis_get_segmento_buyer` (mismos params).
7. Set state `seg_buyer_result = Result of step 6`.
8. Call `analisis_get_segmento_angulos` (mismos params).
9. Set state `seg_angulos_result = Result of step 8`.

**Triggers:**
- Button Chip Briefing on-click → `Trigger cargar_briefing`.
- Button Chip Seg1..Seg4 on-click → `Trigger cargar_segmento` con `idx = 1..4`.
- Page Loaded step 12 → `Trigger cargar_briefing`. **Only when**: `conv_metadata_estado is "completado" or conv_metadata_estado is "entregado"`.
- `refresh_mails event` (extender) tras el `Set state conv_metadata_estado` añadir 2 steps:
  - `Trigger cargar_briefing` — Only when `chip_activo is "briefing"`.
  - `Trigger cargar_segmento` con `idx = chip_activo:truncated from end to 1:converted to number` — Only when `chip_activo contains "seg"`.

**Lock progresivo de chips Seg1-4 (2026-04-24, Fase 3 — segmentos uno a uno):**

Como ahora los segmentos se generan uno a uno (Fase 3), los chips Seg1-4 deben deshabilitarse mientras su segmento correspondiente no exista. Patrón sin nuevas RPC ni API Connectors — reutiliza el `analisis_get_wip` ya cargado.

- **Custom state** nuevo: `segmentos_count` (number, default 0).
- **Page Loaded** step posterior a `analisis_get_wip` (step 7): `Set state segmentos_count = Result of step 7 :first item's segmentos :count`. Funciona directo porque Bubble tipa `segmentos` como `list of analisis_get_wip segmento` (requiere haber re-inicializado el API Connector con una conv que tenga datos completos — ver memoria `feedback_bubble_patterns` #9 + #15).
- **`refresh_mails event`** añadir el mismo Set state al final → re-cuenta cuando WebSocket notifica un Update WIP tras cada turno del agent.
- **Conditional en cada chip** (1 condition con 2 properties):
  - Chip Seg N: `When Current Page's segmentos_count < N` → `This element isn't clickable = yes` + `Opacity = 0.4`.

Este patrón es replicable en cualquier UI donde se desbloquean elementos progresivamente (Newsletter, Tareas con subtasks, etc). Ver `feedback_bubble_patterns.md` #15.

**Element tree real (tal como Ben lo está montando en Bubble, 2026-04-23):**

```
Group columna analisis (contenedor del panel derecho)
├── Group Cabezera analisis
├── Group Selectores Analisis  (los 5 chips: Briefing + Seg1..4)
├── Group Contenido Briefing   (visible si chip_activo is "briefing")
│   └── RG Briefing Items  (12 cells, source = briefing_result)
│       cell: Text Num (Seccion_num) + Text Titulo + Text Valor multi-line
└── Group Contenido Segmento   (visible si chip_activo contains "seg")
    ├── Group Cabecera Segmento
    │   ├── Text pill "SEGMENTO N · PRIORITARIO"  → "SEGMENTO " + seg_meta_result:first item's Idx + " · PRIORITARIO"
    │   ├── Text título     → seg_meta_result:first item's Nombre
    │   ├── Text subtítulo  → seg_meta_result:first item's Descripcion
    │   └── Group Problema y Solucion (row)
    │       ├── Group Problema   → seg_meta_result:first item's Problematica
    │       └── Group Oportunidad → seg_meta_result:first item's Oportunidad
    ├── Group Empatia  (colapsable, default OPEN)
    │   ├── Group Encabezado Empatia (clickable → toggle_empatia)
    │   └── Group Empatia Content  (visible si empatia_expanded is "yes")
    │       └── 7 × Group RG <bloque>   (1 por bloque_key)
    │           cada uno: Text cabecera + RG interno de 5 items
    │           RG source: seg_empatia_result :filtered Bloque_key is "<key>"
    ├── Group Buyer Persona  (colapsable, default CLOSED)
    │   ├── Group Encabezado Buyer (clickable → toggle_buyer)
    │   └── RG Buyer Rows  (visible si buyer_expanded is "yes")
    │       source: seg_buyer_result
    │       cell: Text Label (uppercase small caps) + Text Value stacked
    └── Group Angulos  (colapsable, default CLOSED)
        ├── Group Encabezado Angulos (clickable → toggle_angulos)
        └── RG Angulos Items  (visible si angulos_expanded is "yes")
            source: seg_angulos_result
            cell card: Num badge + Titulo + row(ENFOQUE/Enfoque) + row(MENSAJE/Mensaje)
```

**Decisiones de construcción (por qué este tree — revisadas 2026-04-23):**
- **Briefing como 1 RG plano de 12 cells** (no 12 Groups fijos — decisión revisada). Sin headers de grupo intercalados. Orden = `briefing_result` tal cual (seccion_num 1..12). Más simple de mantener; Ben descartó los 5 headers agrupadores.
- **Empatía como 7 Groups fijos con RG interno de 5.** Descarta el RG único de 35 items con group-by (Bubble no lo hace nativo). Cada RG interno se filtra por `bloque_key` con `seg_empatia_result :filtered Bloque_key is "<nombre_bloque>"`. Las 7 keys son: `problemas_externos`, `problemas_internos`, `puntos_dolor_concretos`, `motivaciones_inmediatas`, `deseos_aspiracionales`, `falsas_creencias`, `objeciones_compra_reales`.
- **Buyer como 1 RG plano vertical** (label arriba en uppercase small caps + value debajo). Las keys del buyer varían entre segmentos (el agent puede usar "activo"/"activa" según género, o añadir campos); no conviene desempacar a 24 Groups fijos. El RG es agnóstico.
- **Ángulos como 1 RG de 5 cards.** Mapping directo: cada cell = 1 ángulo con num badge + titulo + 2 rows (enfoque, mensaje).

**Collapse/expand por sección (2026-04-23):**

Empatía · Buyer · Ángulos son colapsables **independientemente** (no excluyentes — puedes tener las 3 abiertas, las 3 cerradas, o cualquier combinación). Briefing y Cabecera Segmento NO son colapsables.

- 3 custom states booleanos en `analisis_cliente`: `empatia_expanded` (default yes), `buyer_expanded` (default no), `angulos_expanded` (default no).
- Custom Event `cargar_segmento` extendido con 3 Set state finales que resetean al default (Empatía open + Buyer closed + Ángulos closed) cada vez que el usuario cambia de segmento.
- 3 workflows toggle, uno por sección: click en `Group Encabezado <Sección>` → `Set state <sección>_expanded = This page's <sección>_expanded is "no"`.
- Condicional de visibility en el Group Content de cada sección (NO en el encabezado): `When <sección>_expanded is "no" → This element is not visible`.
- Chevron indicator por header: dos icons superpuestos (▼ cuando collapsed, ▲ cuando expanded) toggleados por condicional de visibility.

**Patrones aplicados** (ver memoria `feedback_bubble_patterns`):
- #9: API Connectors RPCs deben re-inicializarse con datos reales o el response sale como "raw body text" (descubierto durante B1).
- #10: `cargar_segmento(idx)` evita clonar 4 workflows on-click idénticos.
- #11: cheatsheet de operadores (`truncated from end to`, `converted to number`, `contains`).

Detalle completo en plan `bien-haz-el-plan-imperative-hellman.md`.

---

## Decisiones clave (2026-04-22)

1. **Ver Doc = carpeta Drive del cliente** (no doc_url específico). Más simple.
2. **Entrega bajo demanda por Botón UI**, no por intent. Prompt más limpio.
3. **Primer análisis progresivo por bloques**. 3 fases distintas en el prompt.
4. **Multitenant real**: `agencia_id` dinámico.
5. **UNIQUE (conversation_id)** en analisis_wip. Previene duplicados.

---

## Pendientes (post E2E OK)

1. **Tanda B — KB Drive** ✅ **CERRADO 2026-04-23**. Workflow `IA Análisis — KB Fetch [SUB]` (`Cfs3NFEE1enu1jTx`) implementado. tool_loop llama al sub-workflow si `kb_text` vacío → lee Drive, extrae PDF/TXT/MD/DOCX/JSON, empaqueta `kb_text` (max 60k chars) + `kb_links_text` y actualiza WIP. Prompt del agent inyecta el bloque `<documentos_conocimiento_cliente>` para priorizar docs sobre web pública.
2. **Cron reset** filas colgadas en `estado=analizando` > 15 min ✅ **CERRADO 2026-04-23**. Workflow `CRON IA Análisis — Reset Stuck (15min)` (`V60MieFkQzOszxhh`) + RPC `analisis_reset_stuck_analyzing(p_ttl_minutes int)` en cbi. Schedule cada 15 min, TTL 15 min. Marca WIP error + inserta mensaje assistant explicativo.
3. **Guard opcional Page Loaded step 3**: añadir `Only when Current Page Clientes's notion_id is not empty` para prevenir conv huérfanas tipo `analisis_` (sin sufijo) en recargas prematuras. Pendiente en Bubble editor (T5.1 del plan).

---

## Gotchas descubiertos durante implementación

Documentados en memoria:
- `feedback_n8n_antipatterns.md` — Supabase node sin UPSERT, jsonb doble-encode, executeWorkflow ResourceLocator, Anthropic streaming, JSON truncado.
- `feedback_postgrest_gotchas.md` — schema cache (NOTIFY), `eq.` duplicado URL+value, jsonb storage.
- `feedback_bubble_patterns.md` — contrato `eq.` por endpoint, chat-IA Button Send necesita fallback get_or_create + Set state.

---

## Cliente test

- **Actualízate Psicología**
  - bubble_id: `1772815116826x630388853372878800`
  - cliente_notion_id (= UUID Notion): `31de4743-b0ae-8165-aa1c-c14e6387385c`
  - conv_id canónico (E2E 2026-04-23): `b19b3b10-a3c7-4357-97d7-e6fe8475af98`
  - Drive folder: `https://drive.google.com/drive/folders/136baB98ana-6NWEl6ISPWxSpW7L-cgBH`

---

## Greeting inicial — pendientes Bubble (2026-04-30)

Backend desplegado: `IA Análisis — Init` (`8hAokf6zfQl0dMlR`) + columna `analisis_wip.kb_files` + patches en `IA Análisis — KB Fetch [SUB]` y `IA Análisis — Tool Loop [SUB]`. Falta solo el cableado en Bubble.

### 1. Nuevo API Connector — "Análisis IA — Init"

Grupo: **Análisis IA** (mismo que `analisis_send_message`).

- **Method:** POST
- **URL:** `https://n8n-n8n.irzhad.easypanel.host/webhook/init-analisis`
- **Body type:** JSON (Content-Type: application/json)
- **Body template (con `:formatted as JSON-safe` aplicado a cada valor desde el caller):**
  ```json
  {
    "conversation_id": "<conv_id>",
    "agencia_id": "<agencia_id>",
    "cliente_notion_id": "<cliente_notion_id>"
  }
  ```
- **Data type:** **Empty** (fire-and-forget; n8n responde 200 antes de procesar el greeting).
- **Use as:** **Action**.
- **Initialize obligatorio.** Usar UUIDs reales de la conv test (Actualízate Psicología):
  - `conv_id`: `b19b3b10-a3c7-4357-97d7-e6fe8475af98`
  - `agencia_id`: `e748c7d4-5823-413d-8cb3-532896f6e41d` (TheNucleo)
  - `cliente_notion_id`: `31de4743-b0ae-8165-aa1c-c14e6387385c`
  - El race guard del workflow `count(msgs)>0` previene que el Initialize inserte greeting en una conv con historial.

### 2. Insertar step en Page Loaded de `/clientes/{empresa_id}/analisis`

Después del subscribe Realtime y **antes** del `Trigger cargar_briefing`:

- **Action:** Call API Connector "Análisis IA — Init".
- **Parámetros:**
  - `conversation_id` = `Current Page Clientes's Current Conversation Id` (state Bubble).
  - `agencia_id` = `Current User's agencia_id's Uuid Supabase`.
  - `cliente_notion_id` = `Current Page Clientes's notion_id`.
- **Only when:** `Result of analisis_get_messages :count is 0`.

Mismo patrón que el step equivalente de Newsletter (ver `docs/sectores/04-chat-newsletter.md` §7.13).

### 3. Render mensajes — sin cambios

El RG del chat ya usa `</> HTML text mensaje` (HTML element) en `Group Burbuja Diseño`. El greeting llega con `<a href>` y los chips de citas inline `[fuente: X]` también — todo se renderiza nativo. Cero cambios en RG.

### 4. (Opcional) Estilo CSS para chips de citas

En el HTML element, las citas inline llevan clase `cita-fuente`. Si quieres estilarlas (chip pill, color acento verde, hover underline), añadir al `<style>` global de la page o al HTML element:
```css
.cita-fuente {
  display: inline-block;
  padding: 0 6px;
  margin: 0 2px;
  border-radius: 4px;
  background: rgba(34,197,94,0.15);
  color: #22c55e;
  text-decoration: none;
  font-size: 0.85em;
}
.cita-fuente:hover { text-decoration: underline; }
```

### 5. Smoke test E2E

1. Abrir `/clientes/{actualizate_id}/analisis` con conv test fresca (`DELETE FROM chat_messages WHERE conversation_id='b19b3b10-...'; UPDATE analisis_wip SET kb_files='[]'::jsonb, kb_text=null, kb_links_text=null WHERE conversation_id='b19b3b10-...';`).
2. Verificar greeting con lista de archivos del Drive + narrativa Gemini + drive link.
3. Mandar "Analiza Actualízate Psicología" → tool_loop dispara `IA Análisis — KB Fetch [SUB]` → `kb_files` se actualiza con `incluido/truncado`.
4. Confirmar que el agent cita `[fuente: X]` en algún punto del briefing y aparece como chip clicable en el chat.