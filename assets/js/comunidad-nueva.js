import { supabase, getCurrentUser, loginWithGoogle } from "./comunidad-supabase.js";

const loginCta = document.getElementById("login-cta");
const form = document.getElementById("nueva-form");
const fb = document.getElementById("form-feedback");
const tipoSelect = document.getElementById("tipo");
const camposPool = document.getElementById("campos-pool");
const loginBtn = document.getElementById("login-google");

function escape(s) {
  return String(s ?? "").replace(/[&<>"']/g, (m) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  }[m]));
}

function togglePoolFields() {
  const tipo = tipoSelect.value;
  camposPool.style.display = tipo === "idea" ? "none" : "";
}

async function refreshGate() {
  const user = await getCurrentUser();
  if (user) {
    loginCta.style.display = "none";
    form.style.display = "";
  } else {
    loginCta.style.display = "";
    form.style.display = "none";
  }
}

loginBtn?.addEventListener("click", () => loginWithGoogle());
tipoSelect.addEventListener("change", togglePoolFields);
togglePoolFields();

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  fb.innerHTML = "";
  const u = await getCurrentUser();
  if (!u) {
    await loginWithGoogle();
    return;
  }

  const titulo = document.getElementById("titulo").value.trim();
  const tipo = tipoSelect.value;
  const descripcion = document.getElementById("descripcion").value.trim();
  const problema = document.getElementById("problema").value.trim() || null;
  const beneficio = document.getElementById("beneficio").value.trim() || null;

  const payload = {
    titulo,
    descripcion,
    problema,
    beneficio,
    tipo_propuesta: tipo,
    autor_id: u.id,
    estado: "pendiente",
  };

  if (tipo !== "idea") {
    const cot = parseFloat(document.getElementById("cotizacion").value);
    const umb = parseFloat(document.getElementById("umbral").value);
    const adh = parseFloat(document.getElementById("precio_adhoc").value);
    if (!Number.isNaN(cot)) payload.cotizacion_precio = cot;
    if (!Number.isNaN(umb)) payload.umbral_financiacion_pool = umb;
    if (!Number.isNaN(adh)) payload.precio_adhoc = adh;
  }

  const submit = form.querySelector("button[type=submit]");
  submit.disabled = true;
  const { error } = await supabase.from("comunidad_propuestas").insert(payload);
  submit.disabled = false;

  if (error) {
    fb.innerHTML = `<div class="alert error">${escape(error.message)}</div>`;
    return;
  }
  form.reset();
  togglePoolFields();
  fb.innerHTML = `<div class="alert success">Propuesta enviada. Pasará por moderación antes de publicarse en /comunidad/.</div>`;
});

supabase.auth.onAuthStateChange(() => refreshGate());
refreshGate();
