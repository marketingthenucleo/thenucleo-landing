const SUPABASE_URL = process.env.SUPABASE_URL || "https://cbixhqjsnpuhcrcjppah.supabase.co";
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || "";

const CATEGORIA_LABELS = {
  gestor_tareas: "Gestor de tareas",
  crm: "CRM",
  erp: "ERP / Facturación",
  reuniones: "Reuniones",
  storage: "Almacenamiento",
  time_tracking: "Time tracking",
};

const CATEGORIA_ORDER = ["gestor_tareas", "crm", "erp", "reuniones", "storage", "time_tracking"];

module.exports = async () => {
  const empty = { items: [], categorias: [], byCategoria: {}, total: 0, fetchedAt: null };

  if (!SUPABASE_ANON_KEY) {
    console.warn("[_data/addons] SUPABASE_ANON_KEY missing → empty catalog");
    return empty;
  }

  const url =
    SUPABASE_URL +
    "/rest/v1/v_addons_catalogo_publico" +
    "?select=*" +
    "&order=orden.asc.nullslast,nombre.asc";

  try {
    const res = await fetch(url, {
      headers: {
        apikey: SUPABASE_ANON_KEY,
        Authorization: "Bearer " + SUPABASE_ANON_KEY,
      },
    });
    if (!res.ok) {
      console.error("[_data/addons] fetch failed", res.status, await res.text());
      return empty;
    }
    const rows = await res.json();
    const items = rows.map((r) => {
      const precio_eur = Number(r.precio_eur || 0);
      const es_gratis = precio_eur === 0;
      const tiene_price = !!r.stripe_price_id;
      const es_comprable = es_gratis || tiene_price;
      let precio_label;
      if (es_gratis) precio_label = "Incluido";
      else if (tiene_price) precio_label = precio_eur.toLocaleString("es-ES") + " €";
      else precio_label = "Solicitar";
      return {
        slug: r.slug,
        nombre: r.nombre,
        categoria: r.categoria,
        categoriaLabel: CATEGORIA_LABELS[r.categoria] || r.categoria,
        precio_eur,
        precio_label,
        es_gratis,
        es_comprable,
        descripcion: r.descripcion || "",
        stripe_price_id: r.stripe_price_id || null,
        orden: r.orden,
      };
    });

    const byCategoria = {};
    for (const it of items) {
      if (!byCategoria[it.categoria]) byCategoria[it.categoria] = { categoria: it.categoria, label: it.categoriaLabel, items: [] };
      byCategoria[it.categoria].items.push(it);
    }
    const categorias = CATEGORIA_ORDER
      .filter((c) => byCategoria[c])
      .map((c) => byCategoria[c])
      .concat(Object.values(byCategoria).filter((g) => !CATEGORIA_ORDER.includes(g.categoria)));

    console.log("[_data/addons] loaded", items.length, "addons in", categorias.length, "categorias");
    return {
      items,
      categorias,
      byCategoria,
      total: items.length,
      fetchedAt: new Date().toISOString(),
    };
  } catch (err) {
    console.error("[_data/addons] fetch error", err);
    return empty;
  }
};
