# SEO Audit — work.thenucleo.com
**Fecha:** 2026-04-11  
**URL auditada:** https://work.thenucleo.com/  
**Tipo de negocio:** SaaS B2B — Portal de gestión para agencias de marketing (España)  
**Idioma:** Español (es_ES)

---

## SEO Health Score: 42 / 100

| Categoría | Peso | Puntuación | Contribución |
|-----------|------|-----------|--------------|
| Technical SEO | 22% | 60/100 | 13.2 |
| Content Quality / E-E-A-T | 23% | 35/100 | 8.1 |
| On-Page SEO | 20% | 62/100 | 12.4 |
| Schema / Structured Data | 10% | 0/100 | 0.0 |
| Performance (CWV estimado) | 10% | 40/100 | 4.0 |
| AI Search Readiness | 10% | 25/100 | 2.5 |
| Imágenes & assets | 5% | 45/100 | 2.25 |
| **TOTAL** | | | **42 / 100** |

---

## Top 5 Critical Issues

1. **robots.txt y sitemap.xml apuntan al dominio antiguo** `app.thenucleo.com` → Google indexará la URL incorrecta
2. **Cero structured data (JSON-LD)** → sin schema la página es invisible para Rich Results y AI
3. **Video de 7.7 MB** sin optimizar → LCP crítico en móvil, penalización directa en Core Web Vitals
4. **Links de Stripe en modo TEST** (`buy.stripe.com/test_...`) → los CTAs de compra no funcionan en producción
5. **Sin social proof verificable ni señales E-E-A-T** → Google no puede establecer autoridad del dominio

## Top 5 Quick Wins

1. Corregir `robots.txt` y `sitemap.xml` → cambiar `app.thenucleo.com` → `work.thenucleo.com` (5 min)
2. Añadir JSON-LD `SoftwareApplication` + `Organization` (30 min)
3. Convertir `Logo_the_nucleo_circulo.png` a WebP + crear OG image 1200×630 real
4. Añadir `rel="noopener noreferrer"` al link `portal.thenucleo.com`
5. Añadir sección con nombre de empresa, fundador y contacto (email) en footer

---

## 1. Technical SEO — 60/100

### Crawlabilidad
| Check | Estado | Detalle |
|-------|--------|---------|
| robots.txt accesible | ✅ | `Allow: *` correcto |
| Sitemap referenciado en robots.txt | ❌ CRÍTICO | URL incorrecta: `https://app.thenucleo.com/sitemap.xml` → debe ser `work.thenucleo.com` |
| Canonical configurado | ✅ | `<link rel="canonical" href="https://work.thenucleo.com/">` |
| HTML lang | ✅ | `lang="es"` correcto |
| Viewport meta | ✅ | `width=device-width, initial-scale=1.0` |
| charset UTF-8 | ✅ | Presente |
| Redirects | No verificado sin acceso a headers en vivo |

### Indexabilidad
| Check | Estado | Detalle |
|-------|--------|---------|
| Robots meta | ✅ | No hay `noindex` (correcto para landing pública) |
| Sitemap URL correcta | ❌ CRÍTICO | `<loc>https://app.thenucleo.com/</loc>` → debe ser `work.thenucleo.com` |
| Sitemap lastmod | ✅ | 2026-04-11 |
| Un solo URL en sitemap | ⚠️ | OK para single page, pero sin página de privacidad, contacto, etc. |

### Seguridad / Headers
| Header | Estado | Detalle |
|--------|--------|---------|
| X-Content-Type-Options | ✅ | `nosniff` configurado en vercel.json |
| X-Frame-Options | ✅ | `DENY` configurado |
| Referrer-Policy | ✅ | `strict-origin-when-cross-origin` |
| Content-Security-Policy | ❌ | No configurado — recomendado para SaaS |
| HSTS (Strict-Transport-Security) | ❌ | No configurado en vercel.json |
| Permissions-Policy | ❌ | No configurado |

### Assets externos
- Three.js cargado desde CDN jsDelivr (`cdn.jsdelivr.net`) → dependencia externa no controlada
- Google Fonts con `preconnect` configurado ✅

---

## 2. On-Page SEO — 62/100

