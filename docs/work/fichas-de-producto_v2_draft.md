---
title: Fichas de Producto v2 — borrador para revisión (homogeneización con Excel comercial)
dominio: fichas-de-producto
estado: borrador
creado: 2026-05-20
fuente: cruce del Excel "Servicios vendidos en Onboarding.xlsx" (7 clientes, 199 filas) con las 63 fichas operativas actuales
total: 57 fichas comerciales unificadas
---

# Fichas de Producto v2 — Borrador

> **Qué es esto:** propuesta de las 57 fichas comerciales nuevas que sustituirán a las 63 operativas actuales. Una por servicio que se le vende al cliente. Cantidad embebida en `unidad`. Dudas del equipo dentro de `alcance`. Sin filtro por plan ni por cliente (es el catálogo, no la asignación).
>
> **Cómo revisar:** ve por categorías. Si una ficha está mal redactada o sobra/falta, márcalo en el comentario lateral o dímelo en chat. Cuando acabes, generamos el SQL `DELETE + INSERT` batch para aplicarlo a Supabase.
>
> **Fusiones literales aplicadas (62 → 57):**
> - `CRM - licencia mensual (GHL)` + `CRM — licencia mensual (GHL)` → 1
> - `Google My Business -` + `Google My Business —` → 1
> - `Pipeline de seguimiento en CRM` + `Pipelines de seguimiento en CRM` → 1
> - `Optimización perfil Instagram (bio + portadas)` + `(bio + portadas / identidad visual)` → 1
> - `Revisión de puntos de contacto (web, teléfono, correo, IG)` + `Revisión de puntos de contacto con usuario` → 1
>
> **Categorías vacías:** `Producción Audiovisual` y `Soporte y Relación con el Cliente`. El Excel no las cubre. Las mantenemos en `fichas_categorias` por si se rellenan más adelante; ahora sin fichas dentro.
>
> **Convención:** los `[???]` señalan información que no consta en Excel ni en las fichas previas. Se quedan literales en `flexibilidad` para que las completes a mano. Los bloques `Pendiente aclarar` dentro de `alcance` son dudas del equipo capturadas en el Excel (columna F).

---

## 1. Onboarding (4 fichas)

### `Sesión de onboarding`
- **Unidad:** 1 sesión inicial (one-shot)
- **Alcance:** Reunión inicial con el cliente para alinear expectativas, recoger información necesaria para arrancar el servicio (datos del negocio, accesos, ficha de producto, cliente ideal, calendario de temporada) y dejar definido el plan de acción de las primeras semanas. Duración aprox. 90 min. La conduce Valentina o Mel.
- **No incluye:** Ejecución de las tareas posteriores (cada una es su ficha) · estrategia profunda — solo alineación y recogida · reuniones técnicas de configuración (van como reuniones técnicas aparte)
- **Flexibilidad:** El conductor puede extender la reunión si el cliente lo necesita · si el cliente no aporta info clave, se generan tareas de resolución de incidencias técnicas
- **sop_url:** —

### `Análisis de cuenta, competencia y propuesta de valor`
- **Unidad:** 1 análisis inicial (one-shot)
- **Alcance:** Análisis del negocio del cliente: cuenta, competencia, posicionamiento y propuesta de valor. Incluye investigación de competidores, definición de ángulos de venta y buyer persona, y entregable con conclusiones que sirve como base para todas las campañas posteriores (Meta, Google Ads, contenido). **Pendiente aclarar (Segosky):** si el cliente solo contrata Google Ads, ¿se hace igual o solo la parte relevante?
- **No incluye:** Análisis de keywords (ficha aparte en Google Ads) · diseño de anuncios · estrategia de captación operativa
- **Flexibilidad:** El consultor decide profundidad y número de competidores · [???] formato del entregable (informe vs reunión)
- **sop_url:** —

### `Setup de arranque`
- **Unidad:** 1 pago único (one-shot)
- **Alcance:** Setup técnico de arranque del servicio: alta de subcuenta de GHL, configuración del pipeline estándar, conexiones (correo corporativo, Google Ads, Meta Ads, WhatsApp Oficial), configuración de Meta Business (Instagram Portfolio, Facebook Portfolio, Pixel API, audiencias base), pack inicial de plantillas de WhatsApp aprobadas por Meta y automatizaciones base del CRM (alta de contacto, oportunidad en pipeline, primer correo y primer WhatsApp automáticos).
- **No incluye:** Redacción del copy del primer correo/WhatsApp (fichas aparte) · diseño visual del primer correo (ficha aparte) · automatizaciones avanzadas o personalizadas (entran en Mejoras del CRM) · configuración de DNS del dominio del cliente
- **Flexibilidad:** Si el cliente no tiene Facebook Business Manager verificado o no tiene acceso a DNS, [???] decisión de a quién se escala · el ejecutor decide identificadores internos según convención de agencia
- **sop_url:** —

### `Definición de estrategia, flujos y secuencias de interacción del lanzamiento`
- **Unidad:** 1 definición inicial (one-shot)
- **Alcance:** Documento estratégico inicial que describe cómo van a interaccionar los distintos canales del cliente durante las primeras semanas: qué flujo siguen los leads, qué secuencias de mensajes se disparan en cada canal (Meta, WhatsApp, correo), qué objetivos publicitarios y qué KPIs miden el éxito del lanzamiento.
- **No incluye:** Montaje técnico de los flujos y secuencias (cubierto por las fichas operativas correspondientes del CRM) · diseño de anuncios · planificación de contenidos posterior
- **Flexibilidad:** El consultor decide profundidad del documento · [???] formato del entregable
- **sop_url:** —

