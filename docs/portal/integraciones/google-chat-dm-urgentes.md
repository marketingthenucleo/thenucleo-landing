---
title: DM Urgentes Google Chat
dominio: integracion
estado: planificado
actualizado: 2026-05-20
tags: [google-chat, n8n, notificaciones, dm, plan]
---

# Plan: DM privado bot↔usuario cuando se detecta incidencia con menciones

## Contexto

El workflow `8snJvdNsmRM2yI2y` (OPS LOG — Mensajes Google Chat Pub/Sub) hoy hace **lectura pasiva**: capta cada mensaje, lo clasifica con Haiku 4.5 y persiste fila en `actividad_diaria_log`. Ben quiere que cuando un mensaje sea **acción urgente dirigida a alguien concreto** (proxy: `clasificacion='incidencia'` + el cliente ha @mencionado a uno o varios miembros del equipo), el bot envíe un **DM privado** al/los mencionados notificándoles.

**Decisiones del usuario:**
- Canal = DM privado bot↔usuario en Google Chat (no responder en el space del cliente).
- Destinatario = personas mencionadas en el mensaje (extraídas de `annotations[].USER_MENTION`).
- Trigger = `clasificacion='incidencia'` (reusa el classifier actual, sin cambios al prompt).
- Estilo conservador: cooldown agresivo, empezar con umbral alto, validar antes de escalar.

**Outcome esperado:** que cuando un cliente escriba en su space algo tipo *"@Benjamin urgente, la web está caída"*, Ben (el mencionado) reciba inmediatamente un DM del bot con el resumen + link al mensaje original, sin tener que estar mirando el space.

---

## Bloqueante de plataforma (resolver antes de tocar n8n)

El bot actual es **read-only**. Sus scopes en Marketplace SDK son `chat.app.messages.readonly`, `chat.app.memberships.readonly`, `chat.app.spaces.readonly`. Para enviar mensajes hace falta añadir `https://www.googleapis.com/auth/chat.bot` (legacy estable) **o** `chat.app.messages.create` (nuevo, app auth).

