import {
  supabase, getCurrentUser, getAccessToken, goToLogin,
} from "./comunidad-supabase.js";

const $loading   = document.getElementById("admin-gate-loading");
const $login     = document.getElementById("admin-gate-login");
const $forbidden = document.getElementById("admin-gate-forbidden");
const $panel     = document.getElementById("admin-panel");
const $loginBtn  = document.getElementById("admin-login-btn");
const $propuestas   = document.getElementById("propuestas-pendientes");
const $aprobadas    = document.getElementById("propuestas-aprobadas");
const $comentarios  = document.getElementById("comentarios-pendientes");

const EDGE = window.__EDGE_ADMIN_ACTION__;

const PROPUESTA_COLS = "id, titulo, descripcion, problema, beneficio, modo, estado, autor_id, created_at, slug, cotizacion_precio, umbral_financiacion_pool, recaudado_pool, precio_adhoc";

function escape(s) {
  return String(s ?? "").replace(/[&<>"']/g, (m) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  }[m]));
}

$loginBtn?.addEventListener("click", () => goToLogin());

async function gate() {
  const user = await getCurrentUser();
  if (!user) {
    $loading.style.display = "none";
    $login.style.display = "";
    return false;
  }
  const { data, error } = await supabase.rpc("is_comunidad_admin");
  if (error || !data) {
    $loading.style.display = "none";
    $forbidden.style.display = "";
    $forbidden.querySelector("code").textContent =
      `INSERT INTO comunidad_admins (user_id) VALUES ('${user.id}');`;
    return false;
  }
  $loading.style.display = "none";
  $panel.style.display = "";
  return true;
}

async function callEdge(payload) {
  const token = await getAccessToken();
  return fetch(EDGE, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: "Bearer " + token },
    body: JSON.stringify(payload),
  });
}

function renderEditableFields(p) {
  const isPool = p.modo === "pool";
  const numericFields = isPool
    ? `
      <div class="input-group" style="flex:1;min-width:160px;margin:0">
        <label class="input-label">Cotización (€)</label>
        <input type="number" class="input-field" data-field="cotizacion_precio" min="0" step="1" value="${p.cotizacion_precio ?? ""}">
      </div>
      <div class="input-group" style="flex:1;min-width:160px;margin:0">
        <label class="input-label">Umbral pool (€)</label>
        <input type="number" class="input-field" data-field="umbral_financiacion_pool" min="0" step="1" value="${p.umbral_financiacion_pool ?? ""}">
      </div>`
    : `
      <div class="input-group" style="flex:1;min-width:160px;margin:0">
        <label class="input-label">Precio individual (€)</label>
        <input type="number" class="input-field" data-field="precio_adhoc" min="0" step="1" value="${p.precio_adhoc ?? ""}">
      </div>`;
  return `
    <div class="input-group" style="margin-bottom:10px">
      <label class="input-label">Título</label>
      <input type="text" class="input-field" data-field="titulo" maxlength="120" value="${escape(p.titulo)}">
    </div>
    <div class="input-group" style="margin-bottom:10px">
      <label class="input-label">Descripción</label>
      <textarea class="input-field" data-field="descripcion" maxlength="2000" style="min-height:90px">${escape(p.descripcion)}</textarea>
    </div>
    <div class="input-group" style="margin-bottom:10px">
      <label class="input-label">Problema que resuelve</label>
      <textarea class="input-field" data-field="problema" maxlength="2000" style="min-height:70px">${escape(p.problema || "")}</textarea>
    </div>
    <div class="input-group" style="margin-bottom:10px">
      <label class="input-label">Beneficio esperado</label>
      <textarea class="input-field" data-field="beneficio" maxlength="2000" style="min-height:70px">${escape(p.beneficio || "")}</textarea>
    </div>
    <div class="admin-row" style="gap:10px;flex-wrap:wrap;align-items:flex-end;margin-bottom:12px">
      ${numericFields}
    </div>
  `;
}

function badgeFor(p) {
  if (p.modo === "pool") {
    return `<span class="badge badge--pending" style="background:var(--accent-primary-muted);color:var(--accent-primary)">${escape(p.modo)}</span>`;
  }
  return `<span class="badge badge--violet">${escape(p.modo)}</span>`;
}

function estadoBadge(estado) {
  if (estado === "financiada") return `<span class="badge badge--done">financiada</span>`;
  if (estado === "aprobada")   return `<span class="badge badge--done" style="background:var(--accent-secondary-muted);color:var(--accent-secondary)">aprobada</span>`;
  return `<span class="badge">${escape(estado)}</span>`;
}

async function loadPropuestas() {
  const { data, error } = await supabase
    .from("comunidad_propuestas")
    .select(PROPUESTA_COLS)
    .eq("estado", "pendiente")
    .order("created_at", { ascending: true });
  if (error) { $propuestas.innerHTML = `<p class="muted">Error: ${escape(error.message)}</p>`; return; }
  if (!data || data.length === 0) { $propuestas.innerHTML = `<p class="muted">Sin propuestas pendientes.</p>`; return; }
  $propuestas.innerHTML = data.map((p) => `
    <article class="proposal-card" data-row-id="${p.id}">
      <div class="proposal-title-row">
        <span class="proposal-title">${escape(p.titulo)}</span>
        ${badgeFor(p)}
        <span class="proposal-time">${new Date(p.created_at).toLocaleString("es-ES")}</span>
      </div>
      <div class="muted" style="margin-bottom:14px">Autor UID: <code style="font-family:var(--font-mono)">${escape(p.autor_id || "—")}</code></div>
      ${renderEditableFields(p)}
      <div class="admin-row">
        <button class="btn btn--primary btn--sm" data-accion="aprobar" data-tipo="propuesta" data-id="${p.id}">Aprobar</button>
        <button class="btn btn--secondary btn--sm" data-accion="rechazar" data-tipo="propuesta" data-id="${p.id}">Rechazar</button>
      </div>
    </article>
  `).join("");
}

