const SUPABASE_URL = process.env.SUPABASE_URL || "https://cbixhqjsnpuhcrcjppah.supabase.co";
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || "";

module.exports = async () => {
  if (!SUPABASE_ANON_KEY) {
    console.warn("[_data/comunidad] SUPABASE_ANON_KEY missing → skipping fetch (build will have empty list)");
    return { propuestas: [] };
  }

  const url =
    SUPABASE_URL +
    "/rest/v1/v_comunidad_propuestas_publicas" +
    "?select=*" +
    "&order=fecha_publicacion.desc.nullslast";

  try {
    const res = await fetch(url, {
      headers: {
        apikey: SUPABASE_ANON_KEY,
        Authorization: "Bearer " + SUPABASE_ANON_KEY,
      },
    });
    if (!res.ok) {
      console.error("[_data/comunidad] fetch failed", res.status, await res.text());
      return { propuestas: [] };
    }
    const propuestas = await res.json();
    return { propuestas };
  } catch (err) {
    console.error("[_data/comunidad] fetch error", err);
    return { propuestas: [] };
  }
};
