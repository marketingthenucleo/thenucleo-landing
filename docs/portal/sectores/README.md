---
title: Sectores (Índice)
dominio: sectores
estado: vivo
actualizado: 2026-05-08
tags: [sectores, hub, arquitectura]
---

# Sectores TheNucleo — Arquitectura completa por área funcional

Documentación de auditoría y estado por sector. Proyecto Supabase único: `cbixhqjsnpuhcrcjppah` (cbi). Cada sector cubre **todas las capas**: Bubble (UI + Data Types + API Connectors + backend workflows), Supabase (tablas + vistas + RPCs + RLS), n8n (workflows) y relaciones transversales.

> Al retomar: lee primero este índice. Para trabajar en un sector, abre su doc y sigue el apartado "Próximos pasos".

---

## Arquitectura general confirmada (Sesión 2026-04-21)

```
┌─────────────┐       ┌─────────┐        ┌──────────────┐
│  Notion     │◄─────►│         │───────►│   Supabase   │
│  ClickUp    │◄─────►│ BUBBLE  │  SYNC  │   (bub_*)    │
│  Asana      │◄─────►│  HUB    │ ABSOLUTO│  ESPEJO      │
│  (futuros)  │       │         │         │              │
└─────────────┘       └─────────┘         └──────────────┘
                          ▲                      │
                          │                      ▼
                       Usuario              Vistas + Chat IA
                        edita               + Ops Monitor
                                           + Finanzas + Clockify
```

### Reglas maestras
- **Bubble es el hub de datos.** Todo pasa por Bubble.
- **Supabase cbi es espejo read-only.** Tablas `bub_*` replican Data Types Bubble 1:1 (vía `FGxG67I24POOUeHW`).
- **Notion/ClickUp/Asana son fuentes externas** que se sincronizan bidireccionalmente con Bubble.
- **Anti-rebote bidireccional**: field `last_edit_source` en Data Type Bubble (canónico desde F0 multi-provider 2026-05-02). Markers: `notion`, `clickup`, `bubble`, `user`, `cron`. El legacy `updated_by` coexiste solo en `bub_tareas_notion` por compat — no usar para nuevos flujos.

### Patrón por Data Type bidireccional
```
[Organizador externo]  ──(n8n workflow <org>→Bubble, setea last_edit_source=<org>)──►  Bubble
                                                                                     │
                                                                                     ▼
                                                                       Backend on-save:
                                                                         1. sync_bubble_mirror  (siempre)
                                                                         2. sync_<dt>_bubble_<org>  (solo si last_edit_source != '<org>')
                                                                                     │
                                                                                     ▼
                                                             [Organizador externo (PATCH)]
```

### Convenciones establecidas
| Prefijo | Significado |
|---|---|
| `bub_<tabla>` | Tabla Supabase espejo 1:1 de un Data Type Bubble |
| `SUP_<col>` | Columna solo existe en Supabase, no en Bubble |
| `BUB_<col>` | Columna en Bubble Data Type (se propaga al espejo) |
| `last_edit_source` | Field/columna marker anti-rebote canónico desde F0 (valor: `notion`, `clickup`, `bubble`, `user`, `cron`). Reemplaza al legacy `updated_by`. |

### IDs y URLs críticos
- **Supabase cbi**: `cbixhqjsnpuhcrcjppah` (eu-west-1) — OPERATIVO
- ~~**Supabase maw**: `mawpgbtdvskmneqqcqag` (eu-central-1)~~ — INACTIVE desde mayo 2026. Cualquier ref a maw en docs es histórica; no operacional.
- **Agencia UUID**: `e748c7d4-5823-413d-8cb3-532896f6e41d`
- **n8n instancia**: `https://n8n-n8n.irzhad.easypanel.host`
- **n8n project TheNucleo**: `cehv5Dib1J6eKwYQ`
- **Bubble live**: `portal.thenucleo.com` · **Bubble dev**: `app-the-nucleo-agency.bubbleapps.io`
- **Bubble API token**: `088a20b5465b6fa2cb8fbba67f250a79`
- **Notion DB TAREAS**: `b67f8416-322f-4761-ba36-40b938ae9387`

---

## Sectores

| # | Sector | Estado | Doc |
|---|---|---|---|
| 1 | **Tareas** (Notion ↔ Bubble ↔ Supabase) | ✅ REFACTORIZADO. Pendiente verificación (tests 1-4) | [[01-tareas]] |
| 2 | **Clientes** (Notion ↔ Bubble ↔ Supabase) | ⏳ PENDIENTE AUDITAR | [[02-clientes]] |
| 3 | **AutoSYNC Reconciliaciones** | ⏳ PENDIENTE AUDITAR | [[03-autosync-reconciliaciones]] |
| 4 | **Chat Newsletter IA** (co-creativo) | ⏳ PENDIENTE VERIFICAR POST-CBI | [[04-chat-newsletter]] |
| 5 | **Chat Cerebro IA** (consulta) | ✅ MIGRADO A CBI (2026-04-21). Task list de pruebas E2E pendiente | [[05-chat-cerebro]] |
| 6 | **Chat Tareas** | ❌ ELIMINADO (confirmado por Ben 2026-04-25). UI no existe en Bubble. Workflows huérfanos `RPdNg5ZNXK0VrOhG` y `aGML9yyMsoAQ6ZGL` pendientes de archivar en n8n | — |
| 7 | **Análisis Estratégico Cliente** (chat co-creativo) | ✅ E2E OPERATIVO (2026-04-25) — Supabase cbi ✅ + 6 workflows n8n activos (`dtgF0G35aeJQVVfn`, `FFhkdTFCjTtfyvhP`, `Cfs3NFEE1enu1jTx`, `JtXdkXHm6RyGOJft`, `QW8VZ9cV5ECsSKvZ`, `V60MieFkQzOszxhh`) + Bubble (9 API Connectors auditados 2026-04-22/23) | [[07-analisis-cliente-conversion]] |

---

## Transversales (no son sector pero tocan todos)

- **`FGxG67I24POOUeHW`** (SYNC ABSOLUTO Bubble → Supabase espejo) — cubre 19 Data Types, crítico. Solo hace UPSERT (no DELETE). Revisar si alguna vez se extiende para DELETE.
- **`HRDQ9Ju4NAIUV0qyhKzlz`** (Error handler) — capture de errores para Ops Monitor.
- **Backend workflows Bubble** — existen uno por Data Type bidireccional, disparan SYNC ABSOLUTO + opcionalmente el sync al organizador externo.
- **Control campañas** (`workflow_executions` en cbi) — leer este para diagnóstico de fallos.

---

## Pendientes urgentes (bloqueantes antes de nuevos sectores)

### Claude — al retomar
- Preguntar qué sector abordar.
- Aplicar el patrón establecido en Tareas (sector 1) como plantilla para los siguientes bidireccionales (Clientes sector 2).

---

## Decisiones arquitectónicas cerradas (NO replantear)

- Bubble es el hub, NO Supabase.
- `bub_*` tablas en cbi son canónicas.
- `FGxG67I24POOUeHW` es transversal y cubre todos los Data Types bidireccionales.
- Hoy Bubble es read-only para tareas (usuario no edita/borra). El workflow `SYNC Tarea Bubble → Notion` queda desactivado hasta que se habilite edición en Bubble.
- Marker anti-rebote canónico: `last_edit_source = <origen>` (ej: `notion`, `clickup`, `bubble`, `user`, `cron`). El legacy `updated_by` queda en `bub_tareas_notion` solo por compat — no usar para nuevos flujos.
- Convención `SUP_`/`BUB_` solo para columnas NUEVAS (no renombrar históricas).
