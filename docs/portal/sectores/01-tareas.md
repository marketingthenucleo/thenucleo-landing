---
title: Sector — Tareas
dominio: sectores
estado: activo
actualizado: 2026-05-08
tags: [sector, tareas, notion, bubble]
---

# Sector 1 — Tareas (Notion ↔ Bubble ↔ Supabase)

**Estado:** ✅ REFACTORIZADO en sesión 2026-04-21. Pendiente verificación de 4 tests + acciones manuales Ben.

> **Nota 2026-05-07:** las menciones a `maw` y a la migración `maw → cbi` que aparecen abajo son **históricas**. El proyecto maw está INACTIVE desde mayo 2026. Todos los workflows referenciados ya operan contra cbi. El field anti-rebote canónico es `last_edit_source` (F0 multi-provider 2026-05-02); el legacy `updated_by` aún coexiste en `bub_tareas_notion` por compat pero no se usa para flujos nuevos. La columna `bub_miembro_notion` fue DROP el 2026-05-02 — todas las referencias deben leer `bub_user`.

---

## Arquitectura del sector

```
┌──────────────────┐
│  NOTION          │  ← master editorial (edición nativa en Notion app)
│  DB TAREAS       │
│  b67f8416-...    │
└────────┬─────────┘
         │ trigger Notion cada 1 min (create + update)
         │
         ▼
┌──────────────────────────────┐
│ n8n: GjijIDEUyiH05Mg0        │  v2 Notion→Bubble
│ - Detecta archivado/nuevo    │
│ - Mapea email→Bubble user ID │
│ - Create/Update/Delete Bubble│
│ - Setea updated_by=notion    │
└────────┬─────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│ BUBBLE Data Type:            │  HUB (hoy read-only para usuarios)
│   tareas_notion              │
│   + field updated_by         │
└────────┬─────────────────────┘
         │ backend Database Trigger on-save
         │
         ▼
┌──────────────────────────────┐       ┌──────────────────────────────┐
│ n8n: FGxG67I24POOUeHW        │──────►│ SUPABASE cbi:                │
│ SYNC ESPEJO (transversal)    │ espejo│   bub_tareas_notion          │
│ - GET Bubble Data API        │       │   + updated_by               │
│ - Normaliza + Upsert Supabase│       │                              │
└──────────────────────────────┘       └────────┬─────────────────────┘
                                                │
                                                ▼
                                       ┌──────────────────────────────┐
                                       │ Vistas: v_tareas_panel,      │
                                       │   v_tareas_contexto_ia,      │
                                       │   v_tareas_cerebro_ia        │
                                       │ Chat IA Cerebro (RAG)        │
                                       │ Ops Monitor                  │
                                       └──────────────────────────────┘
```

### Flujos transversales del sector
- **Entrada a Notion** (desde Bubble): formulario `eHyXBETcaGSNXqLk` (crear) + plantilla `KSBwigoSEpHl5OG1`. Ambos crean en Notion y luego v2 refleja en Bubble.
- **Safety net**: `ZqccS38F2Lz8WFwX` (CRON Huérfanas cada 3h) detecta tareas archivadas en Notion que quedaron en Bubble y las limpia.

---

## Capa Bubble

### Data Type `tareas_notion` (hoy)

| Field | Tipo | Observaciones |
|---|---|---|
| nombre | text | título |
| estado | text | Backlog, En progreso, etc. |
| prioridad | text | Alta/Media/Baja |
| fecha_entrega | date | |
| area_tarea | text | Meta Ads, SEO, etc. |
| incidencia | yes/no | |
| cliente_notion_id | text | FK a cliente Notion |
| responsables | list of User | bubble_ids de User |
| responsable_nombres | text | derived |
| aprobador_emails | list of texts | emails |
| aprobador_nombres | text | derived |
| observadores_emails | list of texts | emails |
| observadores_nombres | text | derived |
| bloqueado_por_ids | list of texts | notion_ids de otras tareas |
| bloqueando_ids | list of texts | notion_ids de otras tareas |
| estimacion_min | number | |
| duracion_real_min | number | |
| notion_id | text | ID de página Notion |
| url | text | |
| last_edited_time | date | |
| **updated_by** | text | **AÑADIDO sesión 2026-04-21. Default `user`. Valores: `user`, `notion`, futuro `clickup`, `asana`...** |

### Páginas / UI

- **Operaciones Kanban** (`/operaciones`): muestra tareas desde `v_tareas_panel` (lee `bub_tareas_notion`).
- **Formulario Crear Tarea**: frontend dispara webhook `crear_tarea_formulario` → n8n `eHyXBETcaGSNXqLk` → Notion.
- **Botón Aplicar Plantilla**: frontend dispara webhook `Agregar_plantilla_a_cliente_paso_1` → n8n `KSBwigoSEpHl5OG1`.
- ⚠️ **Edición/borrado directo en Bubble NO EXISTE HOY.** Cuando se implemente (Kanban drag, modal editar, botón borrar), se activa el workflow `9mEU2MzE14mGpry2`.

