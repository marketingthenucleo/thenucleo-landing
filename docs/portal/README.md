---
title: portal/ — Portal interno Bubble (portal.thenucleo.com)
dominio: portal
estado: vivo
actualizado: 2026-05-26
tags: [hub, portal, bubble]
---

# portal/ — Portal interno (portal.thenucleo.com)

App Bubble (no-code) servida en dos URLs (`portal.thenucleo.com` custom + `app-the-nucleo-agency.bubbleapps.io`). Distinción dev/live por path: `/api/1.1/obj/...` = live, `/version-test/api/1.1/obj/...` = dev.

## Documentos

| Archivo | Para qué sirve | Cuándo consultarlo |
|---|---|---|
| [[secciones-app]] | Detalle funcional de las 9 secciones (8 internas + 1 pública) | Para entender qué hace cada pantalla del Portal |
| [[ficha-cliente-operativa]] | Visión operacional de la Ficha de Cliente v2: 3 capas (Cliente / Pipeline / Campaña), nomenclatura PxCx, catálogo abierto de Plantillas, flujo Account→PM→Equipo | Al rediseñar la ficha pública admin-only para que Account vuelque Pipelines/Campañas y la PM distribuya con código forzado |
| [[pipelines-presentacion]] | 📣 Presentación en 1 página del cambio para Account + PM + Equipo. Antes/después, regla mental, 3 roles, 3 reglas, qué pasa si no se sigue, calendario | **Punto de entrada** del equipo al cambio · onboarding · alinear expectativas |
| [[account-manual-pipelines]] | Manual operativo en lenguaje plano para Account (Melina). 3 capas, reglas nomenclatura, flujo paso a paso, casuísticas comunes | Onboarding de Account · ante duda sobre cuándo usar plantilla / archivar / modificar |
| [[pm-manual-pipelines]] | Manual operativo para PM. Flujo diario (cómo identificar trabajo pendiente y gaps), cómo generar tareas Notion con código desde la ficha, **tabla maestra de reparto por rol**, verificación semanal, casuísticas | Onboarding de PM · cuando una Campaña esté lista para repartir |
| [[equipo-manual-pipelines]] | Manual operativo para el equipo ejecutor (Estratega · Copy · Diseño · Media Buyer · CRM). 6 pasos universales al recibir una tarea con código + secciones por rol con qué códigos llegan y dónde guarda cada entregable | Onboarding del equipo · cuando alguien empiece a recibir tareas con código PxCx |
| [[pipelines-roadmap]] | ⚠️ Roadmap auditoría 2026-05-24 del flujo Pipelines: qué está vivo (frontend seed), qué está en transición (account/PM manual) y qué bloquea F2 (backend Supabase + 4 tablas + RPCs). Inventario de TODOs por fase | Antes de empezar trabajo Pipelines F2 · alinear próximo milestone |
| [[ficha-cliente-pipelines-handoff-landing]] | ✅ Completado 2026-05-23. Histórico del brief que se usó para implementar el módulo en `thenucleo-landing` | Referencia para futuras evoluciones del módulo |
| [[flujo-registro-saas]] ⚠️ EN CONSTRUCCIÓN | Flujo SaaS multi-tenant: Stripe → n8n provision → Invitación → Registro | Antes de tocar signup/registro, Stripe webhooks, Agencia/Invitacion |
| [[chat-cocreativo-blueprint]] | Blueprint para chats IA co-creativos (Newsletter, Análisis): Bubble + n8n + Supabase + estados + checklist | Al construir un chat IA nuevo que genere artefacto en paralelo |
| [[notificaciones]] | Módulo Notificaciones (sección 9): schema, workflows, popup, RG dashboard, Privacy Rules con quirks Bubble | Al retomar mejoras: modal thread, mark as read, página `/notificaciones`, eventos sistema |
| [[demo-quasar]] | Agencia "Demo Quasar" multitenant en LIVE (datos seed anonimizados clonados desde TheNucleo). Convivencia con producción real | Al validar features multitenant · al editar la cuenta demo (no añadir a allowlists work.com) |
| [[sectores/README\|sectores/]] | Hub: auditoría funcional por área (Tareas, Clientes, Reconciliaciones, Chats IA, Análisis) | Al retomar refactor / auditoría de área funcional |
| [[integraciones/README\|integraciones/]] | Hub: sistemas externos que solo alimentan al Portal (ClickUp, Google Chat, Meta Ads, Google Ads) | Al tocar un sistema externo conectado al Portal |

## Las 9 secciones de la app

1. **Dashboard** (`/dashboard`) — KPIs globales
2. **Clientes** (`/clientes`) — Kanban + ficha + Chat Cerebro IA + Newsletter IA
3. **Operaciones** (`/operaciones`) — Kanban tareas (8 estados) + plantillas + Control Tiempo + Control Campañas Ads
4. **Finanzas** — Holded
5. ~~Comunidad~~ → MIGRADA 2026-04-28 a Work (`work.thenucleo.com/comunidad`, ver [[../work/README|work/]])
6. ~~Incidencias~~ → eliminada como sección independiente (panel en `work.thenucleo.com/incidencias`)
7. **Ajustes** — Config agencia, miembros, onboarding, integración GHL, addons (ver [[../addons/README|addons/]])
8. **Recursos Humanos** — Perfiles, NPS, departamentos
9. **Notificaciones** — sistema interno (1 emisor → N destinatarios con respuesta inline por destinatario). Ver [[notificaciones]]
10. **Soporte** — pendiente documentar
