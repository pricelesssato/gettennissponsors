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

const _esc = (s) => String(s ?? "").replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

// Split a sponsor name into highlightable terms: "Danone (Evian)" -> ["Danone","Evian"].
export function brandTerms(name) {
  if (!name) return [];
  const out = [];
  const m = String(name).match(/^(.*?)\s*[\(（](.*?)[\)）]\s*$/);
  if (m) { out.push(m[1].trim()); out.push(m[2].trim()); }
  else String(name).split(/\s*[\/／]\s*/).forEach(p => out.push(p.trim()));
  return out.filter(t => t.length >= 2);
}

// Escape `text`, then wrap occurrences of the sponsor brand terms in <mark class="brand">.
// Pass brand="" to just escape (e.g. for member posts where author isn't the sponsor).
export function markBrand(text, brand) {
  let out = _esc(text);
  const terms = brandTerms(brand).sort((a, b) => b.length - a.length);
  for (const t of terms) {
    const et = _esc(t).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    out = out.replace(new RegExp("(" + et + ")(?![^<]*>)", "gi"), '<mark class="brand">$1</mark>');
  }
  return out;
}

// Generative SVG key-visual thumbnail — copyright-safe (our own art) but
// tied to the SOURCE via its favicon + outlet name (attribution use, like an
// RSS reader). Varied by 8 palettes x 5 patterns so no two look alike.
const THUMB_PALETTES = [
  ["#0A3A27", "#15573C"], ["#0c2e3a", "#176069"], ["#10243f", "#1d3f6b"],
  ["#241033", "#3d2057"], ["#2a2018", "#4a3520"], ["#2b1320", "#5a2236"],
  ["#11302a", "#1f5a4e"], ["#1a2a12", "#33500f"],
];
function thumbDomain(url) {
  try { const d = new URL(url).hostname.toLowerCase(); return d.startsWith("www.") ? d.slice(4) : d; }
  catch (e) { return ""; }
}
function thumbPattern(i, op) {
  const s = `stroke="#fff" stroke-width="2" fill="none" opacity="${op}"`;
  switch (i) {
    case 0: return `<g ${s}><rect x="34" y="30" width="332" height="190"/><line x1="200" y1="30" x2="200" y2="220"/><line x1="34" y1="125" x2="366" y2="125"/><rect x="116" y="70" width="168" height="110"/></g>`; // court
    case 1: return `<g ${s}>${[0, 1, 2, 3, 4, 5, 6, 7].map(k => `<line x1="${-60 + k * 70}" y1="250" x2="${60 + k * 70}" y2="0"/>`).join("")}</g>`; // diagonal stripes
    case 2: return `<g ${s}>${[40, 90, 140, 190].map(r => `<circle cx="360" cy="40" r="${r}"/>`).join("")}</g>`; // concentric
    case 3: return `<g fill="#fff" opacity="${op}">${Array.from({ length: 40 }, (_, k) => `<circle cx="${20 + (k % 8) * 52}" cy="${20 + Math.floor(k / 8) * 52}" r="3"/>`).join("")}</g>`; // dots
    default: return `<g ${s}><path d="M0 70 Q100 30 200 70 T400 70"/><path d="M0 130 Q100 90 200 130 T400 130"/><path d="M0 190 Q100 150 200 190 T400 190"/></g>`; // waves
  }
}
export function newsThumb(n) {
  const name = (n.sponsor_name || n.author_name || "GetTennisSponsors").trim();
  const cat = ({ player: "Player", club: "Club", tournament: "Tournament" }[n.author_type] || "News");
  const dom = thumbDomain(n.link_url || "");
  const esc = (s) => String(s).replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  let h = 0; const key = name + "|" + dom; for (const ch of key) h = (h * 33 + ch.charCodeAt(0)) >>> 0;
  const [c1, c2] = THUMB_PALETTES[h % THUMB_PALETTES.length];
  const pat = thumbPattern(h % 5, 0.12);
  const initials = name.split(/\s+/).slice(0, 2).map(w => w.charAt(0)).join("").toUpperCase();
  const disp = name.length > 24 ? name.slice(0, 23) + "…" : name;
  const id = "g" + (h % 100000);
  const fav = dom
    ? `<g transform="translate(28,196)"><circle cx="13" cy="13" r="15" fill="#fff"/><image href="https://www.google.com/s2/favicons?domain=${esc(dom)}&amp;sz=64" x="3" y="3" width="20" height="20"/></g>
       <text x="52" y="210" fill="#cfe0d6" font-family="'Roboto Mono',monospace" font-size="11" font-weight="700">${esc(dom)}</text>`
    : `<text x="28" y="214" fill="#9fb8ab" font-family="'Roboto Mono',monospace" font-size="10" letter-spacing="1">GETTENNISSPONSORS</text>`;
  return `<svg viewBox="0 0 400 250" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" role="img" aria-label="${esc(name)}">
  <defs><linearGradient id="${id}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${c1}"/><stop offset="1" stop-color="${c2}"/></linearGradient></defs>
  <rect width="400" height="250" fill="url(#${id})"/>
  ${pat}
  <circle cx="344" cy="44" r="34" fill="#C8DC2B" opacity="0.9"/>
  <path d="M312 26 q22 18 0 36 M376 26 q-22 18 0 36" fill="none" stroke="#0F4D34" stroke-width="2.5" opacity="0.85"/>
  <text x="28" y="42" fill="#C8DC2B" font-family="'Roboto Mono',monospace" font-size="12" font-weight="700" letter-spacing="1.5">${esc(cat.toUpperCase())}</text>
  <text x="28" y="132" fill="#fff" font-family="'Noto Sans JP',sans-serif" font-size="34" font-weight="900">${esc(initials)}</text>
  <text x="28" y="166" fill="#eaf2ed" font-family="'Noto Sans JP',sans-serif" font-size="18" font-weight="700">${esc(disp)}</text>
  ${fav}
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
