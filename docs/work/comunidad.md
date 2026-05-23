---
title: Comunidad Pública
dominio: comunidad
estado: activo
actualizado: 2026-05-08
tags: [comunidad, eleventy, supabase, oauth, publico]
---

# Comunidad pública — `work.thenucleo.com/comunidad`

Guía operativa de la sección Comunidad migrada de Bubble (interna, sección 5 del portal) a la landing pública el **2026-04-28**.

> ⚠️ Antes de tocar cualquier pieza, leer también `thenucleo-landing/CLAUDE.md` (sección "Comunidad pública") y `docs/infra/supabase-schema.md` (sección "Comunidad pública (cbi)").

---

## Qué es y por qué

Comunidad pública con propuestas, votación, comentarios y crowdfunding. Visible a cualquier visitante. Captación SEO + branding.

**Dos modos** (campo `modo` en `comunidad_propuestas`, antes `tipo_propuesta`):
- `pool` — Pool de Proyectos (financiación colectiva con `umbral_financiacion_pool` + `recaudado_pool`).
- `referidos` — Desarrollo con Referidos (un agencia desarrolla, otras pagan por uso; `precio_adhoc`).

Sustituye a las tablas `bub_comunidad_*` (eliminadas 2026-04-28).
---

## Stack

| Capa | Tecnología | Donde |
|---|---|---|
| Frontend SSG | Eleventy v3 | `thenucleo-landing/comunidad/` |
| Cliente JS | `@supabase/supabase-js@2` vía CDN jsdelivr (sin bundler) | `thenucleo-landing/assets/js/comunidad-*.js` |
| Auth | Supabase Auth — Google OAuth | provider configurado en Supabase cbi |
| Datos | Supabase nativo (cbi) | tablas `comunidad_*` |
| Moderación | Edge Function `comunidad_admin_action` | Supabase cbi |
| Pagos al pool | Stripe Checkout (**Fase 2 pendiente**) | botón stub `disabled` mientras Stripe PROD esté pausado |
| Hosting | Vercel proyecto `app-landing-thenucleo` (cuenta `marketingthenucleo`) | `https://work.thenucleo.com/comunidad/` |

---

## Tablas Supabase (cbi `cbixhqjsnpuhcrcjppah`, schema `public`)

- `comunidad_propuestas` — slug auto (trigger), `modo` (`pool`|`referidos`), estado workflow `pendiente`→`aprobada`/`rechazada`/`financiada`/`archivada`. Campos crowdfunding: `cotizacion_precio`, `umbral_financiacion_pool`, `recaudado_pool` (default 0), `precio_adhoc`.
- `comunidad_comentarios` — estado `pendiente`/`aprobado`/`rechazado`. Cascada al borrar propuesta.
- `comunidad_votos_propuesta` — PK compuesta `(propuesta_id, usuario_id)`. Toggle = INSERT/DELETE.
- `comunidad_votos_comentario` — igual.
- `comunidad_admins` — allowlist moderadores. RLS habilitada **sin policies** → solo `service_role` lee directo. Acceso desde JS via función `is_comunidad_admin()` (SECURITY DEFINER).

**Vista pública para SSG:** `v_comunidad_propuestas_publicas` (security_invoker=true, GRANT SELECT a anon/authenticated). Solo `estado IN ('aprobada','financiada')`. Añade columnas calculadas `votos` y `comentarios_count`.

**Helpers:** `is_comunidad_admin()`, `comunidad_slugify(text)`, triggers `trg_comunidad_set_slug` y `trg_comunidad_set_updated_at`.

**RLS (resumen):**
- Propuestas/Comentarios → SELECT público para aprobadas/aprobado + autor las suyas + admin todas; INSERT authenticated con CHECK duro (autor=auth.uid, estado=pendiente, sin moderación, sin pool tocado); UPDATE/DELETE solo admin.
- Votos → SELECT público; INSERT/DELETE solo `usuario_id=auth.uid()` (toggle).

---

## Edge Function `comunidad_admin_action`

- **Endpoint:** `https://cbixhqjsnpuhcrcjppah.supabase.co/functions/v1/comunidad_admin_action`
- **verify_jwt:** true
- **Body:** `{ tipo: 'propuesta'|'comentario', id: uuid, accion: 'aprobar'|'rechazar', nota?: string }`
- **Flujo:**
  1. Verifica JWT del caller con anon client.
  2. Comprueba `comunidad_admins` con service-role.
  3. UPDATE en la tabla con service-role: `estado`, `moderado_por`, `moderado_at`, `moderacion_nota`. Si aprueba propuesta → `fecha_publicacion = now()`.
  4. Si aprueba propuesta → `fetch POST` a `VERCEL_DEPLOY_HOOK_URL` (secret) para regenerar SSG.

