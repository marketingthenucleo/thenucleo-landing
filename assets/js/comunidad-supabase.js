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

export function goToLogin(next) {
  const path = window.location.pathname + window.location.search + window.location.hash;
  const target = next || path || "/comunidad/";
  const dest = "/comunidad/entrar/?next=" + encodeURIComponent(target);
  if (window.location.pathname !== "/comunidad/entrar/") {
    window.location.assign(dest);
  }
}

export async function loginWithGoogle() {
  goToLogin();
}

export async function logout() {
  await supabase.auth.signOut();
  window.location.assign("/comunidad/");
}

export function authorDisplay(user) {
  if (!user) return "Anónimo";
  const meta = user.user_metadata || {};
  return meta.full_name || meta.name || (user.email ? user.email.split("@")[0] : "Anónimo");
}

function avatarUrl(user) {
  const meta = user?.user_metadata || {};
  return meta.avatar_url || meta.picture || null;
}

function initials(name) {
  return String(name || "?")
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase() || "")
    .join("") || "?";
}

function bindNav() {
  const loginBtn = document.getElementById("auth-login");
  const menu = document.getElementById("auth-menu");
  if (!loginBtn && !menu) return;

  const trigger = document.getElementById("auth-menu-trigger");
  const dropdown = document.getElementById("auth-menu-dropdown");
  const avatarEl = document.getElementById("auth-menu-avatar");
  const initialsEl = document.getElementById("auth-menu-initials");
  const nameEl = document.getElementById("auth-menu-name");
  const fullnameEl = document.getElementById("auth-menu-fullname");
  const emailEl = document.getElementById("auth-menu-email");
  const logoutBtn = document.getElementById("auth-menu-logout");

  function closeMenu() {
    if (!menu) return;
    menu.classList.remove("is-open");
    trigger?.setAttribute("aria-expanded", "false");
  }

  function openMenu() {
    if (!menu) return;
    menu.classList.add("is-open");
    trigger?.setAttribute("aria-expanded", "true");
  }

  function toggleMenu() {
    if (!menu) return;
    menu.classList.contains("is-open") ? closeMenu() : openMenu();
  }

  async function refresh() {
    const user = await getCurrentUser();
    if (user) {
      if (loginBtn) loginBtn.style.display = "none";
      if (menu) menu.style.display = "";

      const display = authorDisplay(user);
      const url = avatarUrl(user);
      if (nameEl) nameEl.textContent = display;
      if (fullnameEl) fullnameEl.textContent = display;
      if (emailEl) emailEl.textContent = user.email || "";

      if (avatarEl && initialsEl) {
        if (url) {
          avatarEl.src = url;
          avatarEl.alt = display;
          avatarEl.style.display = "";
          initialsEl.style.display = "none";
        } else {
          avatarEl.style.display = "none";
          initialsEl.textContent = initials(display);
          initialsEl.style.display = "";
        }
      }
    } else {
      if (loginBtn) loginBtn.style.display = "";
      if (menu) menu.style.display = "none";
      closeMenu();
    }
  }

  loginBtn?.addEventListener("click", () => goToLogin());
  trigger?.addEventListener("click", (e) => {
    e.stopPropagation();
    toggleMenu();
  });
  logoutBtn?.addEventListener("click", () => logout());

  document.addEventListener("click", (e) => {
    if (!menu) return;
    if (!menu.contains(e.target)) closeMenu();
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeMenu();
  });

  supabase.auth.onAuthStateChange(() => refresh());
  refresh();
}

bindNav();