async function loadAprobadas() {
  const { data, error } = await supabase
    .from("comunidad_propuestas")
    .select(PROPUESTA_COLS)
    .in("estado", ["aprobada", "financiada"])
    .order("created_at", { ascending: false });
  if (error) { $aprobadas.innerHTML = `<p class="muted">Error: ${escape(error.message)}</p>`; return; }
  if (!data || data.length === 0) { $aprobadas.innerHTML = `<p class="muted">Sin propuestas aprobadas.</p>`; return; }
  $aprobadas.innerHTML = data.map((p) => `
    <article class="proposal-card" data-row-id="${p.id}">
      <div class="proposal-title-row">
        <a href="/comunidad/${escape(p.slug)}/" target="_blank" rel="noopener" class="proposal-title">${escape(p.titulo)}</a>
        ${badgeFor(p)}
        ${estadoBadge(p.estado)}
        <span class="proposal-time">${new Date(p.created_at).toLocaleString("es-ES")}</span>
      </div>
      ${renderEditableFields(p)}
      <div class="admin-row">
        <button class="btn btn--primary btn--sm" data-accion="guardar" data-tipo="propuesta" data-id="${p.id}">Guardar cambios</button>
      </div>
    </article>
  `).join("");
}

async function loadComentarios() {
  const { data, error } = await supabase
    .from("comunidad_comentarios")
    .select("id, texto, autor_id, created_at, propuesta_id")
    .eq("estado", "pendiente")
    .order("created_at", { ascending: true });
  if (error) { $comentarios.innerHTML = `<p class="muted">Error: ${escape(error.message)}</p>`; return; }
  if (!data || data.length === 0) { $comentarios.innerHTML = `<p class="muted">Sin comentarios pendientes.</p>`; return; }
  $comentarios.innerHTML = data.map((c) => `
    <article class="proposal-card" data-row-id="${c.id}">
      <div class="proposal-title-row">
        <span class="muted">propuesta: <code style="font-family:var(--font-mono)">${escape(c.propuesta_id)}</code></span>
        <span class="proposal-time">${new Date(c.created_at).toLocaleString("es-ES")}</span>
      </div>
      <p>${escape(c.texto)}</p>
      <div class="muted" style="margin-bottom:14px">Autor UID: <code style="font-family:var(--font-mono)">${escape(c.autor_id || "—")}</code></div>
      <div class="admin-row">
        <button class="btn btn--primary btn--sm" data-accion="aprobar" data-tipo="comentario" data-id="${c.id}">Aprobar</button>
        <button class="btn btn--secondary btn--sm" data-accion="rechazar" data-tipo="comentario" data-id="${c.id}">Rechazar</button>
      </div>
    </article>
  `).join("");
}

const NON_NULL_TEXT_FIELDS = new Set(["titulo", "descripcion"]);

async function persistPropuestaCampos(card, id) {
  const inputs = card.querySelectorAll("[data-field]");
  if (inputs.length === 0) return null;
  const updates = {};
  inputs.forEach((inp) => {
    const field = inp.dataset.field;
    const raw = (inp.value ?? "").trim();
    if (inp.type === "number") {
      if (raw === "") return;
      const n = parseFloat(raw);
      if (!Number.isNaN(n)) updates[field] = n;
      return;
    }
    if (raw === "" && NON_NULL_TEXT_FIELDS.has(field)) return;
    updates[field] = raw === "" ? null : raw;
  });
  if (Object.keys(updates).length === 0) return null;
  const { error } = await supabase.from("comunidad_propuestas").update(updates).eq("id", id);
  return error;
}

document.body.addEventListener("click", async (e) => {
  const btn = e.target.closest("button[data-accion]");
  if (!btn) return;
  const { accion, tipo, id } = btn.dataset;
  const card = btn.closest("[data-row-id]");
  btn.disabled = true;
  const orig = btn.textContent;

  if (accion === "guardar") {
    btn.textContent = "Guardando…";
    const updErr = await persistPropuestaCampos(card, id);
    if (updErr) {
      alert("Error: " + updErr.message);
      btn.disabled = false;
      btn.textContent = orig;
      return;
    }
    btn.textContent = "Guardado ✓";
    setTimeout(() => { btn.textContent = orig; btn.disabled = false; }, 1500);
    return;
  }

  btn.textContent = accion === "aprobar" ? "Aprobando…" : "Rechazando…";

  if (accion === "aprobar" && tipo === "propuesta" && card) {
    const updErr = await persistPropuestaCampos(card, id);
    if (updErr) {
      alert("Error guardando cambios: " + updErr.message);
      btn.disabled = false;
      btn.textContent = orig;
      return;
    }
  }

  const res = await callEdge({ tipo, id, accion });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    alert("Error: " + (err.error || res.status));
    btn.disabled = false;
    btn.textContent = orig;
    return;
  }
  card?.remove();
  if (accion === "aprobar" && tipo === "propuesta") {
    loadAprobadas();
  }
});

(async () => {
  const ok = await gate();
  if (!ok) return;
  loadPropuestas();
  loadAprobadas();
  loadComentarios();
})();