---

## 2. Google Ads (5 fichas)

### `Estructura campaña Google Ads`
- **Unidad:** 1 campaña + hasta 2 conjuntos de anuncios (one-shot al arrancar)
- **Alcance:** Diseño de la estructura inicial de la cuenta de Google Ads: análisis de keywords propias, análisis de keywords de competencia, agrupación en campañas y conjuntos de anuncios, preparación del listado para aprobación del cliente y publicación una vez aprobado. Incluye configuración inicial de la cuenta (recursos, eventos, conversiones, audiencias). **Pendiente aclarar (Tengo Teatro):** equipo declaró "no sabemos qué es este servicio" — concretar qué incluye exactamente la estructura.
- **No incluye:** Redacción del copy de los anuncios — [???] ¿o sí? · seguimiento posterior (cubierto por Gestión Google Ads)
- **Flexibilidad:** El ejecutor decide número y agrupación de campañas/ad groups según buenas prácticas · [???] decisión de presupuesto por campaña (ejecutor vs cliente)
- **sop_url:** —

### `Gestión Google Ads`
- **Unidad:** Incluida (servicio recurrente mientras dure el contrato)
- **Alcance:** Gestión continua de la cuenta de Google Ads: revisión periódica del rendimiento, optimización ad-hoc (pausar lo que no funciona, ajustar pujas, refinar audiencias, añadir/quitar negativas), informe mensual manual con KPIs y conclusiones e informe semanal automático.
- **No incluye:** Creación de campañas nuevas desde cero (eso es lanzamiento separado) · rediseño completo de la estructura · cambios pedidos por el cliente que requieran análisis estratégico nuevo · recomendaciones estratégicas profundas (eso es consultoría)
- **Flexibilidad:** El ejecutor decide qué optimizaciones aplicar según criterio técnico sin consultar · [???] qué tipo de cambios sí requieren consulta con el cliente o con responsable
- **sop_url:** —

### `Campañas en Google Ads`
- **Unidad:** Hasta 2 campañas activas
- **Alcance:** Diseño y montaje de hasta 2 campañas de Google Ads activas en simultáneo a lo largo del servicio (más allá del setup inicial): estructura de keywords, copy de anuncios, audiencias, lanzamiento.
- **No incluye:** Estructura inicial (cubierto por Estructura campaña Google Ads) · seguimiento continuo (cubierto por Gestión Google Ads)
- **Flexibilidad:** [???] qué se cuenta como "campaña" frente a "ajuste de campaña existente"
- **sop_url:** —

### `Revisión diaria de campañas Google Ads y negativización`
- **Unidad:** Continua (diaria mientras dure el contrato)
- **Alcance:** Revisión diaria de las búsquedas que han activado los anuncios para añadir keywords negativas que evitan tráfico irrelevante y optimizar el coste por clic. Operativa de bajo nivel del especialista en Google Ads.
- **No incluye:** Cambios estructurales de campañas (cubierto por Gestión Google Ads) · informes al cliente (parte de Gestión Google Ads)
- **Flexibilidad:** [???] frecuencia mínima si un día no se llega
- **sop_url:** —

### `Definición de enfoque y objetivos publicitarios`
- **Unidad:** 1 definición inicial (one-shot)
- **Alcance:** Documento inicial que fija el enfoque y los objetivos de las campañas publicitarias del cliente: qué se busca medir (leads, ventas, llamadas), qué presupuesto se asume, qué prioridades hay entre productos/servicios. Sirve como punto de partida para que el equipo de Ads construya las campañas.
- **No incluye:** Estructura técnica de las campañas (fichas aparte) · diseño de anuncios
- **Flexibilidad:** [???] formato del documento · [???] iteraciones con el cliente
- **sop_url:** —

---

## 3. Meta Ads (8 fichas)

### `Estrategia de captación continua (Meta + Google Ads)`
- **Unidad:** 1 campaña activa simultánea (servicio continuo)
- **Alcance:** Estrategia transversal Meta + Google Ads que mantiene al menos 1 campaña activa simultánea en cada canal durante todo el servicio: definición de objetivo, presupuesto, audiencias, ángulos de venta, calendario y revisiones. **Pendiente aclarar (Segosky):** ¿se aplica si el cliente solo contrata Google Ads (cliente cree que no, pero el servicio dice Meta + Google)?
- **No incluye:** Gestión operativa de cada canal (cubierto por Gestión Meta Ads y Gestión Google Ads) · diseño de anuncios
- **Flexibilidad:** [???] el "1 simultánea" es mínimo o tope · [???] decisión de reparto de presupuesto Meta vs Google
- **sop_url:** —

