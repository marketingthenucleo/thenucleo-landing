---
title: Sector — Clientes
dominio: sectores
estado: activo
actualizado: 2026-05-08
tags: [sector, clientes, notion, bubble]
---

# Sector 2 — Clientes (Notion ↔ Bubble ↔ Supabase)

**Estado:** ✅ Bidireccional operativo desde 2026-04-27. `wvHcgVqqjkWJcJDu` (Bubble→Notion+Drive) + `FcTmv78nLjbCb2Ea08qbt` (Notion→Bubble) activos. Espejo `bub_clientes` en cbi vía SYNC ABSOLUTO.

> **Nota 2026-05-07:** las menciones a `maw` y `notion_empresas` que aparecen abajo son **históricas** (sesión auditoría 2026-04-21, antes de la migración). maw está INACTIVE desde mayo 2026. La fuente canónica de clientes es `bub_clientes` en cbi. El marker anti-rebote es `last_edit_source` (no `updated_by`).

---

## Arquitectura esperada (análoga a tareas)

```
┌──────────────────┐
│  NOTION          │  ← master: DB CLIENTES
│  DB Clientes     │
└────────┬─────────┘
         │ trigger Notion (create + update)
         ▼
┌──────────────────────────────┐
│ n8n: FcTmv78nLjbCb2Ea08qbt   │  SYNC CLIENTES — Notion → Bubble (legacy)
│ (hoy inactivo, apunta a maw) │
└────────┬─────────────────────┘
         │ ... pipeline actualmente desconocido post-cbi
         ▼
┌──────────────────────────────┐
│ BUBBLE Data Type:            │  HUB
│   (nombre a verificar)       │  ¿cliente? ¿clientes_notion?
└────────┬─────────────────────┘
         │ backend on-save
         ▼
┌──────────────────────────────┐       ┌──────────────────────────────┐
│ n8n: FGxG67I24POOUeHW        │──────►│ SUPABASE cbi:                │
│ SYNC ESPEJO — Bubble → Supabase│ espejo│   bub_clientes               │
└──────────────────────────────┘       └──────────────────────────────┘
```

---

## Capa Bubble

### Data Type candidato: `clientes` o `cliente`
- **A verificar** en editor Bubble: nombre exacto del Data Type.
- Probable: `clientes` (la tabla espejo es `bub_clientes`, ver lista en `FGxG67I24POOUeHW`).
- Fields esperados (pendiente verificación): nombre, logo, agencia_id, notion_id, integración_ghl, responsable_principal, etc.

### Páginas relevantes
- **`/clientes`** — Kanban / listado de clientes. Muestra desde `bub_clientes` o vista derivada.
- **Ficha cliente `/clientes/{empresa_id}`** — Detalle con subpáginas: Cerebro IA, Newsletter IA.
- **Modal crear cliente** — (verificar) probablemente crea en Bubble y/o en Notion.

### API Connectors (revisar `docs/infra/bubble-api-connectors.md`)
- Según doc, existen varios relacionados con clientes/empresas. Auditar:
  - GET bubble → Supabase vistas
  - POST a n8n webhook `sync-cliente` (workflow `n8n_sync_cliente` en doc)

### Backend workflows Bubble
- On-save `clientes` (o nombre real) → llama `sync_bubble_mirror` con `tabla=bub_clientes`.
- ¿Existe on-save que dispare Bubble→Notion? Probablemente NO todavía. Pendiente.

---

## Capa Supabase cbi

### Tablas (confirmadas por allowlist de `FGxG67I24POOUeHW`)
- **`bub_clientes`** — espejo del Data Type Bubble `clientes`.

### Vistas candidatas (verificar existencia)
- `v_clientes_opciones` — dropdown activo/inactivo (mencionado en CLAUDE.md, probablemente existe).

### Tabla legacy
- `notion_empresas` (en maw) — no existe en cbi (confirmado en sesión 2026-04-21).
- Cualquier workflow que apunte a `notion_empresas` en maw debe migrarse a leer de `bub_clientes` en cbi.

### RLS
- Sin RLS explícita (espejo).

---

## Capa n8n — Workflows a auditar

### Candidatos (del CLAUDE.md y n8n-workflows.md)

| ID | Nombre | Estado sospechado | Acción sugerida |
|---|---|---|---|
| `FcTmv78nLjbCb2Ea08qbt` | SYNC CLIENTES — Notion → Bubble | ✅ Reescrito 2026-04-27. Apunta a Bubble Data API (live) + cbi vía SYNC ESPEJO. Activo |
| `wvHcgVqqjkWJcJDu` | SYNC CLIENTES — Bubble → Notion + Drive | ✅ Reescrito 2026-04-27. Apunta a cbi + Notion + Drive. Activo |
| `n8n_sync_cliente` (webhook) | (ID no identificado) | A identificar | Auditar |

---

## Decisiones arquitectónicas por tomar

1. **¿Cómo nacen los clientes nuevos?**
   - Opción A: Se crean en Notion, trigger Notion → workflow → escribe Bubble → espejo auto.
   - Opción B: Se crean en Bubble (modal), workflow `Cliente Bubble → Notion`, espejo auto.
   - Opción C: Ambos (bidireccional real).
   - **Estado actual hoy**: desconocido, verificar con Ben.

2. **Plantilla para convertir a nuevos organizadores** (si algún día clientes vienen de Salesforce/HubSpot/etc):
   - Mismo patrón que tareas: 1 workflow por dirección + updated_by markers.

3. **Integración GHL** (GoHighLevel): los clientes también se crean en GHL. ¿Cómo se sincroniza?
   - Puede haber un tercer flujo GHL ↔ Bubble que pase por n8n. Auditar `docs/infra/bubble-api-connectors.md` Grupo 6 (GHL).

---

## Pendientes al auditar (checklist)

- [ ] Inspeccionar Data Type `clientes` en Bubble: listar fields + verificar `updated_by`.
- [ ] Query a `bub_clientes` para ver columnas actuales.
- [ ] Inspeccionar JSON de `FcTmv78nLjbCb2Ea08qbt` → identificar URLs maw.
- [ ] Inspeccionar JSON de `wvHcgVqqjkWJcJDu` → idem.
- [ ] Listar workflows que tocan `bub_clientes` o `notion_empresas`.
- [ ] Verificar si existe backend workflow Bubble on-save para `clientes`.
- [ ] Verificar flujo GHL ↔ clientes: ¿funciona hoy post-cbi?
- [ ] Mapeo del Modal crear cliente: ¿qué workflow dispara?

---

## Plan de ejecución (cuando se aborde)

1. Auditoría completa de los workflows candidatos + Bubble Data Type.
2. Aplicar patrón bidireccional como se hizo con tareas:
   - Añadir field `updated_by` al Data Type `clientes`.
   - Añadir columna `updated_by` a `bub_clientes` en Supabase.
   - Reescribir `FcTmv78nLjbCb2Ea08qbt` si aplica.
   - Reescribir `wvHcgVqqjkWJcJDu` si aplica.
   - Crear workflow safety-net CRON huérfanas (análogo a `ZqccS38F2Lz8WFwX`).
3. Configurar backend workflows Bubble on-save + on-delete con condición `updated_by != 'notion'`.
4. Tests de verificación análogos a los 4 de tareas.
