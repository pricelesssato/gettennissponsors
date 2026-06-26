#!/usr/bin/env python3
"""
GetTennisSponsors — historical bulk backfill (target ~3000 items).

Sweeps GDELT month-by-month (default from 2021) for TENNIS sponsorship news,
plus Google News RSS for recent items. Claude verifies each is genuinely about
a tennis sponsorship/partnership (filters out anything off-tennis), rewrites a
clean English headline + sponsor-exposure blurb, classifies the category, and
inserts into Supabase. Photos are left to the backfill-photos job / SVG fallback.

Env (GitHub Actions secrets):
  SUPABASE_URL, SUPABASE_SERVICE_ROLE, ANTHROPIC_API_KEY
Optional:
  MAX_ITEMS=3000        hard cap on new inserts this run
  START_YEAR=2021       earliest year to sweep
  DRY_RUN=1             classify but do not insert
"""
import os, sys, json, time, html
from urllib.parse import quote_plus, urlparse
from datetime import datetime, timezone

import requests, feedparser, anthropic

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SERVICE_ROLE = os.environ.get("SUPABASE_SERVICE_ROLE", "")
ANTHROPIC_KEY = os.environ.get("ANTHROPIC_API_KEY", "")
MAX_ITEMS = int(os.environ.get("MAX_ITEMS", "3000"))
START_YEAR = int(os.environ.get("START_YEAR", "2021"))
DRY_RUN = os.environ.get("DRY_RUN") == "1"
CLAUDE_MODEL = os.environ.get("CLAUDE_MODEL", "claude-haiku-4-5-20251001")

GDELT_QUERY = 'tennis (sponsor OR sponsorship OR partnership OR endorsement OR "title sponsor") -"table tennis" sourcelang:english'
RSS_QUERIES = ["tennis sponsorship", "tennis title sponsor", "tennis player endorsement",
               "tennis academy sponsor", "ATP sponsor", "WTA sponsor", "ITF sponsor"]
TENNIS_HINT = ("tennis", "atp", "wta", "itf", "grand slam", "roland", "wimbledon",
               "open", "davis cup", "billie jean", "racquet", "racket")
SPONSOR_HINT = ("sponsor", "partner", "endorse", "deal", "naming", "kit", "apparel",
                "ambassador", "title ")


def die(m): print("ERROR:", m, file=sys.stderr); sys.exit(1)
def domain_of(u):
    try:
        d = urlparse(u).netloc.lower(); return d[4:] if d.startswith("www.") else d
    except Exception: return ""


def months(start_year):
    now = datetime.now(timezone.utc)
    y, m = start_year, 1
    out = []
    while (y < now.year) or (y == now.year and m <= now.month):
        if m == 12: ny, nm = y + 1, 1
        else: ny, nm = y, m + 1
        out.append((f"{y:04d}{m:02d}01000000", f"{ny:04d}{nm:02d}01000000"))
        y, m = ny, nm
    return out


def gdelt_window(start, end):
    url = ("https://api.gdeltproject.org/api/v2/doc/doc?query=" + quote_plus(GDELT_QUERY) +
           f"&mode=ArtList&maxrecords=250&format=json&sort=DateDesc&startdatetime={start}&enddatetime={end}")
    for attempt in range(3):
        try:
            r = requests.get(url, timeout=40, headers={"User-Agent": "GTS-history/1.0"})
            if r.status_code == 200 and r.headers.get("content-type", "").startswith("application/json"):
                return r.json().get("articles", [])
            time.sleep(2)
        except Exception:
            time.sleep(2)
    return []


def parse_seendate(s):
    try:
        return datetime.strptime(s[:15], "%Y%m%dT%H%M%S").date().isoformat()
    except Exception:
        return None


def collect_candidates():
    seen, out = set(), []
    # GDELT historical sweep
    for (s, e) in months(START_YEAR):
        arts = gdelt_window(s, e)
        for a in arts:
            u = a.get("url", "")
            if not u or u in seen: continue
            seen.add(u)
            out.append({"title": (a.get("title") or "").strip(), "url": u,
                        "outlet": a.get("domain", ""), "snippet": "",
                        "date": parse_seendate(a.get("seendate", ""))})
        print(f"  gdelt {s[:6]}: total candidates {len(out)}")
        time.sleep(1.2)  # be gentle with GDELT
    # Google News RSS (recent supplement)
    for q in RSS_QUERIES:
        try:
            feed = feedparser.parse(f"https://news.google.com/rss/search?q={quote_plus(q)}&hl=en-US&gl=US&ceid=US:en")
        except Exception:
            continue
        for en in feed.entries[:40]:
            u = getattr(en, "link", "")
            if not u or u in seen: continue
            seen.add(u)
            out.append({"title": getattr(en, "title", "").strip(), "url": u,
                        "outlet": (getattr(en.source, "title", "") if getattr(en, "source", None) else ""),
                        "snippet": getattr(en, "summary", "")[:400], "date": None})
    return out


