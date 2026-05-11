# ACTION PLAN — work.thenucleo.com
**Generado:** 2026-04-11  
**Score actual:** 42/100 | **Score objetivo:** 72/100

---

## 🔴 CRÍTICO — Hacer ahora (bloquean producción o indexación)

### C1 — Corregir robots.txt y sitemap.xml
**Impacto:** Technical SEO | **Esfuerzo:** 5 min

En `robots.txt`:
```
# Cambiar:
Sitemap: https://app.thenucleo.com/sitemap.xml
# Por:
Sitemap: https://work.thenucleo.com/sitemap.xml
```

En `sitemap.xml`:
```xml
# Cambiar:
<loc>https://app.thenucleo.com/</loc>
# Por:
<loc>https://work.thenucleo.com/</loc>
```

---

### C2 — Reemplazar links de Stripe TEST por links de producción
**Impacto:** Conversión / funcionalidad | **Esfuerzo:** 10 min

Los 3 CTAs de pricing tienen URLs `buy.stripe.com/test_...` que no funcionan en producción.
Reemplazar por los links reales de Stripe producción cuando estén disponibles.

---

### C3 — Añadir páginas legales obligatorias (RGPD/LOPD)
**Impacto:** Legal + Trust | **Esfuerzo:** 2-4 horas

Crear y linkear desde el footer:
- `/privacidad` — Política de Privacidad
- `/aviso-legal` — Aviso Legal (nombre empresa, CIF, dirección)
- Si procesas cookies: banner RGPD

---

## 🟠 ALTO — Hacer esta semana (impacto directo en rankings)

### A1 — Añadir JSON-LD estructurado
**Impacto:** Schema 0→60, Rich Results | **Esfuerzo:** 1 hora

Añadir en `<head>` antes del cierre `</head>`:

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "SoftwareApplication",
      "name": "TheNucleo",
      "description": "Portal de gestión que centraliza tareas, clientes, equipo y finanzas de agencias de marketing.",
      "applicationCategory": "BusinessApplication",
      "operatingSystem": "Web",
      "url": "https://work.thenucleo.com/",
      "offers": [
        {
          "@type": "Offer",
          "name": "Plan Mensual",
          "price": "79",
          "priceCurrency": "EUR",
          "billingIncrement": "P1M"
        },
        {
          "@type": "Offer",
          "name": "Plan Trimestral",
          "price": "205",
          "priceCurrency": "EUR",
          "billingIncrement": "P3M"
        },
        {
          "@type": "Offer",
          "name": "Plan Anual",
          "price": "700",
          "priceCurrency": "EUR",
          "billingIncrement": "P1Y"
        }
      ],
      "featureList": [
        "Dashboard KPIs",
        "Automatizaciones ilimitadas",
        "IA integrada (Cerebro)",
        "Integraciones con Holded, Clockify, Notion",
        "Ops Monitor",
        "WhatsApp Register"
      ]
    },
    {
      "@type": "Organization",
      "name": "TheNucleo",
      "url": "https://work.thenucleo.com/",
      "logo": "https://work.thenucleo.com/Media/Logo_the_nucleo_circulo.png",
      "sameAs": []
    },
    {
      "@type": "WebSite",
      "url": "https://work.thenucleo.com/",
      "name": "TheNucleo",
      "inLanguage": "es-ES"
    }
  ]
}
</script>
```

---

### A2 — Crear OG Image 1200×630 real
**Impacto:** Social sharing, CTR en SERP | **Esfuerzo:** 1 hora

El `og:image` actual es `Logo_the_nucleo_circulo.png` (logo circular). En Twitter/LinkedIn/WhatsApp aparecerá mal.

Crear una imagen `og-image.png` de 1200×630px con:
- Fondo oscuro del brand
- Logo + nombre en grande
- Tagline: "Recupera el control de tu agencia"
- Visual del dashboard (screenshot)

Actualizar en `index.html`:
```html
<meta property="og:image" content="https://work.thenucleo.com/Media/og-image.png" />
<meta name="twitter:image" content="https://work.thenucleo.com/Media/og-image.png" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
```

---

### A3 — Optimizar title tag con keyword principal
**Impacto:** CTR en SERP, ranking | **Esfuerzo:** 5 min

**Actual:** `TheNucleo — Recupera el control de tu agencia`

**Propuesta:** `TheNucleo — Portal de gestión para agencias de marketing`

o si quieres mantener el copy emocional:

`TheNucleo — El portal que centraliza tu agencia de marketing`

---

### A4 — Optimizar H1 con keyword
**Impacto:** On-page SEO | **Esfuerzo:** 10 min

**Actual:** `Recupera el control.`

**El H1 creativo puede mantenerse visualmente**, pero añadir texto descriptivo justo debajo (visible para crawlers):

```html
<h1 class="hero-title glow-yellow">Recupera el<br/><em>control.</em></h1>
<p class="hero-kicker" aria-label="Portal de gestión para agencias de marketing">
  El sistema operativo de tu agencia de marketing
