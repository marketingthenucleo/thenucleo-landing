/*!
 * TheNucleo — Cookie consent banner
 * RGPD / LSSI-CE / Guía AEPD 2023
 *
 * Categorías:
 *   - necessary  (siempre activas)
 *   - analytics  (Google Analytics, Search Console, etc.)
 *   - marketing  (Google Ads, Meta Pixel, remarketing, etc.)
 *
 * Para activar scripts solo si hay consentimiento, márcalos así:
 *   <script type="text/plain" data-cookie-category="analytics" src="..."></script>
 *
 * API pública:
 *   window.TNConsent.open()    — abre el panel de configuración
 *   window.TNConsent.reset()   — borra el consentimiento y vuelve a pedirlo
 *   window.TNConsent.get()     — devuelve el estado actual
 */
(function () {
  'use strict';

  var STORAGE_KEY = 'tn_consent_v1';
  var CONSENT_VERSION = 1;
  var RENEWAL_DAYS = 395; // ~13 meses, recomendación AEPD

  var DEFAULT_DENIED = { necessary: true, analytics: false, marketing: false };

  // ─────────────────────────────────────────────────────────────
  // Google Consent Mode v2 — defaults denegados antes de todo
  // ─────────────────────────────────────────────────────────────
  window.dataLayer = window.dataLayer || [];
  function gtag() { window.dataLayer.push(arguments); }
  gtag('consent', 'default', {
    ad_storage: 'denied',
    ad_user_data: 'denied',
    ad_personalization: 'denied',
    analytics_storage: 'denied',
    functionality_storage: 'granted',
    security_storage: 'granted',
    wait_for_update: 500
  });

  // ─────────────────────────────────────────────────────────────
  // Storage
  // ─────────────────────────────────────────────────────────────
  function loadConsent() {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return null;
      var s = JSON.parse(raw);
      if (s.version !== CONSENT_VERSION) return null;
      var ageDays = (Date.now() - s.timestamp) / 86400000;
      if (ageDays > RENEWAL_DAYS) return null;
      return s;
    } catch (e) { return null; }
  }

  function saveConsent(state) {
    var record = {
      version: CONSENT_VERSION,
      timestamp: Date.now(),
      necessary: true,
      analytics: !!state.analytics,
      marketing: !!state.marketing
    };
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(record)); } catch (e) {}
    return record;
  }

  // ─────────────────────────────────────────────────────────────
  // Aplicar consentimiento (Consent Mode + activar scripts pendientes)
  // ─────────────────────────────────────────────────────────────
  function applyConsent(state) {
    gtag('consent', 'update', {
      analytics_storage: state.analytics ? 'granted' : 'denied',
      ad_storage: state.marketing ? 'granted' : 'denied',
      ad_user_data: state.marketing ? 'granted' : 'denied',
      ad_personalization: state.marketing ? 'granted' : 'denied'
    });

    var pending = document.querySelectorAll('script[type="text/plain"][data-cookie-category]');
    pending.forEach(function (el) {
      var cat = el.getAttribute('data-cookie-category');
      if (!state[cat]) return;
      var s = document.createElement('script');
      for (var i = 0; i < el.attributes.length; i++) {
        var a = el.attributes[i];
        if (a.name === 'type' || a.name === 'data-cookie-category') continue;
        s.setAttribute(a.name, a.value);
      }
      s.text = el.text;
      el.parentNode.replaceChild(s, el);
    });

    document.dispatchEvent(new CustomEvent('tn:consent', { detail: state }));
  }

  // ─────────────────────────────────────────────────────────────
  // CSS
  // ─────────────────────────────────────────────────────────────
  var CSS = [
    '.tn-c-root, .tn-c-root *, .tn-c-root *::before, .tn-c-root *::after { box-sizing: border-box; }',
    '.tn-c-root { --tn-bg:#171717; --tn-card:#1e1e1e; --tn-border:#2a2a2a; --tn-border-h:#3a3a3a; --tn-text:#E8EAE9; --tn-muted:#8a8a8a; --tn-accent:#C7B299; --tn-accent-dim:rgba(199,178,153,.12); font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif; color:var(--tn-text); }',
    '.tn-c-banner { position:fixed; left:16px; right:16px; bottom:16px; z-index:2147483646; max-width:560px; margin:0 auto; background:var(--tn-card); border:1px solid var(--tn-border); border-radius:14px; padding:20px 22px; box-shadow:0 24px 60px rgba(0,0,0,.55); }',
    '@media (min-width:640px){ .tn-c-banner{ left:24px; right:auto; bottom:24px; margin:0; } }',
    '.tn-c-banner h2 { font-size:15px; margin:0 0 6px; font-weight:600; color:#fff; letter-spacing:.01em; }',
    '.tn-c-banner p { font-size:13px; line-height:1.5; margin:0 0 14px; color:var(--tn-text); }',
    '.tn-c-banner p a { color:var(--tn-accent); text-decoration:underline; text-underline-offset:2px; }',
    '.tn-c-actions { display:flex; flex-wrap:wrap; gap:8px; }',
    '.tn-c-btn { font:inherit; font-size:13px; font-weight:500; padding:10px 14px; border-radius:8px; cursor:pointer; border:1px solid var(--tn-border); background:transparent; color:var(--tn-text); transition:background .15s, border-color .15s; flex:1 1 auto; min-width:120px; }',
    '.tn-c-btn:hover { background:rgba(255,255,255,.04); border-color:var(--tn-border-h); }',
    '.tn-c-btn:focus-visible { outline:2px solid var(--tn-accent); outline-offset:2px; }',
    '.tn-c-btn--primary { background:var(--tn-accent); color:#171717; border-color:var(--tn-accent); font-weight:600; }',
    '.tn-c-btn--primary:hover { background:#d8c4ad; border-color:#d8c4ad; }',
    '.tn-c-btn--reject { background:var(--tn-accent); color:#171717; border-color:var(--tn-accent); font-weight:600; }',
    '.tn-c-btn--reject:hover { background:#d8c4ad; border-color:#d8c4ad; }',
    '.tn-c-btn--ghost { flex:0 0 auto; min-width:0; padding:10px 12px; color:var(--tn-muted); }',
    '.tn-c-btn--ghost:hover { color:var(--tn-text); }',
    '.tn-c-overlay { position:fixed; inset:0; z-index:2147483646; background:rgba(0,0,0,.6); display:flex; align-items:flex-end; justify-content:center; padding:0; opacity:0; pointer-events:none; transition:opacity .2s ease; }',
    '@media (min-width:640px){ .tn-c-overlay{ align-items:center; padding:24px; } }',
    '.tn-c-overlay.is-open { opacity:1; pointer-events:auto; }',
    '.tn-c-modal { width:100%; max-width:560px; max-height:90vh; overflow:auto; background:var(--tn-card); border:1px solid var(--tn-border); border-radius:14px 14px 0 0; padding:24px; transform:translateY(20px); transition:transform .25s ease; }',
    '@media (min-width:640px){ .tn-c-modal{ border-radius:14px; } }',
    '.tn-c-overlay.is-open .tn-c-modal { transform:translateY(0); }',
    '.tn-c-modal h2 { font-size:17px; font-weight:600; color:#fff; margin:0 0 6px; }',
    '.tn-c-modal > p { font-size:13px; line-height:1.5; color:var(--tn-muted); margin:0 0 18px; }',
    '.tn-c-modal > p a { color:var(--tn-accent); text-decoration:underline; }',
    '.tn-c-cat { border:1px solid var(--tn-border); border-radius:10px; padding:14px 16px; margin-bottom:10px; }',
    '.tn-c-cat-head { display:flex; justify-content:space-between; align-items:center; gap:12px; }',
    '.tn-c-cat h3 { font-size:14px; font-weight:600; color:#fff; margin:0; }',
    '.tn-c-cat p { font-size:12.5px; line-height:1.5; color:var(--tn-muted); margin:6px 0 0; }',
    '.tn-c-toggle { position:relative; width:42px; height:24px; flex-shrink:0; cursor:pointer; }',
    '.tn-c-toggle input { position:absolute; opacity:0; width:100%; height:100%; cursor:pointer; margin:0; }',
    '.tn-c-toggle .tn-c-track { position:absolute; inset:0; background:#3a3a3a; border-radius:999px; transition:background .15s; }',
    '.tn-c-toggle .tn-c-thumb { position:absolute; top:3px; left:3px; width:18px; height:18px; background:#fff; border-radius:50%; transition:transform .15s; }',
    '.tn-c-toggle input:checked ~ .tn-c-track { background:var(--tn-accent); }',
    '.tn-c-toggle input:checked ~ .tn-c-thumb { transform:translateX(18px); }',
    '.tn-c-toggle input:disabled ~ .tn-c-track { background:var(--tn-accent); opacity:.6; cursor:not-allowed; }',
    '.tn-c-toggle input:focus-visible ~ .tn-c-track { outline:2px solid var(--tn-accent); outline-offset:2px; }',
    '.tn-c-modal-actions { display:flex; flex-wrap:wrap; gap:8px; margin-top:18px; }',
    '.tn-c-modal-actions .tn-c-btn { flex:1 1 140px; }',
    '.tn-c-fab { position:fixed; left:14px; bottom:14px; z-index:2147483645; width:38px; height:38px; border-radius:50%; background:var(--tn-card); border:1px solid var(--tn-border); color:var(--tn-muted); cursor:pointer; display:flex; align-items:center; justify-content:center; padding:0; transition:color .15s, border-color .15s; }',
    '.tn-c-fab:hover { color:var(--tn-text); border-color:var(--tn-border-h); }',
    '.tn-c-fab:focus-visible { outline:2px solid var(--tn-accent); outline-offset:2px; }',
    '.tn-c-fab svg { width:18px; height:18px; }',
    '@media (prefers-reduced-motion: reduce){ .tn-c-overlay, .tn-c-modal, .tn-c-toggle .tn-c-track, .tn-c-toggle .tn-c-thumb { transition:none; } }'
  ].join('\n');

  function injectStyles() {
    var s = document.createElement('style');
    s.id = 'tn-consent-styles';
    s.textContent = CSS;
    document.head.appendChild(s);
  }

  // ─────────────────────────────────────────────────────────────
  // DOM
  // ─────────────────────────────────────────────────────────────
  var root, banner, overlay, modal;

  function ensureRoot() {
    if (root) return root;
    root = document.createElement('div');
    root.className = 'tn-c-root';
    root.setAttribute('lang', 'es');
    document.body.appendChild(root);
    return root;
  }

  function buildBanner() {
    if (banner) return;
    ensureRoot();
    banner = document.createElement('section');
    banner.className = 'tn-c-banner';
    banner.setAttribute('role', 'dialog');
    banner.setAttribute('aria-live', 'polite');
    banner.setAttribute('aria-label', 'Aviso de cookies');
    banner.innerHTML =
      '<h2>Cookies en TheNucleo</h2>' +
      '<p>Usamos cookies necesarias para que el sitio funcione y, con tu permiso, cookies de análisis y publicidad para mejorar la experiencia. Puedes aceptar todas, rechazarlas o configurarlas. Más información en nuestra <a href="/aviso-legal">Política de Cookies</a>.</p>' +
      '<div class="tn-c-actions">' +
        '<button type="button" class="tn-c-btn tn-c-btn--primary" data-action="accept">Aceptar todas</button>' +
        '<button type="button" class="tn-c-btn tn-c-btn--reject" data-action="reject">Rechazar todas</button>' +
        '<button type="button" class="tn-c-btn tn-c-btn--ghost" data-action="configure">Configurar</button>' +
      '</div>';
    root.appendChild(banner);

    banner.querySelector('[data-action="accept"]').addEventListener('click', acceptAll);
    banner.querySelector('[data-action="reject"]').addEventListener('click', rejectAll);
    banner.querySelector('[data-action="configure"]').addEventListener('click', openModal);
  }

  function hideBanner() {
    if (banner && banner.parentNode) banner.parentNode.removeChild(banner);
    banner = null;
  }

  function buildModal() {
    if (modal) return;
    ensureRoot();
    overlay = document.createElement('div');
    overlay.className = 'tn-c-overlay';
    overlay.setAttribute('role', 'dialog');
    overlay.setAttribute('aria-modal', 'true');
    overlay.setAttribute('aria-labelledby', 'tn-c-modal-title');

    overlay.innerHTML =
      '<div class="tn-c-modal" role="document">' +
        '<h2 id="tn-c-modal-title">Configurar cookies</h2>' +
        '<p>Elige qué tipos de cookies quieres permitir. Puedes cambiar tu elección en cualquier momento desde el botón inferior izquierdo. Detalles en la <a href="/aviso-legal">Política de Cookies</a>.</p>' +

        '<div class="tn-c-cat">' +
          '<div class="tn-c-cat-head">' +
            '<h3>Necesarias</h3>' +
            '<label class="tn-c-toggle"><input type="checkbox" checked disabled aria-label="Cookies necesarias (siempre activas)"><span class="tn-c-track"></span><span class="tn-c-thumb"></span></label>' +
          '</div>' +
          '<p>Imprescindibles para el funcionamiento del sitio (sesión, preferencias del propio banner). No requieren consentimiento.</p>' +
        '</div>' +

        '<div class="tn-c-cat">' +
          '<div class="tn-c-cat-head">' +
            '<h3>Análisis</h3>' +
            '<label class="tn-c-toggle"><input type="checkbox" data-cat="analytics" aria-label="Permitir cookies de análisis"><span class="tn-c-track"></span><span class="tn-c-thumb"></span></label>' +
          '</div>' +
          '<p>Nos ayudan a entender cómo se usa el sitio (páginas vistas, fuentes de tráfico) para mejorarlo. Ejemplo: Google Analytics.</p>' +
        '</div>' +

        '<div class="tn-c-cat">' +
          '<div class="tn-c-cat-head">' +
            '<h3>Publicidad</h3>' +
            '<label class="tn-c-toggle"><input type="checkbox" data-cat="marketing" aria-label="Permitir cookies de publicidad"><span class="tn-c-track"></span><span class="tn-c-thumb"></span></label>' +
          '</div>' +
          '<p>Permiten medir campañas y mostrar anuncios relevantes en otros sitios. Ejemplo: Google Ads, Meta Pixel.</p>' +
        '</div>' +

        '<div class="tn-c-modal-actions">' +
          '<button type="button" class="tn-c-btn tn-c-btn--primary" data-action="accept">Aceptar todas</button>' +
          '<button type="button" class="tn-c-btn tn-c-btn--reject" data-action="reject">Rechazar todas</button>' +
          '<button type="button" class="tn-c-btn" data-action="save">Guardar selección</button>' +
        '</div>' +
      '</div>';

    root.appendChild(overlay);
    modal = overlay.querySelector('.tn-c-modal');

    overlay.addEventListener('click', function (e) { if (e.target === overlay) closeModal(); });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && overlay.classList.contains('is-open')) closeModal();
    });
    overlay.querySelector('[data-action="accept"]').addEventListener('click', function () { acceptAll(); closeModal(); });
    overlay.querySelector('[data-action="reject"]').addEventListener('click', function () { rejectAll(); closeModal(); });
    overlay.querySelector('[data-action="save"]').addEventListener('click', function () {
      var checks = overlay.querySelectorAll('input[data-cat]');
      var state = { necessary: true };
      checks.forEach(function (c) { state[c.dataset.cat] = c.checked; });
      var saved = saveConsent(state);
      applyConsent(saved);
      hideBanner();
      closeModal();
    });
  }

  function syncModalToggles() {
    if (!overlay) return;
    var current = loadConsent() || DEFAULT_DENIED;
    overlay.querySelectorAll('input[data-cat]').forEach(function (c) {
      c.checked = !!current[c.dataset.cat];
    });
  }

  function openModal() {
    buildModal();
    syncModalToggles();
    overlay.classList.add('is-open');
    var first = overlay.querySelector('input[data-cat]');
    if (first) setTimeout(function () { first.focus(); }, 0);
  }

  function closeModal() {
    if (overlay) overlay.classList.remove('is-open');
  }

  function buildFab() {
    ensureRoot();
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'tn-c-fab';
    btn.setAttribute('aria-label', 'Configurar cookies');
    btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21.95 11.1a10 10 0 1 1-9.05-9.05 5.5 5.5 0 0 0 5.5 5.5 5.5 5.5 0 0 0 3.55 3.55Z"/><circle cx="9" cy="11.5" r="1"/><circle cx="14.5" cy="14.5" r="1"/><circle cx="9" cy="16.5" r="1"/></svg>';
    btn.addEventListener('click', openModal);
    root.appendChild(btn);
  }

  // ─────────────────────────────────────────────────────────────
  // Acciones rápidas
  // ─────────────────────────────────────────────────────────────
  function acceptAll() {
    var state = saveConsent({ analytics: true, marketing: true });
    applyConsent(state);
    hideBanner();
  }

  function rejectAll() {
    var state = saveConsent({ analytics: false, marketing: false });
    applyConsent(state);
    hideBanner();
  }

  // ─────────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────────
  function init() {
    injectStyles();
    var saved = loadConsent();
    if (saved) {
      applyConsent(saved);
    } else {
      buildBanner();
    }
    buildFab();

    window.TNConsent = {
      open: openModal,
      reset: function () {
        try { localStorage.removeItem(STORAGE_KEY); } catch (e) {}
        location.reload();
      },
      get: function () { return loadConsent(); }
    };

    // Permite que enlaces como <a href="#" data-tn-consent-open> abran el panel
    document.addEventListener('click', function (e) {
      var t = e.target.closest('[data-tn-consent-open]');
      if (!t) return;
      e.preventDefault();
      openModal();
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
