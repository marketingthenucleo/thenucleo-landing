---
title: portal/integraciones/ — Sistemas externos del Portal
dominio: portal
estado: vivo
actualizado: 2026-05-21
tags: [hub, portal, integraciones]
---

# portal/integraciones/ — Sistemas externos conectados al Portal

Integraciones de terceros que el Portal consume. Cada doc cubre el sistema, los workflows n8n que lo orquestan, y los puntos de conexión con Bubble/Supabase.

> **Nota:** estas integraciones **viven en el Portal** (no son transversales). Antes del 2026-05-20 estaban en `docs/integraciones/` como dominio aparte; se movieron aquí para reflejar que solo alimentan al Portal. [[../../addons/README|Addons]] es la excepción cross-domain (Portal + Work) y vive en `docs/addons/`.

## Documentos

| Archivo | Sistema | Estado | Cuándo consultarlo |
|---|---|---|---|
| [[clickup]] | ClickUp (tareas + clientes) | Multi-provider plan v3 opción C híbrida. F2.F y F3 pendientes | Antes de retomar refactor multi-provider Notion+ClickUp |
| [[google-chat-log]] | Google Chat (captura actividad) | Operativo desde 2026-05-08, rollout multi-espacio 2026-05-09 | Antes de tocar workflows `8snJvdNsmRM2yI2y` / `xzNDkDNiUOYOA2Ku` o tabla `bub_actividad_diaria_log` |
| [[google-chat-dm-urgentes]] | Google Chat (DM al @mencionado) | ⚠️ Planificado, 5 fases | Antes de implementar Fases 0–4 del plan |
| [[control-de-campanias]] | Meta Ads + Google Ads | Meta Ads v2 F0+F1 ✅ (5 workflows + 11 RPCs + 7 tablas `ads_*`). Intra-día Google+Meta unificado 2026-05-21 | Antes de tocar workflows `hwKBGC6QWP2dFObT` / `VhlqAQ1vH9HldpH5` / `pIxC6RNqHISWvpoU` / `Uqv3R3txzcg8GI1B` (legacy `BCgSCKjzryYaFYMC` ⏸) / `sNpVWEkinc4g0KfA`, schema `ads_*`, o construir Google Ads |

## Otras integraciones sin doc dedicado

Algunas integraciones del Portal viven solo en `n8n-workflows` + `bubble-api-connectors` (ambos en [[../../infra/README|infra/]]):

- **Notion** — gestor tareas + clientes (workflows `GjijIDEUyiH05Mg0`, `FcTmv78nLjbCb2Ea08qbt`, `wvHcgVqqjkWJcJDu`)
- **Clockify** — tiempo trackeado (workflow `ccPQuZmH7DGYRRbe` CRON 23:00 Madrid)
- **Holded** — facturación (workflow `vI3TbyxtFM6wjhBS`)
- **GHL** — CRM (Ajustes + Bubble API Connector, sin n8n)
- **Google Drive** — carpetas cliente automáticas (workflow `wvHcgVqqjkWJcJDu` + subworkflow `d0B4LokmPhHWdg6g`)
- **Evolution API** — WhatsApp (sin doc dedicado todavía)

## Cross-refs

- **Hub Portal:** [[../README|portal/README]] — vuelve aquí desde la lista de docs del Portal.
- **Stripe / Addons** (cross-domain): [[../../addons/README|addons/]] vive fuera de Portal porque también toca el flujo signup de Work.
