---
title: Sector — AutoSYNC
dominio: sectores
estado: activo
actualizado: 2026-05-08
tags: [sector, autosync, reconciliaciones]
---

# Sector 3 — AutoSYNC / Reconciliaciones

**Estado:** ⏳ PENDIENTE AUDITAR. Carpeta parent que contiene CRONs de reconciliación transversales.

---

## Scope

AutoSYNC es una carpeta parent (`q3rr4KiKriY4bcfi`) en n8n que agrupa:
- SYNC Tareas (ya auditado → sector 1)
- SYNC Clientes (sector 2)
- Reconciliaciones (`kRqR09PKYfk1dAkD`) — subcarpeta con CRONs de salud de datos

Este sector cubre **solo las Reconciliaciones** transversales que no son específicas de un Data Type.

---

## Arquitectura del sector

Los workflows de reconciliación son "safety nets" periódicos que:
1. Escanean el estado actual en Notion / Bubble / Supabase
2. Detectan desfases o huérfanos
3. Corrigen el estado aplicando el origen master

Con la arquitectura A confirmada (Bubble es hub, Supabase es espejo), muchos workflows de reconciliación 3-capas son obsoletos. Lo que sigue aplicando:

- **Huérfanas por Data Type**: safety net individuales (ya creado para Tareas: `ZqccS38F2Lz8WFwX`).
- **Reconciliación sync espejo**: detectar Data Type que quedó desfasado del espejo (probable redundante si `FGxG67I24POOUeHW` no falla).
- **Reconciliación cross-Data Type**: detectar inconsistencias entre Data Types (ej: tareas con cliente_notion_id que no existe en `bub_clientes`).

---

## Capa Bubble

No aplica directamente. Los CRONs de reconciliación operan server-side entre Notion, n8n y Supabase. Bubble solo consume el resultado (datos corregidos).

---

## Capa Supabase cbi

### Tablas observadas por reconciliaciones
- `bub_tareas_notion`, `bub_clientes`, etc.
- `activity_log` — destino de logs de reconciliación (`accion='eliminada_huerfana'`, `accion='reconciliada_sync'`).
- `workflow_executions` — log de ejecuciones para Ops Monitor.

### Vistas potenciales de diagnóstico (no confirmadas)
- Vista que liste inconsistencias (si existiera).

---

## Capa n8n — Workflows del sector

### Archivados en sesión 2026-04-21
| ID | Nombre | Razón |
|---|---|---|
| `aX4Zo7SCTl45R4H5` | CRON Reconciliación Tareas (3-capas) | Arquitectura antigua |
| `ZOtpnTjojGyIjMHo` | LIMPIEZA duplicados | One-shot cumplido |

### Activos post-cbi (requieren verificación)
| ID | Nombre | Estado esperado |
|---|---|---|
| `ZqccS38F2Lz8WFwX` | CRON TAREAS — Reconciliar Huérfanas Notion (reescrito) | Pendiente activar |
| (otros) | A identificar |

### Candidatos a crear (si se detecta necesidad)
- CRON Huérfanas Clientes (cuando se aborde sector 2).
- CRON de integridad referencial: detectar tareas con `cliente_notion_id` fantasma, clientes sin tareas tras X días, etc.
- CRON de consistencia espejo ↔ Bubble: si por caso rarísimo `FGxG67I24POOUeHW` pierde un evento, este CRON re-sincroniza.

---

## Preguntas abiertas (resolver al auditar)

- ¿El `FGxG67I24POOUeHW` (SYNC ESPEJO) es fiable al 100% o necesita una reconciliación CRON periódica?
- ¿Hay algún CRON de "auditoría de integridad" que detecte inconsistencias entre Data Types Bubble (ej: tareas con cliente inexistente)?

> **Resuelto 2026-05-07:** todos los CRONs operativos apuntan a `cbi` (proyecto único). maw INACTIVE desde mayo 2026.

---

## Plan de ejecución (cuando se aborde)

1. Listar todos los workflows con trigger `scheduleTrigger` en el proyecto que no estén clasificados en sectores 1-7.
2. Inspeccionar cada uno:
   - ¿Es redundante con la arquitectura actual?
   - ¿Útil como safety net?
3. Decidir por workflow: mantener / reescribir / archivar.
4. Si hace falta, crear nuevos CRONs para cubrir casos no contemplados.

---

## Nota al retomar

Antes de abordar este sector, completar Tareas (sector 1) y Clientes (sector 2). Las reconciliaciones dependen de que los flujos base estén estables.
