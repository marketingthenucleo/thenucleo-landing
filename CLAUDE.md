# TheNucleo Landing — work.thenucleo.com

## Qué es
Landing page de captación para TheNucleo + blog público SEO `/conocimiento-zenyx/`.
Stack: HTML + CSS + Three.js (SPA) para la landing + **Eleventy v3** como static site generator para procesar los markdown del blog.
Deploy: Vercel (proyecto `app-landing-thenucleo`, cuenta `marketingthenucleo`)
Repo: `marketingthenucleo/thenucleo-landing`

## URLs
- **Producción:** https://work.thenucleo.com/
- **Blog:** https://work.thenucleo.com/conocimiento-zenyx/
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
sitemap.njk                 ← sitemap dinámico con todos los posts
_includes/
  blog.njk                  ← layout de cada post del blog
conocimiento-zenyx/
  index.njk                 ← listado /conocimiento-zenyx/
content/
  conocimiento-zenyx/
    conocimiento-zenyx.json ← data file (layout=blog, tags=blog, permalink)
    {slug}.md               ← posts (los commitea n8n)
fonts/                      ← NewBlack Typeface (woff2)
icons/                      ← logos integraciones
Media/                      ← logo circular PNG (favicon + OG)
macbook_laptop.glb          ← modelo 3D del MacBook
videonuevo_dashboard.mp4    ← video del dashboard
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
Posts generados por el workflow n8n `CNlBtiFCwY69I6Wl` ("BLOG Zenyx — DIARIO 18:00 Madrid") a las 18:00 Madrid cada día. El workflow:
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

**Documentación completa del blog:** [`../docs/blog-zenyx-workflow.md`](../docs/blog-zenyx-workflow.md)

## SEO — Estado actual landing
**Score:** 42/100 (auditado 2026-04-11)
Documentos de referencia:
- `FULL-AUDIT-REPORT.md` — análisis completo por categoría
- `ACTION-PLAN.md` — plan priorizado con código listo para aplicar

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
1. Links de Stripe en **modo TEST** (`buy.stripe.com/test_...`) → se mantiene TEST hasta que Ben finalice la cuenta Stripe PROD (decisión 2026-04-19)

## Mejoras no críticas
- OG image (`Media/og-image.png`, 1200×630): usa el logo con fondo blanco. Funciona pero choca con la identidad dark del site y no lleva tagline. Cuando haya tiempo, rehacer con fondo `#171717` + logotipo dark theme + hook textual.

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
