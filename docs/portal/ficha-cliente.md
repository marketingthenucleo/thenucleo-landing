---
title: Ficha de Cliente — visión operacional
dominio: portal
estado: vivo (frontend con seed) · backend F2 pendiente
actualizado: 2026-05-23
tags: [ficha-cliente, pipelines, campañas, nomenclatura, account, pm, briefing]
---

# Ficha de Cliente — visión operacional

> ✅ **Frontend del módulo Pipelines vivo desde 2026-05-23** en `work.thenucleo.com/ficha-cliente/` (repo `marketingthenucleo/thenucleo-landing`, push a `main`, deploy Vercel auto). Datos seed hardcoded de Dra. Neuss. Backend Supabase (`cliente_pipelines` + `cliente_campanias` + `cliente_triggers` + `cliente_emails` + RPCs) es F2 — sesión técnica pendiente.
>
> **Para el equipo**: empieza por [[pipelines-presentacion]] (1 página). Después, según tu rol: [[account-manual-pipelines]] o [[pm-manual-pipelines]].
>
> Este documento describe **qué información se recoge de cada cliente, quién la recoge y cómo la consume cada rol del equipo**. Es la visión funcional. La UX implementada en frontend respeta este modelo.
>
> Origen: nomenclatura definida en `TheNucleoNomenclatura2.docx` + diagnóstico real del cliente Dra. Neuss (60 tareas marzo→mayo 2026) + auditoría de las fichas existentes (interna Bubble + pública `work.thenucleo.com/ficha-cliente/`).

## 1. Por qué existe la ficha

La ficha de cliente es el **mapa operativo del cliente**. Cuando un cliente nos pide algo, la información de qué quiere, qué incluye, dónde encaja en su negocio y qué hemos hecho ya viaja por muchas manos: cliente → Account → PM → equipo. En cada salto se pierde contexto, se duplica trabajo y se generan archivos con nombres tipo `Email_bienvenida_v3_FINAL.docx` que mañana nadie sabe identificar.

Hoy ese mapa **no existe en un sitio único**. Vive repartido entre:

- La cabeza de Account (recuerda qué quiere el cliente y por qué).
- La cabeza de la PM (recuerda qué se está montando y quién).
- Notion (tareas sueltas sin estructura paraguas).
- Drive (briefings sueltos sin enlazar a tareas).
- Chats del equipo y reuniones.

Síntomas observables hoy en `bub_tareas_notion` (caso Neus marzo→mayo 2026):

- 3 tareas distintas para el mismo píxel de conversión (`Píxel de conversión`, `Investigar pixel de conversión`, `Pixel de seguimiento ventas`) creadas con días de diferencia por el caos de comunicación.
- 3 tareas llamadas `Lanzamiento de campañas` en fechas distintas, sin código que las distinga.
- `PAID MEDIA` / `Meta Ads` / `Media Buyer` usadas como tres áreas distintas para el mismo Damian.
- Briefings duplicados (`Briefing Mayo` Newsletter + `Briefing Mayo` RRSS el mismo día) sin saber si son uno o dos.
- ≥4 pipelines latentes operando en paralelo (Venta directa curso, Captación leads, Reactivación, Newsletter) **sin que nadie los haya declarado**.

La ficha de cliente v2 es el sitio único donde **Account vuelca el mapa** y el resto del equipo lo consume con disciplina.

## 2. Las tres capas anidadas

La ficha tiene tres capas. Cada una tiene su unidad, su responsable y su vida útil.

### Capa Cliente

Estable, una por cliente. **Ya existe hoy** en `bub_clientes` (73 registros, eu-west-1) y se pinta en `work.thenucleo.com/ficha-cliente/`. No se rediseña. Solo se documenta lo que hay.

Campos relevantes ya capturados:

