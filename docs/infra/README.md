---
title: infra/ — Plataforma técnica (transversal)
dominio: infra
estado: vivo
actualizado: 2026-05-20
tags: [hub, infra]
---

# infra/ — Plataforma técnica

Capa transversal que alimenta tanto a [[../portal/README|Portal]] como a [[../work/README|Work]]. Aquí vive el schema canónico, los workflows n8n, las API calls Bubble y los IDs/credenciales.

## Documentos

| Archivo | Para qué sirve | Cuándo consultarlo |
|---|---|---|
| [[ids-referencias]] | IDs Supabase, credenciales n8n, tokens Bubble, UUIDs clave | Antes de cualquier llamada API o integración |
| [[supabase-schema]] | Schema completo `cbixhqjsnpuhcrcjppah` (cbi): ~40 tablas espejo `bub_*` + operativas (chat, comunidad, RAG, addons, blog, ads), vistas, RPCs, triggers, RLS | Al escribir SQL, modificar esquema, diagnosticar datos |
| [[n8n-workflows]] | Mapa de los ~46 workflows del Portal (tag `portal`) + **anti-patrones** | Al crear/editar cualquier workflow. **Revisar anti-patrones siempre** |
| [[bubble-api-connectors]] | 59 API Connector calls en 12 grupos activos (todas auditadas 2026-05-14) | Al tocar integraciones Bubble ↔ backend |

## Decisiones arquitectónicas (no negociables)

- **Bubble es el hub de datos** (decisión 2026-04-21). Notion/ClickUp son fuentes externas que sincronizan bidireccionalmente con Bubble vía workflows n8n.
- **Supabase cbi es destino canónico y único.** Espejo `bub_*` 1:1 vía workflow `FGxG67I24POOUeHW` (SYNC ESPEJO — Bubble → Supabase). Proyecto histórico `mawpgbtdvskmneqqcqag` está INACTIVE — no usar.
- **Anti-rebote bidireccional:** field `last_edit_source` + tabla `sync_suppress` (ventana 30s).
- **Discriminador multi-provider:** `bub_agencia.proveedor_tareas` (XOR notion/clickup por agencia).
- **Agencia identificadores:** `bubble_id` para Data API y filtros de vistas. `uuid_supabase` solo para algunas RPCs internas.
- **Credenciales:** siempre por ID en n8n, nunca hardcoded.
- **SQL functions:** prefijo `p_` en parámetros.
- **Vistas críticas:** `v_tareas_panel` (Notion) la reconstruye Ben manualmente, no tocar sin OK.

## Reglas de seguridad

- n8n usa `service_role` (bypass RLS). Bubble usa `anon` (sujeto a RLS).
- RLS activo: todas las `bub_*` + operativas con datos sensibles.
- Sin RLS: `chat_*` (pendiente D3). Con RLS sin policies (deny-all anon/auth, service_role bypass): `activity_log`, `blog_videos`, `cliente_external_links`, `provider_webhooks`, `sync_suppress`.
- Fallos silenciosos de PATCH Bubble → primer check siempre = RLS policies.
- `DROP VIEW IF EXISTS` antes de cualquier rename/type change en columnas de vistas.

## Cross-refs

- **Consumidores:** [[../portal/README|portal/]] (lectura+escritura — incluye `portal/integraciones/` para ClickUp/Meta/GChat) y [[../work/README|work/]] (lectura nativa Supabase, escritura via Edge Functions).
- **Cross-domain especial:** [[../addons/README|addons/]] (sistema de pago Stripe que toca Portal Ajustes y Work signup).
