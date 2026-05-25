---
title: Disponibilidades — Calendario disponibilidad laboral del equipo
dominio: work
estado: vivo (desplegado 2026-05-20)
actualizado: 2026-05-21
tags: [disponibilidades, work, admin, calendario, equipo, supabase]
---

# Disponibilidades — `/disponibilidades`

Pantalla admin-only en `work.thenucleo.com/disponibilidades` para que la **Project** vea de un vistazo quién del equipo está disponible **ahora**, durante el día y a lo largo de la semana, y pueda registrar circunstancias especiales (médicos, vacaciones, llegadas tarde, salidas tempranas, ausencias) sobre la franja horaria base de cada miembro.

Todo el equipo trabaja **100% en remoto** — no hay etiqueta "teletrabajo" porque es la norma, no la excepción.

## Para qué sirve

- Responder en 1 segundo *"¿a quién puedo molestar ahora?"* — vista AHORA.
- Planificar el día: ver solapamientos de comidas, ventanas activas comunes — vista HOY.
- Planificar la semana: ver vacaciones, festivos, ausencias previstas — vista SEMANA.
- Registrar circunstancias puntuales que rompen la franja base (médico, enfermo, llega tarde, etc.).

## Franjas base del equipo (estado 2026-05-20)

| Miembro | Activo AM | Comida | Activo PM | Horas/día |
|---|---|---|---|---|
| **Benjamin Sanchis** | 08:30 – 14:30 | 14:30 – 16:00 | 16:00 – 18:00 | 8h |
| **Valentina** | 09:00 – 14:00 | 14:00 – 15:00 | 15:00 – 18:00 | 8h |
| **Camilo** | 10:30 – 15:00 | 15:00 – 16:00 | 16:00 – 19:00 | 7.5h |
| **Damian** | 13:00 – 18:00 | — | — | 5h |
| **Joaquin** | 13:00 – 17:00 | 17:00 – 18:00 | 18:00 – 21:00 | 7h |
| **Valeria Diez** | 13:00 – 17:00 | — | — | 4h |

Excepciones permanentes: sábados, domingos y **festivos nacionales España** (no CCAA) → todo el equipo en estado FUERA.

**Quién aparece en el calendario:** cualquier `bub_user` que tenga al menos una fila en `disponibilidad_franjas_base`. La RPC `disponibilidad_miembros()` hace `SELECT DISTINCT` con JOIN. Para añadir un miembro nuevo basta con INSERTAR sus franjas — el frontend lo detecta sin redeploy. Damian y Valeria sólo tienen un tramo activo (sin comida modelada); el JS los pinta correctamente sin necesidad de tramo `comida`.

## Diseño UX/UI — 3 capas apiladas

### Capa 1 · AHORA (cabecera fija)

Fila horizontal con un avatar por miembro. Dot/halo de estado en tiempo real:

| Estado | Color | Significado |
|---|---|---|
| 🟢 ACTIVO | Verde (`--accent-primary`) | Dentro de franja activa |
| 🍽 COMIENDO | Ámbar (`--status-warning`) | Dentro de franja comida |
| ⚫ FUERA | Gris (`--status-neutral`) | Fuera horario / finde / festivo |
| 🟡 OVERRIDE | Color del tipo + icono | Circunstancia activa pinta encima de la base |

Tap en avatar → drawer lateral con: estado actual, hora fin de la ventana actual, próxima ventana, override activo si lo hay (motivo + nota + hasta cuándo).

### Capa 2 · HOY (timeline horizontal)

Eje X: 08:00 – 20:00. Una banda por miembro. Bandas base verde/ámbar/gris. Línea vertical roja "AHORA". Los overrides se pintan **encima** de la banda base con borde punteado para distinguirlos de la franja por defecto.

### Capa 3 · SEMANA (grid L–V)

5 columnas × 3 filas (una por miembro). Cada celda = mini-timeline del día reducido + badge "Xh activas". Festivos en gris con bandera 🇪🇸. Vacaciones planificadas pre-pintadas. Hover → previsualiza el detalle sin entrar.

## Set de overrides (sin "Teletrabajo" y sin "Foco")

| Icono | Tipo | Color banda | Notas |
|---|---|---|---|
| 🏥 | Médico | Ámbar | Ventana corta dentro del día |
| 🤒 | Enfermo | Rojo | Día entero o varios días |
| ⏰ | Llega tarde | Azul | Recorta inicio de franja AM |
| 🚪 | Sale antes | Azul | Recorta fin de franja PM |
| ✈ | Vacaciones | Morado | Día entero o rango |
| 👻 | Avatar no responde | Rosa | Persona ilocalizable / sin respuesta |
| 📌 | Otro | Neutro | Nota obligatoria |

