---
title: Notificaciones — Módulo interno del Portal
dominio: portal
estado: WIP (MVP funcional, varios pendientes)
actualizado: 2026-05-21
tags: [portal, notificaciones, bubble]
---

# Notificaciones — Módulo interno

Sistema de notificaciones internas del Portal. Un usuario (o el sistema vía n8n) puede notificar a uno o varios usuarios de la misma agencia, con posibilidad de respuesta inline por cada destinatario.

## Decisión de diseño (2026-05-15)

Schema fusionado a **2 tablas** (no 3 como se planteó inicialmente). Histórico: empezamos con 3 (`Notificacion` + `Notificacion_Destinatario` + `Notificacion_Respuesta`) pensando en threads multi-reply tipo chat. Tras revisar el caso de uso real (1 respuesta máxima por destinatario), se fusionaron las dos hijas en `Notificacion_Receptor` que guarda tanto el estado de lectura como la respuesta del destinatario. **Si en el futuro se quiere thread con múltiples respuestas por destinatario, se vuelve a separar la respuesta en su propia tabla**.

## Schema (Bubble)

### Option Sets (4)

| Option Set | Options | Atributos |
|---|---|---|
| `Notificacion_Remitente_Tipo` | `usuario`, `sistema` | — |
| `Notificacion_Tipo_Evento` | `manual` (extensible: `tarea_vencida`, `mencion_chat`, `ads_alerta`, etc.) | — |
| `Notificacion_Prioridad` | `baja`, `normal`, `alta` | `color` (text): `#6b7280` / `#22c55e` / `#ef4444` |
| `Notificacion_Canal` | `in_app`, `email`, `whatsapp` | — |

### Data Type `Notificacion`

Mensaje original que se envía. Una sola fila por noti.

| Campo | Tipo | List | Notas |
|---|---|---|---|
| `remitente` | User | no | NULL si remitente_tipo = sistema |
| `remitente_tipo` | Notificacion_Remitente_Tipo | no | |
| `tipo_evento` | Notificacion_Tipo_Evento | no | Slug del evento. Puerta abierta para eventos automáticos. |
| `titulo` | text | no | |
| `mensaje` | text | no | **Contiene BBCode de Bubble** `[img width=Xpx]URL[/img]` para imágenes pegadas en el Rich Text Input (desde 2026-05-21). Las imágenes pegadas se suben automáticamente al File Manager y se referencian por URL CDN protocol-relative. El `mensaje` se renderiza con Rich Text Input disabled en RG y modal. |
| `imagen` | file | sí | Adjuntos. Pese al nombre, soporta cualquier tipo de archivo (PDFs, docs, zips, imágenes). |
| `enlace_url` | text | sí | Múltiples URLs como list of texts. UI muestra dominio extraído. |
| `cliente` | Cliente | sí | Cliente(s) relacionado(s), opcional |
| `prioridad` | Notificacion_Prioridad | no | |
| `canal` | Notificacion_Canal | sí | Default `in_app` |
| `fecha_limite` | date | no | Cuándo debe estar resuelta la acción |
| `expira_en` | date | no | Cuándo auto-archivar |
| `agencia` | Agencia | no | |
| **`destinatarios`** | User | **sí** | **Denormalizado para Privacy Rules. Incluye remitente** (poblado con `:plus item remitente` al crear). |
| `archivada` | yes/no | no | Flag de archivado del mensaje original a nivel global (visibilidad agencia). Independiente del `archivada` por receptor — un emisor puede archivar la noti completa sin que los receptores hayan tocado su slot. |

### Data Type `Notificacion_Receptor`

Una fila por cada destinatario que recibe la noti. Aquí vive el estado de lectura **y** la respuesta del destinatario (fusión).