### `Anuncios iniciales Meta de arranque`
- **Unidad:** 6 anuncios iniciales (pack de arranque, one-shot)
- **Alcance:** Producción y publicación del pack inicial de 6 anuncios para Meta. Cubre el ciclo completo: briefing interno del servicio, definición de clusters y ángulos, preparación del briefing creativo, presentación al cliente para aprobación, diseño efectivo de las 6 creatividades y subida + lanzamiento en Meta Ads Manager. **Pendiente aclarar (Tengo Teatro):** "hasta 6 si funcionan, si no los que hagan falta" — homogeneizar si el tope son 6 estrictos o flexibles. **Pendiente aclarar (Yucalcari):** equipo creía que eran 4, no 6 — unificar comunicación.
- **No incluye:** Captura de material audiovisual (sería Producción audiovisual on-site, no contratada actualmente) · seguimiento posterior (cubierto por Gestión Meta Ads) · anuncios adicionales fuera del pack inicial (cubierto por Actualizaciones mensuales)
- **Flexibilidad:** [???] iteraciones máximas con el cliente en briefing y diseño · el diseñador decide variantes visuales dentro del briefing aprobado
- **sop_url:** —

### `Anuncios nuevos al mes (Meta)`
- **Unidad:** Hasta 2 anuncios nuevos por mes
- **Alcance:** Producción mensual de hasta 2 anuncios nuevos para Meta más allá del pack inicial: briefing creativo, diseño y subida.
- **No incluye:** Optimización de anuncios existentes (cubierto por Gestión Meta Ads) · captura de material audiovisual nuevo
- **Flexibilidad:** [???] iteraciones del cliente · [???] qué se cuenta como "anuncio nuevo" vs "variante de uno existente"
- **sop_url:** —

### `Actualizaciones mensuales de anuncios Meta`
- **Unidad:** Mensual (continuo)
- **Alcance:** Refresco mensual de los anuncios de Meta cuando se detecta fatiga creativa o caída de rendimiento: ajuste de copy, cambio de creatividad, prueba de variantes. **Pendiente aclarar (Tengo Teatro):** ¿qué significa "funcionando"? ¿Si un anuncio funciona se actualiza o se mantiene?
- **No incluye:** Anuncios nuevos completos desde briefing (cubierto por Anuncios nuevos al mes) · rediseño estratégico (sería nuevo análisis inicial)
- **Flexibilidad:** El ejecutor decide qué anuncios refrescar según rendimiento · [???] cuántas actualizaciones cuenta una al mes
- **sop_url:** —

### `Gestión Meta Ads`
- **Unidad:** Incluida (servicio recurrente mientras dure el contrato)
- **Alcance:** Gestión continua de la cuenta de Meta Ads: revisión periódica del rendimiento, optimización ad-hoc (pausar lo que no funciona, ajustar pujas, refinar audiencias), ampliación con nuevos anuncios cuando se observa fatiga creativa o se necesita escalar.
- **No incluye:** Diseño de anuncios desde cero con briefing nuevo (eso es ciclo completo aparte) · informes mensuales al cliente (asimetría con Google: en Meta no se entrega informe) · rediseño estratégico
- **Flexibilidad:** El ejecutor decide qué optimizaciones aplicar sin consultar · [???] qué tipo de cambios requieren consulta · [???] cuántos anuncios nuevos al mes incluye la ampliación
- **sop_url:** —

### `Campañas en Meta`
- **Unidad:** Hasta 2 campañas simultáneas, 8 anuncios/mes
- **Alcance:** Diseño y montaje de hasta 2 campañas activas en simultáneo con un total de hasta 8 anuncios al mes entre todas (más allá del pack inicial de arranque): estructura, audiencias, copy, creatividades, lanzamiento.
- **No incluye:** Pack inicial (cubierto por Anuncios iniciales Meta de arranque) · seguimiento (cubierto por Gestión Meta Ads)
- **Flexibilidad:** El equipo decide cómo repartir los 8 anuncios entre las 2 campañas según rendimiento · [???] qué se cuenta como "campaña simultánea"
- **sop_url:** —

### `Definición de estrategia de anuncios`
- **Unidad:** Incluida (one-shot inicial)
- **Alcance:** Documento o sesión que fija la estrategia de anuncios del cliente: clusters de público, ángulos de venta, mensajes principales, recursos visuales que se utilizarán y calendario de prueba.
- **No incluye:** Diseño efectivo de los anuncios (cubierto por Anuncios iniciales / Anuncios nuevos) · seguimiento posterior
- **Flexibilidad:** [???] entregable (informe vs reunión) · [???] iteraciones con el cliente
- **sop_url:** —

### `Diseño anuncios Meta por campaña promocional`
- **Unidad:** 3 anuncios por campaña promocional
- **Alcance:** Diseño de las 3 creatividades de Meta que se lanzan dentro de cada campaña promocional mensual: copy, imagen/vídeo, llamada a la acción, dimensiones adaptadas a cada placement.
- **No incluye:** Briefing creativo previo (es parte de Campaña promocional mensual) · subida y lanzamiento (es parte de Campaña promocional mensual) · captura de material audiovisual nuevo
- **Flexibilidad:** El diseñador decide variantes visuales dentro del brief · [???] iteraciones con el cliente
- **sop_url:** —

---

## 4. CRM (23 fichas)

### `CRM — licencia mensual (GHL)`
- **Unidad:** Incluida (recurrente mensual)
- **Alcance:** Licencia mensual de la subcuenta del cliente dentro de GoHighLevel (CRM de agencia) repercutida a través del servicio.
- **No incluye:** Configuración inicial del CRM (cubierto por Setup de arranque o Implementación del CRM) · mejoras y personalizaciones (fichas aparte)
- **Flexibilidad:** Ninguna — el coste está fijo y forma parte del servicio
- **sop_url:** —

