import { supabase, getCurrentUser, loginWithGoogle } from "./comunidad-supabase.js";

const cards = Array.from(document.querySelectorAll(".propuesta"));

// Filtros por tipo
const filterButtons = document.querySelectorAll("#filters button");
filterButtons.forEach((btn) => {
  btn.addEventListener("click", () => {
    filterButtons.forEach((b) => b.classList.remove("active"));
    btn.classList.add("active");
    const tipo = btn.dataset.tipo;
    cards.forEach((card) => {
      card.style.display = tipo === "all" || card.dataset.tipo === tipo ? "" : "none";
    });
  });
});

// Marcar votos propios y bind toggle
async function syncVotes() {
  const user = await getCurrentUser();
  const buttons = Array.from(document.querySelectorAll("[data-vote-propuesta]"));
  if (buttons.length === 0) return;

  if (user) {
    const ids = buttons.map((b) => b.dataset.votePropuesta);
    const { data } = await supabase
      .from("comunidad_votos_propuesta")
      .select("propuesta_id")
      .in("propuesta_id", ids)
      .eq("usuario_id", user.id);
    const voted = new Set((data || []).map((r) => r.propuesta_id));
    buttons.forEach((b) => {
      if (voted.has(b.dataset.votePropuesta)) b.classList.add("voted");
    });
  }

  buttons.forEach((b) => b.addEventListener("click", onVoteClick));
}

async function onVoteClick(e) {
  const btn = e.currentTarget;
  const id = btn.dataset.votePropuesta;
  const user = await getCurrentUser();
  if (!user) {
    await loginWithGoogle();
    return;
  }
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
