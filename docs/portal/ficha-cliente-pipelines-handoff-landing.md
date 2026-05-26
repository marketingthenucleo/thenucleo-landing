---
title: Ficha Cliente — Handoff al repo landing para integrar módulo Pipelines
dominio: portal
estado: completado
actualizado: 2026-05-23
tags: [ficha-cliente, pipelines, handoff, landing, work, implementado]
---

# Ficha Cliente · Handoff a `thenucleo-landing` — módulo Pipelines y Campañas

> ✅ **COMPLETADO 2026-05-23.** El módulo se pusheó a `main` en `marketingthenucleo/thenucleo-landing` y Vercel desplegó automáticamente. Vivo en `work.thenucleo.com/ficha-cliente/` con datos seed hardcoded. Próxima fase: backend Supabase + RPCs (ver "Próxima fase F2" al final).
>
> Este documento queda como **referencia histórica** del brief que se le dio a la sesión Claude Code que hizo la implementación. Las restricciones, decisiones y reglas operacionales descritas aquí siguen siendo válidas para evolucionar el módulo.

Documento puente entre la sesión de visión operacional (este repo, `thenucleo-vault`) y la implementación frontend (otro repo, `marketingthenucleo/thenucleo-landing` que sirve `work.thenucleo.com`).

## Entregables de la sesión (origen)

| Archivo | Repo | Para qué sirve |
|---|---|---|
| [[ficha-cliente-operativa]] | `thenucleo-vault` | Visión operacional completa: 3 capas (Cliente/Pipeline/Campaña), nomenclatura PxCx, catálogo abierto de Plantillas, flujo Account→PM→Equipo, casos casuísticos del `.docx`. **Fuente de verdad funcional.** |
| [[account-manual-pipelines]] | `thenucleo-vault` | Manual operativo para Account en lenguaje plano. Acompaña a Melina al usar la nueva ficha. No es spec técnica. |
| `Design/mockups/ficha-cliente-v2/index-v3.html` | `thenucleo-vault` (gitignored, entrega aparte) | Mockup standalone del módulo aislado. React+Tailwind CDN. Pegado a fuentes (sin invenciones). |
| `Design/mockups/ficha-cliente-v2/index-integrado.html` | `thenucleo-vault` (gitignored, entrega aparte) | Mockup del módulo **dentro de la ficha completa** (Datos / Servicios / Pipelines / Catálogos MOCKUP / Anomalías MOCKUP). Es lo que la otra sesión Claude debe replicar. |
| `~/.claude/plans/root-claude-uploads-c0a7cf67-b3ea-4549-humble-stearns` | local (no en repo) | Plan operacional con modelo de datos Supabase propuesto. Lo guarda Ben fuera del repo. |

## Misión para la sesión de `thenucleo-landing`

Reemplazar el placeholder MOCKUP de "Pipelines" en `thenucleo-landing/ficha-cliente/index.html` por el módulo real (con datos seed hardcoded — el backend Supabase es otra fase posterior).

**Catálogos** y **Anomalías** siguen como MOCKUP. No se tocan.

## Restricciones técnicas

1. **Solo UI, sin backend.** No crear tablas Supabase (`cliente_pipelines`, `cliente_campanias`, `cliente_triggers`, `cliente_emails`). No crear RPCs nuevas. No tocar `ficha_cliente_get` / `ficha_cliente_listar`. Eso es F2.
2. **Stack del repo.** Si la página actual es vanilla JS (estilo `playbook/`, `casuisticas/`), portar el mockup a vanilla. Si ya es React/Tailwind, mantener como en el adjunto.
3. **Paleta TheNucleo**: `#0c0d12` fondo, `#13151c` card, `#1e2130` borde, `#edeef3` texto, `#22c55e` verde. Font New Black donde corresponda.
4. **Mobile-first** (como el resto de la ficha).
5. **admin-only** — reusar el gate de auth ya existente (allowlist `is_comunidad_admin()` o equivalente).
6. **No introducir paneles ni campos que no estén en el mockup** ni en `ficha-cliente.md`. La sesión origen ya hizo el ejercicio de quitar invenciones — respetarlo.

## Qué portar del mockup

El mockup tiene 4 piezas lógicas. Portarlas todas:

1. **Árbol Pipelines → Campañas → Triggers + Emails** (sidebar izquierdo, ~260px desktop; colapsa a top en mobile).
2. **Panel detalle** con 4 vistas según selección: Pipeline / Campaña / Trigger / Email. Inline editing en modo Account.
3. **Drawers** sliding desde la derecha:
   - Nuevo Pipeline.
   - Nueva Campaña (modal único, **no wizard**, con selector de plantilla del catálogo + opción "Sin plantilla / Custom" + botón "+ Nueva plantilla" arriba).
   - Nueva Plantilla.
   - Crear tareas Notion (genera tareas con código forzado a partir de la plantilla).
