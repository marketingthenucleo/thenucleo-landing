# Manual del equipo — Pipelines y Campañas

Audiencia: Estratega creativo · Copy · Diseño · Media Buyer · CRM Manager. Lectura: 6 minutos. Es lo único que necesitas saber para que el sistema te funcione.

> Antes de leer esto, ten leído [[pipelines-presentacion]] (1 página, 4 minutos). Ahí está el "por qué" del cambio. Aquí está tu "qué hago" concreto.

## 0. Tu día cambió poco — pero cambió

**Antes**: te llegaba una tarea Notion tipo `Maquetar email` para Dra. Neuss. Preguntabas a Melina contexto, abrías Drive, buscabas dónde, hacías, guardabas con nombre libre, cerrabas.

**Ahora**: te llega `P2C1E2 — Diseño email Dra. Neuss`. Ese código ya te dice todo. Abres Drive en la carpeta `P2C1`, encuentras el briefing, haces, guardas con el código en el nombre, cierras. **Sin preguntar contexto.**

## 1. Cómo leer cualquier código en 5 segundos

| Trozo | Qué dice |
|---|---|
| `P1` | Pipeline 1 del cliente — la línea de negocio |
| `P1C1` | Campaña 1 dentro de ese Pipeline |
| `P1C1FM1` | Formulario Meta 1 de esa Campaña |
| `P1C1FW1` | Formulario Web 1 de esa Campaña |
| `P1C1BD1` | Envío a BBDD 1 de esa Campaña |
| `P1C1E2` | Email 2 de la secuencia |
| `P1C1E2_copy` | Trabajo de copy para ese email |
| `P1C1E2_diseno` | Trabajo de diseño para ese email |
| `P1C1_estatico_v3` | Estático ad versión 3 de la Campaña |
| `P1C1FM1FW1E1` | Email 1 que aplica solo a esos 2 triggers (caso especial) |

Si dudas, mira el árbol del cliente en `work.thenucleo.com/ficha-cliente/?id=<cliente>` (acceso admin — pide acceso a Ben si no lo tienes).

## 2. Qué hacer cuando te llega una tarea (los 6 pasos universales)

1. **Lee el código** en el título de la tarea.
2. **Abre el Drive del cliente** → `/Cliente/Campañas/PxCx — Nombre/` (donde `PxCx` es el código de la Campaña, sin el sufijo del email/trigger).
3. **Lee el briefing** que vive en esa carpeta (lo pegó Account al declarar la Campaña).
4. **Trabaja**.
5. **Guarda tu entregable en la misma carpeta** con el código + sufijo del rol + extensión (`P1C1E2_copy.docx`, `P1C1E2_diseno.png`).
6. **Pega el link al entregable en la tarea Notion** y **marca Lista**.

Eso es todo.

## 2.bis Estructura de carpetas Drive del cliente

Cada cliente tiene esta estructura en Drive (la crea automáticamente el workflow n8n `d0B4LokmPhHWdg6g` al alta del cliente):

```
📁 /Nombre del cliente/
├── 📁 Onboarding/                              ← documentación inicial cliente
├── 📁 Analisis inicial y estrategia/
│   ├── 📁 Analisis inicial/                    ← análisis del Chat Cerebro IA
│   └── 📁 Estrategia/
│       ├── 📁 Estilo comunicacion y Arquetipos/
│       └── 📁 Historico_newsletters/
├── 📁 Reuniones/                               ← actas, grabaciones
├── 📁 Informes/                                ← reports mensuales
├── 📁 Organizacion interna/
│   ├── 📁 CRM/                                 ← uso interno equipo CRM
│   └── 📁 Compartida Clientes/
│       ├── 📁 RRSS/                            ← histórico publicaciones (no por Campaña)
│       └── 📁 Anuncios/                        ← histórico ads (no por Campaña)
└── 📁 Campañas/                                ← ⚠️ pendiente añadir al sub n8n
    ├── 📁 P1C1 — Curso Suplementación 75€/    ← Account crea al declarar Campaña
    │   ├── 📄 P1C1_briefing.docx               ← TODOS los entregables de esa Campaña juntos
    │   ├── 📄 P1C1_angulos.docx
    │   ├── 🖼️ P1C1_estatico_v1.png
    │   ├── 🎥 P1C1_video.mp4
    │   ├── 📄 P1C1FM1_form_config.json
    │   ├── 📄 P1C1E1_copy.docx
    │   ├── 🖼️ P1C1E1_diseno.png
    │   └── …
    └── 📁 P2C1 — Captación leads/
        └── …
```

