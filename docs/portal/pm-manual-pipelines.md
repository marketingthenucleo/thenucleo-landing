---
title: Manual de PM — Pipelines y reparto con código
dominio: portal
estado: vivo
actualizado: 2026-05-25
tags: [portal, pipelines, manual, pm, nomenclatura]
---

# Manual de PM — Pipelines, Campañas y reparto de tareas con código

Audiencia: PM (Melina y quien venga). Lectura: 8 minutos. Acción: 10 minutos diarios + 5 minutos por Campaña que reparte.

> Antes de leer esto, ten leído [[pipelines-presentacion|la presentación del cambio en 1 página]] y [[account-manual-pipelines|el manual de Account]]. Tu manual cuenta tu mitad de la operación; necesitas saber qué hace Account para repartir bien.

## 0. Por qué este manual existe

Tu trabajo hoy es el cuello de botella del equipo. Eres la única persona que tiene el mapa completo de cada cliente en la cabeza, traduces lo que cuenta Account a tareas concretas y repartes. Si te pones enferma o sales de vacaciones, el flujo se para.

El nuevo módulo "Pipelines y Campañas" de la ficha pública cambia esto:

- **Account ya no te cuenta el cambio en daily** — lo deja escrito en la ficha del cliente.
- **Tú dejas de inventar nombres de tareas** — usas el código del catálogo del cliente.
- **El equipo deja de preguntarte contexto** — abre la ficha y lo encuentra solo.

Sigues siendo la pieza que reparte, pero ya no eres la pieza que recuerda.

## 1. Tu flujo diario

### Cada mañana (10 minutos)

1. **Abre `work.thenucleo.com/ficha-cliente/`** y entra a la ficha de cada cliente activo (selector arriba).
2. **Cambia al modo PM** con el switch arriba a la derecha.
3. **Despliega "Pipelines y Campañas"** (sale abierta por defecto).
4. Pasea por el árbol del cliente: Pipelines → Campañas → Triggers + Emails.

Tu objetivo: detectar qué tiene **trabajo pendiente** y qué tiene **gaps**.

Trabajo pendiente:
- Una Campaña marcada como **"Declarada"** y sin tareas creadas en Notion → tienes que generar las tareas.
- Una Campaña **"En producción"** que el cliente pidió ampliar → revisar si Account ha añadido nuevos Emails / Triggers que aún no estén montados.

Gaps que tú reportas a Account:
- Una Campaña sin **link briefing Drive** (aparece aviso ámbar). Pingas a Account para que lo añada.
- Un Trigger tipo BD sin **fecha de lanzamiento** (aviso ámbar). Mismo ping.
- Una Campaña sin **objetivo o KPI** claro. Mismo ping.

### Cuando una Campaña está lista para montar

1. **Entra al detalle de la Campaña** en el panel derecho.
2. **Pulsa el botón "Crear tareas Notion"** (CTA destacado en verde arriba del detalle, solo visible en modo PM).
3. Se abre un drawer con **todas las tareas pre-generadas a partir de la plantilla** que Account eligió: copy, diseño, formulario, montaje GHL, lanzamiento, etc.
4. **Cada tarea ya viene con**:
   - Código en el título (`P2C1E1 — Copy Dra. Neuss`).
   - Área canónica (`Meta Ads`, `Newsletter`, `CRM`, `Diseño` — sin duplicados).
   - Responsable sugerido por la plantilla (copy → Valentin, diseño → Joaquin, formulario → Damian, GHL → Camilo).
5. **Desmarca las que no quieras crear** (ej: si ese cliente no necesita estáticos porque ya los tiene).
6. **Pulsa "Crear N tareas"**.

Eso es todo. No abres Notion para crearlas — se generan desde la ficha.

### Cuando el cliente pide algo nuevo y Account aún no lo ha declarado

1. **No crees tareas todavía.** El sistema fuerza código del catálogo, y si no existe el código, no debería existir la tarea.
2. **Pingas a Account** (chat del cliente o daily): "necesito que declares en la ficha la Campaña X para `P2`".
3. Cuando Account la declara, vuelves al paso anterior.

### Si tienes que crear una tarea **fuera** de cualquier Campaña

Algunas tareas son **soporte / operativa pura** y no encajan en ningún `PxCx`:
- Reunión semanal con el cliente.
- Auditoría mensual de cuenta.
- Fix de incidencia en la web.
- Onboarding de un nuevo miembro al cliente.

Para esas tareas, créalas como hasta ahora (sin código), pero **identifícalas con un área canónica** y **dale al cliente que toca** (no genéricas tipo "OUTPUT NEUS" — di qué es exactamente, ej: "Auditoría mensual Meta Ads — Dra. Neuss").

## 2. Cómo se compone el código (cheat sheet)

Para que sepas leer cualquier tarea sin abrir la ficha:

