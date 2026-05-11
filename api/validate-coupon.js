const SUPABASE_URL = process.env.SUPABASE_URL || "https://cbixhqjsnpuhcrcjppah.supabase.co";
const SERVICE_ROLE = process.env.SUPABASE_SERVICE_ROLE_KEY || "";

function parseSlugList(raw) {
  if (!raw) return [];
  if (Array.isArray(raw)) return raw.filter(Boolean).map((s) => String(s).trim().toLowerCase());
  const s = String(raw).trim();
  if (!s) return [];
  if (s.startsWith("[")) {
    try {
      const arr = JSON.parse(s);
      if (Array.isArray(arr)) return arr.map((x) => String(x).trim().toLowerCase()).filter(Boolean);
    } catch (_) {}
  }
  return s.split(/[,;\n]+/).map((x) => x.trim().toLowerCase()).filter(Boolean);
}

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

module.exports = async (req, res) => {
  res.setHeader("Cache-Control", "no-store");
  res.setHeader("Content-Type", "application/json; charset=utf-8");

  if (req.method !== "POST") {
    res.statusCode = 405;
    return res.end(JSON.stringify({ valido: false, mensaje_error: "Método no permitido" }));
  }
  if (!SERVICE_ROLE) {
    res.statusCode = 500;
    return res.end(JSON.stringify({ valido: false, mensaje_error: "Configuración del servidor incompleta" }));
  }

  const body = await readJsonBody(req);
  const codigo = (body.codigo || "").toString().trim();
  const addon_slugs = Array.isArray(body.addon_slugs) ? body.addon_slugs.map((s) => String(s).toLowerCase()) : [];

  if (!codigo) {
    res.statusCode = 400;
    return res.end(JSON.stringify({ valido: false, mensaje_error: "Falta el código" }));
  }

  const url =
    SUPABASE_URL +
    "/rest/v1/bub_addons_codigos_descuento" +
    "?select=codigo,descuento_porcentaje,validez_fin,usos_max,usos_actuales,activo,addon_slugs_aplicables,categorias_aplicables,stripe_coupon_id" +
    "&codigo=ilike." + encodeURIComponent(codigo) +
    "&limit=1";

  let row;
  try {
    const r = await fetch(url, {
      headers: {
        apikey: SERVICE_ROLE,
        Authorization: "Bearer " + SERVICE_ROLE,
      },
    });
    if (!r.ok) {
      res.statusCode = 502;
      return res.end(JSON.stringify({ valido: false, mensaje_error: "No se ha podido consultar el código" }));
    }
    const rows = await r.json();
    row = rows && rows[0];
  } catch (_) {
    res.statusCode = 502;
    return res.end(JSON.stringify({ valido: false, mensaje_error: "Error de conexión" }));
  }

  if (!row) {
    return res.end(JSON.stringify({ valido: false, mensaje_error: "Código no encontrado" }));
  }
  if (row.activo === false) {
    return res.end(JSON.stringify({ valido: false, mensaje_error: "Código desactivado" }));
  }
  if (row.validez_fin) {
    const today = new Date().toISOString().slice(0, 10);
    if (row.validez_fin < today) {
      return res.end(JSON.stringify({ valido: false, mensaje_error: "Código caducado" }));
    }
  }
  const usos_max = Number(row.usos_max || 0);
  const usos_actuales = Number(row.usos_actuales || 0);
  if (usos_max > 0 && usos_actuales >= usos_max) {
    return res.end(JSON.stringify({ valido: false, mensaje_error: "Código sin usos disponibles" }));
  }

  const slugsAplicables = parseSlugList(row.addon_slugs_aplicables);
  const categoriasAplicables = parseSlugList(row.categorias_aplicables);

  if (slugsAplicables.length > 0 && addon_slugs.length > 0) {
    const intersect = addon_slugs.some((s) => slugsAplicables.includes(s));
    if (!intersect) {
      return res.end(JSON.stringify({ valido: false, mensaje_error: "El código no aplica a los addons seleccionados" }));
    }
  }
  // Nota: validación por categoría se haría tras leer catálogo. Por ahora delegada al checkout server-side.

  return res.end(JSON.stringify({
    valido: true,
    codigo: row.codigo,
    descuento_porcentaje: Number(row.descuento_porcentaje || 0),
    stripe_coupon_id: row.stripe_coupon_id || null,
    addon_slugs_aplicables: slugsAplicables,
    categorias_aplicables: categoriasAplicables,
  }));
};