| Campo | Tipo | List | Notas |
|---|---|---|---|
| `notificacion` | Notificacion | no | |
| `receptor` | User | no | El destinatario que recibe |
| `mensaje_respuesta` | text | no | Vacío hasta que el receptor responda. Editado vía autobinding. |
| `leida_en` | date | no | NULL = no leída |
| `archivada` | yes/no | no | Flag de archivado del slot por receptor. Independiente del `archivada` global de `Notificacion`. |
| `archivado_en` | date | no | Fecha en que el receptor archivó el slot. Solo registro temporal — no se usa para filtrar (el filtro lo hace `archivada`). |
| `emisor` | User | no | Denormalizado (= `notificacion's remitente`) para Privacy Rules. |
| `destinatarios` | User | sí | Denormalizado (= `notificacion's destinatarios`) para Privacy Rules. |

**No se crea `Notificacion_Receptor` para el emisor** — el emisor no responde a su propio mensaje. Pero el emisor SÍ aparece en `destinatarios` (campo denormalizado) para ver sus propias notis enviadas en el dashboard.

## Privacy Rules

⚠️ **Bubble Privacy Rules tiene restricciones críticas**: no permite Search, no permite chains (`This X's Y's Z`) para conceder Find, y el operador para list fields es **`contains`** (NO `is in`). Por eso denormalizamos `emisor` y `destinatarios` en `Notificacion_Receptor`.

### `Notificacion`
- **Regla A "Destinatarios":** `This Notificacion's destinatarios contains Current User` → ✅ View · ✅ Find
- **Regla B "Emisor":** `This Notificacion's remitente is Current User` → ✅ View · ✅ Find · ✅ Modify via API · ✅ Delete via API

Everyone else: blanco.

⚠️ La Regla B es crítica para que el botón "Notificación Resuelta" del modal funcione (soft-delete del registro + hard-delete de los archivos del File Manager, desde 2026-05-21). Sin Modify via API, Bubble rechaza el UPDATE de `archivada=yes` en servidor. La regla usa `remitente` (no `Creator`) para que las notis sistema (n8n, `remitente_tipo = sistema` con `remitente = NULL`) no puedan modificarse por ningún user. **Delete via API** se mantiene en la regla por si en el futuro se añade hard-delete físico (Papelera del emisor).

### `Notificacion_Receptor`

⚠️ **Requisito previo:** `Notificacion_Receptor` debe estar **expuesto en Data API** (Settings → API → marcar en la lista de data types). Sin esto, Bubble oculta los checkboxes `Modify via API` / `Delete via API` en la pantalla de Privacy Rules y no se pueden conceder. Exposición es además requisito del sync espejo Supabase.

- **Regla A "Mi slot":** `This Notificacion_Receptor's receptor is Current User` → ✅ View · ✅ Find · ✅ Modify via API · **Auto-bind ✅ SOLO en `mensaje_respuesta`** (NO marcar autobind en el resto de fields — un receptor con autobind ampliado podría manipular DOM y pisar `emisor`, `destinatarios`, etc.)
- **Regla B "Destinatario":** `This Notificacion_Receptor's destinatarios contains Current User` → ✅ View · ✅ Find
- **Regla C "Emisor":** `This Notificacion_Receptor's emisor is Current User` → ✅ View · ✅ Find · ✅ Modify via API · ✅ Delete via API

Everyone else: blanco.

⚠️ La Regla C amplía Modify+Delete para que el emisor pueda marcar archivada las filas hijas al ejecutar "Notificación Resuelta" (soft-delete del registro + hard-delete de los archivos del File Manager). Delete via API se mantiene previsto por si en el futuro se añade hard-delete físico.

## Backend Workflows

### `api_crear_notificacion` (público, requiere auth)

Endpoint que crea una notificación con N destinatarios atómicamente. Reutilizable desde frontend (botón Enviar del popup) y desde n8n (eventos automáticos futuros).

**Configuración:**
- ✅ Expose as a public API workflow
- ❌ Run without authentication (requiere token o cookie)
- ✅ Ignore privacy rules when running the workflow

**Parameters:**

| Param | Type | List |
|---|---|---|
| `agencia` | Agencia | no |
| `remitente` | User | no (opcional, vacío si sistema) |
| `remitente_tipo` | Notificacion_Remitente_Tipo | no |
| `tipo_evento` | Notificacion_Tipo_Evento | no |
| `titulo` | text | no |
| `mensaje` | text | no |
| `prioridad` | Notificacion_Prioridad | no |
| `cliente_list` | Cliente | sí |
| `canal_list` | Notificacion_Canal | sí |
| `destinatarios_list` | User | sí |
| `fecha_limite` | date | no |
| `expira_en` | date | no |
| `archivo_list` | file | sí |
| `enlace_url_list` | text | sí |