def keyword_ok(it):
    t = (it["title"] + " " + it["snippet"]).lower()
    if "table tennis" in t or "ping pong" in t: return False
    return any(k in t for k in TENNIS_HINT) and any(k in t for k in SPONSOR_HINT)


def existing_links():
    out = set()
    if not (SUPABASE_URL and SERVICE_ROLE): return out
    r = requests.get(f"{SUPABASE_URL}/rest/v1/news_posts",
                     params={"select": "link_url", "source": "eq.operator", "limit": "8000"},
                     headers={"apikey": SERVICE_ROLE, "Authorization": f"Bearer {SERVICE_ROLE}"}, timeout=40)
    if r.status_code == 200:
        out = {row["link_url"] for row in r.json() if row.get("link_url")}
    return out


PROMPT = """You curate a TENNIS sponsorship news feed. Decide if this item is genuinely about a tennis (not table tennis) sponsorship, partnership, endorsement, or commercial deal involving a player, club, academy, tournament, tour or federation.

If yes, write an editorial summary that doubles as positive EXPOSURE for the sponsor brand (name it; say what it sponsors and the visibility it gains). Stay factual; do not invent figures.

Return ONLY compact JSON:
{{"relevant": true|false,
  "headline": "<clean English headline <=90 chars>",
  "blurb": "<2-4 factual English sentences (~50-90 words)>",
  "author_name": "<sponsor brand or governing body, e.g. 'Nike' or 'ATP Tour'>",
  "category": "tournament|club|player|other",
  "country": "<ISO-3166 alpha-2 or null>"}}
If not clearly tennis sponsorship, return {{"relevant": false}}.

title: {title}
outlet: {outlet}
snippet: {snippet}
"""


def classify(client, it):
    try:
        msg = client.messages.create(model=CLAUDE_MODEL, max_tokens=320,
            messages=[{"role": "user", "content": PROMPT.format(title=it["title"], outlet=it["outlet"], snippet=it["snippet"])}])
        txt = "".join(b.text for b in msg.content if b.type == "text").strip().strip("`").strip()
        if txt.lower().startswith("json"): txt = txt[4:].strip()
        return json.loads(txt)
    except Exception:
        return {"relevant": False}


def insert(it, cls):
    body = {
        "title": (cls.get("headline") or it["title"])[:140],
        "body": cls.get("blurb") or "",
        "author_name": "GetTennisSponsors",
        "sponsor_name": cls.get("author_name") or None,
        "author_type": cls.get("category") if cls.get("category") in ("player", "club", "tournament", "other") else "other",
        "country": cls.get("country") or None,
        "link_url": it["url"],
        "source": "operator", "status": "published",
    }
    if it.get("date"): body["published_at"] = it["date"]
    if DRY_RUN:
        print("  [dry]", body["title"][:60], "|", body["author_type"]); return True
    r = requests.post(f"{SUPABASE_URL}/rest/v1/news_posts",
                      headers={"apikey": SERVICE_ROLE, "Authorization": f"Bearer {SERVICE_ROLE}",
                               "Content-Type": "application/json", "Prefer": "return=minimal"},
                      data=json.dumps(body), timeout=30)
    if r.status_code not in (200, 201, 204):
        print("  insert HTTP", r.status_code, r.text[:120]); return False
    return True


def main():
    if not ANTHROPIC_KEY: die("ANTHROPIC_API_KEY not set")
    if not DRY_RUN and not (SUPABASE_URL and SERVICE_ROLE): die("Supabase env not set")
    client = anthropic.Anthropic(api_key=ANTHROPIC_KEY)

    print(f"Collecting candidates from {START_YEAR}…")
    cands = collect_candidates()
    print(f"raw candidates: {len(cands)}")
    cands = [c for c in cands if c["title"] and keyword_ok(c)]
    print(f"after keyword filter: {len(cands)}")
    seen = existing_links()
    cands = [c for c in cands if c["url"] not in seen]
    print(f"after dedupe vs DB: {len(cands)} (target up to {MAX_ITEMS})")

    inserted = 0
    for it in cands:
        if inserted >= MAX_ITEMS:
            print(f"reached MAX_ITEMS={MAX_ITEMS}"); break
        cls = classify(client, it)
        if not cls.get("relevant"): continue
        if insert(it, cls): inserted += 1
        if inserted % 50 == 0: print(f"  inserted {inserted}…")
        time.sleep(0.25)
    print(f"done. inserted {inserted} item(s).")


if __name__ == "__main__":
    main()
