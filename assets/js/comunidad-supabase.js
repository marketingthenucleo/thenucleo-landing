import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";

const url = window.__SUPABASE_URL__;
const key = window.__SUPABASE_ANON_KEY__;

if (!url || !key) {
  console.error("[comunidad] SUPABASE_URL or SUPABASE_ANON_KEY missing on window globals");
}

export const supabase = createClient(url, key, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    storageKey: "thenucleo-comunidad-auth",
  },
});

export async function getCurrentUser() {
  const { data, error } = await supabase.auth.getUser();
  if (error) return null;
  return data.user;
}

export async function getAccessToken() {
  const { data } = await supabase.auth.getSession();
  return data.session?.access_token ?? null;
}

export async function loginWithGoogle() {
  const here = window.location.href.split("#")[0];
  return supabase.auth.signInWithOAuth({
    provider: "google",
    options: { redirectTo: here },
  });
}

export async function logout() {
  await supabase.auth.signOut();
  window.location.reload();
}

export function authorDisplay(user) {
  if (!user) return "Anónimo";
  const meta = user.user_metadata || {};
  return meta.full_name || meta.name || (user.email ? user.email.split("@")[0] : "Anónimo");
}

// Nav UI bindings (only if elements present)
function bindNav() {
  const loginBtn = document.getElementById("auth-login");
  const logoutBtn = document.getElementById("auth-logout");
  const statusEl = document.getElementById("auth-status");

  async function refresh() {
    const user = await getCurrentUser();
    if (user) {
      if (loginBtn) loginBtn.style.display = "none";
      if (logoutBtn) logoutBtn.style.display = "";
      if (statusEl) {
        statusEl.style.display = "";
        statusEl.textContent = authorDisplay(user);
      }
    } else {
      if (loginBtn) loginBtn.style.display = "";
      if (logoutBtn) logoutBtn.style.display = "none";
      if (statusEl) statusEl.style.display = "none";
    }
  }

  loginBtn?.addEventListener("click", () => loginWithGoogle());
  logoutBtn?.addEventListener("click", () => logout());

  supabase.auth.onAuthStateChange(() => refresh());
  refresh();
}

bindNav();
