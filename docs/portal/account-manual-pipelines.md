# Manual de Account — Pipelines, Campañas y nomenclatura PxCx

Audiencia: Account (Melina y quien venga). Lectura: 10 minutos. Acción: 30 minutos por cliente para llenar el mapa la primera vez. Después, 2-5 minutos por cambio.

## 0. Por qué existe esto

Hoy, cuando hablas con un cliente y quedas en montar algo (una campaña, una newsletter, un lanzamiento), pasa esto:

1. Lo cuentas en daily a Melina.
2. Melina crea tareas sueltas en Notion con nombres descriptivos pero ambiguos ("Lanzamiento de campañas", "Maquetar email", "Briefing Mayo").
3. El equipo recibe la tarea y necesita preguntar para entender contexto.
4. Si dos miembros trabajan en cosas distintas con nombres parecidos, se duplican (a Neus le llegaron 3 tareas de "píxel de conversión" diferentes en la misma semana).
5. Si entra alguien nuevo, no hay sitio único al que mirar.

La ficha pública de cliente con el bloque **Pipelines y Campañas** soluciona esto. Tú vuelcas el mapa una vez. Melina y el equipo lo consumen. Cuando el cliente pide un cambio, tocas la ficha y todo se actualiza.

## 1. Las tres capas que vas a manejar

Piensa en cada cliente como un libro con tres niveles:

- **Cliente** — ya existe (nombre, fiscal, accesos, Drive, etc.). No lo tocas tú aquí.
- **Pipeline (P)** — una **línea estratégica de negocio** del cliente. Un cliente típico tiene entre 1 y 4. Vive meses o años. Si tu Pipeline tiene fecha de fin concreta, **no es un Pipeline — es una Campaña**.
- **Campaña (C)** — una **acción concreta** dentro de un Pipeline. Tiene objetivo medible y normalmente fechas. Es la unidad de trabajo del equipo.

Dentro de una Campaña hay dos cosas:
- **Triggers** — qué dispara la campaña (un formulario, una base de datos).
- **Emails** — los correos que se mandan.

## 2. Cómo se llaman las cosas (nomenclatura PxCx)

Cada cosa tiene un código tipo "dirección postal" que la ubica:

| Código | Qué es | Ejemplo |
|---|---|---|
| `P1`, `P2`… | Pipeline | `P1` = Captación cumpleaños |
| `P1C1`, `P1C2`… | Campaña dentro de Pipeline | `P1C1` = Bienvenida padres |
| `P1C1FM1` | Formulario Meta dentro de Campaña | Anuncio Instagram |
| `P1C1FW1` | Formulario Web | Form en la home |
| `P1C1BD1` | Envío a base de datos | Black Friday a BBDD |
| `P1C1E1`, `P1C1E2`… | Emails de la secuencia | E1 bienvenida, E2 valor, E3 oferta |

Reglas que **no se rompen nunca**:

1. **Siempre empiezas por P.** Nunca dices "FM1" suelto. Dices "P1C1FM1".
2. **El orden es fijo**: P → C → FM/FW/BD → E. Nunca al revés.
3. **Los números son secuenciales por contexto**: el `C1` de un Pipeline no tiene nada que ver con el `C1` de otro Pipeline.
4. **Los números no se reutilizan.** Si eliminas la Campaña 2 de un Pipeline, la siguiente que crees es C3, no C2.
5. **Solo tú asignas códigos.** El equipo los consume, no los crea. Si necesitan uno nuevo, te lo piden a ti.
6. **Los códigos no caducan.** Cuando una Campaña deja de funcionar, **se archiva, no se borra**. El código sigue existiendo para auditoría.
7. **Mismo código en todos lados**: Drive, Notion, GHL, chats del equipo. Una sola palabra para nombrar la cosa.

## 3. Tu flujo diario, paso a paso

### Cuando empiezas con un cliente nuevo (primera vez)

1. **Abre la ficha del cliente** en `work.thenucleo.com/ficha-cliente/?id={cliente}` (selecciona desde el menú admin).
2. **Despliega la sección "Pipelines y Campañas"** (sale abierta por defecto).
3. Pregúntate: *¿qué líneas de negocio distintas tiene este cliente?* Cada respuesta es un Pipeline.
   - Ejemplo Neus: vende un curso 75€ (P1), capta leads (P2), reactiva leads viejos (P3), tiene newsletter mensual (P4). Son 4 pipelines distintos.