**Secrets requeridos en Supabase Edge Function:**
- `VERCEL_DEPLOY_HOOK_URL` — URL del Deploy Hook del proyecto Vercel (rama `main`).

---

## Frontend — archivos clave

```
thenucleo-landing/
├── _data/
│   ├── site.js                       # globals: SUPABASE_URL, SUPABASE_ANON_KEY, edgeFunctionAdminAction
│   └── comunidad.js                  # build-time fetch a v_comunidad_propuestas_publicas
├── _includes/
│   └── comunidad-base.njk            # layout común: nav (auth-menu dropdown) + footer + modal global "Crear propuesta"
├── comunidad/
│   ├── index.njk                     # /comunidad/ — landing 2 cards SVG (Pool red de nodos, Referidos diamante)
│   ├── pool/index.njk                # /comunidad/pool/ — listado pool con tab-bar + filtros
│   ├── referidos/index.njk           # /comunidad/referidos/ — listado referidos
│   ├── propuesta.njk                 # paginate por slug → /comunidad/{slug}/
│   ├── entrar.njk                    # /comunidad/entrar/ — login Google centralizado, noindex
│   └── admin.njk                     # /comunidad/admin/ — panel moderación, noindex
├── assets/css/
│   └── comunidad.css                 # tokens del mockup + componentes (community-card, proposal-card, modal, auth-menu, etc.)
├── assets/js/
│   ├── comunidad-supabase.js         # singleton supabase client + auth-menu dropdown (avatar/email/logout)
│   ├── comunidad-landing.js          # tilt 3D cards + burst SVG en /comunidad/
│   ├── comunidad-listado.js          # search + pills + voto toggle (pool y referidos)
│   ├── comunidad-ficha.js            # voto + lista/post comentarios
│   ├── comunidad-modal.js            # auth gate + submit modal "Crear propuesta" (sustituye nueva.js).
│   │                                 # Solo envía: titulo, descripcion, problema, beneficio, modo, autor_id, estado='pendiente'.
│   │                                 # cotizacion_precio / umbral_financiacion_pool / precio_adhoc se fijan SOLO en el panel admin.
│   ├── comunidad-entrar.js           # widget anti-bot local + signInWithOAuth
│   └── comunidad-admin.js            # gate admin + secciones "Pendientes" / "Aprobadas" / "Comentarios pendientes".
│                                     # Ediciones inline (titulo, descripcion, problema, beneficio + numéricos por modo)
│                                     # via UPDATE directo (RLS admin); aprobar/rechazar via Edge Function.
├── robots.txt                        # Disallow /comunidad/admin/ + /comunidad/entrar/
└── sitemap.njk                       # incluye /comunidad/, /pool/, /referidos/ y cada /comunidad/{slug}/
```

Globals expuestos al cliente vía `<script>` inline en el head de `comunidad-base.njk`:
```html
window.__SUPABASE_URL__
window.__SUPABASE_ANON_KEY__
window.__EDGE_ADMIN_ACTION__
```

Vienen de `_data/site.js` (que lee `process.env.SUPABASE_*` en build).

---

## Configuración necesaria (no código)

### Vercel — proyecto `app-landing-thenucleo`
- **Env Var build/runtime:** `SUPABASE_ANON_KEY` (legacy anon JWT, **público por diseño** porque va al cliente — RLS lo limita).
- **Deploy Hook** rama `main` (`Settings → Git → Deploy Hooks`) → URL guardada como secret en Edge Function (NO checked-in).

### Supabase Auth (cbi)
- **Provider Google:** habilitado con Client ID + Secret de Google Cloud OAuth (proyecto `App TheNucleo`, OAuth client `TheNucleo Comunidad Web`).
- **Site URL:** `https://work.thenucleo.com`.
- **Redirect URLs (allow list):**
  - `https://work.thenucleo.com/comunidad/`
  - `https://work.thenucleo.com/comunidad/entrar/`
  - `https://work.thenucleo.com/comunidad/admin/`
  - `https://work.thenucleo.com/comunidad/pool/` y `/comunidad/referidos/`
  - `http://localhost:8080/comunidad/{,entrar/,admin/,pool/,referidos/}` (dev)

### Google Cloud OAuth
- **Authorized JS origins:** `https://work.thenucleo.com`, `http://localhost:8080`.
- **Authorized redirect URIs:** `https://cbixhqjsnpuhcrcjppah.supabase.co/auth/v1/callback`.
- **Client ID público:** `817779477263-gkjj21peahulv2srkpfnnuqb2p8ighoh.apps.googleusercontent.com` (puede aparecer en logs/HTML).
- **Client Secret:** solo en Supabase Auth provider config.

