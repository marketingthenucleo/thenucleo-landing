/* Onboarding — selección + carrito + checkout
   Patrón: 1 selección por categoría (radio), Stack TheNucleo (precio_eur=0)
   preseleccionado por defecto. Total recalculado en cliente. localStorage
   anónimo persiste entre recargas hasta confirmar el pago.
*/

const STORAGE_KEY = "tn_onboarding_selection_v1";
const COUPON_ENDPOINT = "/api/validate-coupon";
const CHECKOUT_ENDPOINT = "/api/checkout";

const state = {
  selectionBySlug: {},   // { slug -> { categoria, precio_eur, nombre } }
  tarifa: null,          // { periodo, precio_eur, nombre, stripe_price_id, bubble_id, tipo } o null
  coupon: null,          // { codigo, descuento_pct, mensaje? } o null
};

function readStorage() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch (_) {
    return null;
  }
}

function writeStorage() {
  try {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({
        slugs: Object.keys(state.selectionBySlug),
        tarifa_periodo: state.tarifa ? state.tarifa.periodo : null,
        coupon: state.coupon,
        ts: Date.now(),
      }),
    );
  } catch (_) {}
}

function eur(n) {
  if (!n || n === 0) return "0 €";
  return Number(n).toLocaleString("es-ES") + " €";
}

function getCategoriaSelection(categoria) {
  return Object.values(state.selectionBySlug).find(
    (a) => a.categoria === categoria,
  );
}

function selectAddon(card) {
  if (card.dataset.comprable === "false") return;

  const slug = card.dataset.slug;
  const categoria = card.dataset.categoria;
  const precio_eur = Number(card.dataset.precio || 0);
  const nombre = card.dataset.nombre || slug;

  const previous = getCategoriaSelection(categoria);
  if (previous && previous.slug === slug) return;
  if (previous) delete state.selectionBySlug[previous.slug];

  state.selectionBySlug[slug] = { slug, categoria, precio_eur, nombre };
  paintSelection();
  recalcTotals();
  writeStorage();
}

function selectTarifa(card, silent) {
  const section = document.querySelector(".onboarding-plan-section");
  if (!section || !card) return;

  state.tarifa = {
    periodo: card.dataset.periodo,
    precio_eur: Number(card.dataset.precio || 0),
    nombre: card.dataset.nombre || section.dataset.tarifaNombre || "",
    stripe_price_id: card.dataset.stripePriceId || null,
    bubble_id: section.dataset.tarifaBubbleId || null,
    tipo: section.dataset.tarifaTipo || null,
  };

  paintSelection();
  if (!silent) {
    recalcTotals();
    writeStorage();
  }
}

function paintSelection() {
  document.querySelectorAll(".addon-card").forEach((c) => {
    const isTarifa = c.classList.contains("tarifa-card");
    let selected;
    if (isTarifa) {
      selected = !!(state.tarifa && state.tarifa.periodo === c.dataset.periodo);
    } else {
      selected = !!state.selectionBySlug[c.dataset.slug];
    }
    c.classList.toggle("is-selected", selected);
    c.setAttribute("aria-checked", selected ? "true" : "false");
    const inp = c.querySelector('input[type="radio"]');
    if (inp) inp.checked = selected;
  });
}

function calcTotals() {
  const items = Object.values(state.selectionBySlug);
  const paidItems = items.filter((i) => i.precio_eur > 0);
  const addonsSubtotal = paidItems.reduce((s, i) => s + i.precio_eur, 0);
  const tarifaPrecio = state.tarifa ? Number(state.tarifa.precio_eur || 0) : 0;
  const subtotal = addonsSubtotal + tarifaPrecio;
  let descuento = 0;
  if (state.coupon && state.coupon.descuento_pct && subtotal > 0) {
    descuento = Math.round((subtotal * state.coupon.descuento_pct) / 100);
  }
  const total = Math.max(0, subtotal - descuento);
  return { items, paidItems, addonsSubtotal, tarifaPrecio, subtotal, descuento, total };
}

function recalcTotals() {
  const t = calcTotals();
  const cartCount = document.getElementById("cart-count");
  const cartTotal = document.getElementById("cart-total");
  const cartCta = document.getElementById("cart-cta");

  if (cartCount) {
    const tarifaLabel = state.tarifa
      ? state.tarifa.nombre + " · "
      : "Sin plan · ";
    const n = t.items.length;
    cartCount.textContent =
      tarifaLabel + n + " " + (n === 1 ? "addon" : "addons");
  }
  if (cartTotal) {
    if (t.total === 0) {
      cartTotal.innerHTML = '<span class="free">Gratis</span>';
    } else {
      cartTotal.textContent = eur(t.total);
    }
  }
  if (cartCta) {
    cartCta.disabled = !state.tarifa;
    cartCta.textContent = !state.tarifa
      ? "Selecciona un plan"
      : (t.total === 0 ? "Empezar gratis →" : "Continuar al pago →");
  }
}