### `Mensaje de bienvenida por correo`
- **Unidad:** 1 mensaje automatizado (one-shot inicial)
- **Alcance:** Redacción del copy y configuración del primer correo automático que recibe un lead cuando entra al CRM. Texto adaptado al cliente y al buyer persona. Queda integrado en la automatización de alta de leads.
- **No incluye:** Diseño visual del correo (sería trabajo extra, no incluido aquí) · configuración técnica de la automatización (cubierto por Setup de arranque)
- **Flexibilidad:** [???] iteraciones de copy con el cliente
- **sop_url:** —

### `Mensaje de bienvenida por WhatsApp`
- **Unidad:** 1 mensaje automatizado (one-shot inicial)
- **Alcance:** Redacción del copy del primer WhatsApp automático que recibe un lead cuando entra al CRM, ajustado al formato de plantilla aprobable por Meta. Incluye gestión de la aprobación de Meta y configuración en GHL.
- **No incluye:** Plantillas adicionales fuera de la inicial · configuración técnica del envío automático (cubierto por Setup de arranque)
- **Flexibilidad:** [???] iteraciones con el cliente · [???] hasta cuántas iteraciones si Meta rechaza la plantilla
- **sop_url:** —

### `Configuración WhatsApp automatizado`
- **Unidad:** Incluida (one-shot inicial)
- **Alcance:** Conexión y verificación de la cuenta de WhatsApp Business API (Oficial) con la subcuenta de GHL para poder enviar plantillas y mensajes automatizados desde el CRM.
- **No incluye:** Chatbot conversacional (cubierto por Desarrollo) · redacción del primer mensaje de WhatsApp (ficha aparte) · plantillas nuevas fuera del pack inicial
- **Flexibilidad:** Si el cliente no tiene Facebook Business Manager verificado, [???] quién lo gestiona
- **sop_url:** —

### `Secuencias automáticas de bienvenida (CRM)`
- **Unidad:** Incluidas (one-shot inicial)
- **Alcance:** Configuración de las secuencias automáticas que arrancan cuando entra un lead: serie de correos y WhatsApps espaciados en el tiempo que nutren al lead durante los primeros días hasta que se convierte o se enfría.
- **No incluye:** Redacción de los copys individuales (cubierto por Mensaje de bienvenida correo/WhatsApp para los iniciales) · mensajes para campañas promocionales (fichas aparte)
- **Flexibilidad:** El ejecutor decide número de pasos y espaciado según buenas prácticas · [???] cuántos pasos estándar tiene la secuencia
- **sop_url:** —

### `Respuesta de reseñas automáticas`
- **Unidad:** Incluida (recurrente)
- **Alcance:** Configuración de respuestas automáticas a las reseñas que entran en Google My Business y otros canales relevantes. **Pendiente aclarar (Tengo Teatro):** equipo declaró "no está definido el servicio" — concretar exactamente qué cubre (¿solo positivas? ¿negativas? ¿plantilla fija? ¿adaptado por reseña?).
- **No incluye:** Gestión de crisis de reputación (caso a caso) · respuestas escritas manualmente caso por caso
- **Flexibilidad:** [???] todo — falta definición previa
- **sop_url:** —

### `Implementación del CRM`
- **Unidad:** 1 implementación inicial (one-shot)
- **Alcance:** Implementación completa del CRM para clientes que no contratan Setup de arranque pero sí necesitan el CRM funcionando: alta de subcuenta GHL, pipeline estándar, conexiones (correo, Meta, Google Ads, WhatsApp), automatizaciones base.
- **No incluye:** Setup completo de Meta Business y Google Ads (eso es Setup de arranque) · plantillas avanzadas · personalizaciones del pipeline
- **Flexibilidad:** [???] qué diferencia exactamente con Setup de arranque · si el cliente no tiene accesos clave, [???] decisión a quién se escala
- **sop_url:** —

### `Pipeline de seguimiento en CRM`
- **Unidad:** 1 pipeline configurado (one-shot)
- **Alcance:** Configuración del pipeline de ventas estándar dentro de la subcuenta de GHL: etapas, campos, vistas. Es el pipeline base de la agencia, igual para todos los clientes.
- **No incluye:** Personalización del pipeline para el cliente (sería Mejoras del CRM) · automatizaciones sobre el pipeline (ficha aparte)
- **Flexibilidad:** Ninguna — es estándar · si el cliente pide cambios, se escala a Mejoras del CRM
- **sop_url:** —

### `Automatización primeros pasos del contacto (WhatsApp + correo)`
- **Unidad:** 1 automatización inicial (one-shot)
- **Alcance:** Configuración de las automatizaciones que se disparan en los primeros segundos tras la entrada de un lead: creación del contacto, creación de oportunidad en el pipeline, envío del primer correo automático y envío del primer WhatsApp automático.
- **No incluye:** Redacción del copy de los mensajes (fichas aparte) · automatizaciones avanzadas o personalizadas (cubierto por Mejoras del CRM)
- **Flexibilidad:** [???] qué se considera "automatización avanzada" y queda fuera de este pack
- **sop_url:** —

### `Saneo e importación de base de datos`
- **Unidad:** 1 saneo + 1 importación inicial (one-shot)
- **Alcance:** Recepción de la base de datos previa del cliente (Excel, CSV, otro CRM), limpieza de duplicados, normalización de campos (teléfono, email, nombre) e importación al CRM con las etiquetas y segmentos correctos.
- **No incluye:** Recuperación de contactos perdidos · enriquecimiento de la base de datos con datos externos · segmentación avanzada posterior
- **Flexibilidad:** El ejecutor decide qué campos normalizar y qué duplicados fusionar · [???] tamaño máximo de la base que se acepta
- **sop_url:** —