**Regla operativa**: TODO entregable que pertenezca a una Campaña concreta (briefings, copies, diseños, estáticos, reels, segmentos BBDD, configs de formularios) vive en `Campañas/PxCx — Nombre/`. Las otras L1 (Onboarding, Estrategia, Reuniones, Informes, Organizacion interna) son para activos del cliente que NO son por-Campaña (estilo de marca, análisis inicial, actas de reunión, reportes, etc.).

> 🔧 **Estado técnico (2026-05-23)**: la L1 `Campañas` aún NO la crea automáticamente el sub `d0B4LokmPhHWdg6g`. Mientras tanto, **Account crea esta carpeta manualmente** al declarar el primer Pipeline de un cliente. Modificación del sub queda pendiente — anotada en `docs/infra/n8n-workflows.md`.

## 3. Por rol — qué tareas te llegan y qué generas

### Estratega creativo

Te llegan tareas con códigos tipo:

| Código | Acción | Dónde guardas |
|---|---|---|
| `PxCx_briefing` | Briefing creativo de la Campaña | `/Cliente/Campañas/PxCx — Nombre/PxCx_briefing.docx` |
| `PxCx_angulos` | Documento de ángulos de venta | `/Cliente/Campañas/PxCx — Nombre/PxCx_angulos.docx` |
| `PxCx_cluster` | Análisis de cluster / segmentación | `/Cliente/Campañas/PxCx — Nombre/PxCx_cluster.docx` |
| `PxCx_briefing_estaticos` | Briefing diseño estáticos | `/Cliente/Campañas/PxCx — Nombre/PxCx_briefing_estaticos.docx` |
| `PxCx_briefing_video` | Guion / briefing diseño vídeo | `/Cliente/Campañas/PxCx — Nombre/PxCx_briefing_video.docx` |

**Tu input**: la conversación de Account con el cliente (resumida en `notas Account` de la ficha + briefing master de Drive que Account duplicó). Tu output: el briefing creativo que el resto del equipo usará.

**Regla operativa**: tu trabajo vive **antes** del resto. Si no has cerrado el briefing, Diseño / Copy / Media Buyer no deben empezar. La PM espera tu Lista para repartir el resto.

### Copy

Te llegan tareas tipo `PxCxEn_copy` o `PxCx_copy_RRSS_vN`:

| Código | Acción | Dónde guardas |
|---|---|---|
| `PxCxE1_copy` | Copy email 1 de la secuencia | `/Cliente/Campañas/PxCx — Nombre/PxCxE1_copy.docx` |
| `PxCxE2_copy` | Copy email 2 | `/Cliente/Campañas/PxCx — Nombre/PxCxE2_copy.docx` |
| `PxCx_copy_RRSS_vN` | Copy publicación RRSS | `/Cliente/Campañas/PxCx — Nombre/PxCx_copy_RRSS_vN.docx` |
| `PxCx_copy_estaticos` | Copy textos para estáticos ad | `/Cliente/Campañas/PxCx — Nombre/PxCx_copy_estaticos.docx` |

**Tu input**: el briefing del Estratega (que ya está en la misma carpeta) + el objetivo y la espera del email (lo ves en el árbol de la ficha o en la descripción de la tarea).

**Modificar copy existente** (caso 7 .docx): si te piden rehacer `P1C1E2_copy`, **mantienes el mismo código**. Guardas `P1C1E2_copy_v2.docx`. No renombras.

### Diseño