**Steps:**

1. **Create Notificacion**: setea todos los campos con los params + **`destinatarios = destinatarios_list:plus item remitente`** (esto es crítico — el emisor está en su propia lista de destinatarios para ver sus enviadas).
2. **Schedule API Workflow on a list**:
   - API Workflow: `_crear_receptor_notif`
   - Type of things: `User`
   - List to run on: `destinatarios_list` (sin `:plus item remitente` aquí — el emisor NO necesita su propia fila de Receptor)
   - Pass params: `notificacion = Result of step 1`, `receptor = This User`, `emisor = remitente`, `destinatarios_list = destinatarios_list:plus item remitente`

### `_crear_receptor_notif` (privado, sub-workflow)

Crea 1 `Notificacion_Receptor` por cada destinatario.

**Configuración:**
- ❌ Expose as public API workflow (es interno)
- ✅ Ignore privacy rules when running the workflow

**Parameters:** `notificacion` (Notificacion), `receptor` (User), `emisor` (User), `destinatarios_list` (User, list)

**Step 1:** Create Notificacion_Receptor:
- notificacion = notificacion
- receptor = receptor
- emisor = emisor
- destinatarios = destinatarios_list
- mensaje_respuesta = (vacío)
- leida_en = (vacío)

### `_borrar_archivo_rte` (privado, sub-workflow, 2026-05-21)

Borra UN archivo del File Manager dada su URL canónica. Invocado por `Schedule API Workflow on a list` desde el botón "Notificación Resuelta" — itera sobre las URLs extraídas del `mensaje` con regex.

**Configuración:**
- ❌ Expose as public API workflow (es interno)
- ✅ Ignore privacy rules when running the workflow

**Parameters:**

| Param | Type | List |
|---|---|---|
| `url` | text | no |

**Step 1:** Delete an uploaded file
- `File URL`: Arbitrary text `https://[url]` (el `[url]` como dynamic expression del parameter)

⚠️ Por qué backend y no inline: la acción `Delete an uploaded file` de Bubble opera sobre UN archivo por llamada — no hay variante "Delete a list of uploaded files". La única forma idiomática de iterar sobre N URLs es `Schedule API Workflow on a list`, que solo dispara workflows backend.

## Espejo Supabase (`bub_notificacion` + `bub_notificacion_receptor`)

Creado 2026-05-16. Sync vía workflow existente `FGxG67I24POOUeHW` (SYNC ESPEJO — Bubble → Supabase): `ALLOWED_TABLES` ampliado 23 → 25.

Convención `bub_*` estándar: PK `bubble_id text`, `_synced_at timestamptz DEFAULT now()` + trigger `trg_set_synced_at`, RLS ON, GRANT solo `service_role` (Bubble no lee este espejo — solo lecturas analíticas / n8n vía service_role).

**`bub_notificacion`** — espeja `Notificacion`. List fields como `text[]`: `archivo`, `enlace_url`, `cliente`, `canal`, `destinatarios`. Índice GIN sobre `destinatarios` para queries por receptor. Índice `modified_date DESC` para listados recientes.

**`bub_notificacion_receptor`** — espeja `Notificacion_Receptor`. Índices simples sobre `notificacion`, `receptor`, `emisor` + GIN sobre `destinatarios`.

**Columna `archivada` (2026-05-21):** `boolean NOT NULL DEFAULT false` en ambas tablas (`bub_notificacion` y `bub_notificacion_receptor`) alineada con los Data Types Bubble. El sync `FGxG67I24POOUeHW` no tiene whitelist por columna, así que propaga el campo en automático en cada UPDATE/INSERT desde Bubble.