## Modelo de permisos

| Quién | Qué ve | Qué puede hacer |
|---|---|---|
| Anónimo (sin login) | Nada — gate Auth Google obligatorio | — |
| **Admin equipo** (allowlist única) | AHORA + HOY + SEMANA completas + botón "+" override | Crear/editar/borrar overrides. **Hoy todos los admin son "Project".** |

**Allowlist actual (2026-05-25):** 5 emails en frontend `EDITOR_EMAILS`. Los 4 originales coinciden con `comunidad_admins`; **Valentina sólo está en frontend** — pendiente INSERT en `comunidad_admins` tras su primer login.
- `benjamin.sanchis@thenucleo.com`
- `alejandro.lopez@thenucleo.com`
- `marketing.thenucleo@gmail.com`
- `mel.dalmazo@thenucleo.com`
- `valentina.ramirez@thenucleo.com` ⚠️ frontend sí, `comunidad_admins` no — necesita INSERT manual con su `auth.uid` después de loguearse

**RLS Supabase:** las 3 tablas (`disponibilidad_franjas_base`, `disponibilidad_overrides`, `festivos_es`) usan `is_comunidad_admin()` como gate. Esto es **distinto** del patrón de Casuísticas/Playbook (allowlist hardcoded en SQL). Ventaja: un INSERT en `comunidad_admins` da acceso automáticamente al nuevo admin **sin tocar RLS**. Sigue requiriendo editar el frontend `EDITOR_EMAILS` igualmente.

⚠️ **Memoria [[feedback_playbook_allowlist_5_sitios|allowlist en 6 sitios]] aplica aquí:**
- Para añadir un admin nuevo, INSERT en `comunidad_admins` + UPDATE `EDITOR_EMAILS` en `disponibilidades/index.html` (2 sitios, no 6 — porque RLS es vía RPC).
- ⚠️ Si añades a `EDITOR_EMAILS` pero NO a `comunidad_admins`, el gate frontend pasa pero todas las queries RLS rechazan silenciosamente → UI con arrays vacíos sin error. Bug silencioso.

## Modelo de datos Supabase (aplicado 2026-05-20)

Tres tablas + 1 RPC. Migrations `disponibilidades_init` + `disponibilidades_seed` + `disponibilidades_add_joaquin_damian_valeria`.

### RPC `disponibilidad_miembros()`

```sql
CREATE OR REPLACE FUNCTION public.disponibilidad_miembros()
RETURNS TABLE(bubble_id text, nombre text, color text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT DISTINCT u.bubble_id,
         COALESCE(u.nombre, u.email) AS nombre,
         COALESCE(u.color, '#6b7280') AS color
  FROM bub_user u
  INNER JOIN disponibilidad_franjas_base f ON f.miembro_id = u.bubble_id
  ORDER BY 2;
$$;
GRANT EXECUTE ON FUNCTION public.disponibilidad_miembros() TO authenticated;
```

`SECURITY DEFINER` necesario porque `bub_user` tiene RLS y los admins de Comunidad no tienen policy de lectura ahí. La RPC sólo expone `bubble_id + nombre + color`, no PII adicional. El frontend la llama al boot y deriva el array `MIEMBROS` — para añadir o retirar a alguien del calendario basta INSERT/DELETE en `disponibilidad_franjas_base`.

### Tablas

```sql
-- Franjas base del equipo (L-V, 1 fila por miembro+tramo). Cambian rara vez.
CREATE TABLE public.disponibilidad_franjas_base (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  miembro_id   text NOT NULL REFERENCES bub_user(bubble_id) ON DELETE CASCADE,
  tramo        text NOT NULL CHECK (tramo IN ('activo_am','comida','activo_pm')),
  hora_inicio  time NOT NULL,
  hora_fin     time NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE(miembro_id, tramo)
);

-- Circunstancias puntuales (time-series).
CREATE TABLE public.disponibilidad_overrides (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  miembro_id   text NOT NULL REFERENCES bub_user(bubble_id) ON DELETE CASCADE,
  tipo         text NOT NULL CHECK (tipo IN ('medico','enfermo','llega_tarde','sale_antes','vacaciones','avatar_no_responde','otro')),
  desde        timestamptz NOT NULL,
  hasta        timestamptz NOT NULL,
  nota         text,
  creado_por   text NOT NULL,
  creado_en    timestamptz NOT NULL DEFAULT now(),
  CHECK (hasta > desde)
);
CREATE INDEX idx_disp_overrides_miembro_fecha ON public.disponibilidad_overrides (miembro_id, desde);
CREATE INDEX idx_disp_overrides_rango ON public.disponibilidad_overrides (desde, hasta);

-- Festivos nacionales España (carga manual anual, sin CCAA).
CREATE TABLE public.festivos_es (
  fecha    date PRIMARY KEY,
  nombre   text NOT NULL
);
```

