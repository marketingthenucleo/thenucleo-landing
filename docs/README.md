---
title: Índice de Documentación
dominio: hub
estado: vivo
actualizado: 2026-05-20
tags: [hub, indice]
---

# docs/ — Índice de documentación TheNucleo

Punto de entrada para cualquier intervención técnica. Empieza por el dominio, luego abre el doc específico desde su hub.

**Reorganización 2026-05-13:** estructura domain-first reflejando el modelo mental Work/Portal/Infra/Integraciones. Cada dominio tiene su propio README hub. Wikilinks Obsidian siguen funcionando (usan nombre único, no path).

**Limpieza grafo 2026-05-20:** este índice ya no enlaza a docs hoja para mantener la jerarquía visible en Graph View. Para acceso directo a un archivo, entra por su hub de dominio.

---

## Modelo de organización

```
docs/
├── work/                       ← cara pública (work.thenucleo.com)
├── portal/                     ← interno Bubble (portal.thenucleo.com)
│   └── integraciones/          ← ClickUp, Google Chat, Meta Ads (viven en Portal)
├── infra/                      ← transversal técnico (Supabase, n8n, Bubble API, IDs)
└── addons/                     ← cross-domain Portal + Work signup (Stripe Coupons)
```

**Convención (revisada 2026-05-20):** Work y Portal son los **dos productos**. Infra es la capa transversal genuina (consumida por ambos). Addons es cross-domain real (Portal Ajustes + Work signup). Las integraciones que solo alimentan al Portal (ClickUp, Google Chat, Meta/Google Ads) viven dentro de `docs/portal/integraciones/`, no como dominio aparte. Cuando un cambio cruza dominios, va en el log con tags múltiples — ver [[log-cambios]].

---

## Hubs por dominio

| Dominio | Hub | Qué contiene |
|---|---|---|
| **Work** (público) | [[work/README\|work/README]] | Landing, Pricing, Blog Zenyx, Comunidad, Playbook, Fichas, Casuísticas, Disponibilidades |
| **Portal** (interno Bubble) | [[portal/README\|portal/README]] | 9 secciones app + flujo registro SaaS + chat co-creativo blueprint + sectores auditoría + integraciones del Portal |
| **Infra** (transversal técnico) | [[infra/README\|infra/README]] | Supabase schema, n8n workflows, Bubble API, IDs/credenciales |
| **Addons** (cross-domain) | [[addons/README\|addons/README]] | Sistema de pago addons (Stripe Coupons + Bubble catalog + deploy F3) |
| **Design Tokens** (cross-domain) | [[design-tokens]] | Paleta dual dark/light + mapping Bubble Styles ↔ CSS vars work. **Consultar siempre antes de hardcodear un hex.** |

---

## Trabajos en construcción

| Proyecto | Dominio | Estado |
|---|---|---|
| Flujo Registro SaaS (Stripe → Provision) | Portal | En construcción 2026-04-17. Arquitectura decidida. Workflows pendientes |
| Multi-provider Notion+ClickUp v3 | Portal | F0+F1+F2.A-E ✅. F2.F (onboarding Zenyx) y F3 (refactor 3 routers) pendientes |
| Sistema Addons (Bubble + Supabase + Stripe) | Addons | F1 ✅ cerrada 2026-05-04. F2 (sync cupones Stripe) y F3 (deploy) pendientes |
| DM Urgentes Google Chat | Portal | Planificado. Fases 0-4 |
| Control de Campañas v2 — Google Ads | Portal | Meta Ads F0+F1 ✅. Google Ads pendiente OAuth corporate |

Detalle y links a docs hoja en el hub de cada dominio.

---

## Troubleshooting rápido