- **Identificación:** `nombre_empresas`, `nombre_sociedad`, `dni_nif`, `direccion_fiscal`, `codigo_postal`, `provincia`, `pais`, `telefono_principal`.
- **Contacto:** `contacto_principal`, `correo_principal`.
- **Presencia digital:** `pagina_web`, `logo_url`. ⚠️ Instagram, Facebook, Meta BM, Google Ads, GHL, DNS hoy son `MOCKUP` — pendiente decidir si entran como columnas nuevas o tabla aparte `cliente_accesos`.
- **Operaciones internas:** `link_drive`, `bb_link_drive_analisis`, `notion_id`, `gchat_space_id`, `slug`, `fecha_onboarding`, `ultimo_seguimiento`, `nps`, `facturacion`.
- **Gestión:** `estado` (Activo / No Activo), `sector`, `niveles` (kanban Onboarding → Cliente estable), `descripcion_plan`, `bb_estado_facturacion`, `agencia_id`, `admin_cliente` (array de responsables).
- **Servicios contratados:** real desde `playbook_cliente_servicios` (199 filas) vía RPC `ficha_cliente_get` con `jsonb_agg` agrupado por categoría.

Esta capa es lo "frío" del cliente — la identidad. Cambia poco.

### Capa Pipeline (P)

Nueva. 1-4 por cliente. **Estable en el tiempo** (vive meses o años, no semanas).

Un Pipeline representa una **línea estratégica de negocio del cliente**. Agrupa todas las acciones de marketing que persiguen un mismo objetivo de negocio.

Campos:

- `codigo` — `P1`, `P2`, `P3`… secuencial dentro del cliente, nunca se reutiliza.
- `nombre` — corto y operativo (ej: `Captación grupos cumpleaños`, `Reactivación clientes antiguos`, `B2B colegios`).
- `objetivo_negocio` — texto libre breve. Qué problema del cliente resuelve este Pipeline.
- `estado` — `activo` / `archivado`. Nunca se borra.
- `responsable_account` — quién lo lleva del lado TheNucleo (referenciado desde `bub_user`).
- `notas` — texto libre opcional.

**Regla mental:** si lo que estás describiendo se acaba en una fecha concreta, no es un Pipeline. Es una Campaña.

### Capa Campaña (C) — con Triggers y Emails

Nueva. N por Pipeline. **Es la unidad real de trabajo del equipo.** Cuando se monta algo, se monta una Campaña.

#### Campaña

Campos:

- `codigo` — `C1`, `C2`… secuencial dentro del Pipeline, nunca se reutiliza.
- `nombre` — corto (ej: `Bienvenida padres`, `Black Friday cumpleaños`, `Lanzamiento Curso Suplementación`).
- `plantilla_origen` — referencia a la Plantilla del catálogo de la que se heredó (ver §4). Permite saber el tipo a posteriori.
- `estado` — `declarada` / `en producción` / `archivada`. Nunca se borra.
- `fecha_inicio`, `fecha_fin` — opcionales (vacías si recurrente).
- `presupuesto_eur`, `canal_principal` (Meta / Google / Email / Orgánico / Mixto).
- `kpi_objetivo` — texto corto: "100 leads", "30 ventas/mes", "20% apertura".
- `link_briefing_drive` — **el briefing detallado vive aquí en Drive**, no en la ficha. La ficha solo apunta. Es el doc/PDF del cliente (como el del Curso suplementación de Neus que motivó esta visión).
- `responsable_pm` — quién distribuye al equipo.
- `notas_account` — texto libre corto. Contexto que no encaja en el briefing Drive.

Una Campaña **siempre tiene al menos un Trigger** (FM, FW o BD). Si no tiene Trigger, está incompleta — está declarada pero no ejecutable.

Una Campaña **puede tener 0 o N Emails**. Una Venta Directa puede no tener Emails (anuncio → checkout y punto). Una Captación de Leads suele tener 3-5.

#### Trigger (FM / FW / BD)

Sub-bloque dentro de la Campaña.

| Tipo | Qué es | Quién lo crea | Campo obligatorio especial |
|---|---|---|---|
| **FM** — Formulario Meta | Form nativo Instagram/Facebook que captura lead dentro de la plataforma | Media Buyer | — |
| **FW** — Formulario Web | Form en la web del cliente (landing/popup) que envía lead a GHL | CRM Manager o Dev | — |
| **BD** — Base de Datos | Lista existente a la que se lanza secuencia en fecha programada | CRM Manager | `fecha_lanzamiento` obligatoria |

Campos:

- `codigo` — `FM1`, `FW1`, `BD1`… secuencial dentro de la Campaña.
- `tipo` — `FM` / `FW` / `BD`.
- `descripcion` corta.
- `link_externo` — ID del formulario Meta, URL del FW en web, nombre del segmento GHL del BD.
- `fecha_lanzamiento` — obligatoria solo si `tipo='BD'`.
- `estado` — `declarado` / `creado` / `monitorizando`.