### Admins activos (allowlist `comunidad_admins`)
- `67e17245-a7d3-4ce8-8530-ad31dcff6f67` → `marketing.thenucleo@gmail.com`
- `9d76957f-5ff4-4ee2-89cf-b71ffbe6b000` → `benjamin.sanchis@thenucleo.com`

Para añadir/quitar:
```sql
INSERT INTO comunidad_admins (user_id) VALUES ('<uid>')
  ON CONFLICT (user_id) DO NOTHING;
DELETE FROM comunidad_admins WHERE user_id = '<uid>';
```

---

## Fase 2 — Stripe (pendiente)

El botón **"Aportar al pool"** de la ficha está `disabled` con nota "próximamente" (ver `comunidad/propuesta.njk` y CLAUDE.md raíz: Stripe PROD pausado por decisión 2026-04-19 hasta que Ben finalice cuenta Stripe de producción).

Cuando se active:
1. Crear precios dinámicos en Stripe (uno por propuesta o uno genérico con `success_url` que incluya `propuesta_id`).
2. Webhook Stripe → Edge Function que valide la firma + UPDATE `comunidad_propuestas SET recaudado_pool = recaudado_pool + amount` y, si `recaudado_pool >= umbral_financiacion_pool`, `estado = 'financiada'`.
3. Quitar `disabled` del botón en `propuesta.njk` y conectar al Checkout.

---

## Flujo de moderación (`/comunidad/admin/`)

El usuario público envía propuestas con **solo los textos** (titulo, descripcion, problema, beneficio). Cotización, umbral y precio individual son responsabilidad del admin.

**Sección "Propuestas pendientes":**
- Cada card muestra los 4 textos como inputs/textareas editables (admin puede corregir ortografía o reformular antes de publicar) + inputs numéricos según `modo`:
  - `pool` → `cotizacion_precio` + `umbral_financiacion_pool`.
  - `referidos` → `precio_adhoc`.
- Botón **Aprobar** → primero hace `UPDATE` con todas las ediciones (vía RLS admin, NO Edge Function), después llama a la Edge Function `comunidad_admin_action` con `accion: 'aprobar'` (que setea `estado='aprobada'`, `fecha_publicacion=now()` y dispara Vercel Deploy Hook).
- Botón **Rechazar** → solo Edge Function, sin tocar campos.
- Tras aprobar, la card se mueve automáticamente a la sección "Aprobadas" sin recargar página.

**Sección "Propuestas aprobadas":**
- Lista propuestas con `estado IN ('aprobada','financiada')` ordenadas DESC por `created_at`. Título es link al post público (`/comunidad/{slug}/`) en `target=_blank`.
- Mismos inputs editables que en pendientes.
- Botón **Guardar cambios** → solo `UPDATE` directo, no toca Edge Function ni dispara rebuild.
- ⚠️ **Las ediciones se guardan en BD inmediatamente, pero la web pública (Eleventy SSG) las refleja solo tras el siguiente rebuild de Vercel.** Si urge republicar, ejecutar `curl -X POST '<VERCEL_DEPLOY_HOOK_URL>'` o aprobar/rechazar cualquier otra propuesta para forzar el rebuild.

**Slug:** el trigger `trg_comunidad_set_slug` corre `BEFORE INSERT`, no en UPDATE. Si admin corrige el `titulo` después de aprobar, el slug **no se regenera** (URLs públicas no se rompen, pero queda con el título antiguo). Si hace falta regenerarlo, hacerlo a mano: `UPDATE comunidad_propuestas SET slug = comunidad_slugify(titulo) WHERE id='<uuid>'`.

**Validación cliente:** los inputs tienen `maxlength` (titulo 120, textos 2000) que evita choques con los CHECK constraints de Supabase. `titulo` y `descripcion` son NOT NULL → si se vacían, el cliente los descarta del payload (no los envía a UPDATE).

---

## Operaciones comunes

### Aprobar / rechazar manualmente desde SQL (si la UI admin falla)
```sql
-- Aprobar propuesta
UPDATE comunidad_propuestas
SET estado='aprobada',
    fecha_publicacion=now(),
    moderado_por='<tu uid>',
    moderado_at=now()
WHERE id='<uuid propuesta>';

-- Tras aprobar, hay que regenerar SSG: o esperas al próximo push, o triggear deploy hook a mano:
-- curl -X POST '<VERCEL_DEPLOY_HOOK_URL>'
```

