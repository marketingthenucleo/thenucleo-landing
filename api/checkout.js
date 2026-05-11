const SUPABASE_URL = process.env.SUPABASE_URL || "https://cbixhqjsnpuhcrcjppah.supabase.co";
const SERVICE_ROLE = process.env.SUPABASE_SERVICE_ROLE_KEY || "";
const STRIPE_KEY = process.env.STRIPE_SECRET_KEY || "";
const ORIGIN = process.env.PUBLIC_ORIGIN || "https://work.thenucleo.com";

const PERIODOS = new Set(["mensual", "trimestral", "anual"]);

async function readJsonBody(req) {
  if (req.body && typeof req.body === "object") return req.body;
  if (typeof req.body === "string" && req.body.length) {
    try { return JSON.parse(req.body); } catch (_) {}
  }
  return await new Promise((resolve) => {
    let chunks = "";
    req.on("data", (c) => { chunks += c; });
    req.on("end", () => {
      if (!chunks) return resolve({});
      try { resolve(JSON.parse(chunks)); } catch (_) { resolve({}); }
    });
    req.on("error", () => resolve({}));
  });
}

function jsonError(res, code, msg) {
  res.statusCode = code;
  return res.end(JSON.stringify({ error: msg }));
}

async function fetchAddonsBySlug(slugs) {
  if (!slugs.length) return [];
  const inFilter = "(" + slugs.map((s) => '"' + s.replace(/"/g, '\\"') + '"').join(",") + ")";
  const url =
    SUPABASE_URL +
    "/rest/v1/bub_addons_catalogo" +
    "?select=slug,nombre,categoria,precio_eur,stripe_price_id,activo" +
    "&slug=in." + encodeURIComponent(inFilter) +
    "&activo=eq.true";
  const r = await fetch(url, {
    headers: {
      apikey: SERVICE_ROLE,
      Authorization: "Bearer " + SERVICE_ROLE,
    },
  });
  if (!r.ok) throw new Error("supabase fetch failed: " + r.status);
  return await r.json();
}

async function fetchTarifa(bubble_id) {
  const filter = bubble_id
    ? "&bubble_id=eq." + encodeURIComponent(bubble_id)
    : "&limit=1";
  const url =
    SUPABASE_URL +
    "/rest/v1/v_tarifas_catalogo_publico" +
    "?select=*" + filter;
  const r = await fetch(url, {
    headers: {
      apikey: SERVICE_ROLE,
      Authorization: "Bearer " + SERVICE_ROLE,
    },
  });
  if (!r.ok) throw new Error("supabase tarifas fetch failed: " + r.status);
  const rows = await r.json();
  return rows[0] || null;
}

function resolveTarifaPrice(tarifa, periodo) {
  if (!tarifa || !periodo) return null;
  const priceField = "stripe_price_id_" + periodo;
  const eurField = "precio_" + periodo;
  const stripe_price_id = tarifa[priceField];
  if (!stripe_price_id) return null;
  return {
    stripe_price_id,
    precio_eur: Number(tarifa[eurField] || 0),
    nombre: tarifa.nombre,
    bubble_id: tarifa.bubble_id,
    tipo: tarifa.tipo,
    periodo,
  };
}

async function validateCouponServer(codigo) {
  if (!codigo) return null;
  const url =
    SUPABASE_URL +
    "/rest/v1/bub_addons_codigos_descuento" +
    "?select=codigo,descuento_porcentaje,validez_fin,usos_max,usos_actuales,activo,addon_slugs_aplicables,stripe_coupon_id" +
    "&codigo=ilike." + encodeURIComponent(codigo) +
    "&limit=1";
  const r = await fetch(url, {
    headers: {
      apikey: SERVICE_ROLE,
      Authorization: "Bearer " + SERVICE_ROLE,
    },
  });
  if (!r.ok) return null;
  const rows = await r.json();
  const row = rows[0];
  if (!row || row.activo === false) return null;
  if (row.validez_fin && row.validez_fin < new Date().toISOString().slice(0, 10)) return null;
  const usos_max = Number(row.usos_max || 0);
  const usos_actuales = Number(row.usos_actuales || 0);
  if (usos_max > 0 && usos_actuales >= usos_max) return null;
  return {
    codigo: row.codigo,
    descuento_porcentaje: Number(row.descuento_porcentaje || 0),
    stripe_coupon_id: row.stripe_coupon_id || null,
  };
}

async function createStripeSession(params) {
  const body = new URLSearchParams();
  body.set("mode", "subscription");
  body.set("success_url", ORIGIN + "/onboarding/ok/?sid={CHECKOUT_SESSION_ID}");
  body.set("cancel_url", ORIGIN + "/onboarding/?cancelled=1");
  body.set("customer_email", params.email);
  body.set("metadata[flow]", "onboarding");
  body.set("metadata[agencia_nombre]", params.agencia_nombre);
  body.set("metadata[tarifa_bubble_id]", params.tarifa.bubble_id || "");
  body.set("metadata[tarifa_tipo]", params.tarifa.tipo || "");
  body.set("metadata[tarifa_periodo]", params.tarifa.periodo);
  body.set("metadata[addon_slugs]", params.addon_slugs.join(","));
  if (params.codigo_descuento) body.set("metadata[codigo_descuento]", params.codigo_descuento);

  body.set("subscription_data[metadata][agencia_nombre]", params.agencia_nombre);
  body.set("subscription_data[metadata][tarifa_bubble_id]", params.tarifa.bubble_id || "");
  body.set("subscription_data[metadata][tarifa_periodo]", params.tarifa.periodo);

  body.set("line_items[0][price]", params.tarifa.stripe_price_id);
  body.set("line_items[0][quantity]", "1");

  params.addon_prices.forEach((price, idx) => {
    body.set("line_items[" + (idx + 1) + "][price]", price);
    body.set("line_items[" + (idx + 1) + "][quantity]", "1");
  });

  if (params.stripe_coupon_id) {
    body.set("discounts[0][coupon]", params.stripe_coupon_id);
  } else {
    body.set("allow_promotion_codes", "true");
  }

  const r = await fetch("https://api.stripe.com/v1/checkout/sessions", {
    method: "POST",
    headers: {
      Authorization: "Bearer " + STRIPE_KEY,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: body.toString(),
  });
  const json = await r.json();
  if (!r.ok) {
    const err = (json && json.error && json.error.message) || "Stripe error";
    throw new Error(err);
  }
  return json;
}

module.exports = async (req, res) => {
  res.setHeader("Cache-Control", "no-store");
  res.setHeader("Content-Type", "application/json; charset=utf-8");

  if (req.method !== "POST") return jsonError(res, 405, "Método no permitido");
  if (!SERVICE_ROLE) return jsonError(res, 500, "Configuración del servidor incompleta (Supabase)");
  if (!STRIPE_KEY) return jsonError(res, 503, "Pasarela de pago no configurada (STRIPE_SECRET_KEY ausente)");

  const body = await readJsonBody(req);
  const email = (body.email || "").toString().trim();
  const agencia_nombre = (body.agencia_nombre || "").toString().trim();
  const slugs = Array.isArray(body.addon_slugs) ? body.addon_slugs.map((s) => String(s).toLowerCase()) : [];
  const tarifa_periodo = (body.tarifa_periodo || "").toString().toLowerCase();
  const tarifa_bubble_id = (body.tarifa_bubble_id || "").toString().trim() || null;
  const codigo_descuento = (body.codigo_descuento || "").toString().trim() || null;

  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return jsonError(res, 400, "Email inválido");
  if (agencia_nombre.length < 2) return jsonError(res, 400, "Nombre de agencia inválido");
  if (!PERIODOS.has(tarifa_periodo)) return jsonError(res, 400, "Periodo de tarifa inválido");

  let tarifaRow;
  try {
    tarifaRow = await fetchTarifa(tarifa_bubble_id);
  } catch (_) {
    return jsonError(res, 502, "No se ha podido cargar la tarifa");
  }
  if (!tarifaRow) return jsonError(res, 404, "Tarifa no encontrada");

  const tarifa = resolveTarifaPrice(tarifaRow, tarifa_periodo);
  if (!tarifa) return jsonError(res, 503, "La tarifa no tiene precio configurado para " + tarifa_periodo);

  let addons = [];
  if (slugs.length) {
    try {
      addons = await fetchAddonsBySlug(slugs);
    } catch (_) {
      return jsonError(res, 502, "No se ha podido cargar el catálogo");
    }
  }

  const paid = addons.filter((a) => Number(a.precio_eur || 0) > 0);
  const missingPriceIds = paid.filter((a) => !a.stripe_price_id);
  if (missingPriceIds.length > 0) {
    return jsonError(
      res,
      503,
      "Estos addons aún no están disponibles para compra: " + missingPriceIds.map((a) => a.nombre).join(", "),
    );
  }

  let coupon = null;
  if (codigo_descuento) {
    coupon = await validateCouponServer(codigo_descuento);
    if (coupon && !coupon.stripe_coupon_id) {
      return jsonError(res, 503, "El código existe pero aún no está sincronizado con Stripe. Inténtalo en unos minutos.");
    }
  }

  let session;
  try {
    session = await createStripeSession({
      email,
      agencia_nombre,
      tarifa,
      addon_slugs: paid.map((a) => a.slug),
      addon_prices: paid.map((a) => a.stripe_price_id),
      codigo_descuento: coupon ? coupon.codigo : null,
      stripe_coupon_id: coupon ? coupon.stripe_coupon_id : null,
    });
  } catch (e) {
    return jsonError(res, 502, e.message || "No se ha podido crear la sesión de pago");
  }

  return res.end(JSON.stringify({ url: session.url, session_id: session.id }));
};