#### Email (E)

Sub-bloque dentro de la Campaña.

- `codigo` — `E1`, `E2`… secuencial dentro de la Campaña.
- `orden` — 1, 2, 3…
- `espera_desde_anterior` — texto operativo: "Día 0", "Día +1", "Día +3", "1 semana".
- `objetivo` — texto corto: "Bienvenida + catálogo", "Agitar dolor", "Oferta descuento", "Recordatorio".
- `triggers_aplicables` — multi-select de los FM/FW/BD declarados. Vacío = se aplica a todos los triggers de la Campaña (caso típico).
- `link_copy_drive`, `link_diseno_drive`, `link_ghl_workflow` — entregables.
- `estado` — `declarado` / `copy listo` / `diseño listo` / `montado GHL` / `activo`.

**Cuándo poner el trigger en el código del Email:** solo cuando hace falta distinguir. Si los 3 triggers envían los mismos Emails, los Emails se nombran sin trigger (`P1C1E1`). Si cada trigger envía emails distintos, se incluye (`P1C1FM1E1`, `P1C1FW1E1`).

## 3. La nomenclatura PxCx

**Fuente original:** `TheNucleoNomenclatura2.docx` (cargada por Ben 2026-05-23). Este documento es la fuente viva alineada con la implementación; el .docx queda como anexo histórico.

### La idea en una frase

Cada cosa que producimos para un cliente se nombra con una dirección que dice exactamente dónde encaja en el negocio del cliente.

```
[CLIENTE]  →  [PIPELINE]  →  [CAMPAÑA]  →  [TRIGGER opcional]  →  [QUÉ ES]
```

El cliente lo da la carpeta Drive (estás dentro de Laser Space, está implícito). El resto se codifica.

### Las 5 piezas

- **P** — Pipeline (línea estratégica del negocio).
- **C** — Campaña (acción concreta dentro del Pipeline).
- **FM** — Formulario Meta.
- **FW** — Formulario Web.
- **BD** — Base de Datos.
- **E** — Email individual dentro de una secuencia.

### Las 7 reglas de oro

1. **Toda nomenclatura empieza por el Pipeline.** Nunca se nombra un elemento aislado.
   - Mal: `FM1`, `E2`. Bien: `P1C1FM1`, `P1C1E2`.

2. **Orden fijo de izquierda a derecha.** `P → C → Triggers (FM/FW/BD) → E`.
   - Bien: `P1C1FM1E1`. Mal: `E1P1C1FM1` — si cada uno ordena como quiere, ya no hay lenguaje común.

3. **Los números son secuenciales por contexto.** `P1, P2, P3` dentro del cliente. `C1, C2, C3` dentro de su Pipeline. `E1, E2, E3` dentro de su Campaña.
   - El `P1` de Neus no tiene nada que ver con el `P1` de Laser Space.
   - Puede existir `P1C1E1` y `P2C1E1` en el mismo cliente — son emails distintos en campañas distintas.

4. **Los números nunca se reutilizan.** Si eliminas la Campaña `C2`, no creas una nueva `C2` después. La siguiente es `C3`.
   - Si reutilizo, los archivos antiguos en Drive quedan ambiguos.

5. **Solo Account asigna nuevos códigos.** El equipo consume códigos. No los crea.
   - Si Copy/Diseño/Media/CRM necesitan un código que no existe → piden a Account que lo añada a la ficha.
   - Si varios pueden crear códigos al mismo tiempo, dos personas pueden crear el mismo `E4` para cosas distintas.

6. **Los códigos no caducan.** Una vez creado, vive para siempre, aunque se desactive.
   - Se marca `archivado`, pero el código sigue existiendo. Los archivos Drive con ese código siguen ahí.

7. **Mismo código en todos los sitios.** El mismo elemento se llama exactamente igual en:
   - Nombre de archivo en Drive
   - Nombre de tarea en Notion
   - Nombre del flujo en GHL
   - Nombre del formulario en Meta
   - Nombre en los chats del equipo
   - Nombre en la ficha del cliente

### Casuísticas frecuentes

#### Caso 1 — Email único por trigger único
`P1C1FM1E1` — Pipeline 1, Campaña 1, Formulario Meta 1, Email 1.

