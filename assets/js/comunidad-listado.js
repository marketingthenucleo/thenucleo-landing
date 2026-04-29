import { supabase, getCurrentUser, goToLogin } from "./comunidad-supabase.js";

// Filtros (search + pills) + voto toggle
const cards = Array.from(document.querySelectorAll(".proposal-card"));
const searchInput = document.getElementById("search");
const pills = document.querySelectorAll("#pills .pill");
const tabCount = document.getElementById("tab-count");

function applyFilters() {
  const q = (searchInput?.value || "").toLowerCase().trim();
  const activeEstado = document.querySelector("#pills .pill.active")?.dataset.estado || "all";
  let visibles = 0;
  cards.forEach((c) => {
    const titulo = c.dataset.titulo || "";
    const estado = c.dataset.estado || "";
    const matchQ = !q || titulo.includes(q);
    const matchEstado = activeEstado === "all" || estado === activeEstado;
    const show = matchQ && matchEstado;
    c.style.display = show ? "" : "none";
    if (show) visibles++;
  });
  if (tabCount) tabCount.textContent = visibles;
}

searchInput?.addEventListener("input", applyFilters);
pills.forEach((p) => p.addEventListener("click", () => {
  pills.forEach((x) => x.classList.remove("active"));
  p.classList.add("active");
  applyFilters();
}));

// Voto: marcar votos propios + bind toggle
async function syncVotes() {
  const buttons = Array.from(document.querySelectorAll("[data-vote-propuesta]"));
  if (buttons.length === 0) return;
  const user = await getCurrentUser();
  if (user) {
    const ids = buttons.map((b) => b.dataset.votePropuesta);
    const { data } = await supabase
      .from("comunidad_votos_propuesta")
      .select("propuesta_id")
      .in("propuesta_id", ids)
      .eq("usuario_id", user.id);
    const voted = new Set((data || []).map((r) => r.propuesta_id));
    buttons.forEach((b) => { if (voted.has(b.dataset.votePropuesta)) b.classList.add("voted"); });
  }
  buttons.forEach((b) => b.addEventListener("click", onVoteClick));
}

async function onVoteClick(e) {
  e.preventDefault();
  const btn = e.currentTarget;
  const id = btn.dataset.votePropuesta;
  const user = await getCurrentUser();
  if (!user) { goToLogin(); return; }
  const isVoted = btn.classList.contains("voted");
  btn.disabled = true;
  const countEl = btn.querySelector("[data-vote-count]");
  const current = parseInt(countEl.textContent, 10) || 0;

  if (isVoted) {
    const { error } = await supabase
      .from("comunidad_votos_propuesta")
      .delete()
      .eq("propuesta_id", id)
      .eq("usuario_id", user.id);
    if (!error) {
      btn.classList.remove("voted");
      countEl.textContent = String(Math.max(0, current - 1));
    }
  } else {
    const { error } = await supabase
      .from("comunidad_votos_propuesta")
      .insert({ propuesta_id: id, usuario_id: user.id });
    if (!error) {
      btn.classList.add("voted");
      countEl.textContent = String(current + 1);
    }
  }
  btn.disabled = false;
}

syncVotes();