4. **Pulsa "+ Pipeline"** en el sidebar para cada uno. Ponle nombre operativo corto y objetivo de negocio.
5. **Dentro de cada Pipeline crea sus Campañas**: pulsa "+ Campaña en P1" → se abre el modal de plantilla.

### Cuando el cliente te pide algo nuevo en una conversación

1. **Identifica el Pipeline** que toca. ¿Es algo nuevo o cae en uno existente?
   - Si es nuevo → "+ Pipeline" primero.
   - Si encaja en uno existente → ve directo a Campañas.
2. **Crea la Campaña** con el modal:
   1. Elige una plantilla del catálogo (Venta Directa, Captación leads FM/FW, Reactivación BBDD, Newsletter recurrente, Lanzamiento multicanal, Evento) o "Sin plantilla" si es algo nuevo.
   2. Rellena nombre, fechas (vacío = recurrente), presupuesto, KPI.
   3. **Pega el link al briefing en Drive.** Si la plantilla tenía un briefing master, duplícalo a `/Cliente/Campañas/PxCx — Nombre/` y pega ese link. Si no hay master, sube tú el briefing al Drive del cliente y pega el link.
   4. La plantilla ya te ha pre-cargado Triggers y Emails típicos. Ajústalos si hace falta.
3. **Avisa a Melina** (en GChat del cliente o en daily): "Cliente X tiene nueva campaña `P2C3`. Está en la ficha. Necesita montaje".

### Cuando el cliente te pide modificar algo existente

- **Modificar un email existente** ("el email 2 no convierte, vamos a rehacerlo"): **no creas código nuevo**. Mantienes `P1C1E2`. El equipo versiona internamente en Drive (`P1C1E2_v2_copy.docx`).
- **Añadir un email a una secuencia** ("metedme un cuarto email con descuento"): pulsas "+ Email" en la Campaña, se crea `P1C1E4`. No renumeras los anteriores.
- **Desactivar una campaña**: pulsa "Archivar campaña" en el detalle. La Campaña no desaparece — queda visible si activas el toggle "Mostrar archivados" en el sidebar.

## 4. Cuándo usar plantilla y cuándo "Sin plantilla"

Usa plantilla **siempre que el patrón encaje**. Las plantillas:
- Te pre-cargan campos típicos (KPI, presupuesto).
- Crean los Triggers y Emails típicos automáticamente.
- Sugieren a quién asigna las tareas el equipo.
- Apuntan a un briefing master en Drive listo para duplicar.

Usa **"Sin plantilla / custom"** cuando:
- Es algo totalmente nuevo que no se parece a nada del catálogo.
- Es una campaña experimental o muy puntual.

Si detectas que estás usando "Sin plantilla" varias veces para algo parecido, **pulsa "+ Nueva plantilla"** y créala. Queda disponible para todos los clientes y la siguiente vez vas más rápido. El catálogo es tuyo.

## 4.bis Qué tareas se generan al declarar (tabla maestra)

Cuando declaras una Campaña con plantilla y la PM pulsa "Crear tareas Notion", esto es lo que se genera (la PM lo ajusta si hace falta). Útil que tengas el mapa para saber qué entregables se mueven al equipo:

| Código del entregable | Acción | Rol que lo hace | Área Notion |
|---|---|---|---|
| `PxCx_briefing` / `_angulos` / `_cluster` / `_briefing_estaticos` / `_briefing_video` | Briefing creativo y ángulos de venta | **Estratega creativo** (Valen / Valentina) | Estrategia |
| `PxCxEn_copy` / `PxCx_copy_RRSS_vN` / `PxCx_copy_estaticos` | Copy de emails y RRSS | **Copy** (Valen / Valentin Arias) | Copy / Newsletter |
| `PxCxEn_diseno` / `PxCx_estatico_vN` / `PxCx_reel_vN` / `PxCx_carrusel_vN` / `PxCx_video` | Diseño de emails y creatividades ad | **Diseño** (Valentin Arias / Joaquin Rojo) | Diseño |
| `PxCxFMn_form` / `_pixel` / `_estaticos_subir` / `PxCx_lanzar` | Formularios Meta + lanzamiento campaña | **Media Buyer** (Damian) | Meta Ads |
| `PxCxFWn_form` / `PxCxBDn_segmento` / `PxCx_ghl` / `PxCxEn_montaje` | Formularios web, segmentos BBDD, workflow GHL | **CRM Manager** (Camilo Balanta) | CRM |

Si quieres que el Estratega creativo trabaje **antes** que Copy/Diseño/Media Buyer/CRM (recomendado), declaras los briefings primero como "Declarada" y dejas los demás emails/triggers como "Declarada" — la PM solo genera tareas del Estratega hasta que cierre. Después declara el resto.

