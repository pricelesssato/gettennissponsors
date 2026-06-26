// Public client config. The anon key is a PUBLIC client key (safe to embed).
// NEVER put the Supabase service_role key here.
// PEXELS_API_KEY is optional — it powers the "Choose from stock" photo picker.
//   It's only a rate-limit token (no data access). Leaving it "" hides the picker.
window.GTS_CONFIG = {
  SUPABASE_URL: "https://YOUR-PROJECT.supabase.co",
  SUPABASE_ANON_KEY: "YOUR-ANON-PUBLIC-KEY",
  PEXELS_API_KEY: "",
};