| Código | Significa | Ejemplo |
|---|---|---|
| `P1` | Pipeline 1 del cliente | Pipeline = línea de negocio |
| `P1C1` | Campaña 1 de ese Pipeline | Campaña = acción concreta |
| `P1C1FM1` | Formulario Meta #1 de esa Campaña | Trigger |
| `P1C1FW1` | Formulario Web #1 | Trigger |
| `P1C1BD1` | Envío masivo a BBDD #1 | Trigger |
| `P1C1E1`, `E2`, `E3`… | Emails de la secuencia | Por orden |
| `P1C1FM1FW1E1` | Email 1 que aplica solo a esos 2 triggers concretos | Caso especial |

Una tarea que llegue como `P2C1E2 — Diseño Dra. Neuss` la lees así: Pipeline 2 (Captación leads), Campaña 1 (Captación junio), Email 2 (Educación / valor), trabajo de diseño, para Dra. Neuss.

## 2.bis Tabla maestra — qué código va a qué rol (tu cheat sheet de reparto)

Cuando pulsas "Crear tareas Notion" desde una Campaña, las tareas se generan **siguiendo esta tabla**. Si tienes que crear una manualmente, usa este mapping para no equivocarte.

| Código del entregable | Acción | Rol responsable default | Área Notion canónica | Dónde acaba el entregable |
|---|---|---|---|---|
| `PxCx_briefing` | Briefing creativo de la Campaña | Estratega creativo | Estrategia | Drive `/Cliente/Campañas/PxCx — Nombre/` |
| `PxCx_angulos` | Ángulos de venta | Estratega creativo | Estrategia | Drive `/Cliente/Campañas/PxCx — Nombre/` |
| `PxCx_cluster` | Análisis de cluster | Estratega creativo | Estrategia | Drive `/Cliente/Campañas/PxCx — Nombre/` |
| `PxCx_briefing_estaticos` | Briefing diseño estáticos | Estratega creativo | Estrategia | Drive `/Cliente/Campañas/PxCx — Nombre/` |
| `PxCx_briefing_video` | Briefing diseño vídeo / guion | Estratega creativo | Estrategia | Drive `/Cliente/Campañas/PxCx — Nombre/` |
| `PxCxEn_copy` | Copy email de la secuencia | Copy | Newsletter / Copy | Drive `/Cliente/Campañas/PxCx — Nombre/` |
| `PxCx_copy_RRSS_vN` | Copy publicación RRSS | Copy | RRSS / Copy | Drive `/Cliente/Campañas/PxCx — Nombre/` |
| `PxCx_copy_estaticos` | Textos para estáticos ad | Copy | Copy | Drive `/Cliente/Campañas/PxCx — Nombre/` |
| `PxCxEn_diseno` | Diseño email maquetado | Diseño | Diseño | Drive `/Cliente/Campañas/PxCx — Nombre/` |
| `PxCx_estatico_vN` | Estático ad Meta | Diseño | Diseño | Drive `/Cliente/Campañas/PxCx — Nombre/` |
| `PxCx_reel_vN` | Reel para ad | Diseño | Diseño | Drive `/Cliente/Campañas/PxCx — Nombre/` |
| `PxCx_carrusel_vN` | Carrusel para ad | Diseño | Diseño | Drive `/Cliente/Campañas/PxCx — Nombre/` |
| `PxCx_video` | Vídeo VSL / explicativo | Diseño | Diseño | Drive `/Cliente/Campañas/PxCx — Nombre/` |
| `PxCxFMn_form` | Crear formulario Meta | Media Buyer | Meta Ads | Meta Ads Manager (objeto nombrado igual que el código) |
| `PxCxFMn_pixel` | Vincular píxel de conversión | Media Buyer | Meta Ads | GHL/Meta (pixel_id en ficha) |
| `PxCx_estaticos_subir` | Subir creatives a Meta | Media Buyer | Meta Ads | Meta Ads |
| `PxCx_lanzar` | Lanzar campaña Meta | Media Buyer | Meta Ads | Meta Ads |
| `PxCxFWn_form` | Form en web del cliente | CRM Manager / Dev | CRM | Web cliente (URL en `ext` del Trigger) |
| `PxCxBDn_segmento` | Crear segmento BBDD | CRM Manager | CRM | GHL (segmento nombrado igual que código) |
| `PxCx_ghl` | Montar workflow completo GHL | CRM Manager | CRM | GHL (workflow `PxCx` + acciones `PxCxEn`) |
| `PxCxEn_montaje` | Subir HTML email a GHL | CRM Manager | CRM | GHL |

**Áreas canónicas Notion** (definitivas — cero duplicados):
- `Estrategia` (sustituye los antiguos "Project Manager" / briefings sueltos)
- `Copy` (sustituye "Newsletter" para tareas de copywriting)
- `Newsletter` (solo para entregable newsletter recurrente)
- `Diseño` (engloba estáticos, reels, carruseles, vídeo, maquetación email)
- `Meta Ads` (sustituye los duplicados `PAID MEDIA` / `Media Buyer`)
- `CRM` (GHL, formularios web, segmentos BBDD, montaje flujos)
- `RRSS` (publicaciones orgánicas en redes)