**DB Triggers Bubble (activos desde 2026-05-16):** uno por Data Type ("A Notificacion is modified" + "A Notificacion_Receptor is modified") llamando al API Connector `sync_bubble_mirror` con `body.tabla = "bub_notificacion" | "bub_notificacion_receptor"` + `body.bubble_id = This X now's unique id`. Cada CREATE/UPDATE en Bubble propaga al espejo en ~1-2s.

## UI

### Popup `popup_nueva_notificacion`

Ubicado en el Header reusable element. Se abre al hacer click en el icono campana del header.

**Elementos:**
- `mdd_destinatarios` (Multidropdown, Type: User) — required
- `mdd_clientes` (Multidropdown, Type: Cliente) — opcional
- `input_titulo` (Input) — required
- `rte_mensaje` (**Rich Text Input** — desde 2026-05-21, sustituye al `mli_mensaje` Multiline Input previo) — required. Permite pegar capturas directamente desde el portapapeles: Bubble las sube automáticamente al File Manager y embebe el BBCode `[img width=Xpx]URL[/img]` en el value.
- `dd_prioridad` (Dropdown, Type: Notificacion_Prioridad, default `normal`) — required
- `dtp_fecha_limite` (DateTime Picker) — opcional
- `uploader_archivo` (Multi-File Uploader o PictureUploader según versión) — opcional. Sigue siendo el canal para adjuntos no-imagen (PDFs, zips, docs). Estos archivos sí están vinculados al campo `imagen` (file list) del Data Type y se borran automáticamente via cascade nativo si en el futuro se hace hard-delete de la Notificacion.
- `btn_enviar` con conditional disabled si faltan campos required

**Workflow del botón Enviar:**
1. Schedule API Workflow `api_crear_notificacion` con todos los params del popup (`canal_list` hardcoded a `[in_app]`, `remitente = Current User`, `remitente_tipo = usuario`, `tipo_evento = manual`, `agencia = Current User's agencia`, `mensaje = rte_mensaje's value`).
2. Reset relevant inputs (puede no limpiar el RTE; añadir Reset inputs del grupo contenedor si hace falta).
3. Hide popup_nueva_notificacion

### RG en el Dashboard

`RepeatingGroup notificaciones` en el panel inferior derecho del dashboard.

**Config:**
- Type of content: `Notificacion`
- Data source: `Search for Notificacions where destinatarios contains Current User AND archivada is "no"`, sort `Modified Date` descending. El filtro `archivada is "no"` excluye las notis resueltas (soft-delete).

Cada celda contiene split visual Input (mensaje original) / Output (sub-RG con todos los receptores). El mensaje original se renderiza con un **Rich Text Input disabled** (Initial content = `Current cell's Notificacion's mensaje`, `This input is disabled` ON) para que las imágenes pegadas en el RTE se muestren renderizadas en lugar de como BBCode crudo.

**Sub-RG `rg_receptores` dentro del output:**
- Type: `Notificacion_Receptor`
- Data source: `Search for Notificacion_Receptors where notificacion = Parent group's Notificacion`

Cada celda del sub-RG es un slot de respuesta. El slot del current user tiene el MultilineInput con autobinding sobre `mensaje_respuesta`. Los slots de otros destinatarios son read-only (Conditional: `Current cell's Notificacion_Receptor's receptor is not Current User` → not editable).

### Modal Thread (`popup_thread_notificacion`)

Popup que se abre al hacer click en una fila del RG dashboard. Renderiza mensaje original + N respuestas (1 por destinatario que haya respondido) + archivos + footer reply (solo destinatarios) + botón "Notificación Resuelta" (solo emisor).

**Type of content:** `Notificacion`. Display data al click de la fila.

**Header:**
- `txt_modal_titulo` — Text: `"Notificación · " + Parent group's Notificacion's cliente:first item's nombre` (Conditional: si `cliente:count is 0` → `"Notificación"`).
- `icon_close_modal` — Icon X: Hide popup.