### `Aviso al equipo de ventas al entrar lead`
- **Unidad:** Incluida (one-shot inicial)
- **Alcance:** Configuración de una notificación automática (Slack, email o WhatsApp interno del equipo del cliente) que avisa cuando entra un lead nuevo, para que ventas pueda contactar rápido.
- **No incluye:** Asignación automática del lead a un comercial concreto si requiere lógica avanzada · gestión del CRM del lado del cliente
- **Flexibilidad:** [???] canal preferido del aviso · [???] qué cuenta como "lead" para disparar el aviso (solo formularios o también llamadas)
- **sop_url:** —

### `Mejoras mensuales en sistemas`
- **Unidad:** 2 horas al mes
- **Alcance:** Bolsa mensual de 2 horas para mejorar, ajustar o personalizar los sistemas del cliente (CRM, automatizaciones, integraciones). **Pendiente aclarar (Tengo Teatro):** más de 2h sin autorización de ventas — confirmar política.
- **No incluye:** Trabajo identificable como otra ficha (alta nueva, plantilla nueva, conexión nueva): se factura aparte · soporte/dudas del cliente sobre cómo usar el CRM (eso es soporte)
- **Flexibilidad:** El ejecutor prioriza según criterio técnico · [???] si no se consumen las 2h, ¿se acumulan o se pierden?
- **sop_url:** —

### `Mejoras en CRM o flujos automáticos`
- **Unidad:** Hasta 2 horas al mes
- **Alcance:** Bolsa de hasta 2 horas mensuales específica para mejoras del CRM y los flujos automáticos: ajustar automatizaciones, añadir pasos, optimizar plantillas, integraciones extra.
- **No incluye:** Trabajo identificable como otra ficha · soporte sobre cómo usar el CRM
- **Flexibilidad:** [???] diferencia exacta con "Mejoras mensuales en sistemas" — probablemente son la misma bolsa vendida con nombre distinto a clientes distintos · [???] acumulación de horas no consumidas
- **sop_url:** —

### `Flujos de reactivación para leads fríos en temporada baja`
- **Unidad:** Incluida — [???] **el equipo necesita definir "lead frío" y "temporada baja"** (Rock & Climb)
- **Alcance:** Diseño y montaje de flujos automatizados en GHL que se disparan sobre leads inactivos durante periodos de baja venta del cliente, para intentar reactivarlos con ofertas específicas o contenido de valor. **Pendiente aclarar (Rock & Climb):** definir qué cuenta como "lead frío" (¿X días sin interacción?) y "temporada baja" (¿calendario por sector? ¿lo marca el cliente?). Bajar a tierra antes de prometer.
- **No incluye:** Ejecución de campañas paid sobre esos leads (eso es Campaña promocional mensual) · creación de contenido nuevo para la reactivación
- **Flexibilidad:** [???] todo — falta definición previa
- **sop_url:** —

### `Mensajes de urgencia y escasez (FOMO)`
- **Unidad:** Incluida — [???] **el equipo necesita que se defina cantidad mensual** (Rock & Climb)
- **Alcance:** Diseño y configuración de mensajes automáticos de urgencia o escasez (FOMO) dentro del CRM para acelerar la conversión de leads dudosos: ofertas con caducidad, "últimas plazas", "solo hoy", etc. Se montan como pieza dentro del flujo de seguimiento de leads. **Pendiente aclarar (Rock & Climb):** ¿cuántos mensajes FOMO entran al mes? ¿Se reciclan los mismos o se redactan nuevos cada campaña?
- **No incluye:** Diseño de campañas promocionales completas (ficha aparte) · redacción de copy publicitario para Meta/Google
- **Flexibilidad:** [???] todo — falta definición previa
- **sop_url:** —

### `Secuencia de seguimiento de leads`
- **Unidad:** Incluida — [???] **el equipo declaró "no sabemos qué abarca"** (Rock & Climb)
- **Alcance:** Configuración de la secuencia que sigue a un lead tras los primeros mensajes de bienvenida y hasta que se cierra como ganado o perdido: recordatorios, reintentos de contacto, escalado a comercial humano. **Pendiente aclarar (Rock & Climb):** concretar qué incluye exactamente (número de pasos, canales utilizados, plazo total). Diferenciar de Secuencias automáticas de bienvenida.
- **No incluye:** Bienvenida (cubierto por Secuencias automáticas de bienvenida) · reactivación de leads fríos (ficha aparte)
- **Flexibilidad:** [???] todo — falta definición previa
- **sop_url:** —

### `Correo de activación`
- **Unidad:** Hasta 1 correo al mes (desde mes 2)
- **Alcance:** Envío puntual de un correo de "activación" cuando el cliente quiere comunicar algo concreto a su base (por ejemplo: instalación de aire acondicionado, nuevo servicio, novedad operativa). Diseño + envío. **Pendiente aclarar (Tengo Teatro):** equipo cree que se refiere a "un correo puntual de algo que quiere decir el cliente" — confirmar con ventas.
- **No incluye:** Campañas promocionales con seguimiento (cubierto por Campaña promocional mensual) · serie de correos (sería newsletter)
- **Flexibilidad:** [???] iteraciones con el cliente
- **sop_url:** —