Te llegan tareas tipo `PxCxEn_diseno`, `PxCx_estatico_vN`, `PxCx_reel_vN`, `PxCx_carrusel_vN`, `PxCx_video`:

| Código | Acción | Dónde guardas |
|---|---|---|
| `PxCxE1_diseno` | Diseño email 1 maquetado | `/Cliente/Campañas/PxCx — Nombre/PxCxE1_diseno.png` (o `.html`) |
| `PxCx_estatico_v1` | Estático 1 para ad Meta | `/Cliente/Campañas/PxCx — Nombre/PxCx_estatico_v1.png` |
| `PxCx_reel_v1` | Reel para ad | `/Cliente/Campañas/PxCx — Nombre/PxCx_reel_v1.mp4` |
| `PxCx_carrusel_v1` | Carrusel para ad | `/Cliente/Campañas/PxCx — Nombre/PxCx_carrusel_v1.png` (multi-slide) |
| `PxCx_video` | Vídeo VSL / explicativo | `/Cliente/Campañas/PxCx — Nombre/PxCx_video.mp4` |

**Tu input**: copy ya cerrado por Copy + briefing creativo / estáticos / video del Estratega — todos están en la misma carpeta `PxCx`.

**Versionado**: si haces 3 versiones de un estático, son `_v1`, `_v2`, `_v3`. Si haces 3 estáticos distintos para la misma Campaña, son `_estatico_v1`, `_estatico_v2`, `_estatico_v3` (el "v" indica versión cuando es retrabajo, o indica cardinalidad cuando son piezas distintas — usa criterio).

**Una pieza que vale para 2 Campañas hermanas** (caso 11 .docx): duplica el archivo con cada código (`P1C1_estatico_oferta.png` + `P1C2_estatico_oferta.png`). NO uses `P1C1C2_...` (código compuesto).

### Media Buyer

Te llegan tareas tipo `PxCxFMn_form`, `PxCxFMn_pixel`, `PxCx_lanzar`:

| Código | Acción | Dónde guardas / configuras |
|---|---|---|
| `PxCxFM1_form` | Crear formulario nativo Meta | Meta Ads Manager — **nombra el formulario igual que el código** (`P1C1FM1`) |
| `PxCxFM1_pixel` | Vincular píxel de conversión a la campaña | Configuración GHL/Meta — pega el `pixel_id` en el campo `ext` del Trigger en la ficha |
| `PxCx_estaticos_subir` | Subir estáticos a Meta como ad creatives | Meta Ads — nombra cada creative `P1C1_estatico_v1` |
| `PxCx_lanzar` | Lanzar campaña en Meta | Meta Ads Manager — **el conjunto de anuncios se llama igual que el código `P1C1`** |

**Tu input**: estáticos / reels / vídeos ya en Drive con su código + briefing del Estratega + el campo `ext` del Trigger (URL destino, ID del producto en GHL, etc.).

**Regla operativa**: cuando crees el formulario, anuncio o campaña en Meta, **nombra cada objeto igual que su código en la ficha**. Si pones nombres distintos, rompes la cadena de trazabilidad.

**Reporta**: cuando termines, pega el `Form ID Meta` / `Campaign ID Meta` en el campo `ext` del Trigger en la ficha (o pídele a Account/PM que lo haga). Eso cierra el bucle.

### CRM Manager

Te llegan tareas tipo `PxCxBDn_segmento`, `PxCxFWn_form`, `PxCx_ghl`, `PxCxEn_montaje`:

| Código | Acción | Dónde guardas / configuras |
|---|---|---|
| `PxCxBD1_segmento` | Crear segmento en GHL para envío BBDD | GHL — **nombra el segmento igual que el código** (`P1C1BD1`) |
| `PxCxFW1_form` | Montar formulario en la web del cliente | Web del cliente — anota la URL final en el campo `ext` del Trigger |
| `PxCx_ghl` | Montar workflow GHL completo de la Campaña | GHL — **workflow llamado `P1C1`**, acciones de email llamadas `P1C1E1`, `P1C1E2`, etc. |
| `PxCxEn_montaje` | Subir HTML del email a GHL | GHL — **action de email nombrada igual que el código** del email |