### API Connectors relevantes

- `crear_tarea_formulario` → n8n eHyXBETcaGSNXqLk
- `Agregar_plantilla_a_cliente_paso_1` → n8n KSBwigoSEpHl5OG1
- `sync_bubble_mirror` → n8n FGxG67I24POOUeHW (transversal)
- **Pendiente futuro**: `sync_tarea_bubble_notion` → n8n 9mEU2MzE14mGpry2 (cuando se habilite edición)

### Backend workflows Bubble
- **On-save `tareas_notion`** (ya existe): llama `sync_bubble_mirror`. Visible en el editor Bubble.
- **On-before-delete `tareas_notion`** (pendiente crear): llamará a `sync_tarea_bubble_notion` con action=delete. Solo necesario cuando se habilite borrado desde Bubble.

---

## Capa Supabase cbi

### Tabla canónica
- **`bub_tareas_notion`** — espejo read-only de Bubble Data Type `tareas_notion`.
- Actualizada vía `FGxG67I24POOUeHW` (upsert con on_conflict=bubble_id).
- Columna nueva añadida en sesión: `updated_by text DEFAULT 'user'`.

### Vistas que dependen de `bub_tareas_notion`
- `v_tareas_panel` — Kanban de los últimos 20 días. **Ben la reconstruye manualmente, NO tocar sin OK**.
- `v_tareas_contexto_ia` — últimos 10 días para prompts IA.
- `v_tareas_cerebro_ia` — extendida con `dias_hasta_entrega`.

### RLS
- `bub_tareas_notion` sin RLS explícita (espejo, controlado por n8n service_role).

### Tablas auxiliares usadas
- `bub_user` — mapeo identidades miembros (`notion_id`, `clickup_user_id`, `email`, `bubble_id`). Usado por workflows Bubble→Provider para traducir responsables. **Reemplaza a la tabla histórica `bub_miembro_notion` (DROP 2026-05-02).**
- `activity_log` — logs de operaciones (ej: `accion='eliminada_huerfana'`).
- `workflow_executions` — log de ejecuciones n8n (Ops Monitor).

---

## Capa n8n — Workflows del sector

### Activos y funcionales (post-cbi)

| ID | Nombre | Trigger | Estado |
|---|---|---|---|
| `GjijIDEUyiH05Mg0` | SYNC TAREAS — Notion → Bubble | Notion trigger + CRON 1min | ✅ Activo. Modificado con `updated_by=notion` en Create/Update Bubble |
| `eHyXBETcaGSNXqLk` | OPS TAREAS — Crear desde Formulario Bubble | Webhook | ✅ Activo. No requiere cambios (solo toca Notion API + webhook) |
| `KSBwigoSEpHl5OG1` | OPS TAREAS — Aplicar Plantilla a Cliente | Webhook | ✅ Activo. URLs cbi. Pendiente F3: branch CU para multi-provider. |
| `FGxG67I24POOUeHW` | SYNC ESPEJO — Bubble → Supabase | Webhook (transversal) | ✅ Activo. Cubre 19 tablas |

### Creados en esta sesión

| ID | Nombre | Estado | Observaciones |
|---|---|---|---|
| `9mEU2MzE14mGpry2` | SYNC Tarea Bubble → Notion | **DESACTIVADO** | Listo para activar cuando se habilite edición/borrado en Bubble. **Credenciales pendientes de rebind.** |

### Reescritos en esta sesión

| ID | Nombre | Estado | Observaciones |
|---|---|---|---|
| `ZqccS38F2Lz8WFwX` | CRON TAREAS — Reconciliar Huérfanas Notion | **Inactivo, pendiente activar** | URLs maw→cbi migradas. Lee `bub_tareas_notion`, limpia Bubble + espejo. **Credenciales pendientes de rebind.** |

### Archivados en esta sesión (no volver a usar)

| ID | Nombre | Razón |
|---|---|---|
| `gKhvS7eP1B169bhbtc44a` | SYNC TAREAS Notion - Supabase - Bubble (v1) | Obsoleto, reemplazado por v2 |
| `aX4Zo7SCTl45R4H5` | CRON Reconciliación Tareas (3-capas) | Arquitectura antigua, no aplica en cbi |
| `ZOtpnTjojGyIjMHo` | LIMPIEZA Borrar duplicados | One-shot ya cumplido |

---

## Modificaciones aplicadas en la sesión

### En Supabase cbi
```sql
ALTER TABLE bub_tareas_notion 
  ADD COLUMN IF NOT EXISTS updated_by text DEFAULT 'user';
UPDATE bub_tareas_notion SET updated_by = 'user' WHERE updated_by IS NULL;
```

### En Bubble Data Type `tareas_notion`
- Añadido field `updated_by` (text, default `user`).

### En n8n `GjijIDEUyiH05Mg0` (v2) — manual por Ben
- Nodo "Actualizar Tarea en Bubble": añadida property `updated_by = notion`.
- Nodo "Crear Tarea en Bubble": añadida property `updated_by = notion`.