#### Caso 2 — Secuencia de varios emails
`P1C1FM1E1`, `P1C1FM1E2`, `P1C1FM1E3` — tres emails consecutivos disparados por el mismo formulario.

#### Caso 3 — Varios triggers que apuntan al mismo email
`P1C1FM1FW1E1` — un FM y un FW que llevan al mismo email. Los triggers se concatenan antes del E.

#### Caso 4 — Trigger por base de datos con fecha
`P2C1BD1E1`, `P2C1BD1E2` — la fecha de lanzamiento no va en el código. Vive en la ficha asociada al `BD1`.

#### Caso 5 — Misma Campaña con varios triggers, mismos emails
Si los 3 triggers envían los mismos emails → `P1C1E1`, `P1C1E2`, `P1C1E3` (sin trigger en el código).
Si cada trigger tiene variantes → `P1C1FM1E1`, `P1C1FW1E1`, `P1C1BD1E1`.

#### Caso 6 — Varios Pipelines por cliente
```
LASER SPACE
├── P1 — Captación cumpleaños
├── P2 — Reactivación clientes antiguos
└── P3 — Captación B2B colegios
```

#### Caso 7 — Cliente pide modificar un email existente
No se crea código nuevo. Se mantiene `P1C1E2`. Se versiona internamente si hace falta (`P1C1E2_v2_copy.docx`). El código del elemento es estable, el contenido cambia.

#### Caso 8 — Cliente pide añadir email a secuencia existente
Account añade `E4`. Se crea `P1C1E4`. No se renumera nada anterior.

#### Caso 9 — Pipeline o Campaña que se desactiva
`P1C2` se marca `archivado` en la ficha. Los archivos Drive siguen. Si vuelve en el futuro, no se reutiliza — se crea `P1C5`.

#### Caso 10 — Creatividades RRSS (estáticos, reels)
Cuelgan de `PxCx` sin `E`:
- `P1C1_estatico_v1.png`
- `P1C1_reel_v2.mp4`
- `P1C1_copy_RRSS_v1.docx`

#### Caso 11 — Pieza compartida entre Campañas
Recomendado: se duplica con cada código (`P1C1_estatico.png` y `P1C2_estatico.png`). Más limpio que un doble código `P1C1C2_...` que se vuelve ambiguo.

#### Caso 12 — Cliente cancela el servicio
La ficha se marca como archivada. Códigos intactos. Si vuelve en 6 meses, todo sigue válido.

## 4. Catálogo abierto de Plantillas de Campaña

### Concepto

Account mantiene un **catálogo de Plantillas de Campaña** reutilizables, igual que hoy existe `bub_plantillas_tareas_notion` (20 plantillas + 100 subtareas) para las tareas. No son arquetipos fijos — Account puede crear nuevas plantillas cuando detecte un patrón que se repita en varios clientes.

Cada Plantilla define un "molde" para crear Campañas rápido y con coherencia.

### Qué contiene cada Plantilla

- **Nombre operativo** — ej: `Bienvenida vía formulario Meta`, `Black Friday a BBDD`, `Lanzamiento producto multicanal`.
- **Descripción corta** — para qué sirve y cuándo elegirla.
- **Triggers típicos** — qué tipos y cuántos (ej: 1 FM, o 1 FW + 1 BD).
- **Estructura de Emails típica** — orden, espera y objetivo de cada email (ej: `E1 Día 0 bienvenida`, `E2 Día +2 valor`, `E3 Día +5 oferta`).
- **Campos de briefing recomendados** — qué información debería pedirle Account al cliente (ej: presupuesto Meta, link producto, ángulos a probar, info producto, info para guión vídeo).
- **Roles por entregable** — quién hace qué por defecto (ej: copy → Valentin Arias, diseño estáticos → Valentin Arias, edición vídeo → Joaquin Rojo, formulario → Damian, GHL → Camilo).
- **Briefing master sugerido** — link a un template Drive del briefing. Account duplica al usar.
- **KPI por defecto** — qué métrica define éxito (`leads`, `ventas`, `apertura`).

### Cómo se usa