function preselectTarifa(storedPeriodo) {
  const section = document.querySelector(".onboarding-plan-section");
  if (!section) return;
  const cards = section.querySelectorAll(".tarifa-card");
  if (!cards.length) return;

  const qs = new URLSearchParams(location.search);
  const wanted = (qs.get("periodo") || storedPeriodo || "").toLowerCase();
  let target = wanted
    ? section.querySelector('.tarifa-card[data-periodo="' + CSS.escape(wanted) + '"]')
    : null;
  if (!target) target = cards[0];
  selectTarifa(target, true);
}

function preselectStackDefault() {
  const stored = readStorage();
  const validSlugs = new Set(
    Array.from(document.querySelectorAll(".addon-card:not(.tarifa-card)")).map((c) => c.dataset.slug),
  );

  if (stored && Array.isArray(stored.slugs) && stored.slugs.length) {
    stored.slugs.forEach((slug) => {
      if (!validSlugs.has(slug)) return;
      const card = document.querySelector('.addon-card:not(.tarifa-card)[data-slug="' + CSS.escape(slug) + '"]');
      if (card && card.dataset.comprable !== "false") {
        state.selectionBySlug[slug] = {
          slug,
          categoria: card.dataset.categoria,
          precio_eur: Number(card.dataset.precio || 0),
          nombre: card.dataset.nombre || slug,
        };
      }
    });
    if (stored.coupon) state.coupon = stored.coupon;
  } else {
    // Stack default: el primer card con data-incluido en cada categoría
    document.querySelectorAll(".onboarding-category:not(.onboarding-plan-section)").forEach((cat) => {
      const incluido = cat.querySelector('.addon-card[data-incluido="true"]');
      if (incluido) {
        state.selectionBySlug[incluido.dataset.slug] = {
          slug: incluido.dataset.slug,
          categoria: incluido.dataset.categoria,
          precio_eur: 0,
          nombre: incluido.dataset.nombre || incluido.dataset.slug,
        };
      }
    });
  }

  preselectTarifa(stored ? stored.tarifa_periodo : null);

  paintSelection();
  recalcTotals();
}

/* ── Modal de pago ──────────────────────────────────── */

function openModal() {
  const modal = document.getElementById("onb-modal");
  if (!modal) return;
  refreshModalSummary();
  modal.classList.add("is-open");
  document.body.style.overflow = "hidden";
  setTimeout(() => {
    const emailInp = document.getElementById("onb-email");
    if (emailInp) emailInp.focus();
  }, 100);
}

function closeModal() {
  const modal = document.getElementById("onb-modal");
  if (!modal) return;
  modal.classList.remove("is-open");
  document.body.style.overflow = "";
}

function refreshModalSummary() {
  const t = calcTotals();
  const list = document.getElementById("onb-summary-list");
  if (list) {
    list.innerHTML = "";
    if (state.tarifa) {
      const row = document.createElement("div");
      row.className = "onboarding-modal-summary-row plan";
      row.innerHTML =
        "<span>" + state.tarifa.nombre + "</span><span>" +
        eur(state.tarifa.precio_eur) + "</span>";
      list.appendChild(row);
    }
    t.items.forEach((i) => {
      const row = document.createElement("div");
      row.className = "onboarding-modal-summary-row";
      row.innerHTML =
        "<span>" + i.nombre + "</span><span class=\"" +
        (i.precio_eur === 0 ? "muted" : "") + "\">" +
        (i.precio_eur === 0 ? "Incluido" : eur(i.precio_eur)) + "</span>";
      list.appendChild(row);
    });
    if (t.descuento > 0) {
      const row = document.createElement("div");
      row.className = "onboarding-modal-summary-row";
      row.innerHTML =
        '<span class="discount">Descuento (' + state.coupon.codigo + ')</span>' +
        '<span class="discount">−' + eur(t.descuento) + '</span>';
      list.appendChild(row);
    }
    const totalRow = document.createElement("div");
    totalRow.className = "onboarding-modal-summary-row total";
    totalRow.innerHTML =
      "<span>Total</span><span>" + (t.total === 0 ? "Gratis" : eur(t.total)) + "</span>";
    list.appendChild(totalRow);
  }
  const submitBtn = document.getElementById("onb-submit");
  if (submitBtn) {
    submitBtn.textContent = t.total === 0 ? "Confirmar y empezar" : "Pagar " + eur(t.total);
  }
}