### Probar la Edge Function directamente
Desde el navegador autenticado, abre DevTools → Console:
```js
const { data: { session } } = await window.__supabase.auth.getSession();
fetch(window.__EDGE_ADMIN_ACTION__, {
  method: 'POST',
  headers: { 'Authorization': 'Bearer ' + session.access_token, 'Content-Type': 'application/json' },
  body: JSON.stringify({ tipo: 'propuesta', id: '<uuid>', accion: 'aprobar' })
}).then(r => r.json()).then(console.log);
```
(Solo funciona si `comunidad-supabase.js` exporta el client a window — actualmente NO lo hace; añadir `window.__supabase = supabase` en debug si hace falta.)

### Forzar rebuild Vercel sin aprobar nada
```bash
curl -X POST '<VERCEL_DEPLOY_HOOK_URL>'
```

---

## Troubleshooting

| Síntoma | Causa probable | Fix |
|---|---|---|
| `/comunidad/admin/` se queda en "Verificando permisos…" | Caché del navegador con sesión vieja | DevTools → Application → Storage → Clear site data → recarga. Validar primero en incógnito |
| `/comunidad/` listado vacío en producción tras aprobar | Vercel no ha rebuildeado o `VERCEL_DEPLOY_HOOK_URL` mal configurado en Edge Function secret | Ver dashboard Vercel últimos builds; revisar logs Edge Function |
| Build Vercel sin propuestas | `SUPABASE_ANON_KEY` no setteada en Vercel env vars | Settings → Environment Variables; redeploy |
| Login Google falla con `redirect_uri_mismatch` | Falta URL en Authorized redirect URIs de Google Cloud o en allow list de Supabase Auth | Añadir y reintentar |
| INSERT propuesta falla con `new row violates RLS` | Cliente envía campos prohibidos en CHECK de policy `p_insert_auth` (`recaudado_pool != 0`, `moderado_por`, `cotizacion_precio`, `umbral_financiacion_pool`, etc.) | El modal solo debe enviar `titulo`, `descripcion`, `problema`, `beneficio`, `modo`, `autor_id`, `estado='pendiente'`. Los numéricos los fija admin. |
| UPDATE de admin desde panel devuelve 0 filas afectadas | Sesión sin admin verificado, o el `id` no existe | Confirmar uid en `comunidad_admins`; revisar policy UPDATE de la tabla |
| Editar propuesta aprobada no aparece en web pública | SSG no rebuildeado. La Edge Function solo dispara deploy hook al **aprobar**, no al editar aprobadas | Forzar rebuild: `curl -X POST '<VERCEL_DEPLOY_HOOK_URL>'` |
| Modal "Crear propuesta" no se abre desde un botón | Botón debe llamar `window.openComunidadModal('pool'\|'referidos')` o tener `data-open-modal="pool"\|"referidos"` (helper inicializado en `comunidad-base.njk`) | Verificar attribute o handler |
| URL `/comunidad/nueva/` da 404 | Página eliminada en el rediseño 2026-04-28; el form vive ahora en el modal global | Redirigir a `/comunidad/` o usar el botón "Proponer" |
| RPC `is_comunidad_admin` devuelve `false` para admin recién añadido | El cliente cachea el JWT, pero `is_comunidad_admin` lee `comunidad_admins` con `auth.uid()` (no claims) → debe funcionar al instante. Si no, sesión rota → logout + login | — |
| Build Eleventy falla con `extensions.unaccent does not exist` | Extensión no instalada en cbi | `CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA extensions;` (la migration original ya lo hace) |

---

## Cleanup Bubble (pendiente)

Cuando esté validada en producción:

1. Bubble: archivar workflows / Custom Events relacionados con sección Comunidad y eliminar Data Types `Comunidad_Propuestas`, `Comunidad_Comentarios`, `Comunidad_Votos_Propuesta`, `Comunidad_Votos_Comentario`.
2. Portal Bubble UI: ocultar/eliminar la sección 5 (Comunidad) o redirigir a `work.thenucleo.com/comunidad`.
3. ✅ n8n SYNC ABSOLUTO `FGxG67I24POOUeHW` → 4 tablas `bub_comunidad_*` retiradas del `ALLOWED_TABLES` el 2026-05-02 (versión `50c79e0e`).
4. ✅ Supabase: `DROP TABLE bub_comunidad_*` ejecutado 2026-04-28 (migration `drop_bub_comunidad_obsoletas`). Verificado: solo quedan tablas nativas `comunidad_*` + vista `v_comunidad_propuestas_publicas`.
5. Actualizar lista de tablas `bub_*` en `docs/infra/supabase-schema.md` (de 42 → 38).
