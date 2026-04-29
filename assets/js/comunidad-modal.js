import { supabase, getCurrentUser, goToLogin } from "./comunidad-supabase.js";

const overlay   = document.getElementById("modalPropuesta");
if (overlay) {
  const form      = document.getElementById("modal-propuesta-form");
  const fields    = document.getElementById("modal-form-fields");
  const loginCta  = document.getElementById("modal-login-cta");
  const loginBtn  = document.getElementById("modal-login-btn");
  const fb        = document.getElementById("modal-feedback");
  const submit    = document.getElementById("modal-submit");
  const modoSel   = document.getElementById("modal-modo");

  function escape(s) {
    return String(s ?? "").replace(/[&<>"']/g, (m) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
    }[m]));
  }

  loginBtn?.addEventListener("click", () => goToLogin());

  async function refreshAuthGate() {
    const user = await getCurrentUser();
    if (user) {
      loginCta.style.display = "none";
      fields.style.display = "";
      submit.disabled = false;
    } else {
      loginCta.style.display = "";
      fields.style.display = "none";
      submit.disabled = true;
    }
  }

  // Refresca cada vez que se abre el modal
  const observer = new MutationObserver(() => {
    if (overlay.classList.contains("visible")) refreshAuthGate();
  });
  observer.observe(overlay, { attributes: true, attributeFilter: ["class"] });

  supabase.auth.onAuthStateChange(() => refreshAuthGate());
  refreshAuthGate();

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    fb.innerHTML = "";

    const user = await getCurrentUser();
    if (!user) {
      goToLogin();
      return;
    }

    const titulo      = document.getElementById("modal-titulo").value.trim();
    const descripcion = document.getElementById("modal-descripcion").value.trim();
    const problema    = document.getElementById("modal-problema").value.trim() || null;
    const beneficio   = document.getElementById("modal-beneficio").value.trim() || null;
    const modo        = modoSel.value;

    const payload = {
      titulo, descripcion, problema, beneficio,
      modo,
      autor_id: user.id,
      estado: "pendiente",
    };

    submit.disabled = true;
    submit.textContent = "Enviando…";
    const { error } = await supabase.from("comunidad_propuestas").insert(payload);
    submit.disabled = false;
    submit.textContent = "Publicar propuesta";

    if (error) {
      fb.innerHTML = `<div class="alert alert--error">${escape(error.message)}</div>`;
      return;
    }
    form.reset();
    fb.innerHTML = `<div class="alert alert--success">Propuesta enviada. Pasará por moderación antes de publicarse.</div>`;
    setTimeout(() => {
      overlay.classList.remove("visible");
      fb.innerHTML = "";
    }, 1800);
  });
}