Si el responsable default no aplica al cliente concreto (ej: Neus tiene Damian para Meta pero otro cliente tiene otro media buyer), reasignas a mano antes de crear las tareas. La plantilla **sugiere**, no impone.

## 3. Verificación al cierre (semanal)

Cada viernes a última hora:

1. **Recorre los clientes activos** en la ficha.
2. **Por cada Campaña "En producción"**, verifica que todos los entregables están en Drive con su código:
   - `/Cliente/Campañas/P1C1 — Nombre/P1C1E1_copy.docx` ✓
   - `/Cliente/Campañas/P1C1 — Nombre/P1C1E1_diseño.png` ✓
   - `/Cliente/Campañas/P1C1 — Nombre/P1C1E2_copy.docx` ✓
   - etc.
3. **Si falta algo**, abre la tarea Notion correspondiente y persigue.
4. **Si una Campaña ya no se usa**, ping a Account para que la archive.

## 4. Casos que vas a vivir esta semana

### "Account ha declarado una Campaña pero no ha pegado el briefing Drive"

- Aparece el aviso ámbar "Sin briefing — Account pendiente de duplicar template".
- **No generas tareas todavía.** El equipo necesita briefing para trabajar.
- Pingas a Account: "Pega el link briefing en `P3C1` y avisa".
- Cuando esté, generas tareas.

### "Una Campaña tiene un Trigger BD sin fecha de lanzamiento"

- Aparece aviso ámbar `⚠ Algún trigger BD no tiene fecha`.
- **No lanzas todavía.** Una BBDD se manda en una fecha concreta, no a goteo.
- Pingas a Account para que añada fecha.

### "El cliente pide modificar un email ya en producción"

- Account NO crea código nuevo. El email mantiene su código (`P1C1E2`).
- Tú creas tarea Notion `P1C1E2 — Rehacer copy Dra. Neuss`.
- El equipo trabaja, versiona en Drive (`P1C1E2_copy_v2.docx`), Camilo actualiza el flujo GHL.
- El código sigue siendo `P1C1E2`. Estable.

### "El cliente pide añadir un cuarto email a una secuencia"

- Account añade `P1C1E4` en la ficha.
- Tú creas tareas para `P1C1E4`: copy, diseño, montaje GHL.
- No renumeras E1, E2, E3.

### "Una Campaña ya no se usa"

- Account la archiva.
- En el árbol desaparece (a menos que actives el toggle "Mostrar archivados").
- El código sigue vivo para auditoría. **No se reutiliza** — si el cliente vuelve a pedirlo, Account crea `P1C5` o el siguiente disponible.

### "El cliente cancela el servicio"

- La ficha entera pasa a "No Activo" (eso ya pasa en `bub_clientes`).
- Los Pipelines y Campañas quedan archivados pero existentes.
- Si vuelve en 6 meses, todo está intacto.

## 5. Lo que NO tienes que hacer

- **No inventes códigos.** Si el equipo te pide trabajar en algo sin código declarado, ping a Account.
- **No edites Pipelines / Campañas / Triggers / Emails.** Eso es de Account. Tú solo cambias el estado cuando algo se monta (de "Declarado" → "En producción").
- **No crees Plantillas nuevas.** El catálogo es de Account.
- **No abras Notion para crear tareas individuales con código.** Usa el drawer "Crear tareas Notion" desde la ficha — te las crea con todo cableado.

## 6. Si algo se rompe

- **No aparece el módulo Pipelines en la ficha**: avisa a Ben, posible bug de despliegue.
- **El drawer "Crear tareas Notion" no genera nada**: la Campaña está "Sin plantilla / Custom" → tienes que crear las tareas manualmente con el código del catálogo (futuro: dropdown forzado en el formulario Bubble).
- **Una tarea generada tiene un código que no encaja con lo que recuerdas**: probablemente Account cambió la estructura. Antes de protestar, abre la ficha y mira el árbol actualizado.

## 7. Tu nueva métrica de éxito

Antes: número de tareas creadas / cerradas a tiempo.

Ahora añadimos: **número de tareas creadas SIN código en clientes con Pipelines declarados** (objetivo: cero). Si esto pasa, el sistema se rompe.

Y: **número de gaps que reportas a Account por semana** (objetivo: que tienda a cero, porque significa que Account está vertiendo el mapa al ritmo del cliente).

## 8. Resumen en una frase

> Cada mañana abres las fichas de los clientes activos, identificas Campañas con trabajo pendiente, generas las tareas Notion desde el botón "Crear tareas Notion" (código forzado, responsables sugeridos, áreas canónicas), reportas los gaps a Account. Tu cabeza deja de ser el único sitio donde vive el mapa.
