---
title: Demo Quasar — agencia demo multitenant en LIVE
dominio: portal
estado: activo
actualizado: 2026-05-25
tags: [portal, demo, multitenant]
---

# Demo Quasar — agencia demo multitenant en LIVE

Agencia ficticia "**Demo Quasar**" creada en Bubble LIVE el 2026-05-25 como demo del producto sin tocar la operativa de TheNucleo Agency. Convive en paralelo gracias a que el Portal Bubble ya filtra por `agencia_id` en todas las queries que enseñan datos de cliente.

> ⚠️ La cuenta admin Demo opera **EXCLUSIVAMENTE desde el Portal Bubble**. NO entrar con ella en `work.thenucleo.com/*` — las páginas admin tienen allowlist hardcoded de 5 emails @thenucleo.com y devuelven `forbidden`.

## IDs canónicos

| Concepto | Valor |
|---|---|
| `bub_agencia.bubble_id` | `1779722662984x539340237197417400` |
| `bub_agencia.uuid_supabase` | `bea972de-6499-4086-b8de-57e8ed2d42a7` |
| `bub_agencia.nombre` | `Demo Quasar` |
| Email admin (a crear en Bubble UI) | `demo.admin@demoquasar.com` |

## Los 3 clientes Demo (creados via Bubble Data API)

| Nombre | bubble_id | notion_id (fake) | sector | niveles |
|---|---|---|---|---|
| Quasar Software | `1779722839720x580126292749689300` | `e83410ee-2eeb-4e87-87f4-260ebbffab83` | SaaS | Genera primeras ventas |
| Quasar Shop | `1779722940492x447696635447994750` | `b5ddc58a-1956-4f61-bbfa-f79efd5465ae` | Infoproductos | Campañas lanzadas |
| Quasar Studio | `1779722945472x798638472515837600` | `b97dcd3e-5c36-4a65-8a68-e053f3d3f4ee` | Agencia de Marketing | Cliente estable |

Cada cliente tiene datos fake desde el momento de creación: razón social ficticia (Quasar X SL), CIF formato español (B12345674 / B98765431 / B45678912), emails @demo.local, teléfonos +34 600 X00 X00, direcciones genéricas, contacto personal "Ana/Marcos/Carla Demo". El sync `wvHcgVqqjkWJcJDu` se pausó durante el alta + PATCH de notion_id para evitar que se crearan Drive folders y páginas Notion reales en TheNucleo.

## Datos operativos clonados a la agencia Demo

Insertados directamente en Supabase con `agencia_id = bea972de-6499-4086-b8de-57e8ed2d42a7`. No tocan las tablas espejo `bub_*` (el espejo las pisaría desde Bubble).

| Tabla | Filas Demo | Detalle |
|---|---|---|
| `chat_conversations` | 3 | 1 por cliente, tipo `analisis_<notion_id>`, estado `active` |
| `analisis_wip` | 3 | 1 por conv, estado `completado`, briefing 12 secciones + 4 segmentos prellenados |
| `chat_messages` | 15 | 5 por conv, sintéticos (greeting agent → user reto → agent estructura → user diferencial → agent buyer persona). Cero PII de TheNucleo |
| `clockify_time_entries` | 75 | 25 por cliente, distribuidos en últimos 30 días, 5 usuarios Demo, mezcla facturable/no, ~24h por cliente |
| `holded_facturas` | 18 | 6 por cliente, distribuidas en últimos 6 meses, estados mezclados (paid/pending/overdue), numeración `DEMO-XXXX`, total ~45.000€ |
| `holded_metricas` | 6 | 1 por mes, MRR creciente 5.500→7.750€, 3 clientes activos, gastos detallados (herramientas/freelancers/ads/oficina) |

**Mes actual (Demo, vía `finanzas_metricas_mes`):** MRR 7.750€, ingresos 11.276€, gastos 6.696€, margen 4.050€, 3 clientes activos, ticket medio 3.650€, 0 impagos.

## Operativas que se pueden hacer en la demo