Y por la **lección 3** de [google-chat-log.md:379](google-chat-log.md#L379): *"El admin install solo autoriza OAuth clients que existan EN ESE MOMENTO"* — ergo añadir scopes implica **desinstalar y reinstalar la app en Admin Console** para que el nuevo scope quede `Concedido`. Sin esto, cualquier POST a Chat API devolverá `ACCESS_TOKEN_SCOPE_INSUFFICIENT`.

---

## Fases

### Fase 0 — Plataforma GCP (escritura habilitada)

1. **Marketplace SDK App Configuration → Permisos OAuth**: añadir `https://www.googleapis.com/auth/chat.bot` a los 5 scopes existentes. Guardar borrador.
2. **Admin Console → Aplicaciones de Marketplace** → desinstalar TheNucleo Log Bot → reinstalar (Toda la organización).
3. Verificar tab "Clientes de OAuth" del app: el client de la SA `chat-token-thenucleo` (Client ID `104465876387432355478`) debe aparecer **Concedido** con los 6 scopes.
4. Smoke manual con `curl` impersonando la SA:
   ```
   POST https://chat.googleapis.com/v1/spaces/<dmSpaceBen>/messages
   Authorization: Bearer <token con scope chat.bot>
   { "text": "smoke test" }
   ```
   Expectativa: `200 OK` con `name: spaces/.../messages/...`. Si `403`, repetir reinstall.

### Fase 1 — Schema Supabase

Crear **una sola tabla nueva** para auditoría + cooldown:

```sql
CREATE TABLE notification_dm_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agencia_id text NOT NULL,
  cliente_bubble_id text NOT NULL,
  actividad_bubble_id text NOT NULL,           -- FK lógico a actividad_diaria_log
  gchat_message_id text NOT NULL,              -- mensaje origen
  recipient_email text NOT NULL,               -- a quién se envió
  recipient_user_id text,                       -- users/<id> resuelto
  dm_space_id text,                             -- spaces/<id> creado/encontrado
  dm_message_id text,                           -- spaces/.../messages/<id> enviado
  status text NOT NULL,                         -- sent | skipped_cooldown | error
  error_detail text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON notification_dm_log (recipient_email, cliente_bubble_id, created_at DESC);
CREATE INDEX ON notification_dm_log (gchat_message_id);
```

Sin RLS (mismo patrón que `activity_log`, `tarea_en_progreso`). Service-role only.

**Cooldown rule:** `(recipient_email, cliente_bubble_id)` no se notifica más de 1 vez cada **30 min** en MVP. Query simple: `SELECT 1 FROM notification_dm_log WHERE recipient_email=$1 AND cliente_bubble_id=$2 AND status='sent' AND created_at > now() - interval '30 minutes' LIMIT 1`.

### Fase 2 — Extender workflow `8snJvdNsmRM2yI2y`

Patrón: añadir branch **después** del nodo POST Bubble actual, sin tocar la rama existente.

Insertar 8 nodos al final del flujo, después de `POST Bubble actividad_diaria_log`:

1. **`IF Es Incidencia Con Menciones`** (n8n IF):
   - Cond A: `{{ $('Anthropic Classify').item.json.clasificacion }} === 'incidencia'`
   - Cond B: `{{ ($json.message.annotations || []).filter(a => a.type === 'USER_MENTION' && a.userMention?.user?.type === 'HUMAN' && a.userMention?.type === 'MENTION').length > 0 }}`
   - True → continúa. False → end.

2. **`Extract Mentions`** (Code node):
   ```js
   const ann = $('Decode Envelope').first().json.message.annotations || [];
   const mentions = ann
     .filter(a => a.type === 'USER_MENTION'
                  && a.userMention?.user?.type === 'HUMAN'
                  && a.userMention?.type === 'MENTION')
     .map(a => ({
       user_resource_name: a.userMention.user.name,   // "users/123..."
       user_id: a.userMention.user.name.split('/')[1],
       display_name: a.userMention.user.displayName
     }));
   // dedupe por user_id
   const seen = new Set();
   return mentions.filter(m => !seen.has(m.user_id) && seen.add(m.user_id))
                  .map(m => ({ json: m }));
   ```
   Output: 1 item por persona mencionada → split por defecto en n8n.

3. **`Resolve User → Email`** (HTTP Request, cred DWD `aantW5sGVzfHR703`):
   - URL: `https://admin.googleapis.com/admin/directory/v1/users/{{ $json.user_id }}?projection=basic`
   - Mismo patrón que el nodo `GET Admin User` ya existente en el workflow para `autor_email`. Devuelve `primaryEmail`.
   - `onError: continueErrorOutput` (no reventar todo el flow si un user es externo).

4. **`Check Cooldown`** (Supabase HTTP Request, service_role):
   - URL: `https://cbixhqjsnpuhcrcjppah.supabase.co/rest/v1/notification_dm_log?select=id&recipient_email=eq.{{ $json.primaryEmail }}&cliente_bubble_id=eq.{{ $('GET Cliente Bubble').item.json.response.results[0]._id }}&status=eq.sent&created_at=gte.{{ $now.minus({minutes: 30}).toISO() }}&limit=1`

5. **`IF En Cooldown`** (IF):
   - True (`{{ $json.length > 0 }}`) → log skip y end.
   - False → continuar.

6. **`Find/Create DM Space`** (HTTP Request, cred Google SA `chat-token-thenucleo` con scope `chat.bot`):
   - URL: `https://chat.googleapis.com/v1/spaces:findDirectMessage?name=users/{{ $json.user_id }}`
   - GET. Devuelve `{ name: "spaces/<dmSpaceId>", ... }`. Si `404` → POST `/v1/spaces` con `{ singleUserBotDm: true }` + retry GET (Google a veces requiere bootstrap si el user nunca interactuó con el bot).

7. **`Send DM`** (HTTP Request, mismo cred):
   - URL: `https://chat.googleapis.com/v1/{{ $('Find/Create DM Space').item.json.name }}/messages`
   - POST body:
     ```json
     {
       "text": "🚨 *Incidencia urgente* en {{ $('GET Cliente Bubble').item.json.response.results[0].nombre_empresas }}\n\n_{{ $('Anthropic Classify').item.json.resumen }}_\n\nMensaje original: https://chat.google.com/room/{{ spaceIdSinPrefix }}/{{ messageIdSinPrefix }}"
     }
     ```
   - El link a chat.google.com permite saltar al mensaje original con un click.

8. **`Log Notification`** (HTTP Request a Supabase, INSERT):
   - POST `/rest/v1/notification_dm_log` con todos los campos.
   - Esto es lo que alimenta el cooldown y la auditoría.

**Error handling:** todo el branch nuevo apunta a `errorWorkflow: HRDQ9Ju4NAIUV0qyhKzlz` (mismo que el resto del workflow → `n8n_incidencias`).

### Fase 3 — Smoke test

Con bot ya en `spaces/AAQAThLQ5ck` (E|BENJA, cliente TheNucleo):

1. Ben (desde otra cuenta o pidiéndole a alguien) escribe en el space:
   *"@Benjamin Sanchís urgente, la home está dando 500"*
2. Esperar 5–10 s. Verificar en orden:
   - Execution n8n verde, branch nuevo ejecutado.
   - Fila en `bub_actividad_diaria_log` con `clasificacion='incidencia'`.
   - Fila en `notification_dm_log` con `status='sent'`.
   - DM del bot llega al Google Chat de Ben con el texto formateado.
3. Repetir con un segundo mensaje en <30 min → debe quedar `status='skipped_cooldown'`, sin DM.
4. Repetir con mensaje sin @ → no entra al branch (Cond B falsa).
5. Repetir con @ pero `clasificacion='status'` → no entra al branch (Cond A falsa).

### Fase 4 — Auditoría 2 semanas

Antes de escalar a más spaces, monitorizar:

- **Falsos positivos:** filas `status='sent'` cuyo mensaje original NO era urgente real → afina prompt del classifier para distinguir incidencia operativa real vs comentario casual con tono fuerte.
- **Falsos negativos:** mensajes claramente urgentes que NO dispararon DM → revisar si fue por (a) classifier no marcó incidencia, (b) cliente no @mencionó.
- **Cooldown demasiado largo/corto:** ajustar de 30 min según métricas.

Si las métricas son aceptables (>80% precision, <20% FN), **rollout a los 11 spaces cliente** sin tocar nada — el branch ya queda activo y solo depende de que `gchat_space_id` esté mapeado.

---

## Archivos / recursos a modificar

| Recurso | Cambio |
|---|---|
| GCP Marketplace SDK config | Añadir scope `chat.bot` |
| Admin Console | Reinstalar app TheNucleo Log Bot |
| Supabase | `CREATE TABLE notification_dm_log` |
| n8n workflow `8snJvdNsmRM2yI2y` | +8 nodos al final del flujo |
| n8n credentials | Reutilizar `aantW5sGVzfHR703` (DWD) y `chat-token-thenucleo` (app auth) — sin nuevas |
| `docs/portal/integraciones/google-chat-log.md` | Añadir sección "Fase 4 — DM urgentes" |
| `docs/infra/supabase-schema.md` | Documentar `notification_dm_log` |
| `docs/infra/n8n-workflows.md` | Actualizar entrada `8snJvdNsmRM2yI2y` con los 8 nodos nuevos |
| `docs/log-cambios.md` | Entrada del cambio |

---

## Lo que NO hace este plan (límites explícitos)

- **No crea campo `responsable_id` en `bub_clientes`**: el destinatario lo determina la propia mención. Si en el futuro se quiere notificar a un responsable cuando NO hay mención, será otro plan.
- **No toca el system prompt del classifier**: reusa `clasificacion='incidencia'` tal cual.
- **No notifica a externos**: solo a usuarios del workspace `thenucleo.com` (cualquier `users/<id>` que el Admin SDK no resuelva → `onError` skip).
- **No guarda `gchat_user_id` en `bub_user`**: la resolución `userID → email` es <100 ms; si se vuelve hot path se cachea más adelante.
- **No usa Cards V2**: el primer DM es texto plano. Si después se quiere botón "Marcar como visto" → otro plan.

---

## Riesgos

1. **Privacidad**: el bot leerá menciones de mensajes de clientes. Verificar con Ben que clientes externos invitados al space no acaben recibiendo DMs por error (filtro `user.type === 'HUMAN'` + `domain check` opcional contra `thenucleo.com`).
2. **Reinstall del bot interrumpe el log**: durante el reinstall (segundos a minutos) los mensajes nuevos NO se capturan. Hacerlo en horario de poca actividad y validar inmediatamente que `8snJvdNsmRM2yI2y` sigue capturando con el smoke base.
3. **Bot no tiene DM space con Ben todavía**: la primera vez que se intente enviar DM, `findDirectMessage` puede fallar con `404`. Mitigación: que Ben inicie un DM con el bot manualmente una vez antes del smoke (escribir cualquier cosa al bot en chat.google.com → eso bootstrappea el space). Alternativa: lógica `findDirectMessage` → `404` → POST `/spaces` con `singleUserBotDm:true`.
4. **Falsos positivos del classifier marcando `incidencia`**: hoy ya pasa, pero hasta ahora era invisible (solo log). Convertirlo en notificación lo vuelve visible. La auditoría de Fase 4 es crítica.

---

## Verificación end-to-end

```
1. curl -X POST https://chat.googleapis.com/v1/spaces/<X>/messages ✅ 200 (Fase 0)
2. INSERT en notification_dm_log via service_role ✅ (Fase 1)
3. n8n execution con mensaje urgente + @ → branch verde, 1 DM, 1 fila log (Fase 3)
4. Segundo mensaje en <30 min → status=skipped_cooldown (Fase 3)
5. Mensaje urgente sin @ → branch no entra, sin DM (Fase 3)
6. Después de 14 días → revisar precision/recall en notification_dm_log + activity_log (Fase 4)
```
