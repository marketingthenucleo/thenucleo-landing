import {
  supabase, getCurrentUser, getAccessToken, goToLogin,
} from "./comunidad-supabase.js";

const $loading   = document.getElementById("admin-gate-loading");
const $login     = document.getElementById("admin-gate-login");
const $forbidden = document.getElementById("admin-gate-forbidden");
const $panel     = document.getElementById("admin-panel");
const $loginBtn  = document.getElementById("admin-login-btn");
const $propuestas   = document.getElementById("propuestas-pendientes");
const $comentarios  = document.getElementById("comentarios-pendientes");

const EDGE = window.__EDGE_ADMIN_ACTION__;

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

async function loadPropuestas() {
  const { data, error } = await supabase
    .from("comunidad_propuestas")
    .select("id, titulo, descripcion, modo, autor_id, created_at, slug")
    .eq("estado", "pendiente")
    .order("created_at", { ascending: true });
  if (error) { $propuestas.innerHTML = `<p class="muted">Error: ${escape(error.message)}</p>`; return; }
  if (!data || data.length === 0) { $propuestas.innerHTML = `<p class="muted">Sin propuestas pendientes.</p>`; return; }
  $propuestas.innerHTML = data.map((p) => `
    <article class="proposal-card" data-row-id="${p.id}">
      <div class="proposal-title-row">
        <span class="proposal-title">${escape(p.titulo)}</span>
        <span class="badge ${p.modo === "pool" ? "badge--pending" : "badge--violet"}" style="${p.modo === "pool" ? "background:var(--accent-primary-muted);color:var(--accent-primary)" : ""}">${escape(p.modo)}</span>
        <span class="proposal-time">${new Date(p.created_at).toLocaleString("es-ES")}</span>
      </div>
      <div class="proposal-desc">${escape(p.descripcion)}</div>
      <div class="muted" style="margin-bottom:14px">Autor UID: <code style="font-family:var(--font-mono)">${escape(p.autor_id || "—")}</code></div>
      <div class="admin-row">
        <button class="btn btn--primary btn--sm" data-accion="aprobar" data-tipo="propuesta" data-id="${p.id}">Aprobar</button>
        <button class="btn btn--secondary btn--sm" data-accion="rechazar" data-tipo="propuesta" data-id="${p.id}">Rechazar</button>
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

document.body.addEventListener("click", async (e) => {
  const btn = e.target.closest("button[data-accion]");
  if (!btn) return;
  const { accion, tipo, id } = btn.dataset;
  btn.disabled = true;
  const orig = btn.textContent;
  btn.textContent = accion === "aprobar" ? "Aprobando…" : "Rechazando…";
  const res = await callEdge({ tipo, id, accion });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    alert("Error: " + (err.error || res.status));
    btn.disabled = false;
    btn.textContent = orig;
    return;
  }
  btn.closest("[data-row-id]")?.remove();
});

(async () => {
  const ok = await gate();
  if (!ok) return;
  loadPropuestas();
  loadComentarios();
})();