1. Account, en una reunión con cliente, decide crear una Campaña nueva.
2. Abre la ficha del cliente y elige `+ Campaña`.
3. Selecciona una Plantilla del catálogo.
4. La Campaña se crea con los Triggers, Emails, campos y roles **precargados**. Account ajusta lo que haga falta — la Plantilla es **punto de partida, no jaula**.
5. Account duplica el briefing master a la carpeta Drive del cliente (`/Cliente/Campañas/P1C1 — Nombre/briefing.docx`), lo rellena con el cliente, y pega el link en la Campaña.
6. La Plantilla queda intacta. La Campaña vive su vida con su propio briefing.

### Seed inicial recomendado

Estas siete plantillas cubren el grueso de campañas que TheNucleo monta hoy. **No son obligatorias** — son sugerencias de arranque basadas en los patrones observados en los clientes activos.

| Plantilla | Triggers típicos | Emails típicos | Campos briefing clave | KPI |
|---|---|---|---|---|
| **Venta Directa con anuncio Meta** | FM1 (anuncio→checkout) | (Ninguno o E1 recuperación carrito) | Producto, precio, link checkout, presupuesto Meta, ángulos, guión vídeo, briefing estáticos, info producto | Ventas |
| **Captación leads vía FM** | FM1 (formulario Meta) | E1 bienvenida (Día 0), E2 valor (Día +2), E3 oferta (Día +5) | Producto/oferta, lead magnet, presupuesto Meta, ángulos, briefing estáticos | Leads / CPL |
| **Captación leads vía FW** | FW1 (form en web) | E1 bienvenida, E2 valor, E3 oferta | Producto/oferta, URL form, presupuesto Google o orgánico, copy form | Leads / CPL |
| **Reactivación BBDD** | BD1 (fecha obligatoria) | E1 reactivación, E2 oferta, E3 cierre | Segmento BBDD, fecha envío, asunto, oferta de reactivación | Conversiones |
| **Newsletter recurrente** | BD1 (cadencia semanal/mensual) | E1 edición única por envío | Cadencia, segmento, línea editorial, briefing por edición | Apertura / Clicks |
| **Lanzamiento multicanal** | FM1 + FW1 + BD1 | E1-E5 (pre, lanzamiento, post) | Producto, fecha lanzamiento, fases, presupuesto total, mensaje por fase | Ventas |
| **Evento** | FW1 (form web) | E1 confirmación, E2 recordatorio | Producto/evento, fecha, formato, capacidad | Inscripciones |

Account puede crear nuevas plantillas a medida que detecte patrones (ej: si tres clientes pidieron "Sorteo en Instagram" con la misma estructura, esa pasa a ser plantilla).

## 5. Flujo operacional por rol

### Account

1. **Al cerrar o ampliar un cliente:** abre la ficha pública (`work.thenucleo.com/ficha-cliente/?id=<bubble_id>`) y declara los Pipelines del cliente.
2. **Al planificar trabajo con cliente:** crea una Campaña eligiendo Plantilla del catálogo. Duplica el briefing master a Drive del cliente (`/Cliente/Campañas/P1C1 — Nombre/briefing.docx`), lo rellena con el cliente, pega el link en la Campaña.
3. **Declara Triggers (FM/FW/BD) y Emails (E1, E2…)** con su objetivo y espera.
4. **Mantiene la ficha al día** — archiva Campañas inactivas, añade Emails nuevos cuando el cliente pida ampliar, marca Pipelines obsoletos.
5. **Es la única que asigna códigos.** Nunca borra. Nunca renumera.

### PM (Project Manager)

1. **Cada mañana abre la ficha de los clientes activos** y ve el árbol Pipelines → Campañas → Triggers/Emails con su estado (declarada / en producción / archivada).
2. **Para cada Campaña pendiente de montaje, crea las tareas Notion con el código en el título.** Ejemplo: `P1C1E2 — Copy Dra. Neuss`.
3. **Asigna responsables según los roles sugeridos en la Plantilla** (copy → Valentin Arias, diseño → Joaquin Rojo, etc.). Puede desviarse si el caso lo pide.
4. **Pega en la descripción de la tarea Notion el deep-link** a la Campaña en la ficha pública, para que el equipo pueda abrir el briefing sin preguntar.
5. **Verifica al cierre** que cada código tiene sus entregables completos en Drive (si una Campaña declara 3 Emails y solo aparecen 2, salta como anomalía).

### Equipo (Copy, Diseño, Media Buyer, CRM Manager)