| Síntoma | Dominio | Primer sitio a mirar |
|---|---|---|
| Tarea desfasada entre Notion / Supabase / Bubble | Portal+Infra | [[infra/README\|infra]] → `n8n-workflows` "Lecciones aprendidas" + workflows `GjijIDEUyiH05Mg0` + `ZqccS38F2Lz8WFwX` |
| Tarea ClickUp huérfana o desfasada | Portal | [[portal/README\|portal]] → `integraciones/clickup` + workflows `eR5SWFkxJmjMT1VI` + `kbUqzdSOrV7e2lS0` |
| Error de permisos en Supabase desde Bubble | Infra | [[infra/README\|infra]] → `supabase-schema` → RLS policies |
| Workflow n8n falla silenciosamente | Infra | Ops Monitor (Portal) + `workflow_executions` en cbi |
| Duplicados en Bubble por `notion_id` o `external_id` | Portal | [[infra/README\|infra]] → `n8n-workflows` anti-patrón #5 |
| Chat IA no responde o pierde contexto | Portal | [[infra/README\|infra]] → `n8n-workflows` sección Chat IA + skill `chat-ia-builder` |
| Blog Zenyx no publica | Work | [[work/README\|work]] → `blog-zenyx` "Operaciones comunes" + workflow `CNlBtiFCwY69I6Wl` |
| Comunidad: aprobada no aparece, login admin colgado, RLS errors | Work | [[work/README\|work]] → `comunidad` "Troubleshooting" + Edge Function `comunidad_admin_action` |
| Errores de workflows n8n en general | Infra | Panel `work.thenucleo.com/incidencias` + tabla `n8n_incidencias` (alimentado por `HRDQ9Ju4NAIUV0qyhKzlz`) |

---

## Historial de incidencias resueltas

| Fecha | Incidencia | Resolución |
|---|---|---|
| 2026-04-17 | Tareas Listo en Notion aparecían Backlog en Bubble. 41 duplicados. 1100 desincronizadas | 8 anti-patrones. Cron 3h → 30min. Limpieza one-shot |
| 2026-04-24 | Cron huérfanas abortaba en fila zombie | `onError: continueRegularOutput` + saneado IF. Anti-patrón #10 |
| 2026-04-26 | Blog Zenyx muere en `Parse Claude` por JSON.parse SyntaxError | Contrato Claude → tags XML. Anti-patrón #11 |
| 2026-05-02 | SYNC CLIENTES Notion→Bubble: 502 Cloudflare/Notion | `retryOnFail: true` en Notion Triggers |
| 2026-05-02 | Reconciliación huérfanas: timeout 5min | `retryOnFail` + `timeout: 30000` |
| 2026-05-04 | Reconciliación: IF chequeaba `statusCode` inexistente | Cambio a `$json.status`. Anti-patrón #13 |
| 2026-05-07 | Wrapper webhook respondía single object en vez de array | `Response Data: All Entries` + re-init Bubble |
| 2026-05-13 | Tarea Notion en `Listo` aparecía en Bubble `Backlog` (recidiva 2026-04-17 con otra causa). Latencia indexado Bubble Data API ~30-60s tras POST → falso negativo → segunda ejecución decide `create` | Lookup migrado a espejo Supabase (`bub_tareas_notion`, ~1-2s). Anti-patrón #17 |

Detalle completo de cada incidencia: ver [[log-cambios]] y `n8n-workflows` (en hub Infra).

---

## Antes de tocar algo crítico

1. Abrir el README hub del dominio afectado.
2. Leer la sección relevante.
3. **Para workflows n8n:** obligatorio revisar anti-patrones (en hub Infra → `n8n-workflows`).
4. Backup del JSON del workflow / schema antes de modificar.
5. Cambios incrementales, no en bloque.
6. Validar con corrida manual o query antes de activar.
7. **Workflows nuevos del Portal:** asignar tag `portal` antes de activar (sin tag, no entra al backup automático en `marketingthenucleo/n8nthenucleo`).

---

## Convenciones globales

- **Bubble es el hub de datos** (decisión 2026-04-21). Notion/ClickUp sincronizan bidireccionalmente con Bubble.
- **Supabase cbi (`cbixhqjsnpuhcrcjppah`) es destino canónico y único.** Proyecto histórico `mawpgbtdvskmneqqcqag` INACTIVE — no usar.
- **Anti-rebote bidireccional:** `last_edit_source` + `sync_suppress` (ventana 30s).
- **Discriminador multi-provider:** `bub_agencia.proveedor_tareas` (XOR notion/clickup).
- **Agencia identificadores:** `bubble_id` para Data API. `uuid_supabase` solo para algunas RPCs internas.
- **Credenciales:** siempre por ID en n8n, nunca hardcoded.
- **SQL functions:** prefijo `p_` en parámetros.
- **Vistas críticas:** `v_tareas_panel` (Notion) la reconstruye Ben manualmente, no tocar sin OK.
- **Workflows del Portal:** todos llevan tag `portal` (id `8JEzIL3gJwyclObr`).
