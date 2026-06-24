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
  PL: "Poland", HK: "Hong Kong", ES: "Spain", DE: "Germany", CH: "Switzerland",
  CN: "China", IN: "India", AE: "United Arab Emirates", SA: "Saudi Arabia",
};
export const countryName = (c) => COUNTRY[c] || c || "";

// Generative SVG key-visual thumbnail (no external image needed).
// Tennis motif + brand gradient, varied by author name. Returns an <svg> string.
export function newsThumb(n, opts = {}) {
  const name = (n.author_name || "GetTennisSponsors").trim();
  const cat = (n.source === "operator" ? "Curated"
    : ({ player: "Player", club: "Club", tournament: "Tournament" }[n.author_type] || "News"));
  let h = 0; for (const ch of name) h = (h * 31 + ch.charCodeAt(0)) % 360;
  const hue = 150 + (h % 70);            // green -> teal -> blue, on-brand
  const c1 = `hsl(${hue},42%,17%)`, c2 = `hsl(${hue},38%,33%)`;
  const esc = (s) => String(s).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const initials = name.split(/\s+/).slice(0, 2).map(w => w.charAt(0)).join("").toUpperCase();
  const disp = name.length > 26 ? name.slice(0, 25) + "…" : name;
  const id = "g" + (h % 100000);
  return `<svg viewBox="0 0 400 250" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" role="img" aria-label="${esc(name)}">
  <defs><linearGradient id="${id}" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="${c1}"/><stop offset="1" stop-color="${c2}"/></linearGradient></defs>
  <rect width="400" height="250" fill="url(#${id})"/>
  <g opacity="0.13" fill="none" stroke="#fff" stroke-width="2">
    <rect x="38" y="34" width="324" height="182"/><line x1="200" y1="34" x2="200" y2="216"/>
    <line x1="38" y1="125" x2="362" y2="125"/><rect x="120" y="74" width="160" height="102"/></g>
  <circle cx="332" cy="206" r="58" fill="#C8DC2B" opacity="0.92"/>
  <path d="M286 178 q28 28 0 56 M378 178 q-28 28 0 56" fill="none" stroke="#0F4D34" stroke-width="3" opacity="0.85"/>
  <text x="28" y="40" fill="#C8DC2B" font-family="'Roboto Mono',monospace" font-size="13" font-weight="700" letter-spacing="1.5">${esc(cat.toUpperCase())}</text>
  <text x="28" y="150" fill="#fff" font-family="'Noto Sans JP',sans-serif" font-size="30" font-weight="900">${esc(initials)}</text>
  <text x="28" y="186" fill="#eaf2ed" font-family="'Noto Sans JP',sans-serif" font-size="17" font-weight="700">${esc(disp)}</text>
  <text x="28" y="228" fill="#9fb8ab" font-family="'Roboto Mono',monospace" font-size="10" letter-spacing="1">GETTENNISSPONSORS</text>
</svg>`;
}

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