1. **Recibe tarea Notion con código en el título.**
2. **Abre Drive en la carpeta del cliente**, busca la subcarpeta del código (`/Cliente/Campañas/P1C1 — Nombre/`), encuentra el briefing y los archivos hermanos (copies de copy, diseños del diseñador, etc.).
3. **Trabaja y guarda con el código como nombre** (`P1C1E2_copy.docx`, `P1C1E2_diseño.png`).
4. **Marca tarea Lista en Notion** cuando termina. Pega el link al entregable en la descripción.
5. **No edita la ficha del cliente.** La ficha es interna de Account+PM.

### Quién hace qué — tabla resumen

| Código | Qué es | Quién declara | Quién materializa |
|---|---|---|---|
| `P` | Línea estratégica de negocio | Account (con cliente) | — |
| `C` | Campaña concreta dentro de un Pipeline | Account (con cliente) | Equipo completo |
| `FM` | Formulario nativo Meta Ads | Account define / Media Buyer crea | Media Buyer |
| `FW` | Formulario en la web del cliente | Account define / Dev o CRM crea | Dev o CRM Manager |
| `BD` | Envío masivo a lista existente | Account define + fecha | CRM Manager |
| `E` | Email individual de secuencia | Account define orden y objetivo | Copy + Diseño + CRM Manager |

## 6. Cómo se consume la información — vistas por rol

### Vista Account — edición completa

Formulario por niveles con botón `+ Pipeline`, dentro `+ Campaña`, dentro `+ Trigger` / `+ Email`. Modal "Crear Campaña" con dropdown del catálogo de Plantillas que precarga campos. Drag para reordenar Emails. Botón "Archivar" en cada elemento (no borrar).

### Vista PM — lectura + acción mínima

Mismo árbol plegado por defecto, badges visuales de estado por elemento (gris = declarada, verde = en producción, gris claro = archivada). Botón "Crear tareas Notion para esta Campaña" que abre el formulario de creación de tareas pre-rellenado con código, cliente y responsables sugeridos.

### Vista Equipo

**No entran a la ficha.** Consumen el código en Notion + briefing en Drive. Esta es una decisión consciente: la ficha es de Account+PM, no del equipo. El equipo recibe sus inputs vía Notion+Drive y devuelve sus outputs por los mismos canales.

## 7. Cómo encaja con Drive, Notion y GHL

### Drive

- La carpeta raíz del cliente y los L1/L2/L3 los crea hoy el workflow `wvHcgVqqjkWJcJDu` al alta del cliente (invoca subworkflow `d0B4LokmPhHWdg6g`). No se modifica.
- **Subcarpeta por Campaña:** la crea Account al declarar la Campaña. Ruta: `/Cliente/Campañas/P1C1 — Nombre/`. Contiene: briefing, copies, diseños, entregables. Pendiente automatizar — por ahora se crea a mano.
- **Nombres de archivo:** llevan siempre el código (`P1C1E2_copy.docx`, `P1C1_estatico_v1.png`).

### Notion

- **Título de tarea:** siempre lleva el código (`P1C1E2 — Copy Dra. Neuss`).
- **Área (`area_tarea`) canónica:** este rediseño obliga a usar un único valor por área. Hoy hay duplicados (`PAID MEDIA` / `Meta Ads` / `Media Buyer` son la misma cosa para Damian). Valores canónicos propuestos:
  - `Meta Ads`
  - `Google Ads`
  - `Newsletter`
  - `CRM`
  - `Diseño`
  - `RRSS`
  - `Project Manager`
  - `Account`
  - `Copy`
- **Sugerencia automática de área a partir del código** (cuando se implemente el formulario forzado):
  - `E` → `Copy` / `Diseño` / `Newsletter` según subtarea.
  - `FM` → `Meta Ads`.
  - `FW` → `CRM`.
  - `BD` → `CRM` / `Newsletter`.

### GHL

Regla derivada del `.docx` (historia Laser Space + caso 7): **una Campaña = un workflow GHL**. Los Triggers son disparadores de entrada del workflow, los Emails son acciones dentro.

- **Workflow GHL** = código de la Campaña: `P1C1`.
- **Disparadores de entrada del workflow** = códigos de los Triggers: `P1C1FM1`, `P1C1FW1`, `P1C1BD1`. Pueden ser 1 o varios conectados al inicio del workflow.
- **Acciones de email dentro del workflow** = códigos de los Emails: `P1C1E1`, `P1C1E2`, `P1C1E3`.