4. **Toggle "Mostrar archivados"** en sidebar (regla `.docx` caso 9: códigos no caducan).
5. **Switch Account / PM** arriba (Account = edición completa, PM = lectura + CTA destacado "Crear tareas Notion" por Campaña).

## Reglas operacionales que el módulo debe respetar

Vienen del `.docx` de nomenclatura y están implementadas en el mockup. **No cambiarlas**:

- **Generador de código del email** (regla caso 5): si un email aplica a todos los triggers de su Campaña → código sin trigger (`P2C1E1`). Si aplica a subset → código con triggers concatenados ordenados FM→FW→BD (`P2C1FM1FW1E1`). La función `emailCode(camp, email)` del mockup lo implementa.
- **Estados permitidos**: solo `declarada`, `en-produccion`, `archivada`. Nada más.
- **Triggers tipo BD** requieren `fechaLanzamiento` (aviso visible si falta).
- **Creatividades** (estáticos/reels/carruseles/copies RRSS) NO se listan en la ficha — viven en Drive con nomenclatura `PxCx_<tipo>_v<n>`. El mockup tiene un bloque informativo en cada Campaña explicándolo. **No crear sección "Creatividades" en la ficha.**
- **Versionado de emails** (regla caso 7): el código no cambia al modificar, se versiona en Drive (`P1C1E2_v2_copy.docx`). El mockup lo refleja en el detalle del email.

## Datos seed (hasta que exista backend)

Hardcoded en JS, igual que en el mockup adjunto: 4 pipelines de Dra. Neuss (P1 Venta directa curso, P2 Captación leads, P3 Reactivación, P4 Newsletter mensual). Igual que viene.

## Lo que NO hay que hacer en esta fase

- ❌ Crear tablas Supabase ni RPCs.
- ❌ Tocar `ficha_cliente_get` / `ficha_cliente_listar`.
- ❌ Tocar "Catálogos" ni "Anomalías" (siguen MOCKUP).
- ❌ Inventar campos que no estén en el mockup ni en `ficha-cliente.md` (no "Canal principal", no estados intermedios).
- ❌ Conectar el botón "Crear tareas Notion" al formulario Bubble — emite un toast por ahora.

## Criterio de aceptación

1. Abrir `work.thenucleo.com/ficha-cliente/?id=1773847038522x983519237604638700` (Dra. Neuss).
2. Debajo de "Servicios contratados" aparece "Pipelines y Campañas" con los 4 pipelines seed.
3. Switch Account/PM funciona — en PM desaparecen botones "+" y aparece CTA destacado "Crear tareas Notion" en cada Campaña.
4. Drawers abren con animación desde la derecha; formularios responden.
5. Toggle "Mostrar archivados" filtra.
6. Mobile (sidebar arriba, detalle abajo) legible.
7. Catálogos y Anomalías siguen con badge MOCKUP visible.
8. Auth admin-only sigue gatekeeping (email no admin → 403).

## Documentación a actualizar al cerrar

Repo `thenucleo-landing`:
- Su `CLAUDE.md` — anotar que el módulo Pipelines vive en frontend con seed; pendiente backend.

Repo `thenucleo-vault` (pedirle a Ben que abra sesión aquí o lo hace él):
- [[secciones-app#ficha-cliente]] — actualizar la línea "Pipelines / Catálogos / Anomalías marcados como MOCKUP" para reflejar que Pipelines pasó a real con seed.
- [[../log-cambios|docs/log-cambios]] — entrada `[WORK]` del cambio.

## Próxima fase (F2 — no en este handoff)

Backend del módulo:

- Tablas Supabase: `cliente_pipelines`, `cliente_campanias`, `cliente_triggers`, `cliente_emails`, `cliente_campania_plantillas` (catálogo abierto).
- RLS allowlist (mismo patrón `is_comunidad_admin()` que el resto de la ficha).
- RPCs: `ficha_pipelines_get(p_bubble_id)`, `ficha_codigos_catalogo(p_bubble_id)`, `ficha_pipeline_upsert`, `ficha_campania_upsert`, `ficha_trigger_upsert`, `ficha_email_upsert`, `ficha_archivar_codigo`.
- Ampliar `ficha_cliente_get` para incluir `pipelines: ficha_pipelines_get(p_bubble_id)` en el jsonb.
- Cablear frontend a las RPCs (sustituir seed).
- Dropdown forzado de código en formulario Bubble "Crear tarea" (workflow `eHyXBETcaGSNXqLk`).

Eso queda para otra sesión, con el frontend ya validado por Melina.
