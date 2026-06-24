// Shared Supabase client + tiny helpers for both admin & public site.
// Loads supabase-js from CDN (static-site friendly, no build step).
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cfg = window.GTS_CONFIG || {};
export const CONFIGURED =
  !!cfg.SUPABASE_URL &&
  !!cfg.SUPABASE_ANON_KEY &&
  !cfg.SUPABASE_URL.includes("YOUR-PROJECT");

export const supabase = CONFIGURED
  ? createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY)
  : null;

// ISO2 -> English country name (display only; data stores the code).
export const COUNTRY = {
  JP: "Japan", SG: "Singapore", TH: "Thailand", GB: "United Kingdom",
  US: "United States", AU: "Australia", FR: "France", IT: "Italy",
};
export const countryName = (c) => COUNTRY[c] || c || "";

// Format money (deal currency + integer-ish amount).
export const money = (cur, n) =>
  (cur === "JPY" ? "¥" : cur === "USD" ? "$" : cur === "GBP" ? "£" : cur + " ") +
  Number(n || 0).toLocaleString("en-US");

// Guard banner when config.js is missing — so the page never silently breaks.
export function requireConfig() {
  if (CONFIGURED) return true;
  const b = document.createElement("div");
  b.style.cssText =
    "position:fixed;top:0;left:0;right:0;z-index:9999;background:#B23A48;color:#fff;" +
    "font:600 13px/1.5 system-ui;padding:10px 16px;text-align:center";
  b.textContent =
    "Supabase not configured — copy web/shared/config.example.js to config.js and add your Project URL + anon key.";
  document.body.appendChild(b);
  return false;
}