- Login en Portal Bubble como `demo.admin@demoquasar.com` → ve los 3 clientes Quasar, sus métricas Clockify, sus facturas Holded, sus análisis estratégicos completos con conversación visible.
- **Crear nuevos chats Análisis** desde cero (en Bubble UI → Cliente → Análisis): funciona porque `get_or_create_conversation` filtra por `agencia_id`. Los nuevos análisis quedan automáticamente bajo `bea972de-...`.
- **Crear nuevas Newsletter** desde cero: idem, `newsletter_wip` ya filtra por agencia.
- **No funciona** (intencionalmente): Ficha Cliente / Playbook / Casuísticas / Disponibilidades de `work.thenucleo.com/*` porque están protegidos por allowlist 5 emails y `demo.admin` no está incluido.

## Cómo crear el user admin (PASO PENDIENTE para Ben)

En Bubble UI (NO via API, signup requiere endpoint dedicado):

1. Login como Ben en Bubble Editor.
2. Data → `User` → `New Thing`.
3. Campos:
   - email: `demo.admin@demoquasar.com`
   - password: definir uno (anotar en 1Password / similar)
   - `agencia_id`: `1779722662984x539340237197417400`
   - `Nombre`: `Demo Admin`
   - `rol`: añadir `Admin_agencia`
   - `nivel_acceso`: `4`
4. En `bub_agencia` fila Demo Quasar → campo `Admin` → añadir el bubble_id del user recién creado.
5. Probar login en `portal.thenucleo.com` con esas credenciales.

## Mantenimiento automático — Rolling refresh semanal (cbi)

Para que las fechas de la demo siempre se vean "actuales" (no aparezcan vacías por filtros tipo "últimos 30 días" al pasar el tiempo), hay un workflow n8n CRON que rota las fechas cada lunes.

- **Workflow:** `Z9Mp78CHNeuEwtCc` — *CRON DEMO — Rolling Refresh Fechas (Lunes 03:00)* — ACTIVO desde 2026-05-25 (era daily → cambiado a weekly el mismo día por decisión Ben).
- **Trigger:** Schedule weekly, lunes 03:00 Europe/Madrid.
- **Acción:** POST a `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/rpc/demo_rolling_refresh` con headers service_role (`$env.SUPABASE_SERVICE_ROLE_KEY`).
- **Función RPC `demo_rolling_refresh()`** (SECURITY DEFINER, grant a `service_role` + `authenticated`):
  1. Calcula `delta_days = CURRENT_DATE - max(fecha_inicio::date)` de las Clockify seed.
  2. Si `delta_days <= 0` → no-op (`status=skipped, reason=already_fresh`). Idempotente.
  3. Si > 0 → UPDATE:
     - `clockify_time_entries`: `fecha_inicio/fecha_fin += delta_days` (filtro `tag='demo'`).
     - `holded_facturas`: `fecha/fecha_vencimiento += delta_days` (filtro `tag='demo'`).
     - `chat_conversations`: `created_at/updated_at += delta_days` (filtro `metadata.seed='demo'`).
     - `chat_messages`: idem para los mensajes de esas conversations.
     - `analisis_wip`: idem (filtro `cliente_id IN` los 3 notion_ids fake).
  4. **Regenera** `holded_metricas` completas (DELETE + INSERT 6 últimos meses desde NOW()).
  5. Devuelve `{status:'ok', delta_days, rows: {...}}`.

**Datos que NO se mueven (intencionalmente):** lo que crees TÚ en la demo (chats nuevos, análisis nuevos, facturas que metas a mano) no lleva `tag='demo'` ni `metadata.seed='demo'`, así que el rolling no los toca. Persisten tal cual.

**Importante — qué NO mueve el CRON:** las fechas que viven en Bubble (`bub_clientes.fecha_onboarding`, `bub_clientes.ultimo_seguimiento`, `Created Date` interno) NO se tocan automáticamente porque son espejo desde Bubble. Si las modificara en cbi, el siguiente sync `FGxG67I24POOUeHW` las pisaría. **Estado actual (set 2026-05-25):** Quasar Software onboarding=2025-11-25 + seguimiento=2026-05-18 (hace 6m/7d); Quasar Shop 2026-01-25 + 2026-05-11 (hace 4m/14d); Quasar Studio 2026-03-25 + 2026-05-22 (hace 2m/3d).