Single-row JSON estilo `casuisticas_board` **descartado**: los overrides son time-series y querremos filtrar por fecha en SQL.

### IDs canónicos de los 6 miembros del equipo (`bub_user.bubble_id`)

| Miembro | bubble_id | Color |
|---|---|---|
| Benjamin Sanchis | `1772728038513x480671187100790300` | `#0C29AB` |
| Valentina | `1772798993384x712884450325125900` | `#00FFFF` |
| Camilo | `1773165777528x565611358129485950` | `#FF1493` |
| Damian | `1773057357337x468860004761055800` | `#FF0040` |
| Joaquin | `1773165270743x407759088346369540` | `#7DF9FF` |
| Valeria Diez | `1778497476044x261105595193495740` | `#FF8C00` |

El frontend usa los `color` directamente para el fondo del avatar. Avatar muestra iniciales (1 ó 2 letras) — usar 2 cuando hay 2+ palabras en el nombre (caso "Valeria Diez" → "VD" para no chocar con "Valentina" → "V").

### Festivos cargados (España nacional 2026, 10 filas)

`2026-01-01` Año Nuevo · `2026-01-06` Epifanía · `2026-04-03` Viernes Santo · `2026-05-01` Día del Trabajo · `2026-08-15` Asunción · `2026-10-12` Fiesta Nacional · `2026-11-01` Todos los Santos · `2026-12-06` Constitución · `2026-12-08` Inmaculada · `2026-12-25` Navidad. Sin traslados, sin CCAA. Cargar manualmente cada año.

## Acceso

Sesión Supabase Auth compartida con `/comunidad/*` y resto de páginas admin (`storageKey: thenucleo-comunidad-auth`). Login en `/comunidad/entrar/?next=/disponibilidades/`.

## Nav admin unificado

La auth bar replica el dropdown común de `work.thenucleo.com`:

- Playbook · `/playbook/`
- Ficha de Cliente · `/ficha-cliente/` (pendiente crear)
- Fichas de Producto · `/fichas-de-producto/`
- Casuísticas · `/casuisticas/`
- **Disponibilidades** · `/disponibilidades/` (activo en esta página)

## Arquitectura técnica

- HTML standalone en `disponibilidades/index.html` (no pasa por Eleventy, como Casuísticas y Playbook).
- Design tokens TheNucleo: NewBlack + paleta dark/light.
- Supabase JS via CDN jsdelivr.
- Lectura de sesión directa desde `localStorage` (bypass `getSession()` por bug `GoTrueClient hang`).
- Mobile-first crítico: la PM consultará desde el móvil. La capa AHORA debe funcionar sin scroll en 360px (3 avatares en fila + dot + tap → drawer fullscreen).

## Pendientes — features futuras (v2+)

Funcionalidades anotadas para futuras iteraciones, **fuera del scope inicial PM-only**:

1. **Enlace a Notion Calendar del usuario** — campo opcional en perfil de cada miembro con URL pública del calendario Notion. La vista de detalle (drawer del avatar) muestra próximos eventos del miembro para que la PM tenga contexto sin salir de la pantalla.
2. **Enlace a Google Calendar del usuario** — mismo patrón, campo URL pública del Google Calendar (ICS o link compartido). Solo lectura, no sync bidireccional. La PM ve eventos próximos del miembro en el mismo drawer.
3. **Sistema self-service con push al PM** — cada miembro puede marcar su propio override desde su perfil. Al crear el override, se dispara push notification al PM (vía Evolution API WhatsApp o email) con detalle: *"Camilo marcó Médico mañana 10:00–12:00 — nota: revisión rutinaria"*. La PM puede aprobar/rechazar o simplemente quedar informada. Cambia el modelo de permisos: pasa de PM-only a self-service con audit + notificación.

Estas tres entran como hilo único de "v2 — automatización y delegación" cuando el flujo manual PM esté validado en uso real.

## Decisiones cerradas (2026-05-20)

1. **Festivos:** solo nacionales España. CCAA fuera de scope.
2. **"Project" = todos los admin actuales** de `work.thenucleo.com`. No se separa rol viewer/editor en v1.
3. **🎯 Foco NO se incluye** en el set inicial de overrides.

## Cross-refs

- [[work/README]] — hub work con todas las páginas internas.
- [[casuisticas]] — patrón de gate, allowlist, auth bar, persistencia Supabase replicado aquí.
- [[playbook]] — patrón allowlist en 6 sitios (advertencia).
- [[supabase-schema]] — schema Supabase (añadir tablas `disponibilidad_*` + `festivos_es` cuando se construya).