**Bloque mensaje original** — Group (Type: Notificacion = Parent's Notificacion):

Avatar + autor + tiempo relativo + mensaje + tags. El mensaje se renderiza con un **Rich Text Input disabled** llamado `rte_mensaje_view` (Initial content = `Parent group's Notificacion's mensaje`, `This input is disabled` ON). Esto es necesario porque el `mensaje` contiene BBCode `[img]URL[/img]` desde 2026-05-21 — un Text element lo mostraría como texto crudo en lugar de renderizar las imágenes. Tiempos relativos con patrón **1 Text + N Conditionals que sobreescriben el property `Text`**:

```
txt_tiempo_original:
  Default Text:
    hace  (Current date/time - Parent group's Notificacion's Creation Date) :formatted as minutes  min
  Conditional 1 — When (...) :formatted as minutes ≥ 60
    Text → hace  (...) :formatted as hours  h
  Conditional 2 — When (...) :formatted as hours ≥ 24
    Text → hace  (...) :formatted as days  d
```

Bubble evalúa las Conditionals top-to-bottom y la última que se cumpla gana. Patrón aplicado también a `txt_tiempo_respuesta` (sobre `Current cell's Modified Date`) y a `txt_tag_deadline` con cuarta Conditional `< 0 → "vencida"`.

**Tags** (solo bajo el mensaje original — no duplicar como header meta):
- `txt_tag_cliente` — visible si `cliente:count > 0`. Texto: `cliente:each item's nombre:join with " · "`.
- `txt_tag_deadline` — visible si `fecha_limite is not empty`. Conditionals sobre `(fecha_limite - Current date/time) :formatted as minutes/hours/days` + "vencida" cuando diff < 0.
- `txt_tag_prioridad` — `prioridad's Display`, bg color = `prioridad's color` (atributo del Option Set).

**Bloque respuestas** — `rg_respuestas` (RepeatingGroup):
- Type: `Notificacion_Receptor`
- Data source: `Search for Notificacion_Receptors where notificacion = Parent's Notificacion AND mensaje_respuesta is not empty, sort Modified Date ascending`
- Por celda: avatar receptor + nombre + `txt_tiempo_respuesta` + `Current cell's mensaje_respuesta`.

**Bloque archivos** — `rg_archivos` (RepeatingGroup):
- Type: **file**, Data source: `Parent's Notificacion's imagen`
- Por celda: `Current cell's file's filename` + botón "Descargar" → workflow "Open an external website" → URL: `Current cell's file's URL`.
- ⚠️ Bubble abre el archivo en pestaña nueva. PDFs/imágenes se renderizan inline; zips/docx descargan directo. Forzar descarga universal requiere plugin "Download File" o backend con `Content-Disposition: attachment`.

**Footer reply** — Group `grp_reply_footer` (Type: `Notificacion_Receptor`):
- Data source: `Search for Notificacion_Receptors where notificacion = Parent's Notificacion AND receptor is Current User :first item`
- Conditional visible: `grp_reply_footer's Notificacion_Receptor is not empty`
- Contiene `mli_respuesta` (Multiline Input con autobinding sobre `Parent group's Notificacion_Receptor's mensaje_respuesta`) + `btn_enviar_respuesta`.

Como el emisor no tiene fila propia de Receptor por diseño, el data source viene vacío → Conditional false → footer oculto. Coherente con "todos los que pueden responder".

**Botón "Notificación Resuelta" (soft-delete del registro + hard-delete de archivos del File Manager, desde 2026-05-21)** — `btn_eliminar_notificacion`:

- **Tab General**: `This element is visible on page load` ❌ desmarcado (arranca oculto).
- **Conditional**: When `Parent group's Notificacion's remitente is Current User` → property `This element is visible` toggle ✅ ON (lo enciende solo al emisor).

Workflow del botón (4 steps, el orden visual no es lo que se ejecuta primero porque Bubble paraleliza — pero los `Schedule on a list` evalúan su `List to run on` al inicio del workflow padre, así que las URLs quedan capturadas en memoria aunque el Step 1/2 actualicen luego):

1. **Make changes to a list of things** → `Search for Notificacion_Receptors where notificacion = Popup Notificacion's Notificacion` → `archivada = yes`, `archivado_en = Current date/time`.
2. **Make changes to Notificacion** → `Popup Notificacion's Notificacion` → `archivada = yes`.
3. **Hide** `popup_thread_notificacion`.
4. **Schedule API Workflow on a list** → `_borrar_archivo_rte`
   - `Type of things`: `text`
   - `List to run on`: `Popup Notificacion's Notificacion's mensaje :extract with Regex` con pattern `(?<=\[img[^\]]*\])\S+?(?=\[/img\])` — devuelve lista de URLs protocol-relative (sin brackets).
   - `Scheduled date`: `Current date/time`
   - `Interval (seconds)`: `0`
   - Param `url` del subworkflow: `This text`

**Por qué soft-delete del registro + hard-delete de archivos:** soft-delete del registro preserva el `mensaje` como audit trail y evita borrado irreversible. Hard-delete de archivos libera storage del File Manager (las URLs CDN de Bubble se acumulan si no se purgan explícitamente). Trade-off consciente: al abrir una noti archivada en el futuro, los `[img]` apuntarán a archivos muertos y se mostrarán rotos — aceptable porque las archivadas no se vuelven a abrir en flujo normal.

**Por qué el regex usa lookbehind/lookahead y NO capture group:** el operador `:extract with Regex` de Bubble ignora capture groups y devuelve el match completo. Si se usara `\[img[^\]]*\](\S+?)\[/img\]` con group 1, el match devuelto sería el bloque entero `[img...]URL[/img]` y el `Delete an uploaded file` recibiría una URL malformada (`https://[img...]URL[/img]`). El lookbehind `(?<=\[img[^\]]*\])` y lookahead `(?=\[/img\])` hacen que el match COMPLETO sea solo la URL pelada.

**Por qué el List to run on lee del Popup y no de Result of step X:** desacopla del orden de ejecución. Los steps se paralelizan; leer del popup directamente garantiza que la fuente del regex es el mensaje original aunque el Step 2 ya esté ejecutándose.

## Pendientes para retomar

- **Mark as read** automático al abrir el modal: `Make changes to Notificacion_Receptor` → `leida_en = Current date/time` solo si está vacío.
- **Indicador no-leídas en la campana** del header (badge con count).
- **Página `/notificaciones`** con histórico completo + archivar. Backend ya tiene los flags listos: `Notificacion.archivada` (archivado global por emisor — soft-delete) y `Notificacion_Receptor.archivada` (archivado de slot por receptor). Falta UI con botón archivar + filtro en RG (`archivada is "no"` / `is "yes"`). Nota: las notis archivadas via "Notificación Resuelta" tendrán los `[img]` rotos (archivos físicos borrados) — coherente con el trade-off de soft-delete del registro + hard-delete de archivos.
- **Eventos sistema:** ningún `tipo_evento` automático conectado todavía. n8n los disparará vía `api_crear_notificacion` cuando se modelen casos como `tarea_vencida`, `mencion_chat`, `ads_alerta`.
- **Notificaciones viejas pre-refactor** no tienen `destinatarios` poblado → no aparecen en el RG. Si quieres recuperarlas, edita a mano en App Data o bórralas.
- **Sub-RG vs Group simple en el output:** actualmente sub-RG muestra todos los receptores. Si el usuario quiere ver solo SU slot inicialmente y abrir thread al click → cambiar a Group simple filtrado por `receptor = Current User`.
- **Privacidad de URLs del CDN:** los archivos pegados en el RTE (igual que los del campo `imagen`) tienen URL pública del CDN de Bubble. Cualquiera con el link los ve, no enumerable pero filtrable. Aceptado como modelo consistente con `imagen` actual. Si en el futuro las notis manejan datos sensibles (capturas con clientes/financiero), reevaluar pasar a storage privado (Supabase Storage o S3 con signed URLs) — fuera del scope actual.

## Lecciones aprendidas durante el montaje

1. **Bubble Privacy Rules usa `contains` para list fields, NO `is in`** (al revés que data sources normales). Y NO permite Search ni chains para Find. Para evitarlo, denormalizar campos (`destinatarios`, `emisor`) directamente en las tablas hijas.
2. **Autobinding requiere doble permiso**: `Modify via API` en la regla + checkbox `Auto-bind` por field específico en la columna de la regla. Marcar autobind global en todos los fields es un agujero de seguridad: un receptor con DOM manipulado podría escribir en `emisor`/`destinatarios`/`notificacion`.
3. **Backend workflows deben tener `Ignore privacy rules`** marcado, o fallan al crear/modificar things que el current user no podría tocar directamente.
4. **`Schedule API Workflow on a list` ≠ `Schedule API Workflow`**: la "on a list" itera y permite `This X` como item; la single no.
5. **`:plus item remitente` en `destinatarios`** al crear es el truco para que el emisor vea sus propias notis enviadas en el dashboard sin tener que crearle un `Notificacion_Receptor` (lo cual sería raro, "responderse a sí mismo").
6. **Data API expone checkboxes Modify/Delete via API en Privacy Rules.** Si un data type no está expuesto en Settings → API → Data API, Bubble oculta esos 3 checkboxes en la pantalla de reglas. Sin ellos visibles, las reglas no pueden conceder Modify/Delete y los workflows fallan silenciosamente en servidor. Para Notificacion_Receptor hubo que exponerlo antes de poder ampliar la Regla C.
7. **Patrón "1 Text + N Conditionals que sobreescriben Text"** es la forma limpia de mostrar tiempo relativo (min/h/d) en Bubble. Mejor que 3 Texts apilados con visibility mutuamente excluyente: menos elementos, mismo resultado, evaluación top-to-bottom donde la última Conditional que aplica gana.
8. **`:formatted as minutes/hours/days`** sobre la resta de dos fechas es la forma nativa de obtener diff en cada unidad. Evita los `/60`, `/3600`, `/86400` manuales.
9. **Visibilidad condicional de elementos** se monta con dos piezas: tab General → `This element is visible on page load` ❌ (default oculto), y Conditional → toggle `This element is visible` ✅ ON cuando se cumple el When. Si el toggle está OFF en el Conditional, oculta cuando se cumple — al revés de lo deseado, bug común.
10. **`remitente` vs `Creator` en Privacy Rules**: `Creator` es metadato BD que puede ser NULL o user técnico cuando n8n dispara notis sistema. Usar el campo de dominio explícito (`remitente`) blinda la regla para que notis sistema sean inmutables.
11. **Rich Text Input nativo pega imágenes como URL CDN, NO base64** (descubierto 2026-05-21). Bubble sube la imagen al File Manager y embebe `[img width=Xpx]//cdn.bubble.io/.../richtext_content.png[/img]` en el `value`. La premisa inicial del refactor era split en 2 Data Types por peso de base64 — al ser URLs cortas, el split es innecesario y `mensaje` (text) absorbe el value directamente.
12. **`:extract with Regex` ignora capture groups** (descubierto 2026-05-21). El operador devuelve el match completo, sin importar si el pattern define `(...)`. Para extraer solo una parte usar lookbehind `(?<=...)` y lookahead `(?=...)` para que el match COMPLETO ya sea lo deseado. Pattern usado para URLs del RTE: `(?<=\[img[^\]]*\])\S+?(?=\[/img\])`.
13. **`Delete an uploaded file` acepta URL string canónica** (descubierto 2026-05-21). La acción funciona con `https://cdn.bubble.io/.../filename.png` sin query strings (`?_gl=...` rompe el match). NO opera sobre listas — para borrar N archivos, usar `Schedule API Workflow on a list` con subworkflow que reciba UNA URL por invocación. Es la única vía nativa para cascade de archivos pegados en RTE.
14. **URL en File Manager UI ≠ URL canónica** (descubierto 2026-05-21). Cuando clicas un archivo en File Manager, Bubble añade query string analytics `?_gl=...` a la URL del navegador. La URL canónica para `Delete an uploaded file` es la que aparece en el `value` del RTE (sin tracking), no la que ves al clicar.
15. **El BBCode `[img]URL[/img]` solo se renderiza en Rich Text Input disabled.** Un Text element con dynamic value = `Notificacion's mensaje` muestra el BBCode crudo. Para visualizar imágenes en RG y modal hay que usar Rich Text Input con `This input is disabled` ON e `Initial content` apuntando al mensaje.