### Title Tag
```
TheNucleo — Recupera el control de tu agencia
```
- Longitud: 47 caracteres ✅ (límite ~60)
- Incluye marca ✅
- **Problema:** no incluye keyword principal. "Recupera el control" no es lo que busca nadie. Debería incluir "agencia de marketing", "portal de gestión" o similar.

### Meta Description
```
El portal de gestión que centraliza tareas, clientes, equipo y finanzas de tu agencia de marketing. IA integrada, automatizaciones reales, un solo panel.
```
- Longitud: 153 caracteres ✅ (límite ~155)
- Descriptiva ✅
- **Problema:** no hay call-to-action ni diferenciador de urgencia. Tampoco keyword en primeras palabras (Google las trunca).

### Headings
| Tag | Texto | Análisis |
|-----|-------|---------|
| H1 | "Recupera el control." | Punchy pero sin keyword. No lo indexaría Google como relevante para búsquedas de software |
| H2 | "Todo lo que necesitas. Nada que sobre." | Creativo, no indexable |
| H2 | "No es un mockup. Está en producción." | Idem |
| H2 | "Abres el portal. Todo controlado." | Idem |
| H2 | "Un plan simple. Sin sorpresas." | Idem |
| H2 | "Tu agencia merece funcionar sin que tú la empujes cada día." | Solo H2 con potencial de keyword long-tail |

**Conclusión:** todos los headings son taglines creativos. Ninguno target una keyword real. Google no puede entender de qué trata la página más allá del meta.

### Estructura de enlaces
| Tipo | Detalle |
|------|---------|
| Navegación interna | `href="#"` con `data-phase` — JavaScript puro, no son anclas reales. Google no los sigue. |
| CTA principal "Acceder" | `href="https://portal.thenucleo.com/"` + `target="_blank"` — falta `rel="noopener noreferrer"` |
| CTAs de pricing | `href="https://buy.stripe.com/test_..."` — ⚠️ **MODO TEST** — no funcionan en producción |
| CTA "Empezar ahora" (footer) | `<button>` sin `href` — no tiene acción definida |
| CTA "Contactar" (footer) | `<button>` sin `href` — no tiene acción definida |
| Links en footer | Solo texto estático, sin links a legales, contacto ni RRSS |

---

## 3. Content Quality / E-E-A-T — 35/100

### Problemas críticos de autoridad

**Experience (Experiencia):**
- No hay casos de uso con clientes reales nombrados
- Métricas sin fuente: "85% menos tiempo en tareas manuales", "0 tareas perdidas" — ¿de dónde salen?
- Afirmación "Datos reales del sistema que ya gestiona agencias" sin evidencia verificable

**Expertise (Pericia):**
- No aparece ningún autor, equipo, ni persona detrás del producto
- No hay sección "Sobre nosotros" ni mención de Benjamin Sanchis u otros fundadores
- No hay blog, artículos ni contenido educativo

**Authoritativeness (Autoridad):**
- Cero backlinks relevantes presumibles desde una landing nueva
- No hay menciones en prensa, comparadores de software ni directorios
- No hay integración con G2, Capterra, Product Hunt, etc.

**Trustworthiness (Confianza):**
- ❌ Sin política de privacidad
- ❌ Sin términos de servicio
- ❌ Sin aviso legal (obligatorio legalmente en España/LOPD)
- ❌ Sin información de empresa (nombre legal, CIF, dirección)
- ❌ Sin email de contacto visible
- ❌ CTAs de pago en modo TEST — si un usuario hace clic en "Empezar" → URL de Stripe rota

### Legibilidad
- Texto en español, punchy y bien escrito ✅
- Copy muy enfocado en "dolor" sin suficiente "solución detallada"
- Falta sección de preguntas frecuentes (FAQ) — crítico para SEO y AEO

---

## 4. Schema / Structured Data — 0/100

**No hay ningún JSON-LD ni microdatos** en la página.

### Oportunidades perdidas

```json
// SoftwareApplication — Rich Result en SERP
{
  "@type": "SoftwareApplication",
  "name": "TheNucleo",
  "applicationCategory": "BusinessApplication",
  "operatingSystem": "Web",
  "offers": {
    "@type": "Offer",
    "price": "79",
    "priceCurrency": "EUR"
  }
}

// Organization
{
  "@type": "Organization",
  "name": "TheNucleo",
  "url": "https://work.thenucleo.com",
  "logo": "...",
  "contactPoint": { "@type": "ContactPoint", ... }
}

// WebSite (SearchAction)
// FAQPage (si añades FAQ)
```