### Creado workflow `9mEU2MzE14mGpry2`
- Webhook `/sync_tarea_bubble_notion`
- Lógica: IF action=delete → PATCH Notion archive. ELSE → GET Bubble → IF notion_id vacío skip → IF updated_by=notion skip → GET bub_miembro_notion → Build properties → PATCH Notion.
- Mapeo de responsables bubble_id→notion_user_id + aprobador/observador emails→notion_user_id.
- **DESACTIVADO**: Bubble no permite edición hoy.

### Reescrito workflow `ZqccS38F2Lz8WFwX` (Huérfanas)
- URLs maw → cbi (4 nodos HTTP Request).
- Tabla origen: `notion_tareas` (maw) → `bub_tareas_notion` (cbi).
- Mantiene nodo Bubble DELETE + HTTP DELETE al espejo + activity_log en cbi.
- **INACTIVO**: credenciales sin rebind.

---

## Pendientes manuales (Ben)

### CRÍTICO (bloquea verificación)
- [ ] **`ZqccS38F2Lz8WFwX` (Huérfanas)**: rebind credenciales en 5 nodos (Supabase x3, Notion x1, Bubble x1) + **activar**.
- [ ] Revisar `KSBwigoSEpHl5OG1` (Plantilla) por si apunta a maw.

### NO crítico (futuro)
- [ ] **`9mEU2MzE14mGpry2` (Bubble→Notion)**: rebind credenciales (4 nodos: Supabase + Notion x2) + **NO activar** hasta habilitar edición en Bubble.
- [ ] Crear API Connector `sync_tarea_bubble_notion` en Bubble (POST al webhook).
- [ ] En backend on-save `tareas_notion`: añadir Action 2 → call `sync_tarea_bubble_notion` con `{bubble_id, action: "update"}`. **Condición**: `This Tareas_notion's updated_by is not "notion"`.
- [ ] Crear backend workflow on-before-delete `tareas_notion`: call `sync_tarea_bubble_notion` con `{bubble_id, notion_id, action: "delete"}`.

---

## Tests de verificación (ejecutar antes de cerrar el sector)

### Test 1 — Notion → Bubble → Espejo (flujo principal)
**Acción:** En Notion, edita una tarea existente (cambia estado, prioridad o fecha).
**Esperado en ~1-2 min:**
- Bubble `tareas_notion` refleja el cambio + `updated_by = notion`
- Supabase `bub_tareas_notion` refleja + `updated_by = notion`
- `workflow_executions` muestra ejecuciones OK de GjijIDEUyiH05Mg0 y FGxG67I24POOUeHW

**Query de verificación:**
```sql
SELECT notion_id, nombre, estado, updated_by, synced_at 
FROM bub_tareas_notion 
WHERE notion_id = '<id_tarea_editada>';
```

### Test 2 — Formulario Crear Tarea
**Acción:** En Bubble, usa el formulario "Crear Tarea".
**Esperado:**
- Notion DB recibe la tarea nueva.
- En ~1 min, aparece en Bubble con `updated_by = notion`.
- En ~pocos segundos adicionales, aparece en el espejo.

### Test 3 — Aplicar Plantilla
**Acción:** Botón "Agregar Plantilla" sobre un cliente cualquiera.
**Esperado:**
- N tareas nuevas en Notion.
- En ~1 min todas reflejadas en Bubble y espejo.

**Si falla este test**: revisar `KSBwigoSEpHl5OG1` — probablemente URLs maw.

### Test 4 — Huérfanas (safety net)
**Pre-req:** Workflow activo + credenciales rebinded.
**Acción:** En Notion, archiva una tarea (trash). En n8n UI, ejecuta `ZqccS38F2Lz8WFwX` manualmente.
**Esperado:**
- Tarea desaparece de Bubble y del espejo.
- Entry en `activity_log` con `accion = 'eliminada_huerfana'`.

**Query:**
```sql
SELECT * FROM activity_log 
WHERE accion = 'eliminada_huerfana' 
ORDER BY timestamp DESC LIMIT 5;
```

---

## Próximos pasos al retomar

1. Verificar que Ben ejecutó las acciones manuales (rebind + activar Huérfanas).
2. Correr los 4 tests.
3. Si alguno falla, diagnosticar con `workflow_executions` y docs de workflow específico.
4. Si todo OK → mover a sector 2 (Clientes).

---

## Preguntas abiertas para resolver al retomar

- ¿`KSBwigoSEpHl5OG1` (Plantilla) apunta a maw? Inspección pendiente.
- ¿Existe ya un workflow "plantilla → Supabase"? ¿Debería? (probable redundante si la plantilla crea tareas en Notion y luego v2 las refleja).
- ¿Hay otros workflows ocultos que toquen `tareas_notion` y no estén en la carpeta "SYNC Tareas"? Ej: error handlers, logs. Auditar.
