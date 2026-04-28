module.exports = {
  supabaseUrl: process.env.SUPABASE_URL || "https://cbixhqjsnpuhcrcjppah.supabase.co",
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || "",
  edgeFunctionAdminAction:
    (process.env.SUPABASE_URL || "https://cbixhqjsnpuhcrcjppah.supabase.co") +
    "/functions/v1/comunidad_admin_action",
};
