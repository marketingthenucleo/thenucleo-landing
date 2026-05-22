// Anon key es público por diseño — ya está hardcoded en fichas-de-producto y playbook
// (mismo storageKey "thenucleo-comunidad-auth"). Fallback para que los previews de Vercel
// funcionen sin depender de la env var SUPABASE_ANON_KEY (que solo aplica a Production).
const SUPABASE_ANON_FALLBACK =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNiaXhocWpzbnB1aGNyY2pwcGFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM1NzU0OTksImV4cCI6MjA4OTE1MTQ5OX0.vbls3tGYkbgUNDhOzgEMBTG7nTlKfLMyTWzlWTmWxTM";

module.exports = {
  supabaseUrl: process.env.SUPABASE_URL || "https://cbixhqjsnpuhcrcjppah.supabase.co",
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || SUPABASE_ANON_FALLBACK,
  edgeFunctionAdminAction:
    (process.env.SUPABASE_URL || "https://cbixhqjsnpuhcrcjppah.supabase.co") +
    "/functions/v1/comunidad_admin_action",
};