Ejemplo aterrizado — `P1C1` con 3 triggers y emails compartidos:

```
GHL workflow: "P1C1"
├── Entrada:
│   ├── P1C1FM1  (form Meta)
│   ├── P1C1FW1  (form web)
│   └── P1C1BD1  (segmento BBDD)
└── Acciones email:
    ├── P1C1E1  (Día 0)
    ├── P1C1E2  (Día +2)
    └── P1C1E3  (Día +5)
```

Cuando alguien pregunta "¿en qué workflow vive `P1C1E1`?", la respuesta es **en `P1C1`**. Un solo sitio. Cualquiera de los 3 triggers lo dispara.

Si los emails varían por Trigger (caso 3 `.docx`), el workflow `P1C1` tiene ramas internas. Las acciones se llaman `P1C1FM1E1`, `P1C1FW1E1`, etc. Cada rama ejecuta solo sus emails.

## 8. Ejemplo aterrizado: la cuenta de Neus después del rediseño

**Diagnóstico previo** (60 tareas marzo→mayo 2026 sin estructura): 4 pipelines latentes operando en paralelo sin que nadie los haya declarado.

**Estado objetivo** (la ficha de Neus después de que Account/Ben/Melina la rellenen en 30 min):

```
DRA. NEUSS  (bubble_id: 1773847038522x983519237604638700)
│
├── P1 — Venta directa Curso Suplementación
│   │  Objetivo negocio: monetizar el infoproducto Curso Suplementación 75€ a tráfico frío.
│   │  Estado: activo · Responsable account: Melina
│   │
│   └── P1C1 — Curso Suplementación 75€  (Plantilla: Venta Directa con anuncio Meta)
│       │  Briefing Drive: [PDF "Campaña de ventas - Curso suplementación" cargado por Account]
│       │  Presupuesto: 500€ Meta · KPI: 30 ventas/mes
│       │  Estado: en producción · Inicio: 15-may
│       │
│       └── P1C1FM1 — Anuncio Meta → checkout GHL
│           Tipo: FM · Link: [funnel.neusmunozgost.com/curso-suplementacion-clinica-40]
│           (sin Emails declarados — venta directa sin secuencia post-compra de momento)
│
├── P2 — Captación de clientes potenciales
│   │  Objetivo negocio: nutrir BBDD con leads cualificados para futuras ofertas.
│   │
│   └── P2C1 — Captación leads  (Plantilla: Captación leads vía FM)
│       │  Briefing Drive: [link]
│       │
│       ├── P2C1FM1 — Formulario Meta "clientes potenciales"
│       ├── P2C1E1 — Bienvenida + valor (Día 0)
│       ├── P2C1E2 — Educación (Día +2)
│       └── P2C1E3 — Oferta curso suplementación (Día +5)
│
├── P3 — Reactivación leads
│   │  Objetivo negocio: recuperar leads sin conversión >60d.
│   │
│   └── P3C1 — Relanzamiento clientes potenciales  (Plantilla: Reactivación BBDD)
│       │  Briefing Drive: [link]
│       │
│       ├── P3C1BD1 — Segmento "leads sin conversión >60d" en GHL · fecha: 25-may
│       └── P3C1E1 — Reactivación
│
└── P4 — Newsletter mensual
    │  Objetivo negocio: mantener relación con BBDD activa.
    │
    └── P4C1 — Newsletter mayo  (Plantilla: Newsletter recurrente)
        │  Briefing Drive: [link "Briefing Mayo"]
        │
        ├── P4C1BD1 — BBDD activa · cadencia mensual
        └── P4C1E1 — Edición mayo
```

**Qué cambia en Notion (proyección):**

Las tareas históricas se dejan como están (auditoría). Las nuevas:

