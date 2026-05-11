const SUPABASE_URL = process.env.SUPABASE_URL || "https://cbixhqjsnpuhcrcjppah.supabase.co";
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || "";

const PERIODO_LABELS = {
  mensual: "Mensual",
  trimestral: "Trimestral",
  anual: "Anual",
};

const PERIODO_SUFFIX = {
  mensual: "/mes",
  trimestral: "/trimestre",
  anual: "/año",
};

const PERIODO_ORDER = ["mensual", "trimestral", "anual"];

const PRECIO_FIELD = {
  mensual: "precio_mensual",
  trimestral: "precio_trimestral",
  anual: "precio_anual",
};

function buildPeriodo(periodo, precio, stripe_price_id) {
  if (!precio || !stripe_price_id) return null;
  const eur = Number(precio);
  return {
    periodo,
    label: PERIODO_LABELS[periodo],
    precio_eur: eur,
    precio_label: eur.toLocaleString("es-ES") + " €" + PERIODO_SUFFIX[periodo],
    stripe_price_id,
  };
}

module.exports = async () => {
  const empty = { items: [], default: null, byPeriodo: {}, fetchedAt: null };

  if (!SUPABASE_ANON_KEY) {
    console.warn("[_data/tarifas] SUPABASE_ANON_KEY missing → empty");
    return empty;
  }

  const url =
    SUPABASE_URL +
    "/rest/v1/v_tarifas_catalogo_publico" +
    "?select=*&order=nombre.asc";

  try {
    const res = await fetch(url, {
      headers: {
        apikey: SUPABASE_ANON_KEY,
        Authorization: "Bearer " + SUPABASE_ANON_KEY,
      },
    });
    if (!res.ok) {
      console.error("[_data/tarifas] fetch failed", res.status, await res.text());
      return empty;
    }
    const rows = await res.json();

    const items = rows.map((r) => {
      const periodos = PERIODO_ORDER
        .map((p) => buildPeriodo(p, r[PRECIO_FIELD[p]], r["stripe_price_id_" + p]))
        .filter(Boolean);
      return {
        bubble_id: r.bubble_id,
        tipo: r.tipo,
        nombre: r.nombre,
        descripcion: r.descripcion || "",
        periodos,
        byPeriodo: Object.fromEntries(periodos.map((p) => [p.periodo, p])),
      };
    });

    const def = items.length ? items[0] : null;

    console.log("[_data/tarifas] loaded", items.length, "tarifas");
    return {
      items,
      default: def,
      byPeriodo: def ? def.byPeriodo : {},
      fetchedAt: new Date().toISOString(),
    };
  } catch (err) {
    console.error("[_data/tarifas] fetch error", err);
    return empty;
  }
};