async function applyCoupon() {
  const inp = document.getElementById("onb-coupon-input");
  const fb = document.getElementById("onb-coupon-feedback");
  if (!inp || !fb) return;
  const codigo = (inp.value || "").trim();
  fb.className = "coupon-feedback";
  fb.textContent = "";

  if (!codigo) {
    state.coupon = null;
    refreshModalSummary();
    writeStorage();
    return;
  }

  fb.textContent = "Validando…";
  fb.className = "coupon-feedback";

  const slugs = Object.keys(state.selectionBySlug);

  try {
    const res = await fetch(COUPON_ENDPOINT, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ codigo, addon_slugs: slugs }),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok || !data.valido) {
      state.coupon = null;
      fb.textContent = data.mensaje_error || "Código no válido";
      fb.className = "coupon-feedback error";
      refreshModalSummary();
      writeStorage();
      return;
    }
    state.coupon = {
      codigo,
      descuento_pct: data.descuento_porcentaje || 0,
      stripe_coupon_id: data.stripe_coupon_id || null,
    };
    fb.textContent = "Aplicado: −" + (state.coupon.descuento_pct) + "%";
    fb.className = "coupon-feedback ok";
    refreshModalSummary();
    recalcTotals();
    writeStorage();
  } catch (e) {
    fb.textContent = "No se ha podido validar el código";
    fb.className = "coupon-feedback error";
  }
}

function validateField(id, predicate, msg) {
  const wrap = document.getElementById(id + "-wrap");
  const inp = document.getElementById(id);
  const err = document.getElementById(id + "-error");
  if (!wrap || !inp) return true;
  const ok = predicate(inp.value);
  if (!ok) {
    wrap.classList.add("has-error");
    if (err) err.textContent = msg;
  } else {
    wrap.classList.remove("has-error");
  }
  return ok;
}

async function submitCheckout(ev) {
  ev.preventDefault();
  const okEmail = validateField(
    "onb-email",
    (v) => /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test((v || "").trim()),
    "Introduce un email válido",
  );
  const okAgencia = validateField(
    "onb-agencia",
    (v) => (v || "").trim().length >= 2,
    "Introduce el nombre de tu agencia",
  );
  if (!okEmail || !okAgencia) return;

  if (!state.tarifa) {
    alert("Selecciona un plan antes de continuar.");
    return;
  }

  const email = document.getElementById("onb-email").value.trim();
  const agencia = document.getElementById("onb-agencia").value.trim();
  const slugs = Object.keys(state.selectionBySlug);
  const t = calcTotals();
  const submitBtn = document.getElementById("onb-submit");
  if (submitBtn) submitBtn.disabled = true;

  try {
    const res = await fetch(CHECKOUT_ENDPOINT, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email,
        agencia_nombre: agencia,
        addon_slugs: slugs,
        tarifa_periodo: state.tarifa.periodo,
        tarifa_bubble_id: state.tarifa.bubble_id,
        codigo_descuento: state.coupon ? state.coupon.codigo : null,
      }),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      alert(data.error || "No se ha podido iniciar el checkout. Inténtalo de nuevo.");
      if (submitBtn) submitBtn.disabled = false;
      return;
    }
    if (data.url) {
      window.location.href = data.url;
      return;
    }
    if (data.gratis) {
      window.location.href = "/onboarding/ok/?free=1&email=" + encodeURIComponent(email);
      return;
    }
    alert("Respuesta inesperada del servidor.");
    if (submitBtn) submitBtn.disabled = false;
  } catch (e) {
    alert("Error de conexión. Inténtalo de nuevo.");
    if (submitBtn) submitBtn.disabled = false;
  }
}

/* ── Init ───────────────────────────────────────────── */

document.addEventListener("DOMContentLoaded", function () {
  preselectStackDefault();

  document.querySelectorAll(".addon-card:not(.tarifa-card)").forEach((card) => {
    card.addEventListener("click", function () {
      selectAddon(card);
    });
    card.addEventListener("keydown", function (e) {
      if (e.key === " " || e.key === "Enter") {
        e.preventDefault();
        selectAddon(card);
      }
    });
  });

  document.querySelectorAll(".tarifa-card").forEach((card) => {
    card.addEventListener("click", function () {
      selectTarifa(card);
    });
    card.addEventListener("keydown", function (e) {
      if (e.key === " " || e.key === "Enter") {
        e.preventDefault();
        selectTarifa(card);
      }
    });
  });

  const cta = document.getElementById("cart-cta");
  if (cta) cta.addEventListener("click", openModal);

  const modalClose = document.getElementById("onb-modal-close");
  if (modalClose) modalClose.addEventListener("click", closeModal);

  const modalOverlay = document.getElementById("onb-modal");
  if (modalOverlay) {
    modalOverlay.addEventListener("click", function (e) {
      if (e.target === modalOverlay) closeModal();
    });
  }
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") closeModal();
  });

  const couponBtn = document.getElementById("onb-coupon-btn");
  if (couponBtn) couponBtn.addEventListener("click", applyCoupon);
  const couponInp = document.getElementById("onb-coupon-input");
  if (couponInp) {
    couponInp.addEventListener("keydown", function (e) {
      if (e.key === "Enter") {
        e.preventDefault();
        applyCoupon();
      }
    });
  }

  const form = document.getElementById("onb-form");
  if (form) form.addEventListener("submit", submitCheckout);
});
