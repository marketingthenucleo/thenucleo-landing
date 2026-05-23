---
title: MOC — Mapa General
dominio: hub
estado: vivo
actualizado: 2026-05-20
tags: [moc, hub, indice]
---

# 🧭 MOC — TheNucleo

Mapa de contenido (Map of Content) del vault. Punto de entrada visual para navegar toda la documentación. Para el índice escrito clásico ver [[README|docs/README]].

> **Nota grafo:** este nodo solo enlaza a los hubs raíz + hubs de dominio. Para llegar a un doc hoja, entra por su hub (`work/README`, `portal/README`, `infra/README`, `portal/integraciones/README`, `addons/README`). Esto mantiene la jerarquía visible en Graph View.

## Hubs raíz

- [[CLAUDE]] — Visión general del proyecto, stack, secciones, reglas de trabajo
- [[README|docs/README]] — Índice oficial de documentación
- [[log-cambios]] — Historial cronológico inverso

## Hubs de dominio

- [[work/README|Work]] — Cara pública (work.thenucleo.com): Landing, Pricing, Blog Zenyx, Comunidad, Playbook, Fichas, Casuísticas, Disponibilidades
- [[portal/README|Portal]] — Interno Bubble (portal.thenucleo.com): 9 secciones, registro SaaS, chats co-creativos, sectores, integraciones del Portal (ClickUp, Google Chat, Meta Ads)
- [[infra/README|Infra]] — Transversal técnico: Supabase schema, n8n workflows, Bubble API, IDs/credenciales
- [[addons/README|Addons]] — Sistema de pago addons (cross-domain Portal + Work signup): Stripe Coupons, Bubble catalog, deploy F3

## 🟢 Activo / 🟡 En construcción / 🔴 Bloqueado

```dataview
TABLE estado, dominio, actualizado
FROM "docs"
WHERE estado != null
SORT estado ASC, dominio ASC
```

## Documentos por dominio

```dataview
TABLE WITHOUT ID file.link AS "Doc", estado, actualizado
FROM "docs"
WHERE dominio != null
SORT dominio ASC, file.name ASC
GROUP BY dominio
```

## Trabajos en construcción

```dataview
LIST estado
FROM "docs"
WHERE estado = "en-construccion"
SORT actualizado DESC
```

## Notas sin frontmatter (limpiar / clasificar)

```dataview
LIST
FROM "docs"
WHERE dominio = null
SORT file.name ASC
```