| Antes (caos actual) | Después (con código) |
|---|---|
| `Investigar pixel de conversión` + `Pixel de seguimiento ventas` + `Píxel de conversión` (3 tareas distintas) | `P1C1FM1_pixel` (1 sola tarea — las otras dos ya no se pueden crear) |
| `Lanzamiento de campañas` (3 veces en fechas distintas) | `P1C1FM1_lanzar`, `P2C1FM1_lanzar`, `P4C1BD1_lanzar` (3 tareas claras) |
| `Briefing Mayo` Newsletter + `Briefing Mayo` RRSS | `P4C1_briefing` (uno solo — RRSS de mayo cuelga de otro Pipeline si existe) |
| `Maquetar email` | `P4C1E1_maquetar` |
| `Copys de Anuncios` | `P1C1FM1_copys` |
| `Aprobación del cliente` (¿de qué?) | `P1C1_aprobacion_cliente` |
| `OUTPUT NEUS` / `12/5 || Input 2DO Lanzamiento` (tareas-comodín de la PM) | Deja de necesitarlas — la información de input vive en la ficha, no en una tarea suelta |

**Efecto medible esperado:** cero tareas duplicadas de píxel en el siguiente mes. La PM debería notarlo en menos de una semana.

## 9. Qué NO incluye esta visión

Para evitar scope creep, este documento deja **fuera** explícitamente:

- **Modelo de datos Supabase exacto** (tablas `cliente_pipelines`, `cliente_campanias`, `cliente_triggers`, `cliente_emails`, `cliente_plantillas_campania`). Se diseñará en sesión aparte (ver §10).
- **UX visual de la ficha pública.** Esta visión describe qué información hay y cómo fluye, no cómo se pinta. El mockup vendrá después.
- **Modificación del formulario "Crear tarea" en Bubble.** La disciplina del dropdown obligatorio de código se diseñará e implementará en otra sesión.
- **Sync ficha → Drive automático** (creación de subcarpeta `/Cliente/Campañas/P1C1 — Nombre/` al declarar Campaña). De momento la subcarpeta la crea Account a mano.
- **Validación automática "tienes 3 Emails declarados pero solo 2 entregables en Drive".** El reporting de huecos vendrá después.
- **Asume que el equipo cumplirá la regla "Account asigna códigos, equipo consume".** La herramienta que lo fuerza vendrá después.

## 10. Siguientes pasos (no parte de esta sesión)

1. **Validar este doc con Melina (PM).** Que lo lea en 15 min y diga si entiende cómo se rellena la ficha de Neus sin tener que preguntar.
2. **Piloto Neus.** Ben + Melina sentados 30 min declaran los 4 Pipelines de Neus en un mockup de papel/HTML. Validan si el modelo aguanta.
3. **Diseñar el modelo de datos Supabase.** Tablas, RPCs, RLS. Sesión técnica aparte.
4. ~~**Refactor del bloque MOCKUP de Pipelines** en `work.thenucleo.com/ficha-cliente/` para que sea funcional.~~ ✅ **Hecho 2026-05-23** — frontend del módulo vivo con seed F1 hardcoded (4 pipelines de Dra. Neuss). Falta cablear backend Supabase (`cliente_pipelines` + `cliente_campanias` + `cliente_triggers` + `cliente_emails` + RPCs) = F2.
5. **Modificar formulario "Crear tarea" en Bubble** para forzar dropdown de código del catálogo del cliente.
6. **Catálogo seed de Plantillas** — crear las 7 plantillas del seed inicial (§4) con sus briefings master en Drive.
7. **Migrar 5 clientes más activos** al modelo en sesiones acompañadas con Account.

## Referencias

- `TheNucleoNomenclatura2.docx` — fuente original de la nomenclatura PxCx (Ben, 2026-05-23). Este documento la incorpora alineada con la implementación.
- `Campaña de ventas - Curso suplementación.pdf` — briefing real cargado por Ben como ejemplo de lo que hoy es un doc Drive suelto. En la visión v2 es el `link_briefing_drive` de la Campaña `P1C1` de Neus.
- [[secciones-app#Ficha Cliente (`/clientes/{empresa_id}`)]] — ficha interna Bubble actual.
- [[secciones-app#Ficha Cliente — `work.thenucleo.com/ficha-cliente/` (admin allowlist, desde 2026-05-22)]] — ficha pública actual: módulo Pipelines vivo con seed F1 de Dra. Neuss (2026-05-23); Catálogos y Anomalías siguen MOCKUP a la espera de cableado F2.
- [[../infra/supabase-schema|supabase-schema]] sección `bub_clientes` + `playbook_cliente_servicios`.
- [[../infra/n8n-workflows|n8n-workflows]] — workflow `wvHcgVqqjkWJcJDu` (crea carpetas Drive) y `eHyXBETcaGSNXqLk` (crear tarea Notion desde Bubble).
