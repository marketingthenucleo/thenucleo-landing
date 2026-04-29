import { supabase, getCurrentUser } from "./comunidad-supabase.js";

const googleBtn = document.getElementById("google-signin");
const captcha = document.getElementById("captcha");
const captchaHelp = document.getElementById("login-help");
const errorEl = document.getElementById("login-error");

let verified = false;
let verifying = false;

function getNextUrl() {
  const params = new URLSearchParams(window.location.search);
  const next = params.get("next");
  if (next && next.startsWith("/") && !next.startsWith("//")) return next;
  return "/comunidad/";
}

function absoluteNext() {
  return new URL(getNextUrl(), window.location.origin).toString();
}

async function redirectIfAlreadyAuthed() {
  const u = await getCurrentUser();
  if (u) window.location.replace(getNextUrl());
}

function setError(msg) {
  if (!msg) {
    errorEl.style.display = "none";
    errorEl.textContent = "";
    return;
  }
  errorEl.style.display = "";
  errorEl.textContent = msg;
}

function setVerified() {
  verified = true;
  captcha.classList.add("is-verified");
  captcha.classList.remove("is-verifying");
  captcha.setAttribute("aria-checked", "true");
  captchaHelp.textContent = "Verificado. Continúa con Google.";
  googleBtn.disabled = false;
}

function startVerifying() {
  if (verified || verifying) return;
  verifying = true;
  captcha.classList.add("is-verifying");
  captchaHelp.textContent = "Verificando…";
  setTimeout(() => {
    verifying = false;
    setVerified();
  }, 750);
}

captcha.addEventListener("click", startVerifying);
captcha.addEventListener("keydown", (e) => {
  if (e.key === " " || e.key === "Enter") {
    e.preventDefault();
    startVerifying();
  }
});

googleBtn.addEventListener("click", async () => {
  if (!verified) {
    setError("Marca primero la casilla \"No soy un robot\".");
    captcha.focus();
    return;
  }
  setError("");
  googleBtn.disabled = true;
  googleBtn.classList.add("is-loading");
  const { error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: { redirectTo: absoluteNext() },
  });
  if (error) {
    googleBtn.disabled = false;
    googleBtn.classList.remove("is-loading");
    setError(error.message || "No se pudo iniciar sesión con Google.");
  }
});

supabase.auth.onAuthStateChange((event) => {
  if (event === "SIGNED_IN") window.location.replace(getNextUrl());
});

redirectIfAlreadyAuthed();
