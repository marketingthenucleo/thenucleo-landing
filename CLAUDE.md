# TheNucleo Landing — work.thenucleo.com

> 📦 **Repo unificado desde 2026-05-23.** Antes existían dos repos:
> - `marketingthenucleo/thenucleo-landing` (este) — código de la cara pública + páginas admin.
> - `marketingthenucleo/thenucleo-vault` — documentación operacional Portal Bubble + infra Supabase/n8n.
>
> El vault se importó bajo `docs/` (squashed) y se archivará una vez validado el deploy. **Este `CLAUDE.md` raíz cubre frontend (landing + páginas admin).** Para Portal Bubble / Supabase / n8n / workflows operacionales, abre [`docs/CLAUDE.md`](./docs/CLAUDE.md) — Claude Code lo carga automáticamente cuando trabajas dentro de `docs/`.

## Layout del repo (post-migración 2026-05-23)

~~~
thenucleo-landing/
├── CLAUDE.md                    ← este archivo (landing + páginas admin)
├── index.html                   ← landing pública (Three.js)
├── aviso-legal.html / privacidad.html
├── ficha-cliente/index.html     ← admin allowlist
├── fichas-de-producto/index.html
├── playbook/index.html
├── disponibilidades/index.html
├── casuisticas/index.html
├── comunidad/                   ← públicas + admin moderación
├── conocimiento-zenyx/          ← blog
├── arquetipo/                   ← test público leadgen
├── _data/, _includes/           ← Eleventy
├── content/conocimiento-zenyx/  ← posts blog (los genera n8n)
├── assets/, fonts/, icons/, Media/
├── _site/                       ← build Eleventy (gitignored)
├── docs/                        ← ex thenucleo-vault (gitignored por Eleventy)
│   ├── CLAUDE.md                ← contexto Portal Bubble / Supabase / n8n
│   ├── MOC.md                   ← Map of Content (Obsidian)
│   ├── README.md
│   ├── log-cambios.md           ← histórico cronológico
│   ├── addons/                  ← sistema de addons (Stripe, F1/F2/F3)
│   ├── infra/                   ← supabase-schema, n8n-workflows, IDs
│   ├── portal/                  ← visión operacional portal.thenucleo.com
│   │   ├── ficha-cliente.md     ← visión Pipelines + nomenclatura PxCx
│   │   ├── account-manual-pipelines.md
│   │   ├── pm-manual-pipelines.md
│   │   ├── equipo-manual-pipelines.md
│   │   ├── pipelines-presentacion.md
│   │   ├── secciones-app.md     ← detalle 9 secciones del portal
│   │   ├── integraciones/       ← ClickUp, GChat, Meta Ads, etc.
│   │   └── sectores/
│   └── work/                    ← documentación pages admin de este repo
├── Design/                      ← assets mockups (gitignored)
├── .claude/skills/              ← skills externas commiteadas (n8n×7, supabase×2, ui-ux-pro-max). 2.7 MB. Tracked en git, ignorado por Eleventy. Detalle abajo.
├── vercel.json
├── .eleventy.js
├── .eleventyignore              ← incluye docs/, Design/, .claude/
└── package.json
~~~

## Cuándo mirar qué

| Trabajas en… | Doc principal |
|---|---|
| Landing pública, hero, pricing, copy | este CLAUDE.md (raíz) |
| Páginas admin (ficha-cliente, playbook, fichas-de-producto, casuisticas, disponibilidades) | este CLAUDE.md + `docs/portal/secciones-app.md` |
| Comunidad, blog Zenyx | este CLAUDE.md |
| Schema Supabase, RPCs, tablas | `docs/infra/supabase-schema.md` |
| Workflows n8n | `docs/infra/n8n-workflows.md` |
| Portal Bubble (no-code app interna) | `docs/portal/secciones-app.md` + `docs/portal/*` |
| Nomenclatura PxCx, Pipelines, Campañas | `docs/portal/ficha-cliente.md` + manuales |
| IDs, credenciales, tokens | `docs/infra/ids-referencias.md` |
| Skills Claude (n8n / supabase / ui-ux-pro-max) | `.claude/skills/<nombre>/SKILL.md` |
| **Crear pieza visual nueva** (CSS work admin o Conditional Bubble) con coherencia dark/light | `docs/design-tokens.md` — sección "Recetas reutilizables" (3 patrones canónicos, regla del salto de jerarquía, anti-patrones, checklist) |

## Skills Claude en el repo (`.claude/skills/`)

Las sesiones de Claude Code on the web corren en contenedores efímeros — skills instaladas en `~/.claude/skills/` no persisten entre sesiones. Para tenerlas disponibles automáticamente al clonar, viven commiteadas en `.claude/skills/`:

- **n8n** (7 skills de [czlonkowski/n8n-skills](https://github.com/czlonkowski/n8n-skills)): `n8n-expression-syntax`, `n8n-mcp-tools-expert`, `n8n-workflow-patterns`, `n8n-validation-expert`, `n8n-node-configuration`, `n8n-code-javascript`, `n8n-code-python`. Pensadas para el MCP de n8n activo en las sesiones.
- **supabase** (2 oficiales de [supabase/agent-skills](https://github.com/supabase/agent-skills)): `supabase` + `supabase-postgres-best-practices` (RLS, security, schema). Recomendadas por el MCP de Supabase.
- **ui-ux-pro-max** (de [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)): priority rules + anti-patterns + 31 CSVs (50+ estilos, 161 paletas, 57 font pairings, 99 guidelines UX, 25 tipos de chart) + 3 scripts Python stdlib. Los symlinks `data`/`scripts` del repo origen se resolvieron a archivos reales (self-contained).

**Reglas:**
- `.claude/` está en `.eleventyignore` → los `SKILL.md` no se procesan ni emiten páginas en `_site/`.
- `__pycache__/` y `*.pyc` en `.gitignore` → los scripts Python no ensucian el repo al ejecutarse.
- Para añadir/actualizar una skill: `cp -r` desde el repo origen, verificar `npm run build` (debe seguir en 53 archivos) y registrar en `docs/log-cambios.md`.

## Hooks de Claude Code (`.claude/settings.json` + `.claude/scripts/`)

Hooks committeados al repo para que se carguen automáticamente en cada sesión nueva del entorno remoto. Configurados en `.claude/settings.json`, implementados en `.claude/scripts/*.sh`. El harness los ejecuta — no el modelo — así que funcionan incluso si Claude se olvida.

**Activos:**
- `log-reminder-session-start.sh` (SessionStart) — al iniciar sesión, si hay commits en HEAD posteriores al último update de `docs/log-cambios.md`, inyecta `systemMessage` al user + `additionalContext` al modelo con la lista de commits pendientes + el formato del log + la convención de propagación a CLAUDE.md/docs.
- `upstream-sync-reminder-session-start.sh` (SessionStart) — al iniciar sesión hace `git fetch` del upstream de la rama actual; si HEAD está detrás (`behind > 0`), inyecta `systemMessage` + `additionalContext` con la lista de commits remotos no aplicados y la instrucción de proponer `git pull` (o stash+pull+pop) sin ejecutarlo sin confirmación. Detecta drift cuando se trabaja desde Claude Code on the web/móvil y el clon local no se ha refrescado. Silencioso si está al día / sin upstream / HEAD detached / sin red. JSON vía python (no jq — Ben en Windows no lo tiene en PATH).
- `log-reminder-stop.sh` (Stop) — counter en `$TMPDIR/claude-thenucleo-log-counter`. Cada turno con cambios en working tree sin tocar `docs/log-cambios.md` incrementa. A los 4 turnos lanza `systemMessage` al user. Resetea al tocar el log o al quedar el tree limpio. Soft nudge — no bloquea.

**Caveat watcher:** la primera carga de `.claude/settings.json` (o cualquier edición) no la detecta el watcher de Claude Code on the web hasta la siguiente sesión. En local, `/hooks` recarga.

**Para añadir un hook nuevo:** crear script en `.claude/scripts/`, hacerlo ejecutable (`chmod +x`), pipe-testear con `echo '{}' | ./script.sh`, registrar en `.claude/settings.json` (event + matcher si aplica + path), validar JSON con `jq -e`, commit + push, registrar en `docs/log-cambios.md`. La skill `update-config` (invocable vía `Skill` tool) guía el proceso.

## Obsidian Git en `docs/.obsidian/`

La carpeta `docs/` es una vault de Obsidian con el plugin **Obsidian Git** instalado (`docs/.obsidian/plugins/obsidian-git/data.json`). En móvil convive un alias `tnpush` de Termux que produce commits con el mismo formato `vault backup (mobile): {{date}}` — ambos lados usan el mismo string por convención.

**Gotcha desktop (importante):** aunque todos los `auto*` settings del plugin estén en 0 (`autoSaveInterval: 0`, `autoBackupAfterFileChange: false`, etc.), **basta con tener Obsidian desktop abierto** con la vault cargada para que aparezcan commits periódicos con el mensaje `vault backup (mobile): {{date}}`. El plugin opera desde repo root (`basePath: "../"`) → barre todo el working tree, no solo `docs/`. Si tienes cambios uncommitted en PC1 (Cursor) cuando el plugin commitea, los absorbe bajo el mensaje genérico y pierdes la trazabilidad de tu commit descriptivo. Probable trigger: `refreshSourceControlTimer: 7000` ms o algún side-effect del Source Control panel del plugin — verificado empíricamente 2026-05-24 (3 entries en `docs/log-cambios.md`).

**Regla operativa (decisión 2026-05-24):** **mantener Obsidian desktop CERRADO mientras trabajes en Cursor en este repo.** Solo abrirlo cuando vayas a editar docs en Obsidian conscientemente. Test verificado: con Obsidian cerrado, 0 commits genéricos en 4 min. Con Obsidian abierto, salen cada pocos segundos/minutos sin patrón fijo.

**Cómo distinguir origen de un commit `vault backup (mobile)` en `git log`:** per-repo `.git/config` tiene `[user] email = benjamin.sanchis@thenucleo.com` que sobreescribe la `~/.gitconfig` global (`marketingthenucleo`). Por tanto: **PC1 commits = "Benjamin Sanchis"** (vienen de Obsidian desktop si están), **móvil Termux commits = "marketingthenucleo"**. Histórico previo a 2026-05-24 con cadencia 15 min exactos = plugin desktop con autocommit on (ya desactivado).

## Convención para evitar drift

**Doc junto a código.** Cualquier cambio funcional en un archivo de este repo se propaga en el mismo PR a su `.md` de referencia:

- Cambio en `ficha-cliente/index.html` → revisar `docs/work/ficha-cliente.md` (canónico) + `docs/portal/secciones-app.md` sección Ficha Cliente + `docs/portal/ficha-cliente.md` si toca Pipelines PxCx.
- Cambio en RPC Supabase → actualizar `docs/infra/supabase-schema.md`.
- Cambio en workflow n8n → actualizar `docs/infra/n8n-workflows.md`.
- Cambio en `playbook/index.html` → revisar `docs/work/playbook.md`.

Antes esta convención requería cross-PR entre 2 repos (y se rompía: por eso unificamos). Ahora todo es en 1 sola sesión.

## Qué es
Landing page de captación para TheNucleo + blog público SEO `/conocimiento-zenyx/`.
Stack: HTML + CSS + Three.js (SPA) para la landing + **Eleventy v3** como static site generator para procesar los markdown del blog.
Deploy: Vercel (proyecto `app-landing-thenucleo`, cuenta `marketingthenucleo`)
Repo: `marketingthenucleo/thenucleo-landing`

## URLs
- **Producción:** https://work.thenucleo.com/
- **Blog:** https://work.thenucleo.com/conocimiento-zenyx/
- **Comunidad:** https://work.thenucleo.com/comunidad/
- **Arquetipo de Marca (leadgen):** https://work.thenucleo.com/arquetipo/
- **Páginas admin internas (allowlist 5 emails TheNucleo, noindex):**
  - `/playbook/` y `/playbook/<bubble_id>` — onboarding cuarentena (anon-mode para cliente final)
  - `/fichas-de-producto/` — catálogo de servicios editable (rewrite mobile-first 2026-05-22)
  - `/estrategia/?id=<bubble_id>` y `/timeline/?id=<bubble_id>` — **subsecciones hermanas de `/ficha-cliente/` (Sprint 1 migración 2026-05-25)**, clones pelados con solo `PIPELINES_MODULE` (Estrategia) y placeholder "en construcción" (Timeline). Mismo gate auth, mismo picker, mismo theme. La idea: el submenú "Clientes" del portal Bubble irá teniendo botones que apuntan a cada subsección por verbo. `/ficha-cliente/` queda intacta como fuente de verdad de los módulos clonados hasta que se extraiga infra compartida (deuda técnica registrada). Bridge Edge Function ampliada con `next_path` (allowlist anti open-redirect) para aterrizar autenticado en la subsección correcta. **Shell unificado portal (2026-05-26):** las 3 páginas (`/ficha-cliente/`, `/estrategia/`, `/timeline/`) comparten un sidebar fijo de 245px (drawer móvil <1024px) con los 6 items del portal Bubble (Dashboard/Clientes/Operaciones/RRHH/Finanzas/Comunidad → links directos a `portal.thenucleo.com/<seccion>`) + footer Ajustes/Soporte/Salir, y un header top de 40px con theme toggle + avatar 40×40 que pinta iniciales y color desde `bub_user.color` via RPC nueva `work_current_user_profile()` (v2 desde 2026-05-26: devuelve también `agencia_id` + `agencia_proveedor_tareas` con LEFT JOIN `bub_agencia`, usado para ocultar el tab "Tareas" cuando la agencia no usa Notion — replica del workflow Bubble "Only when proveedor_tareas is notion"). Estados visuales matching portal: bg main `#0A0A0A` vs sidebar `#111111`, item activo pill `#1a1434` + strip lime `#85DB02` 5×100%, iconos Lucide stroke 1.25 color `#edeef3`, header icon buttons 36×36 sobre bg-card `#12141b`. Sub-pestañas cross-page (General/Tareas/Editar/Estrategia/Timeline) con hover underline 2px×55% `#2563EB`. Botón "Volver atrás" → `portal/clientes/<id>?sec=general` (Opción C — Opción B con `from_sec` propagado por Bubble queda como deuda en `deuda-tecnica.md`). Tokens light-aware: `--ps-sidebar-bg`, `--ps-icon-bg`, `--ps-active-pill` con overrides en `[data-theme="light"]`. La RPC `work_current_user_profile()` es SECURITY DEFINER + self-only por `auth.email()` → NO suma sitio a la allowlist x9.
  - `/ficha-cliente/` y `/ficha-cliente/?id=<bubble_id>` — ficha cliente cableada con `bub_clientes` vía RPCs `ficha_cliente_listar` + `ficha_cliente_get` (desde 2026-05-22). Servicios contratados leídos desde `playbook_cliente_servicios` agrupados por categoría + buscador (fix 2026-05-22). Datos y Catálogos compartimentados en grupos colapsables `.coll-group` con badge `rellenos/total` por sección (fix 2026-05-23). Estado vacío (sin `?id=`) muestra **listado de clientes inline + buscador** directamente en el panel (fix 2026-05-25); botón "Cambiar" del header sigue abriendo el sheet bottom para switch cuando ya hay cliente cargado. **Módulo Pipelines (F2.5d cerrada 2026-05-25; F2.5e tipo SD añadido 2026-05-25):** dentro de cada Campaña 4 sub-bloques hermanos — **Triggers** (FM/FW/BD/**DM**/**SD** con campos a capturar configurables en FM/FW vía col `campos_capturar jsonb`; **DM** = auto-mensaje directo en RRSS con keyword activadora + texto del mensaje, cols `activador`/`mensaje_dm`; **SD** = "Sin trigger definido" para canales ajenos al sistema — broadcast WhatsApp, carteles, eventos, boca a boca — solo declarativo, sin requisitos extra. Migration `ficha_trigger_tipo_sd_sin_definir` amplía CHECK y RPC), **Emails** (modelo simplificado 📡 Compartido / 🎯 Específico para 1 trigger — sin subsets; código per-scope contando archivados), **Mensajes WhatsApp** (códigos `PxCxWAn`, tabla `cliente_mensajes_whatsapp` hermana de `cliente_emails`), **Creatividades** (**1 fila = 1 pieza con código `<trigger.code><E|R|C|O><n>`** — cada pieza apunta a un trigger destino obligatorio; categoría ANUNCIOS [Estático/Reel duración s] / RRSS [Carrusel nº slides / Reel duración s] / OTROS [solo notas obligatorias]; sin `cantidad` — para varias piezas similares crear N entradas; Drive: `<trigger><letra><n>_v<n>` donde v=revisión inmutable; tabla `cliente_creatividades` con cols `trigger_id`/`codigo`/`categoria`/`subtipo`/`duracion_segundos`/`num_slides`). **Brief Drive retirado** de Campaña y de Creatividad (decisión 2026-05-25 "aquí no tenemos URLs" — F2.5b revertida). Presupuesto retirado de Campaña. BD renombrado a "Enviar a base de datos personalizada". Bug breadcrumb corregido. **Módulo Catálogos del cliente (F2.7 Fase A + Fase B Sprint 1+2+3 cerradas 2026-05-25):** panel Catálogos pasa de mockup a 17 catálogos reales `cliente_catalogo_*` agrupados en 7 macro-categorías (📁 Recursos Drive · 💬 Comunicación · 📣 Marketing Meta · 💰 Operativo · 🎯 Producto del cliente · ⚠️ Gobierno · 🌐 Webs cliente). Backend: migration `f2_7_catalogos_cliente` (17 tablas + 36 indexes + 68 policies con `is_comunidad_admin()` + 17 triggers + RPC agregadora `catalogos_cliente_get(p_bubble_id)` SECURITY DEFINER con allowlist 5 emails — 8º sitio de la allowlist). Frontend: lectura 1-fetch via la RPC, CRUD inline via PostgREST (helper nuevo `tableRequest()` con `prefer` opcional), sheet bottom reutilizado, validación required + null-on-empty, soft-delete con badge `🗄 archivada` + tachado, badge naranja "URL pendiente" para entradas seed con URL `PENDIENTE` (convención del bootstrap). **Sprint 3 (visibilidad por cliente, migration `f2_7_sprint3_catalogos_visibilidad`):** tabla auxiliar `cliente_catalogo_visibilidad` (cliente_bubble_id × scope_type macro/catalogo × scope_key × oculto bool, UNIQUE compuesta). **Semántica opt-in (decisión Ben "todas sin seleccionar, las elegirá Valentina"):** si NO existe row → **OCULTO** por defecto; si existe con `oculto=true` → oculto; si existe con `oculto=false` → visible. Macro oculta tiene precedencia sobre catálogos. RPC ampliada para devolver `visibilidad` array. Frontend: botón "⚙️ Gestionar catálogos" arriba del panel abre sheet bottom con switches por macro (7) y catálogo (17 agrupados, disabled si su macro está oculta). UPSERT via PostgREST `on_conflict=cliente_bubble_id,scope_type,scope_key` con `Prefer: resolution=merge-duplicates,return=representation`. **Cascada:** al activar una macro el frontend envía array UPSERT con la macro + todos sus catálogos en `oculto=false` (si no, el default opt-in dejaría todo oculto pese a haber activado la macro). Datos preservados al ocultar (no se borra nada). Auto-hide de macros vacías. Total tablas del bloque F2.7: 17 + 1 = **18 tablas**. **Bugfixes mismo día:** (1) commit `5fa8363` botón "+ Añadir" no respondía por `onclick="stopPropagation()"` inline que bloqueaba el delegate handler; (2) commit `d8fd260` checkbox de visibilidad mostraba "Error" pese a guardar OK — body vacío con `Prefer: return=minimal` rompía `res.json()`. Fix: helper `tableRequest` tolera body vacío + `toggleVisibility` usa `return=representation`. Seed Rock & Climb (`1778244949886x…`) con 16 entradas en 6 catálogos derivadas del PDF de lanzamiento. Sprint 4 pendiente: pickers FK webinar→comunidad_wsp/lead_magnet, editor `campos_capturar` jsonb, buscador global, toggle "ver archivadas". Fase C pendiente: cablear Campaña→Catálogo por referencia + tabla `campania_sesion_webinar` para webinars con N sesiones. **F2.8 Panel contextual "Estás en…" (cerrada 2026-05-25):** tarjeta sticky desktop ≥1280px / FAB `?` + sheet bottom <1280px que explica en cada vista dónde estás + qué puedes hacer + 1 tip práctico. 12 scopes cubiertos (cliente-list, datos, servicios, catálogos, anomalías + 7 de Pipelines: list/pipeline/campaign/trigger/email/whatsapp/creatividad). Reusa `window.openFichaInfo()` del sistema `infoIcon` existente para los links "Más sobre…". **Dismiss progresivo por scope_key** (localStorage `thenucleo-fc-scope-guide-v1`): visita 4 = pre-colapsado, visita 5 = oculto + toast "Pulsa ? para reactivar" + dot violeta en FAB. Botón `?` siempre reactiva. `prefers-reduced-motion` deshabilita transforms. `aria-live="polite"` para screen readers. FAB se oculta automáticamente mientras hay sheet del CRUD abierto (MutationObserver sobre `#sheet`). Cableado vía evento `ficha:view-changed` disparado desde `PIPELINES_MODULE.render()`, tab click handler y bootstrap inicial; `PIPELINES_MODULE` expone ahora `getView()` que devuelve `{kind, code}` resuelto (con escape seguro sobre datos DB). **Deep-link autenticado desde portal Bubble (rollout completo cerrado 2026-05-26):** Edge Function `bridge_from_portal` v6 (`verify_jwt:false`, **bearer primario + HMAC legacy retrocompat** sobre el mismo `BRIDGE_SHARED_SECRET` + allowlist x5) + magic link single-use de Supabase. **3 botones operativos en LIVE** en el submenú Cliente del portal (Estrategia → `/estrategia/?id=…`, Timeline → `/timeline/?id=…`, Ficha legacy → fallback `/ficha-cliente/?id=…`), cada uno con page workflow de **2 steps puros** (API Connector + Open external website — sin Toolbox, sin Server Script). 1 redirect visible (~300ms) → subsección autenticada, sin Google OAuth otra vez. Tabla auditoría `bridge_audit_log`. Allowlist en **9 sitios hardcoded** (8º+9º = Edge Function + policy de la audit table). Patch `assets/js/comunidad-entrar.js` oculta captcha cuando llega `#access_token=` en hash. Setup bearer + rotación + 7 lecciones aprendidas (L1–L7, incluye L5 `Current Page's X` vacío si vive en Group / L6 Initialize values son fallback silencioso / L7 Format custom `X` mayúscula vs unix literal) en `docs/work/bridge-portal-ficha.md`. Bug Toolbox quedó by-passed (deuda técnica baja).
  - `/casuisticas/` — tablero kanban admin
  - `/disponibilidades/` — calendario laboral equipo
  - `/presentacion-pipelines/` — slides Reveal.js sintetizando `pipelines-presentacion.md` + manuales Account/PM para sesión de ejecución (audiencia Account + PM). 29 secciones, mockups HTML/CSS reproduciendo UI real de `/ficha-cliente/` + flujo end-to-end mermaid. Mismo allowlist 5 emails. Creada 2026-05-25.
- **Vercel fallback:** https://app-landing-thenucleo.vercel.app/
- **Dev:** `npm run dev` → `http://localhost:8080`

## Estructura de archivos
```
index.html                  ← landing (HTML + CSS + JS en un solo archivo, Three.js)
aviso-legal.html
privacidad.html
robots.txt
vercel.json                 ← buildCommand + outputDirectory + headers
package.json                ← Eleventy v3 como devDep
.eleventy.js                ← config Eleventy
.eleventyignore             ← excluye index.html/legales del templating
sitemap.njk                 ← sitemap dinámico con todos los posts + comunidad
_data/
  site.js                   ← globals (SUPABASE_URL/ANON_KEY/edge action URL)
  comunidad.js              ← build-time fetch a v_comunidad_propuestas_publicas
_includes/
  blog.njk                  ← layout de cada post del blog
  comunidad-base.njk        ← layout común de /comunidad/* (nav + footer + modal global "Crear propuesta")
arquetipo/
  index.html                ← /arquetipo/ test público de leadgen (12 arquetipos Jung). Standalone HTML+CSS+JS inline, passthrough copy. Sin IA por ahora — calcula arquetipo principal/secundario y muestra descripción genérica + CTA "Generar análisis personalizado" (botón disabled, pendiente Edge Function).
conocimiento-zenyx/
  index.njk                 ← listado /conocimiento-zenyx/
comunidad/
  index.njk                 ← /comunidad/ (landing 2 cards SVG: Pool red de nodos verde + Referidos diamante violeta)
  pool/index.njk            ← /comunidad/pool/ (listado pool con tab-bar + filtros + progress bar)
  referidos/index.njk       ← /comunidad/referidos/ (listado referidos)
  propuesta.njk             ← paginate por slug → /comunidad/{slug}/
  entrar.njk                ← /comunidad/entrar/ (login Google + "No soy un robot", noindex)
  admin.njk                 ← /comunidad/admin/ (panel moderación, noindex)
disponibilidades/
  index.html                ← /disponibilidades/ calendario laboral equipo (admin-only, noindex). Standalone HTML+CSS+JS inline. 3 capas (AHORA/HOY timeline/SEMANA grid). Carga miembros dinámicamente vía RPC `disponibilidad_miembros()`. Override modal con 7 tipos (medico, enfermo, llega_tarde, sale_antes, vacaciones, avatar_no_responde, otro).
ficha-cliente/
  index.html                ← /ficha-cliente/ (admin allowlist, noindex). Standalone HTML+CSS+JS inline, mobile-first dark+verde (paleta TheNucleo, NewBlack, theme switch). Gate auth idéntico a /playbook y /fichas-de-producto. Estado vacío (sin `?id=`) muestra listado inline de clientes activos + buscador directamente en el panel (fix 2026-05-25, antes era un empty card + botón que abría sheet). Botón "Cambiar" del header sigue abriendo el sheet bottom cuando ya hay cliente cargado. URL deep-link `?id=<bubble_id>`. Lee `bub_clientes` vía RPCs `ficha_cliente_listar()` y `ficha_cliente_get(p_bubble_id)`. Panel "Datos" mapea campos reales (identificación, contacto, web, dirección fiscal) + bloque "Operaciones internas" (Drive, análisis, gchat_space_id, NPS, facturación), todo organizado en 5 grupos `.coll-group` plegables con badge `rellenos/total` por sección (verde si completo, ámbar si faltan, `MOCKUP · N` si la sección es 100% placeholder — caso Accesos hoy). Por defecto solo Identificación abierto. Panel "Servicios contratados" lee `playbook_cliente_servicios` vía `ficha_cliente_get` (la RPC agrega un array `servicios` al JSON con jsonb_agg ordenado por orden), renderiza agrupado por `categoria_nombre` con headers `.coll-group` (dot color · nombre · count pill) + buscador (titulo/cat/unidades/periodo/notas, aparece si >4 items, auto-expande matches) + botón Expandir/Colapsar todo. Panel "Catálogos" también en `.coll-group` (mockup). Anomalías sigue como MOCKUP plano (no se inventan datos).
fichas-de-producto/
  index.html                ← /fichas-de-producto/ (admin allowlist, noindex). Rewrite mobile-first 2026-05-22 (tabs por categoría en vez de sidebar, FAB, sheet bottom para nueva categoría, popover estado). Preserva: debounce save 500ms (id,field), CRUD `fichas_categorias` + `fichas_de_producto`.
playbook/
  index.html                ← /playbook/ y /playbook/<bubble_id> (admin allowlist + anon-mode cliente). Capa responsive 2026-05-22: ≤720px oculta view-switcher y fuerza vista timeline (tabla/kanban invisibles en móvil sin tocar JS); pickers (owner/day/auto/phase) reposicionados como bottom-sheet con `slideUpMob`; filtros/stats/sectores con scroll-x; touch ≥40px; anti-zoom iOS.
content/
  conocimiento-zenyx/
    conocimiento-zenyx.json ← data file (layout=blog, tags=blog, permalink)
    {slug}.md               ← posts (los commitea n8n)
assets/css/
  comunidad.css             ← tokens del mockup (#090a0f, verde, azul, violet) + componentes (community-card, proposal-card, modal, auth-menu)
assets/js/
  consent.js                ← cookies RGPD
  comunidad-supabase.js     ← cliente supabase + nav user menu (avatar/logout) + goToLogin()
  comunidad-landing.js      ← tilt 3D cards + burst SVG en /comunidad/
  comunidad-listado.js      ← votos + search + pills (compartido por /pool/ y /referidos/)
  comunidad-ficha.js        ← votos + comentarios en ficha individual
  comunidad-modal.js        ← modal global "Crear propuesta" (sustituye a comunidad-nueva.js)
  comunidad-entrar.js       ← /comunidad/entrar/ → "No soy un robot" + signInWithOAuth Google
  comunidad-admin.js        ← gate admin + aprobar/rechazar via Edge Function
fonts/                      ← NewBlack Typeface (woff2)
icons/                      ← logos integraciones
Media/                      ← logo circular PNG (favicon + OG) + macbook_laptop.glb + videonuevo_dashboard.mp4
```

## Arquitectura de la landing
SPA con scroll-jacking. `#experience` tiene `height: 950vh` con 6 fases sticky:
- Phase 0: Hero ("Recupera el control")
- Phase 1: Features (funcionalidades)
- Phase 2: Resultados (métricas)
- Phase 3: Plataforma (video MacBook 3D)
- Phase 4: Precios (3 planes: €79/€205/€700)
- Phase 5: CTA final

La navegación usa `href="#"` + `data-phase` → JS puro, no anclas reales.
**Excepción:** el link "Conocimiento" en el nav apunta a `/conocimiento-zenyx/` (URL real, el handler JS lo ignora por no tener `data-phase`).

## Eleventy — build del blog
- `npm install` — instala Eleventy v3
- `npm run build` — genera `_site/`
- `npm run dev` — serve en localhost:8080 con watch
- `vercel.json` tiene `buildCommand: npm run build` → Vercel ejecuta Eleventy en cada push

El `index.html` Three.js NO pasa por el template engine (excluido en `.eleventyignore`). Solo se procesan los `.md` del blog, `conocimiento-zenyx/index.njk` y `sitemap.njk`.

## Blog — /conocimiento-zenyx/
Posts generados por el workflow n8n `CNlBtiFCwY69I6Wl` ("CRON BLOG — Zenyx Diario 18:00") a las 18:00 Madrid cada día. El workflow:
1. Lee el siguiente pendiente de Supabase (`v_blog_videos_pendientes` ORDER BY orden ASC)
2. Obtiene transcript de YouTube vía Supadata
3. Claude genera el artículo (title, slug, excerpt, markdown_body)
4. Commit `.md` en `content/conocimiento-zenyx/{slug}.md`
5. Vercel rebuilda → post live en `/conocimiento-zenyx/{slug}/`
6. `IndexNow Ping` → POST a Bing/Yandex con URLs del post nuevo + índice + sitemap

## IndexNow
Key: `d75eac395db864420f8f0401b9277586` (archivo en raíz: `d75eac395db864420f8f0401b9277586.txt`, passthrough en `.eleventy.js`).
Indexa en Bing + Yandex (no Google). El archivo de la key **NO se borra** — si cambia, Bing invalida todas las URLs enviadas anteriormente.

Backlog inicial: 75 vídeos del canal de Miguel Villamil (@soymiguelvillamil), orden cronológico (EP01 primero).

**Documentación completa del blog:** [`docs/work/blog-zenyx.md`](./docs/work/blog-zenyx.md)

## Comunidad pública — `/comunidad/`
Comunidad pública de propuestas (ideas, servicios, herramientas) con votación, comentarios y crowdfunding. Migrada del portal Bubble el 2026-04-28.

**Stack:**
- **Datos:** tablas nativas en Supabase cbi (`comunidad_propuestas`, `comunidad_comentarios`, `comunidad_votos_*`, `comunidad_admins`). Detalle en `docs/infra/supabase-schema.md` sección "Comunidad pública".
- **Auth:** Supabase Auth Google OAuth. Login centralizado en `/comunidad/entrar/` (pantalla estilo Google + widget "No soy un robot" — local, gesto humano antes de OAuth). `goToLogin()` redirige cualquier flujo a `/entrar/?next=<retorno>`. Logout desde menú avatar en nav (dropdown con nombre/email + "Cerrar sesión").
- **SSG:** Eleventy lee `v_comunidad_propuestas_publicas` en build-time (`_data/comunidad.js`) y pre-renderiza listado y fichas. Webhook Supabase → Vercel Deploy Hook al aprobar propuesta (regenera SSG).
- **Cliente:** `@supabase/supabase-js` vía CDN jsdelivr (sin bundler). Globals inyectados en `<head>` por `_includes/comunidad-base.njk` desde `_data/site.js`.
- **Moderación:** Edge Function `comunidad_admin_action` (Supabase, verify_jwt). Allowlist en tabla `comunidad_admins`.
- **Crowdfunding Fase 1:** botón "Aportar al pool" presente como **stub** (`disabled` con nota "próximamente"). Activación con Stripe Checkout cuando Stripe PROD esté operativo (Fase 2, fuera de alcance actual).

**Env vars necesarias en Vercel:**
- `SUPABASE_ANON_KEY` (build-time, también inyectada al cliente — es pública por diseño).
- (`SUPABASE_URL` opcional; default hardcoded a `https://cbixhqjsnpuhcrcjppah.supabase.co`.)

**Secrets en Edge Function (Supabase Dashboard):**
- `VERCEL_DEPLOY_HOOK_URL` — URL del Deploy Hook del proyecto `app-landing-thenucleo` (rama `main`).

**Robots/SEO:**
- `/comunidad/admin/` → `Disallow` en robots.txt + `<meta name="robots" content="noindex,nofollow">` inyectado por JS + `eleventyExcludeFromCollections: true`.
- Sitemap incluye `/comunidad/`, `/comunidad/pool/`, `/comunidad/referidos/` y cada `/comunidad/{slug}/` aprobada. `/comunidad/admin/` y `/comunidad/entrar/` excluidas (noindex + Disallow).
- **Modos** (campo `modo` en BD, antes `tipo_propuesta`): `pool` (financiación colectiva) y `referidos` (desarrollo individual con comisiones). El form de propuesta es un modal global accesible desde el botón "Proponer" de cualquier página `/comunidad/*`.
- **Reparto de campos usuario vs admin** (2026-04-29):
  - Usuario en el modal solo envía: `titulo`, `descripcion`, `problema`, `beneficio`, `modo`. La nota en el modal lo aclara.
  - Admin en `/comunidad/admin/` fija los numéricos: `cotizacion_precio` + `umbral_financiacion_pool` (pool) o `precio_adhoc` (referidos). También puede corregir los textos del usuario (ortografía, reformular) antes de aprobar.
  - Panel admin con dos secciones: **Pendientes** (Aprobar/Rechazar) y **Aprobadas** (Guardar cambios). Aprobar guarda ediciones + dispara Edge Function + rebuild Vercel. Guardar en aprobadas hace UPDATE directo vía RLS admin (NO rebuild — ver troubleshooting en `docs/work/comunidad.md`).

**Bootstrap admin:**
Tras el primer login Google de Ben en `/comunidad/admin/`, ejecutar en Supabase:
```sql
INSERT INTO comunidad_admins (user_id) VALUES ('<uid de auth.users>');
```

## SEO — Estado actual landing
**Score:** 42/100 (auditado 2026-04-11)
Documentos de referencia: `FULL-AUDIT-REPORT.md` (análisis completo por categoría) y `ACTION-PLAN.md` (plan priorizado con código listo para aplicar) vivieron en `docs/archive/` hasta 2026-05-23. Borrados antes de la migración del vault (commit `0e81519`) — recuperables desde git history si vuelven a hacer falta. Items críticos vivos hoy → `docs/work/deuda-tecnica.md`.

## Rendimiento — Estado tras sesión 2026-04-19

**PSI desktop (limpio, servidor Google):** Performance **67/100** — Accesibilidad 100 — Best Practices 100 — SEO 92.

Métricas: FCP 0.7s ✅ · LCP 0.8s ✅ · CLS 0.003 ✅ · TBT **980ms** ⚠️ · SI 2.1s ⚠️.

**Optimizaciones ya aplicadas (commits `b56c729` → `f9afb35`):**
- GLB MacBook: resize 512 + WebP (1.9 MB → 699 KB). Draco se probó y se descartó (disparaba TBT a 22s por decoder en main thread).
- 13 iconos integraciones PNG → WebP (167 KB → 46 KB).
- Favicon dedicado (147 KB PNG usado como 16/32/180 → 2 KB favicon-32 + 28 KB apple-touch).
- Three.js URL → `three.module.min.js`.
- **Idle-pause RAF pattern** en Scene logos+bloom y canvas particles: loops solo corren mientras haya input reciente (1.5s), se auto-pausan después. Lighthouse sin input → main thread idle → TBT bajó de 22,150ms a 980ms.
- Accesibilidad: color contrast footer (quita opacity .6), heading order h4 → h3.
- Security headers + CSP completo en `vercel.json` (con `'unsafe-inline'` por JSON-LD + importmap + CSS inline).

**Pendientes para próxima auditoría (quick wins, ~1h total):**
1. ~~**Self-host Google Fonts**~~ ✅ Eliminado — todo unificado en NewBlack (self-hosted woff2). Space Grotesk y JetBrains Mono removidos.
2. **Bundle Three.js + addons localmente** con esbuild/rollup en un solo archivo. Elimina cadena de 12 requests en cascada a jsDelivr (3119ms critical path). Medio riesgo (cambio de build). Alternativa más simple: self-host los archivos individualmente, mismo dominio.
3. **Lazy-load GLB** con IntersectionObserver en `.phase-showcase`. El MacBook está en Phase 3, cargarlo sólo cuando el usuario se acerque. Bajo riesgo. Ahorra 330 KB del initial transfer. Nota: Scene #2 (MacBook) YA tiene `if (!isVisible) return` en el render loop desde commit original — pero el fetch del GLB ocurre al load.

**Proyección con los 3 aplicados:** Performance 85-92.

**⚠️ Trade-off UX del idle-pause:** al cargar la página sin mover el mouse, el hero queda estático (torus no rota, logos no respiran, partículas congeladas). Primer gesto del usuario arranca todo. Si en el futuro se percibe como mala primera impresión, alternativa: arrancar los RAF al load y auto-pausar tras 3-5 s sin input (compromiso entre UX inicial y Lighthouse).

## Problemas críticos pendientes (no tocar sin leer ACTION-PLAN.md)
1. Links de Stripe en **modo TEST** (`buy.stripe.com/test_...`) → se mantiene TEST hasta que Ben finalice la cuenta Stripe PROD (decisión 2026-04-19). Mitigación visual mínima sugerida: banner "Modo prueba" sobre `.pricing-grid`.
2. ~~**Nav móvil sin hamburguesa**~~ ✅ Resuelto 2026-04-30 — ver "Fix 2026-04-30" abajo.
3. **`prefers-reduced-motion` no aplica a Three.js / partículas / cursorLoop**. La media query CSS solo neutraliza animaciones CSS, los `requestAnimationFrame` (Scene1, Scene2, particles, cursorLoop) corren igual. Riesgo vestibular para ~15-20% del tráfico móvil con la opción activa. Fix: gate global `if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;` en cada loop de render.

## Mejoras no críticas
- OG image (`Media/og-image.png`, 1200×630): usa el logo con fondo blanco. Funciona pero choca con la identidad dark del site y no lleva tagline. Cuando haya tiempo, rehacer con fondo `#171717` + logotipo dark theme + hook textual.
- Magnetic buttons activos en touch (`mousemove` en `.btn-primary/.btn-ghost/.btn-sm/.pricing-cta`). Gate con `(hover: hover) and (pointer: fine)` igual que el cursor custom.
- Touch targets `< 44 px` en `.btn--sm` (32 px) y `.pdot` (8 px). WCAG 2.5.5 AA.
- CSP sin `report-to` / `report-uri` → violaciones inline pasan silenciosas. Añadir endpoint de reporte en `vercel.json` para telemetría.
- RLS de tablas `comunidad_*` no auditada en pase 2026-04-29 (solo lectura cliente). Verificar en Dashboard que UPDATE/DELETE estén restringidos a `comunidad_admins` o filas propias en `pendiente`.

## Auditoría 2026-04-29 — fixes aplicados
- **Nav header click handler**: enlaces `data-phase="N"` aterrizaban en `phaseEdges[idx]` (boundary inicial) y las cards de Funcionalidades/Resultados animaban a partir de localT 0.10+ → la fase aparecía vacía. Ahora aterrizan a `phaseEdges[idx] + 0.55 * span` para que el smooth-scroll recorra la animación durante el viaje. (`index.html:2331-2346`)
- **Botones "Empezar ahora"**: hero (línea 1515) + CTA final (línea 1766) pasan de `data-phase="4"` (scroll a Precios) a `https://portal.thenucleo.com/` con `target="_blank" rel="noopener noreferrer"`, mismo patrón que "Acceder" del nav.
- Auditoría triple completa (UX / seguridad / responsive) consolidada en plan local de Ben (`.claude/plans/pusea-y-hazme-una-noble-ullman.md` en su máquina) — 3 críticas, 5 altas, 8 medias, 7 bajas. Si hace falta para próximas iteraciones, pedir a Ben que lo migre a `docs/work/auditoria-2026-04-29.md`.

## Fix 2026-04-30 — Header móvil + hamburguesa en los 4 navs
- **Bug A (header desbordaba con sesión iniciada en `/comunidad/*`):** a `≤600px` el nav mostraba isotipo + logotipo SVG (~110px) + auth-menu + "Acceder →". Logueado se sumaba avatar/caret y el conjunto excedía el ancho útil (≈315px en iPhone 375).
- **Bug B (nav móvil sin hamburguesa, ≤860/900px):** `.nav-links { display:none }` dejaba el nav móvil sin acceso a Funcionalidades/Resultados/Plataforma/Precios/Comunidad/Conocimiento. Era el problema crítico #2 documentado en este mismo doc. Solo se veía logo + "Acceder".
- **Fix A — `assets/css/comunidad.css`:** a `≤600px` ocultar `.nav-logotipo` (solo isotipo circular), nav padding 10px 14px, `.btn-sm` 8px 12px / 12px. A `≤360px` (iPhone SE) padding 7px 10px y dropdown auth-menu limitado a `calc(100vw - 24px)`.
- **Fix B — Hamburguesa en los 4 navs** (3 barras → X animado, dropdown glass top-right + backdrop, bloquea scroll body, cierra con tap-link/backdrop/Esc/resize > breakpoint):
  - `assets/css/comunidad.css` — estilos `.nav-burger` + `.nav-mobile-menu` + `.nav-mobile-backdrop` (cubre 3 navs njk).
  - `_includes/comunidad-base.njk`, `_includes/blog.njk`, `conocimiento-zenyx/index.njk` — burger + menú + JS handler en el `<script>` existente.
  - `index.html` — CSS inline duplicado (no carga `comunidad.css`), agrupado `Acceder + burger` dentro de un nuevo `.nav-right` (eran hermanos sueltos del `<nav>` con `space-between` → btn quedaba en el centro). Burger handler en el bloque NAV BURGER. Para los links con `data-phase`, en mobile (≤1024px) scrolla directo a `.phase[data-p="N"]` (el padding-top:96px de las phases ya da aire bajo el nav); en desktop sigue el cálculo `phaseEdges + 0.55 * span`.
- **Sin cambio JS auth:** "Acceder →" sigue visible logueado o no porque comunidad y portal son sesiones separadas (Supabase Auth vs Bubble auth).

## Fix 2026-05-23 — Datos y Catálogos colapsables en /ficha-cliente/
- **Problema:** el panel "Datos" mostraba 5 secciones (Identificación, Contacto, Presencia digital, Accesos, Operaciones internas) apiladas con todos sus campos visibles a la vez → demasiado ruido para echar un vistazo rápido. Catálogos igual con sus 2 secciones desplegadas.
- **Fix:** componente colapsable unificado `.coll-group` reutilizado en los 3 paneles (Datos / Catálogos / Servicios). Cada header lleva caret animado, dot de color, nombre y badge contador. Por defecto en Datos solo "Identificación" queda abierto.
- **Badge inteligente** en Datos: cuenta campos con valor real vs total (`X/N`), ignorando los mock. Verde si todo relleno, ámbar si faltan, neutro `MOCKUP · N` si la sección es 100% placeholder.
- **Refactor:** `.svc-group*` → `.coll-group*` (mismas reglas CSS, nombre genérico). Servicios mantiene su atributo `[data-toggle]` con estado propio (allOpen, openCats, búsqueda); Datos/Catálogos usan `[data-coll-toggle]` con handler global (click + Enter/Space, `aria-expanded`).
- **Helper JS:** `renderDatosSection(listId, countId, fields)` reemplaza el `.innerHTML = [...].join('')` por sección. Pinta los rows y actualiza el badge.
- Commit `94fce60` (PR-less, merge directo fast-forward a main).

## Fix 2026-05-26 — "Acceder →" movido dentro del burger móvil (los 4 navs)
- **Problema:** en mobile, header con 3 amarillos compitiendo (aro isotipo + "Acceder →" pill + hero CTA "Empezar ahora"). El segundo le robaba peso al tercero — y "Empezar ahora" es la CTA que convierte tráfico frío. "Acceder" es para clientes existentes, no para nuevos.
- **Fix:** a `≤900px` (landing) y `≤860px` (comunidad/blog/conocimiento), `.nav-right > .btn-sm { display: none }`. El link se reañade como último item del `#nav-mobile-menu`, separado con `<div class="menu-divider">` y estilado con `.menu-cta` (color accent + `font-weight: 600`). Landing usa amarillo (`var(--yellow)` + `rgba(243,249,89,.10)` hover); comunidad/blog/conocimiento usan verde (`var(--accent-primary)` + `var(--accent-primary-muted)` hover).
- **Sin cambios JS:** el delegate `menu.addEventListener('click', e => { if (e.target.closest('a')) close(); })` ya cubría cualquier `<a>` interno.
- **Archivos:** `index.html` (CSS inline), `assets/css/comunidad.css`, `_includes/comunidad-base.njk`, `_includes/blog.njk`, `conocimiento-zenyx/index.njk`. **Skipped intencional:** `_includes/onboarding-base.njk` — su nav no tiene burger ni mobile menu (flujo 1-2-3 step), no aplica.
- **Discrepancia breakpoint detectada (no corregida):** landing usa `≤900px`, comunidad/blog `≤860px`. Unificar = otro cambio.
- **Actualiza la frase del Fix 2026-04-30** "Sin cambio JS auth: 'Acceder →' sigue visible logueado o no". Sigue siendo cierto en desktop; en mobile el botón ya no vive en el header sino dentro del burger (el avatar/auth-menu de comunidad sí permanece visible en `.nav-right` mobile cuando hay sesión).
- Commit `ee60dfd` (PR-less).

## Pendientes backend `/ficha-cliente/` — F2 (auditoría 2026-05-24)

Estado por panel hoy:
- **Datos** → 🟢 real (parcial). 5 grupos cableados a `bub_clientes` vía RPC `ficha_cliente_get`. MOCK los campos que la tabla no almacena: WhatsApp, Quién gestiona dominio, Instagram, Facebook, y la sección Accesos entera (Meta BM, Google Ads, GHL, DNS) — `ficha-cliente/index.html:1410-1426`.
- **Pipelines** → 🟡 seed F1 hardcoded de Dra. Neuss en JS. UI completa con drawers Account/PM pero sin persistencia.
- **Catálogos** → 🔴 mock total (2 secciones `MOCKUP · 1`, sin RPC ni tabla).
- **Servicios** → 🟢 real desde `playbook_cliente_servicios` (jsonb agregado en `ficha_cliente_get`).
- **Anomalías** → 🔴 mock plano + chip header hardcoded (`index.html:1392`).

Pendientes para próxima sesión (orden sugerido en [[docs/work/ficha-cliente.md]]):
1. **Pipelines y Campañas** — crear `cliente_pipelines` + `cliente_campanias` + `cliente_triggers` + `cliente_emails` + RPCs `ficha_pipelines_get` / `ficha_codigos_catalogo` / 4 upserts + webhook n8n para "Crear tareas Notion". Brief de implementación: `docs/portal/ficha-cliente-pipelines-handoff-landing.md`.
2. **Campos MOCK de Datos** — decidir columnas nuevas en `bub_clientes` (opción A) vs tabla `cliente_accesos` con RLS allowlist (opción B, preferida). Tras decidir: ampliar `ficha_cliente_get`, editor inline con debounce 500ms.
3. **Catálogos** — definir con Ben qué entidades modelan (sospecha: items del cliente + base de contactos para campañas). Crear schema + RPC.
4. **Anomalías** — decidir fuente (tareas vencidas, KPIs Ads `loser/fatigue`, silencio GChat, facturación pendiente) y capa (vista materializada vs CRON n8n).
5. **Modales Pipelines** (`new-trigger`, `new-email`, `np-create`, `nc-save`, `tasks-send` líneas 2172-2378) — hoy solo `showToast(... mockup)`. Se cablean al cerrar el punto 1.

**⚠️ Allowlist:** ya está en 7 sitios (3 frontends admin + 2 RLS + 2 RPCs `ficha_cliente_*`). Cada tabla nueva del módulo sumará uno más. Cuando lleguemos a 10+, migrar a tabla `work_admins(email)` o reutilizar `comunidad_admins`.

Doc canónico: `docs/work/ficha-cliente.md`. Entrada en backlog: `docs/work/deuda-tecnica.md` sección "Backend Ficha Cliente — F2".

## Reglas de trabajo
- **NO tocar la arquitectura Three.js / scroll-jacking** sin confirmación explícita
- Los cambios de contenido de landing van en `index.html`
- Los posts del blog los genera n8n, **no se editan manualmente** salvo para fix puntual
- Para deploy: `git push origin main` → Vercel auto-rebuilda con Eleventy
- Los precios actuales: Mensual €79 · Trimestral €205 · Anual €700
- **NO confundir blog (`/conocimiento-zenyx/` público) con Newsletter IA** (módulo interno de TheNucleo, emails por cliente)

## Comandos útiles
```bash
npm install                     # instalar Eleventy
npm run dev                     # dev server localhost:8080
npm run build                   # build a _site/
git push origin main            # deploy (Vercel auto-builda)
```