---

## 5. Performance (CWV estimado) — 40/100

> Sin acceso a CrUX/PageSpeed API en este momento. Estimación basada en análisis de assets.

### Assets críticos
| Asset | Tamaño | Impacto |
|-------|--------|---------|
| `videonuevo_dashboard.mp4` | **7.7 MB** | ❌ CRÍTICO — LCP y carga inicial |
| `macbook_laptop.glb` | **1.8 MB** | ❌ ALTO — bloquea render del 3D |
| `Media/Logo_the_nucleo_circulo.png` | 147 KB | ⚠️ MEDIO — debería ser WebP o SVG |
| Fonts (3 × ~16 KB) | ~47 KB | ✅ Bien — WOFF2 + font-display:swap |
| Icons PNGs (12 archivos) | ~170 KB total | ⚠️ Deberían ser WebP/SVG |

### Otros factores de rendimiento
- Three.js + EffectComposer + UnrealBloomPass → GPU-heavy en móvil
- `height: 950vh` en `#experience` → 9.5× la altura de pantalla de JS de animación
- No hay `rel="preload"` para assets críticos (GLB, video)
- `cursor: none` en desktop + cursor JS personalizado → potencial layout shift
- CSS completo inline (~1500+ líneas) → bloquea render pero al menos no hay una hoja externa adicional
- Google Fonts cargada síncronamente (aunque con preconnect) — considerar self-host

### Estimaciones
| Métrica | Estimación | Rating |
|---------|------------|--------|
| LCP (móvil) | ~5-8s | ❌ Malo |
| LCP (desktop) | ~3-5s | ⚠️ Necesita mejora |
| CLS | Bajo (sticky layout) | ✅ |
| INP | Medio-alto (Three.js) | ⚠️ |

---

## 6. AI Search Readiness (GEO/AEO) — 25/100

| Check | Estado |
|-------|--------|
| `llms.txt` | ❌ No existe |
| Contenido crawleable sin JS | ❌ Página 100% JS-driven — AI crawlers ven solo el HTML base sin las secciones de contenido |
| Respuestas a preguntas frecuentes | ❌ No hay FAQ |
| Datos estructurados para AEO | ❌ Sin JSON-LD |
| Brand mentions citables | ⚠️ Solo la propia web |
| Contenido factual citable | ⚠️ Las métricas son afirmaciones de marketing no verificables |

**Problema principal:** el contenido de la página está renderizado por JavaScript (fases/phases). Googlebot y AI crawlers ejecutan JS pero con limitaciones. Las secciones de features, pricing y resultados podrían no indexarse correctamente.

---

## 7. Imágenes & Assets — 45/100

| Problema | Detalle |
|----------|---------|
| OG Image inadecuada | `Logo_the_nucleo_circulo.png` es un logo circular — en Twitter/LinkedIn aparecerá mal (necesita 1200×630px landscape) |
| Twitter Card image | Mismo problema |
| Logo PNG 147KB | Debería ser SVG inline o WebP |
| 12 icons como PNG | Deberían ser SVG o WebP |
| Sin alt text en assets JS | Los iconos de integraciones cargados por JS no tienen alt text accesible |
| Video autoplay sin poster | El `<video>` no tiene atributo `poster` — pantalla en negro mientras carga |
| Sin `<img>` para logo en nav | El logo se renderiza como SVG inline ✅ (bien para SVG) pero el PNG de favicon es 147KB |

---

## Resumen de hallazgos adicionales

### Legales (bloqueante para ir a producción)
- ❌ **Sin política de privacidad** — ilegal bajo RGPD/LOPD en España si procesas datos de usuarios
- ❌ **Sin aviso legal** — obligatorio para sitios comerciales en España
- ❌ **Sin cookies banner** — si usas analytics o algún tracking, es obligatorio
- ❌ **Stripe en TEST mode** — los 3 CTAs de compra están rotos en producción

### Arquitectura de página única
- Toda la web es una sola página JS con fases. Esto significa:
  - Solo una URL indexable
  - Sin posibilidad de posicionar por múltiples keywords
  - Sin blog ni contenido auxiliar
  - Sin deep-linking funcional