### `Activaciones por WhatsApp`
- **Unidad:** Las necesarias (desde mes 2)
- **Alcance:** Envíos puntuales de WhatsApp masivo a la base del cliente cuando hay algo concreto que comunicar (oferta puntual, recordatorio de temporada, novedad). Sin tope numérico estricto: las que el cliente necesite.
- **No incluye:** Campañas promocionales con flujo completo (cubierto por Flujo automatizado WhatsApp por campaña promocional) · respuesta a contestaciones individuales
- **Flexibilidad:** [???] qué se considera abuso si el cliente pide muchas · [???] aprobación previa de Meta para envíos a base existente
- **sop_url:** —

### `Campaña promocional mensual`
- **Unidad:** 1 campaña al mes (desde mes 2)
- **Alcance:** Diseño y ejecución de una campaña promocional al mes que combina todos los canales: 3 anuncios de Meta diseñados, hasta 5 correos de email marketing, 1 flujo automatizado de WhatsApp y coordinación general. Incluye briefing, calendario y revisión de resultados.
- **No incluye:** Captura de material audiovisual nuevo · campañas adicionales (sería campaña extra a presupuestar)
- **Flexibilidad:** El equipo decide enfoque creativo dentro del briefing del cliente · [???] iteraciones del cliente sobre la campaña completa
- **sop_url:** —

### `Correos email marketing por campaña promocional`
- **Unidad:** Hasta 5 correos por campaña
- **Alcance:** Producción de hasta 5 correos por campaña promocional: copy, diseño visual maquetado, envío programado a la base segmentada. **Pendiente aclarar (Yucalcari):** equipo cree que se refiere a newsletter y solo está haciendo 4 — homogeneizar.
- **No incluye:** Estrategia del calendario mensual (es parte de Campaña promocional mensual) · segmentación avanzada que requiera análisis nuevo de la base
- **Flexibilidad:** El ejecutor decide estructura visual dentro del briefing · [???] rondas de feedback del cliente por correo
- **sop_url:** —

### `Flujo automatizado WhatsApp por campaña promocional`
- **Unidad:** 1 flujo por campaña
- **Alcance:** Diseño y montaje del flujo automatizado de WhatsApp asociado a la campaña promocional del mes: serie de mensajes secuenciales con copy específico de la campaña, segmentación de la base y triggers automáticos.
- **No incluye:** Respuesta manual a contestaciones individuales · plantillas nuevas que requieran aprobación Meta fuera del pack inicial
- **Flexibilidad:** El ejecutor decide número de pasos del flujo · [???] iteraciones con el cliente
- **sop_url:** —

### `Campañas de WhatsApp (campañas promocionales)`
- **Unidad:** Hasta 4 al mes (desde mes 2)
- **Alcance:** Producción de hasta 4 campañas promocionales adicionales por WhatsApp al mes, más allá del flujo de la campaña promocional general. Pensado para clientes con alta cadencia (Aquagames).
- **No incluye:** Flujo de la campaña promocional general (ficha aparte) · respuesta manual
- **Flexibilidad:** [???] qué cuenta como "campaña" frente a "envío puntual" (overlap con Activaciones por WhatsApp)
- **sop_url:** —

### `Campañas de correo electrónico (campañas promocionales)`
- **Unidad:** Hasta 4 al mes (desde mes 2)
- **Alcance:** Producción de hasta 4 campañas de correo promocional al mes, más allá de los correos de la campaña promocional general. Pensado para clientes con alta cadencia (Aquagames).
- **No incluye:** Correos de la campaña promocional general (ficha aparte) · newsletter editorial
- **Flexibilidad:** [???] qué cuenta como "campaña" frente a "correo puntual"
- **sop_url:** —

---

## 5. Google My Business (2 fichas)

### `Google My Business — optimización y actualización`
- **Unidad:** Mensual (recurrente)
- **Alcance:** Optimización mensual de la ficha de Google My Business del cliente: nuevos posts/publicaciones, fotos nuevas, ajustes de horarios o servicios si cambia algo, respuestas a reseñas nuevas, ajustes de categorías y atributos. **Pendiente aclarar (Tengo Teatro):** equipo declaró "no se hace porque no queda claro qué abarca" — concretar qué cubre el servicio mensual exactamente.
- **No incluye:** Creación de la ficha desde cero si no existe — [???] ¿o sí? · gestión de crisis de reputación · respuestas automáticas a todas las reseñas (eso es Respuesta de reseñas automáticas)
- **Flexibilidad:** [???] cuántos posts/fotos al mes mínimos · [???] todas las reseñas se responden o solo las críticas
- **sop_url:** —

### `Revisión de ficha de Google My Business (inicial)`
- **Unidad:** 1 revisión inicial (one-shot)
- **Alcance:** Revisión y optimización inicial de la ficha de GMB existente del cliente al arrancar el servicio: categorías, descripción, horarios, fotos, atributos, servicios. Punto de partida para la gestión mensual posterior.
- **No incluye:** Actualización mensual posterior (cubierto por Google My Business — optimización y actualización) · creación de la ficha desde cero
- **Flexibilidad:** El ejecutor decide categorías y descripción según buenas prácticas · [???] qué decisiones requieren aprobación del cliente
- **sop_url:** —

---

## 6. Redes Sociales (5 fichas)