**Por qué no se metió esto en el CRON automático:** cada PATCH a `bub_clientes` dispara el sync `wvHcgVqqjkWJcJDu` que intentaría actualizar la página Notion del cliente, pero los Demo NO tienen Notion page real (UUIDs fake) → 3 fallos en `n8n_incidencias` cada semana. Solución elegida: refresh Bubble es **on-demand manual**. Pídelo cuando lo necesites ("refresca fechas Bubble Demo"); el operador pausa `wvHcgVqqjkWJcJDu`, hace 3 PATCH con fechas relativas a NOW(), reactiva. Toma ~30 segundos.

**Pendiente Ben:** añadir tag `portal` al workflow en la UI de n8n para que entre al backup automático en `marketingthenucleo/n8nthenucleo`.

**Disparo manual** (cuando quieras forzar refresh antes del CRON nocturno):

```sql
SELECT demo_rolling_refresh();
```

Devuelve JSON con `delta_days` aplicados y filas movidas por tabla.

## Cómo desmontar la demo (rollback completo)

```sql
-- En orden inverso (Bubble es source de bub_*, no se borra desde Supabase)
DELETE FROM chat_messages WHERE conversation_id IN (SELECT id FROM chat_conversations WHERE agencia_id = 'bea972de-6499-4086-b8de-57e8ed2d42a7');
DELETE FROM analisis_wip            WHERE agencia_id = 'bea972de-6499-4086-b8de-57e8ed2d42a7';
DELETE FROM chat_conversations      WHERE agencia_id = 'bea972de-6499-4086-b8de-57e8ed2d42a7';
DELETE FROM clockify_time_entries   WHERE agencia_id = 'bea972de-6499-4086-b8de-57e8ed2d42a7';
DELETE FROM holded_facturas         WHERE agencia_id = 'bea972de-6499-4086-b8de-57e8ed2d42a7';
DELETE FROM holded_metricas         WHERE agencia_id = 'bea972de-6499-4086-b8de-57e8ed2d42a7';
```

Luego en Bubble UI: borrar los 3 clientes Quasar + el user admin + la agencia Demo Quasar. El sync espejo limpia las filas `bub_*` automáticamente.

## Cómo regenerar la demo (reset)

Volver a ejecutar los 4 bloques INSERT del 2026-05-25 (ver `docs/log-cambios.md` entry de ese día). Los conteos son deterministas excepto los `random()` (clockify entries y montos facturas). Total reset: ~2 minutos.

## Riesgos vivos y mitigaciones

1. **Si alguien añade `demo.admin@demoquasar.com` al allowlist de work.com por error** → tendría acceso a `/ficha-cliente/` y vería los 78 clientes TheNucleo reales. Mitigación: el email tiene TLD `.local` (no routable) y no está documentado fuera de aquí. NO añadir a `EDITOR_EMAILS` en ninguno de los 7 sitios.
2. **Si se reactivan los workflows pausados pero no se desactivan después de cada operación** → al crear nuevos clientes Demo desde Bubble UI, `wvHcgVqqjkWJcJDu` creará Drive + Notion reales bajo el árbol TheNucleo. Mitigación: documentar que toda creación de clientes Demo se hace via API REST con el workflow pausado (script reutilizable en este doc).
3. **9 tablas single-tenant pendientes de multitenant** (`playbook_*`, `cliente_pipelines`, `cliente_campanias`, `cliente_triggers`, `cliente_emails`, `cliente_mensajes_whatsapp`, `cliente_creatividades`) — hoy no las consume el Portal Bubble, solo `work.com/ficha-cliente/` y `work.com/playbook/`. Quedan como deuda multitenant para cuando se cableen al Portal. Ver `~/.claude/plans/necesito-que-lo-planifiques-memoized-torvalds.md` para el plan futuro.