**Tu input**: copies + diseños de email ya en Drive con su código + (si es BD) la `fecha_lanzamiento` del Trigger en la ficha (obligatoria para BD).

**Cómo se mapea PxCx a GHL** (regla `.docx` historia Laser Space):

Una Campaña = UN workflow GHL llamado `PxCx`. Los Triggers (FM/FW/BD) son los **disparadores de entrada** del workflow (puede haber 1 o varios). Los Emails son las **acciones internas** del workflow.

```
Campaña P1C1 con FM1 + FW1 + BD1 y emails compartidos (E1, E2, E3)

GHL workflow: "P1C1"
├── Triggers de entrada:
│   ├── P1C1FM1  (form Meta → entra el lead)
│   ├── P1C1FW1  (form web → entra el lead)
│   └── P1C1BD1  (segmento BBDD → entra en bloque)
└── Acciones email:
    ├── P1C1E1  (Día 0)
    ├── P1C1E2  (Día +2)
    └── P1C1E3  (Día +5)
```

**Respondiendo a "¿en qué workflow vive `P1C1E1`?"**: en UN solo workflow llamado `P1C1`. Si tocas el HTML del email, lo tocas una vez. Cualquier Trigger de la Campaña lo dispara.

**Si los emails varían por Trigger** (caso 3 `.docx`): el workflow `P1C1` tiene **ramas internas** según el Trigger de entrada. Las acciones se llaman `P1C1FM1E1`, `P1C1FW1E1`, etc. Cada rama ejecuta solo sus emails.

**Regla operativa**: igual que Media Buyer — **todos los objetos en GHL llevan el código exacto** como nombre. Si el workflow se llama "Bienvenida Neus" en vez de `P1C1`, el sistema no funciona.

**Lanzamiento BD** (caso 4 .docx): la fecha de envío vive en el Trigger de la ficha, no en el código. Si te piden cambiar la fecha, lo hace Account en la ficha — tú reconfiguras GHL para el nuevo timing.

## 4. Lo que NO haces (todos los roles)

- **No inventas códigos.** Si recibes una tarea con un código que no entiendes o que falta, pingas a la PM. Ella va a la ficha o pide a Account.
- **No renombras archivos / creatives / workflows** ya creados. El código es estable. Lo que cambia es la versión (`_v2`, `_v3`).
- **No editas Pipelines / Campañas / Triggers / Emails** en la ficha pública. Eso es de Account.
- **No marcas tareas Lista sin haber pegado el link al entregable** en la tarea Notion. Si la PM no puede comprobar el resultado, queda como hueco.
- **No empiezas tu parte sin el input del rol anterior.** Diseño no empieza sin Copy. Copy no empieza sin briefing del Estratega. Media Buyer no lanza sin estáticos. CRM no monta sin emails.

## 5. Cuando algo no encaja

- **Te llega una tarea con código y no encuentras el briefing en Drive**: la Campaña está incompleta. Pinga a PM, ella pingará a Account.
- **Te llega una tarea sin código** (para un cliente que sí tiene Pipelines): es un error de la PM (no debería pasar cuando el sistema esté del todo cableado). Pinga a la PM.
- **El cliente te habla directo** (rarísimo, pero pasa): no aceptes input directo. Redirige a Account.

## 6. Tu nueva métrica

Antes: tareas cerradas a tiempo.

Ahora añadimos: **tu entregable tiene el código exacto en el nombre del archivo + está en la carpeta `PxCx` correcta + el objeto en Meta/GHL/web lleva el mismo código**. Si esto está bien, tu trabajo se encadena solo con el del resto del equipo. Si está mal, la cadena se rompe.

## 7. Resumen en una frase

> Recibes tarea con código, abres carpeta Drive `PxCx`, lees briefing, trabajas, guardas con el código en el nombre, pegas link en Notion, marcas Lista. Si te falta input del rol anterior, esperas. Si te falta código, preguntas a la PM. Nunca inventas.