### `Reels Instagram`
- **Unidad:** 1 reel al mes (desde mes 2)
- **Alcance:** Producción mensual de 1 reel para Instagram: guion, edición, montaje, música, copy del feed, hashtags, programación en la plataforma de programación y revisión post-publicación. **Pendiente aclarar (Rock & Climb):** el correo del cliente decía "desde este mes" en lugar de "desde mes 2" — homogeneizar fecha de inicio.
- **No incluye:** Captura de material nuevo (sería Producción audiovisual on-site, no contratada) · respuesta a comentarios cuando se publica
- **Flexibilidad:** El editor decide estilo visual dentro del brief · [???] iteraciones máximas con el cliente · [???] decisión de hora/día de publicación (ejecutor vs cliente)
- **sop_url:** —

### `Carruseles Instagram`
- **Unidad:** 2 carruseles al mes (desde mes 2)
- **Alcance:** Producción mensual de 2 carruseles para Instagram: secuencia de slides con copy y elementos visuales, copy del feed, hashtags, programación y revisión post-publicación.
- **No incluye:** Redacción de copy publicitario para Ads (ficha aparte) · respuesta a comentarios
- **Flexibilidad:** El diseñador decide estilo visual dentro del brief · [???] iteraciones máximas · [???] decisión de hora/día de publicación
- **sop_url:** —

### `Optimización perfil Instagram (bio + portadas)`
- **Unidad:** 1 optimización inicial (one-shot)
- **Alcance:** Revisión y mejora inicial del perfil de Instagram del cliente: bio, portadas de highlights, identidad visual del perfil (foto, organización del feed). Se entrega propuesta al cliente y se aplica.
- **No incluye:** Creación de las historias/highlights nuevas · creación de la cuenta · actualización mensual del perfil
- **Flexibilidad:** El ejecutor propone redacción según buenas prácticas · [???] iteraciones máximas con el cliente
- **sop_url:** —

### `Promoción de publicaciones IG`
- **Unidad:** Incluida (recurrente, según necesidad)
- **Alcance:** Promoción puntual con presupuesto de las publicaciones orgánicas del cliente (reels, carruseles, posts) cuando se identifica una pieza con potencial extra. Configuración del boost desde Instagram/Meta Ads Manager.
- **No incluye:** Producción de las piezas (ficha aparte) · campañas publicitarias estructuradas (cubierto por Anuncios Meta)
- **Flexibilidad:** El ejecutor decide qué piezas promocionar según rendimiento orgánico · [???] presupuesto mensual disponible para promociones
- **sop_url:** —

### `Planificación mensual de contenido`
- **Unidad:** Mensual (desde mes 2)
- **Alcance:** Planificación mensual del contenido de redes: calendario editorial, temas, formato (reel/carrusel/historia), fechas tentativas, encaje con campañas promocionales del mes.
- **No incluye:** Producción de las piezas (fichas aparte) · estrategia anual de contenidos
- **Flexibilidad:** El planificador decide temas según calendario y campañas · [???] formato del entregable
- **sop_url:** —

---

## 7. Producción Audiovisual

> *(Categoría vacía — el Excel no contempla servicios de producción audiovisual onsite vendidos a estos 7 clientes. La categoría queda creada por si en el futuro se ofrece.)*

---

## 8. Soporte y Relación con el Cliente

> *(Categoría vacía — el Excel no contempla fichas explícitas de soporte/reunión estratégica como servicio vendible. La categoría queda creada para revisar si se añaden más adelante.)*

---

## 9. Consultoría Comercial y de Producto (2 fichas)

### `Revisión de fichas de producto`
- **Unidad:** 1 revisión inicial (one-shot)
- **Alcance:** Revisión inicial del documento de ficha de producto que ha rellenado el cliente para verificar que la información está completa, coherente y bien estructurada para poder trabajarla en campañas. Se envía al cliente la plantilla, se revisa lo que devuelve y se piden ajustes si falta info.
- **No incluye:** Consultoría sobre la calidad del producto en sí (sería trabajo extra de consultoría) · redacción/mejora de la ficha por parte del equipo
- **Flexibilidad:** El revisor pide ajustes al cliente según criterio · [???] iteraciones máximas · [???] plazo máximo antes de escalar si el cliente no rellena
- **sop_url:** —

### `Revisión de puntos de contacto (web, teléfono, correo, IG)`
- **Unidad:** 1 revisión inicial (one-shot)
- **Alcance:** Revisión de todos los puntos de contacto del cliente con sus leads: formularios web, CTAs, números de teléfono, correos, perfiles sociales, fichas en portales. Detección de errores, inconsistencias o puntos de mejora. **Pendiente aclarar (Rock & Climb):** equipo preguntó "qué abarca esa 'revisión'" — concretar profundidad y entregable.
- **No incluye:** Implementación de los cambios detectados — solo auditoría · auditoría técnica profunda (analítica, tracking)
- **Flexibilidad:** El auditor decide profundidad según criterio · [???] entregable (informe vs Notion)
- **sop_url:** —

---

## 10. Implementación de Canales Externos (4 fichas)

### `Estrategia de portales de terceros y OTAs`
- **Unidad:** 1 estrategia (mes 3)
- **Alcance:** Análisis y propuesta de qué portales externos (TripAdvisor, Viator, GetYourGuide, CheckYeti, Tixalia, etc.) y OTAs son óptimos para el cliente según producto, mercado, precio y posicionamiento. Documento estratégico entregable.
- **No incluye:** Alta efectiva en los portales (ficha aparte) · gestión continua de los portales · negociación de comisiones
- **Flexibilidad:** El consultor decide qué portales recomendar · [???] número mínimo/máximo de recomendaciones
- **sop_url:** —