## 5. Cómo encaja la nomenclatura con el resto

### Drive
Cada Campaña tiene su subcarpeta en el Drive del cliente: `/Cliente/Campañas/P1C1 — Nombre/`. Dentro vive todo lo de esa Campaña: briefing, copies, diseños, vídeos. **Los nombres de archivo llevan el código**: `P1C1E2_copy.docx`, `P1C1FM1_estatico_v3.png`. Esto lo hace el equipo, tú solo te aseguras de que el link al briefing esté pegado en la ficha.

### Notion (tareas del equipo)
Melina crea las tareas en Notion **con el código en el título**: `P1C1E2 — Copy Dra. Neuss`. El formulario "Crear tarea" en Bubble la obliga a elegir un código del catálogo del cliente — no puede crear tareas con nombres genéricos como "Lanzamiento de campañas" para clientes con Pipelines declarados.

### GHL
El nombre del workflow y de las acciones de email en GHL es **exactamente el código**: `P1C1` el workflow, `P1C1E1`, `P1C1E2`, `P1C1E3` las acciones. Camilo lo monta así.

### Creatividades RRSS / estáticos / reels
Viven en Drive con nomenclatura `PxCx_<tipo>_v<n>` (`P1C1_estatico_v1.png`, `P1C1_reel_v2.mp4`, `P1C1_copy_RRSS_v1.docx`). No se listan en la ficha — eso es decisión consciente. La ficha es para Pipelines/Campañas/Triggers/Emails. Las creatividades cuelgan de su Campaña en Drive y ya está.

## 6. Casos comunes y cómo se resuelven

**El cliente tiene una campaña con varios triggers que llevan al mismo email** (ej: un anuncio Meta y un formulario web disparan el mismo email de bienvenida).
- En la ficha declaras `P1C1FM1`, `P1C1FW1` y `P1C1E1` con sus "Triggers aplicables" = ambos.
- El código del email queda como `P1C1E1` (sin trigger en el código) porque los triggers comparten emails.

**El cliente tiene una campaña con varios triggers pero cada trigger manda emails diferentes** (ej: el FM1 manda E1-E3, el FW1 manda E4-E5).
- Marcas en cada Email qué Triggers le aplican.
- Los códigos quedan `P1C1FM1E1`, `P1C1FW1E4`, etc. (el trigger aparece en el código porque diferencia).

**Una pieza (un estático) vale para dos Campañas distintas** (`P1C1` y `P1C2` son campañas hermanas).
- En Drive se duplica el archivo con cada código: `P1C1_estatico.png` y `P1C2_estatico.png`. No usas un nombre con doble código.

**El cliente cancela el servicio**.
- La ficha del cliente entera pasa a "No Activo" (eso ya existe en `bub_clientes`). Los códigos no se tocan. Si vuelve en 6 meses, todo está intacto.

## 7. Cuando entra alguien nuevo al equipo

Le dices "modifica `P1C1E2` de Dra. Neuss". Punto. Va a Drive `/Dra-Neuss/CRM/P1C1/P1C1E2_copy.docx`, lo modifica, lo guarda, va a GHL, busca `P1C1E2`, lo actualiza. Sin preguntar a nadie. Sin reuniones de contexto.

Esa es la promesa del sistema. Tú vuelcas el mapa, el sistema habla solo.

## 8. Lo que NO tienes que hacer

- **No tienes que llenar el briefing en la ficha**. La ficha solo apunta a Drive. El briefing largo (info producto, ángulos, cluster, guion vídeo) vive en el Doc/PDF de Drive como hasta ahora.
- **No tienes que crear las tareas en Notion**. Eso lo hace Melina. Tú solo dejas la Campaña declarada en la ficha y avisas.
- **No tienes que renumerar nada cuando archivas algo.** Los números avanzan, no retroceden.
- **No tienes que abrir Notion** para mantener esto. La ficha es tu sitio.

## 9. Resumen en una frase

> Pipelines son las líneas de negocio del cliente. Campañas son acciones concretas dentro. Triggers son qué dispara. Emails son qué se manda. Tú declaras la estructura en la ficha. El equipo trabaja con código en Notion + briefing en Drive. Lo que no está en la ficha, no existe.

## 10. Si algo no encaja

Hablas con Ben. Si detectas que el sistema no soporta una casuística real de un cliente, no inventes una solución por tu cuenta — apunta el caso y se evalúa. La nomenclatura está pensada para casos típicos, no para todos.
