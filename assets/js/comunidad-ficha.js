import { supabase, getCurrentUser, loginWithGoogle, authorDisplay } from "./comunidad-supabase.js";

const propuestaCard = document.querySelector("section.card[data-id]");
if (!propuestaCard) {
  console.warn("[comunidad-ficha] propuesta no encontrada en DOM");
}
const propuestaId = propuestaCard?.dataset.id;

// ---------- Votos ----------
async function bindVote() {
  const btn = document.querySelector("[data-vote-propuesta]");
  if (!btn) return;
  const user = await getCurrentUser();
  if (user) {
    const { data } = await supabase
      .from("comunidad_votos_propuesta")
      .select("propuesta_id")
      .eq("propuesta_id", propuestaId)
      .eq("usuario_id", user.id)
      .maybeSingle();
    if (data) btn.classList.add("voted");
  }
  btn.addEventListener("click", async () => {
    const u = await getCurrentUser();
    if (!u) {
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
        .eq("propuesta_id", propuestaId)
        .eq("usuario_id", u.id);
      if (!error) {
        btn.classList.remove("voted");
        countEl.textContent = String(Math.max(0, current - 1));
      }
    } else {
      const { error } = await supabase
        .from("comunidad_votos_propuesta")
        .insert({ propuesta_id: propuestaId, usuario_id: u.id });
      if (!error) {
        btn.classList.add("voted");
        countEl.textContent = String(current + 1);
      }
    }
    btn.disabled = false;
  });
}

// ---------- Comentarios ----------
function commentHtml(c) {
  const author = c.__author_name || "Comunidad";
  const fecha = new Date(c.created_at).toLocaleDateString("es-ES", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
  return `
    <div class="comment">
      <div class="author">${escape(author)} · ${fecha}</div>
      <div>${escape(c.texto)}</div>
    </div>
  `;
}

function escape(s) {
  return String(s ?? "").replace(/[&<>"']/g, (m) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  }[m]));
}

async function loadComments() {
  const wrap = document.getElementById("comentarios-lista");
  const { data, error } = await supabase
    .from("comunidad_comentarios")
    .select("id, texto, created_at, autor_id")
    .eq("propuesta_id", propuestaId)
    .eq("estado", "aprobado")
    .order("created_at", { ascending: true });
  if (error) {
    wrap.innerHTML = `<p class="muted">No se pudieron cargar los comentarios.</p>`;
    return;
  }
  if (!data || data.length === 0) {
    wrap.innerHTML = `<p class="muted">Aún no hay comentarios aprobados.</p>`;
    return;
  }
  wrap.innerHTML = data.map(commentHtml).join("");
}

async function bindCommentForm() {
  const wrap = document.getElementById("comentario-form-wrap");
  const cta = document.getElementById("comentario-login-cta");
  const form = document.getElementById("comentario-form");
  const fb = document.getElementById("comentario-feedback");

  const user = await getCurrentUser();
  if (user) {
    wrap.style.display = "";
    cta.style.display = "none";
  } else {
    wrap.style.display = "none";
    cta.style.display = "";
    return;
  }

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    fb.innerHTML = "";
    const texto = document.getElementById("comentario-texto").value.trim();
    if (texto.length < 3) return;
    const u = await getCurrentUser();
    if (!u) {
      await loginWithGoogle();
      return;
    }
    const submitBtn = form.querySelector("button[type=submit]");
    submitBtn.disabled = true;
    const { error } = await supabase.from("comunidad_comentarios").insert({
      propuesta_id: propuestaId,
      autor_id: u.id,
      texto,
    });
    submitBtn.disabled = false;
    if (error) {
      fb.innerHTML = `<div class="alert error">${escape(error.message)}</div>`;
      return;
    }
    form.reset();
    fb.innerHTML = `<div class="alert success">Comentario enviado. Pasará por moderación antes de publicarse.</div>`;
  });
}

if (propuestaId) {
  bindVote();
  loadComments();
  bindCommentForm();
}