</p>
```

O usar un H1 más largo y ocultar la primera línea con CSS si necesitas el efecto visual exacto.

---

### A5 — Añadir HSTS y CSP a vercel.json
**Impacto:** Seguridad, señales de confianza | **Esfuerzo:** 20 min

En `vercel.json`, añadir al bloque global (`source: "/(.*)")`):
```json
{ "key": "Strict-Transport-Security", "value": "max-age=63072000; includeSubDomains; preload" },
{ "key": "Permissions-Policy", "value": "camera=(), microphone=(), geolocation=()" }
```

---

## 🟡 MEDIO — Hacer este mes (optimizaciones de impacto)

### M1 — Optimizar el video del dashboard
**Impacto:** LCP, Performance | **Esfuerzo:** 2-3 horas

`videonuevo_dashboard.mp4` = 7.7MB es demasiado para web.

Opciones:
1. **Comprimir con ffmpeg:** `ffmpeg -i videonuevo_dashboard.mp4 -vcodec libx264 -crf 28 -preset fast -movflags faststart -vf "scale=1280:-2" output.mp4` → target: <2MB
2. **Añadir versión WebM** para Chrome/Firefox (mejor compresión)
3. **Añadir atributo `poster`** con screenshot del primer frame para evitar pantalla negra:
   ```html
   <video poster="Media/dashboard-poster.jpg" ...>
   ```

---

### M2 — Convertir PNG a WebP
**Impacto:** Performance, Images | **Esfuerzo:** 30 min

- `Logo_the_nucleo_circulo.png` (147KB) → WebP o SVG inline
- 12 icons en `/icons/` → WebP o SVG
- En total ~320KB → ~80-100KB expected

---

### M3 — Añadir sección de contacto/empresa en footer
**Impacto:** E-E-A-T, Trust | **Esfuerzo:** 30 min

El footer actual solo tiene el logotipo, "portal.thenucleo.com" y "v3.0 · 2026". Añadir:

```html
<div class="f-contact">
  <a href="mailto:hola@thenucleo.com">hola@thenucleo.com</a>
  <a href="/privacidad">Privacidad</a>
  <a href="/aviso-legal">Aviso legal</a>
</div>
```

---

### M4 — Añadir FAQ section (al menos 5 preguntas)
**Impacto:** AEO, AI Search, long-tail keywords | **Esfuerzo:** 1-2 horas

Ejemplo de preguntas a responder:
- ¿Qué es TheNucleo y para qué tipo de agencias está pensado?
- ¿Se integra con las herramientas que ya uso (Notion, Holded, Clockify)?
- ¿Cuánto tiempo tarda la implementación?
- ¿Puedo cancelar cuando quiera?
- ¿En qué se diferencia de un CRM o un gestor de proyectos?

Incluir también JSON-LD `FAQPage` correspondiente.

---

### M5 — Crear llms.txt
**Impacto:** AI Search Readiness | **Esfuerzo:** 15 min

Crear `/llms.txt` con descripción del producto en lenguaje natural para AI crawlers:

```
# TheNucleo

TheNucleo es un portal de gestión SaaS para agencias de marketing digital hispanohablantes.
Centraliza tareas, clientes, equipo y finanzas en un solo panel.

## Producto
- Dashboard KPIs en tiempo real
- Kanban de tareas con 8 estados
- Módulo de clientes con ficha y chat IA (Cerebro)
- Control de tiempo (integración Clockify)
- Facturación (integración Holded)
- Automatizaciones (n8n)
- IA para newsletters y análisis

## Precios
- Mensual: €79/mes
- Trimestral: €205 (~€68/mes)
- Anual: €700 (~€58/mes)

## Contacto
hola@thenucleo.com
https://work.thenucleo.com/
```

---

## 🟢 BAJO — Backlog (mejoras estructurales a largo plazo)

### B1 — Estrategia de keywords y páginas adicionales
Para posicionar en búsquedas como "software gestión agencia marketing", "herramienta agencia digital" o "CRM agencia publicidad", una landing SPA no es suficiente. Considerar:
- Página de blog con artículos sobre gestión de agencias
- Landing pages por feature (ej: `/integraciones/notion`, `/integraciones/holded`)
- Página de comparación con alternativas

### B2 — Registrar en Google Search Console
- Submittir sitemap corregido en GSC
- Solicitar indexación de `work.thenucleo.com`
- Monitorizar impresiones orgánicas

### B3 — Listado en directorios de software
- Product Hunt (lanzamiento)
- Capterra / G2 (categoría: Agency Management Software)
- AppSumo si aplica
- Betalist para validación

### B4 — Self-host Google Fonts
Para evitar dependencia externa y ganar ~100ms en TTFB:
Descargar Space Grotesk y JetBrains Mono → servir desde `/fonts/`
(Ya tienes el patrón con NewBlack Typeface)

### B5 — Añadir `rel="noopener noreferrer"` a links externos
```html
<!-- Cambiar: -->
<a href="https://portal.thenucleo.com/" target="_blank" class="btn-sm">
<!-- Por: -->
<a href="https://portal.thenucleo.com/" target="_blank" rel="noopener noreferrer" class="btn-sm">
```

---

## Prioridad de implementación

```
Semana 1:  C1 + C2 + A1 + A2 + A3 + A5
Semana 2:  C3 + A4 + M3 + M5
Semana 3:  M1 + M2 + M4
Mes 2+:    B1 + B2 + B3 + B4 + B5
```

**Score estimado tras Semana 1-2:** ~62/100  
**Score estimado tras implementación completa:** ~75/100
