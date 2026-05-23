---
title: Blog Zenyx
dominio: blog
estado: activo
actualizado: 2026-05-08
tags: [blog, seo, eleventy, n8n, publico]
---

# Blog Zenyx — `/conocimiento-zenyx/`

Blog público SEO en `work.thenucleo.com/conocimiento-zenyx/` generado automáticamente desde vídeos del canal YouTube de Miguel Villamil ([@soymiguelvillamil](https://www.youtube.com/@soymiguelvillamil)).

**⚠️ NO confundir con el módulo "Newsletter IA"** de TheNucleo (emails internos por cliente, tabla `newsletter_wip`, workflows `inWFSAEDLCH1kx5P`+). Son cosas distintas.

---

## Resumen

- **Qué es:** blog público SEO con artículos atemporales (evergreen) generados a partir de transcripts de vídeos de YouTube.
- **Ritmo:** 1 artículo/día a las 18:00 Europe/Madrid, cronológicamente antiguo→reciente (EP01 primero, EP41 último).
- **Backlog inicial:** 75 vídeos precargados en `blog_videos`. A razón de 1/día, ~10 semanas de contenido automático.
- **Estado al 2026-04-25:** 3 publicados / 72 pendientes.
- **Dónde vive:** repo [`marketingthenucleo/thenucleo-landing`](https://github.com/marketingthenucleo/thenucleo-landing), carpeta `content/conocimiento-zenyx/*.md`.
- **Frontend:** Eleventy v3 (static site generator). Build en Vercel en cada push a `main`.

---

## Arquitectura

```
Cron 18:00 Madrid (n8n)
       │
       ▼
Supabase v_blog_videos_pendientes (ORDER BY orden ASC)
       │
       ▼  (1 video)
YouTube Oembed ─────► metadata (title, author, thumbnail)
       │
       ▼
Supadata API ──────► transcript (texto plano)
       │
       ▼
Claude API (claude-sonnet-4-6) ──► JSON { title, slug, excerpt, markdown_body }
       │
       ▼
GitHub API ────────► commit content/conocimiento-zenyx/{slug}.md (main)
       │
       ▼
IndexNow API ──────► ping a Bing/Yandex con URL nueva + sitemap
       │
       ▼
Vercel detecta push ─► Eleventy build ─► HTML en /conocimiento-zenyx/{slug}/
       │
       ▼
Supabase UPDATE blog_videos SET estado='publicado', ...
```

---

## Supabase — tabla `blog_videos`

Proyecto: `cbixhqjsnpuhcrcjppah` (cbi).

Columnas:
| Columna | Tipo | Notas |
|---|---|---|
| `id` | UUID PK | Generado |
| `orden` | INTEGER UNIQUE | Orden de publicación. 1 = primer post, 75 = último. EP01 tiene orden=1 |
| `video_id` | TEXT UNIQUE | ID de YouTube (11 chars) |
| `video_url` | TEXT | URL completa `https://youtu.be/...` |
| `video_title` | TEXT | Título original del vídeo en YouTube |
| `estado` | TEXT | `pendiente`/`publicado`/`error_transcript`/`error_claude`/`error_commit`/`skip` |
| `title` | TEXT | Título SEO generado por Claude (60-70 chars) |
| `slug` | TEXT UNIQUE | Long-tail SEO kebab-case |
| `excerpt` | TEXT | Meta description (150-160 chars) |
| `markdown_body` | TEXT | Cuerpo del artículo en markdown, sin H1 |
| `transcript_length` | INTEGER | Chars del transcript |
| `transcript_source` | TEXT | `supadata` normalmente |
| `github_commit_sha` | TEXT | SHA del commit generado |
| `github_path` | TEXT | `content/conocimiento-zenyx/{slug}.md` |
| `published_at` | TIMESTAMPTZ | Cuándo se publicó |
| `error_msg` | TEXT | Si falló, qué pasó |
| `agencia_id` | UUID | Tenant raíz |
| `created_at`, `updated_at` | TIMESTAMPTZ | Auto (trigger `bv_updated_at`) |

### Vista `v_blog_videos_pendientes`

```sql
CREATE VIEW public.v_blog_videos_pendientes AS
SELECT id, orden, video_id, video_url, video_title, estado, agencia_id, created_at
FROM public.blog_videos
WHERE estado = 'pendiente'
ORDER BY orden ASC;
```

**Por qué existe:** el nodo Supabase de n8n no permite `ORDER BY` en getAll. La vista se lo da resuelto. El workflow consulta esta vista con `limit=1` para obtener siempre el siguiente pendiente.

### Índices

- `idx_bv_estado_orden` — sobre `(estado, orden ASC) WHERE estado='pendiente'` (cubre el query del cron)
- `idx_bv_slug` — lookup rápido por slug

### Queries útiles

```sql
-- Ver backlog pendiente en orden de publicación
SELECT orden, video_id, video_title FROM blog_videos
WHERE estado='pendiente' ORDER BY orden ASC LIMIT 10;

-- Ver últimos publicados
SELECT orden, slug, title, published_at FROM blog_videos
WHERE estado='publicado' ORDER BY published_at DESC LIMIT 10;

-- Re-procesar un vídeo que falló
UPDATE blog_videos SET estado='pendiente', error_msg=NULL WHERE video_id='...';

-- Saltar un vídeo (no publicar)
UPDATE blog_videos SET estado='skip' WHERE video_id='...';

-- Reordenar (insertar un vídeo antes del siguiente a publicar)
UPDATE blog_videos SET orden=orden+1 WHERE orden >= 5;
UPDATE blog_videos SET orden=5 WHERE video_id='NUEVO_ID';
```

---

## n8n — workflow `CRON BLOG — Zenyx Diario 18:00`

- **ID:** `CNlBtiFCwY69I6Wl`
- **Proyecto n8n:** `cehv5Dib1J6eKwYQ` (Benjamin marketing.thenucleo@gmail.com)
- **Trigger:** Schedule cron `0 0 18 * * *` timezone `Europe/Madrid`
- **Error handler:** `9WM__jEMrviSSC6KyJCT9` (workflow de errores genérico)
- **URL:** https://n8n-n8n.irzhad.easypanel.host/workflow/CNlBtiFCwY69I6Wl

### 12 nodos del flujo

| # | Nodo | Tipo | Función |
|---|---|---|---|
| 1 | Cron Diario 18h Madrid | Schedule Trigger | `0 0 18 * * *` Europe/Madrid |
| 2 | Get Next Video | Supabase getAll | Lee `v_blog_videos_pendientes` limit=1. `alwaysOutputData: true` |
| 3 | Hay Pendientes | IF | `$json.orden > 0` — si hay vídeo, sigue; si no → Backlog Vacío |
| 4 | YouTube Oembed | HTTP GET | `https://www.youtube.com/oembed?url=...` — metadata sin auth |
| 5 | Get Transcript | HTTP GET | `https://api.supadata.ai/v1/youtube/transcript?videoId=X&text=true` — header `x-api-key` |
| 6 | Build Claude Prompt | Code | Construye user_prompt con metadata + transcript |
| 7 | Claude Generate Article | Anthropic nativo | Modelo `claude-sonnet-4-6`, max 4000 tokens, devuelve JSON |
| 8 | Parse Claude and Build Markdown | Code | Parsea JSON, sanitiza slug, construye frontmatter + full_markdown |
| 9 | Commit Markdown | GitHub nativo | Crea `content/conocimiento-zenyx/{slug}.md` en `main` |
| 10 | IndexNow Ping | HTTP POST | `https://api.indexnow.org/indexnow` con `{host: work.thenucleo.com, key, urlList: [post_url, /conocimiento-zenyx/, sitemap.xml]}`. `onError: continueRegularOutput` + retry x2 con 3s |
| 11 | Mark Publicado | Supabase update | WHERE id=row_id → estado='publicado', guarda title/slug/excerpt/markdown_body/github_commit_sha/published_at |
| 12 | Backlog Vacío | Set | Mensaje "Backlog vacío" si no hay pendientes |

### Credenciales usadas

| Credencial en n8n | Tipo | Usado por |
|---|---|---|
| Supabase account - Rag Clientes | supabaseApi | Get Next Video, Mark Publicado |
| Supapadata Trasncript *(sic)* | httpHeaderAuth | Get Transcript. Header: `x-api-key` → `sd_88be674217fa766de479f5b181218e6f` |
| Anthropic account | anthropicApi | Claude Generate Article |
| GitHub account | githubApi | Commit Markdown |

### Prompt de Claude (system)

El prompt está dentro del nodo "Claude Generate Article" → `options.system`. Resumen de lo que pide:
- Convertir transcript en artículo SEO atemporal (evergreen), 700-1000 palabras
- Español neutro, tono directo, H2/H3, listas
- NO resumir literalmente: reinterpretar y reorganizar
- Contexto: Miguel Villamil + aceleradora Zenyx (ayuda a agencias a superar 1M€)
- Devolver SOLO JSON con schema: `{ title, slug, excerpt, markdown_body }`
- `markdown_body` sin H1 al inicio (el layout añade el H1 del title)

Para cambiar el prompt: editar directamente el nodo en n8n UI. Cambios afectan inmediatamente a los siguientes artículos generados.

---

## Repositorio — `thenucleo-landing`

Stack: **HTML estático + Eleventy v3** (solo para procesar markdown del blog). El `index.html` Three.js SIGUE siendo vanilla, solo añadió un link "Conocimiento" al nav.

### Estructura relevante

```
thenucleo-landing/
├── index.html                  ← landing principal (intacta, solo nav +1 link)
├── package.json                ← Eleventy v3 como devDep + scripts
├── .eleventy.js                ← config Eleventy
├── .eleventyignore             ← excluye index.html/legales del templating
├── vercel.json                 ← buildCommand + outputDirectory
├── sitemap.njk                 ← sitemap dinámico con todos los posts
├── _includes/
│   └── blog.njk                ← layout de cada post (meta OG, JSON-LD Article, CSS)
├── conocimiento-zenyx/
│   └── index.njk               ← página de listado /conocimiento-zenyx/
├── content/
│   └── conocimiento-zenyx/
│       ├── conocimiento-zenyx.json  ← data file: layout, tags, permalink
│       └── {slug}.md           ← posts (los commitea n8n)
└── _site/                      ← output de build (gitignored)
```

### Eleventy

- **Build command:** `npm run build`
- **Dev:** `npm run dev` (serve en `http://localhost:8080`)
- **Output:** `_site/`
- **Engine:** Nunjucks (`.njk`)

### Vercel

- **Proyecto:** `app-landing-thenucleo`
- **Cuenta:** `marketingthenucleo`
- **Build command:** `npm run build`
- **Output:** `_site`
- **Trigger:** push a `main` → rebuild automático (~30-45s)

---

## Formato del markdown publicado

Cada `.md` en `content/conocimiento-zenyx/` tiene frontmatter YAML:

```yaml
---
title: "Título SEO del artículo"
slug: "slug-long-tail-kebab-case"
date: 2026-04-19
video_id: "zDGms9NgWq8"
video_url: "https://youtu.be/zDGms9NgWq8"
video_title: "Título original del vídeo en YouTube"
youtube_channel: "@soymiguelvillamil"
excerpt: "Meta description 150-160 chars"
---

Párrafo gancho de 2-3 líneas...

## Sección H2

Contenido...

### Subsección H3

- Lista
- Con items

Párrafo conclusivo accionable.
```

El `data` file [`content/conocimiento-zenyx/conocimiento-zenyx.json`](../thenucleo-landing/content/conocimiento-zenyx/conocimiento-zenyx.json) aplica a todos los posts:
```json
{
  "layout": "blog.njk",
  "tags": ["blog"],
  "permalink": "/conocimiento-zenyx/{{ slug }}/index.html"
}
```

---

## Operaciones comunes

### Ver el backlog actual
```sql
SELECT orden, video_id, video_title, estado, published_at
FROM blog_videos
ORDER BY orden ASC;
```

### Ejecutar el workflow manualmente (ahora, sin esperar las 18:00)
1. Abre https://n8n-n8n.irzhad.easypanel.host/workflow/CNlBtiFCwY69I6Wl
2. Click "Execute Workflow" (botón play)
3. Tarda ~45-60s. Publica el siguiente pendiente.

### Re-procesar un post fallido
```sql
UPDATE blog_videos SET estado='pendiente', error_msg=NULL WHERE video_id='xxx';
```
Próxima ejecución del workflow lo cogerá (o clic manual).

### Saltar un vídeo
```sql
UPDATE blog_videos SET estado='skip' WHERE video_id='xxx';
```

### Reordenar la cola
El campo `orden` tiene UNIQUE. Para insertar un nuevo vídeo en posición 5:
```sql
UPDATE blog_videos SET orden=orden+1 WHERE orden >= 5;
UPDATE blog_videos SET orden=5 WHERE video_id='xxx';
```

### Añadir vídeos nuevos al backlog
```sql
INSERT INTO blog_videos (orden, video_id, video_url, video_title)
VALUES (76, 'NEW_ID', 'https://youtu.be/NEW_ID', 'Título original');
```

### Pausar el blog
En n8n, desactivar el toggle "Active" del workflow. Los pendientes no se tocan.

---

## IndexNow

- **Host:** `work.thenucleo.com`
- **Key:** `d75eac395db864420f8f0401b9277586`
- **Key location:** `https://work.thenucleo.com/d75eac395db864420f8f0401b9277586.txt`
- **Endpoint:** `POST https://api.indexnow.org/indexnow`
- **URLs notificadas en cada publicación:** post nuevo + landing del blog + sitemap.xml
- **Tolerancia a fallos:** retry x2 con espera 3s + `onError: continueRegularOutput` (no aborta el flow si IndexNow falla, solo se pierde la notificación a buscadores).

---

## Supadata.ai

- **Plan:** free tier (100 transcripts/mes). El backlog de 75 cabe en 1 mes con margen.
- **API key:** `sd_88be674217fa766de479f5b181218e6f`
- **Endpoint usado:** `GET https://api.supadata.ai/v1/youtube/transcript?videoId={ID}&text=true`
- **Header:** `x-api-key: {key}`
- **Response:** JSON `{ lang, availableLangs, content }` donde `content` es texto plano.
- **Upgrade:** si se agota free tier, pricing en supadata.ai (~$0.005/req).

---

## Lecciones aprendidas durante la implementación

1. **`youtubetranscript.com` NO es viable programáticamente** — detecta bots y devuelve mensaje pidiendo parar. Descartado el día 1.
2. **Nodo Supabase de n8n no tiene `ORDER BY`** — necesitamos vista SQL ordenada (`v_blog_videos_pendientes`).
3. **Nodo IF v2.2 con operador string `notEmpty`** tiene bug: espera flag `caseSensitive` que a veces no se emite → error `Cannot read properties of undefined`. Usar operador numérico cuando se pueda (`orden > 0`).
4. **`alwaysOutputData: true`** es imprescindible en nodos que pueden devolver vacío si luego hay IF — si no, el flow se corta silenciosamente.
5. **Credencial Anthropic** es tipo `anthropicApi` para el nodo nativo Anthropic, NO `httpHeaderAuth`. El `Claude` httpHeaderAuth existente no sirve para el nodo nativo.
6. **Los HTTP headers NO pueden tener espacios** — credencial `Supadata` requiere `Name: x-api-key` (sin espacios), no `Supadata Api`.
7. **Rename de `newsletter` → `blog`** se hizo para no colisionar con el módulo Newsletter IA interno de TheNucleo (`newsletter_wip`).

---

## Archivos relacionados

- Workflow JSON (estructura actual): https://n8n-n8n.irzhad.easypanel.host/workflow/CNlBtiFCwY69I6Wl
- Lista original de vídeos (export de YouTube Studio): [`videos.txt`](../videos.txt) (raíz del workspace, no del repo)
- Eleventy config: [`thenucleo-landing/.eleventy.js`](../thenucleo-landing/.eleventy.js)
- Layout de post: [`thenucleo-landing/_includes/blog.njk`](../thenucleo-landing/_includes/blog.njk)
- Listado: [`thenucleo-landing/conocimiento-zenyx/index.njk`](../thenucleo-landing/conocimiento-zenyx/index.njk)
- Sitemap dinámico: [`thenucleo-landing/sitemap.njk`](../thenucleo-landing/sitemap.njk)