### `Alta + gestión de fichas en portales/OTAs`
- **Unidad:** Hasta 2 altas nuevas al mes (desde mes 3)
- **Alcance:** Acompañamiento al cliente en el alta en portales/OTAs (hasta 2 nuevos al mes desde el mes 3): completar documentación, cargar productos, fotos, descripciones, precios. Gestión continua de las fichas creadas mientras dure el servicio.
- **No incluye:** Estrategia de qué portal elegir (cubierto por Estrategia de portales) · negociación de comisiones
- **Flexibilidad:** [???] decisiones técnicas (ejecutor vs cliente) · [???] iteraciones si el portal rechaza el alta
- **sop_url:** —

### `Configuración de servicios en portales/OTAs`
- **Unidad:** Hasta 2 servicios al mes (desde mes 3)
- **Alcance:** Configuración de hasta 2 servicios/productos al mes dentro de portales/OTAs ya dadas de alta: precios, disponibilidad, descripciones por servicio, imágenes específicas, integración con Channels Manager si aplica.
- **No incluye:** Alta del portal en sí (cubierto por Alta + gestión) · estrategia (ficha aparte)
- **Flexibilidad:** [???] qué cuenta como "1 servicio" en un portal con muchos paquetes
- **sop_url:** —

### `Formación sobre funcionamiento de OTAs`
- **Unidad:** Incluida (mes 3, one-shot)
- **Alcance:** Sesión de formación al cliente para que entienda cómo funcionan las OTAs y portales externos: cómo se cargan productos, cómo gestionar disponibilidad, cómo conectar con Channels Manager, cómo resolver incidencias básicas.
- **No incluye:** Alta efectiva (ficha aparte) · gestión continua del Channels Manager por parte del equipo
- **Flexibilidad:** [???] duración estándar · [???] cuántas sesiones se incluyen
- **sop_url:** —

---

## 11. Materiales Comerciales y Formación (2 fichas)

### `Diseño y dossier B2B Colegios`
- **Unidad:** 1 dossier (one-shot)
- **Alcance:** Diseño y redacción de un dossier comercial orientado al segmento B2B de colegios para que el cliente lo use como material de venta. Incluye copy, maquetación visual y entrega final en formato editable.
- **No incluye:** Estrategia comercial de cómo usar el dossier · envío masivo del dossier a colegios · actualizaciones futuras
- **Flexibilidad:** El diseñador decide estética dentro del branding · [???] iteraciones máximas con el cliente · [???] páginas estándar del dossier
- **sop_url:** —

### `Diseño y dossier B2B Empresas`
- **Unidad:** 1 dossier (one-shot)
- **Alcance:** Diseño y redacción de un dossier comercial orientado al segmento B2B de empresas para que el cliente lo use como material de venta. Mismo formato y entregable que el de colegios, adaptado al mensaje y necesidades de empresas.
- **No incluye:** Estrategia comercial · envío masivo · actualizaciones futuras
- **Flexibilidad:** Idem dossier colegios
- **sop_url:** —

---

## 12. Desarrollo (2 fichas)

### `Desarrollo Página web`
- **Unidad:** 1 página web (proyecto a presupuestar)
- **Alcance:** Diseño y desarrollo completo de la página web del cliente: wireframes, mockups, maquetación técnica, configuración, conexión con dominio y hosting, formularios funcionales, integraciones básicas (CRM, analítica). Proyecto a presupuestar caso por caso.
- **No incluye:** Contenido (copy aporte cliente o ficha aparte) · dominio ni hosting recurrente · mantenimiento posterior (cubierto por Bolsa de horas de desarrollo web) · SEO avanzado
- **Flexibilidad:** [???] número de páginas estándar · [???] iteraciones de diseño con el cliente · [???] optimización SEO básica incluida
- **sop_url:** —

### `Bolsa de horas de desarrollo web`
- **Unidad:** Bolsa de horas (cantidad a presupuestar por cliente)
- **Alcance:** Bolsa de horas de desarrollo web para clientes con web ya existente: mantenimiento, ajustes, nuevas funcionalidades, corrección de bugs, integraciones extra.
- **No incluye:** Rediseño completo (sería Desarrollo Página web nuevo) · hosting ni dominio
- **Flexibilidad:** El desarrollador prioriza según briefing del cliente · [???] cuántas horas mínimas se venden por bolsa · [???] caducidad de horas no consumidas
- **sop_url:** —

---

## Recuento final

| Categoría | Fichas |
|---|---|
| Onboarding | 4 |
| Google Ads | 5 |
| Meta Ads | 8 |
| CRM | 23 |
| Google My Business | 2 |
| Redes Sociales | 5 |
| Producción Audiovisual | 0 |
| Soporte y Relación con el Cliente | 0 |
| Consultoría Comercial y de Producto | 2 |
| Implementación de Canales Externos | 4 |
| Materiales Comerciales y Formación | 2 |
| Desarrollo | 2 |
| **TOTAL** | **57** |

## Siguiente paso

Cuando termines la revisión y me marques cambios concretos (renombrar, fusionar, descartar, ajustar texto), preparo el SQL `DELETE + INSERT` batch para aplicarlo a Supabase en una sola transacción. No tocaré la tabla hasta que confirmes.
