#!/usr/bin/env python3
"""
GetTennisSponsors — world news curation pipeline.

Collect tennis sponsorship / partnership news from Google News RSS + GDELT,
keep only items from a TRUSTED source allowlist, use Claude to verify
relevance and rewrite a clean English headline + blurb, then auto-publish
into Supabase `news_posts` (source='operator', status='published').

Env (set as GitHub Actions secrets):
  SUPABASE_URL            e.g. https://cvcpzzubmvqizykhcuog.supabase.co
  SUPABASE_SERVICE_ROLE   service_role key (SECRET — never commit / never client-side)
  ANTHROPIC_API_KEY       Claude API key
Optional:
  MAX_PUBLISH=10          cap inserts per run (default 10)
  DRY_RUN=1               fetch + classify but do not insert
"""
import os, sys, json, time, hashlib
from urllib.parse import quote_plus, urlparse

import requests
import feedparser
import anthropic

# ---- config ----------------------------------------------------------
QUERIES = [
    "tennis sponsorship",
    "tennis sponsor deal",
    "tennis title sponsor",
    "tennis partnership announced",
    "ITF sponsor", "ATP sponsor", "WTA sponsor",
    "tennis tournament sponsor",
]

# Only items whose article domain ends with one of these are eligible.
TRUSTED_DOMAINS = {
    "atptour.com", "wtatennis.com", "itftennis.com", "lta.org.uk",
    "tennis.com", "tennismajors.com", "ubitennis.net",
    "reuters.com", "apnews.com", "bbc.com", "espn.com",
    "sportspromedia.com", "sportbusiness.com", "sportcal.com",
    "insidethegames.biz", "sportsbusinessjournal.com",
    "marketingweek.com", "forbes.com",
    "prnewswire.com", "businesswire.com", "globenewswire.com",
}

CLAUDE_MODEL = os.environ.get("CLAUDE_MODEL", "claude-haiku-4-5-20251001")
MAX_PUBLISH = int(os.environ.get("MAX_PUBLISH", "10"))
DRY_RUN = os.environ.get("DRY_RUN") == "1"
LOOKBACK_DEDUPE = 400  # how many recent operator posts to check for dup links

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SERVICE_ROLE = os.environ.get("SUPABASE_SERVICE_ROLE", "")
ANTHROPIC_KEY = os.environ.get("ANTHROPIC_API_KEY", "")


def die(msg):
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def domain_of(url):
    try:
        d = urlparse(url).netloc.lower()
        return d[4:] if d.startswith("www.") else d
    except Exception:
        return ""


def trusted(url):
    d = domain_of(url)
    return any(d == t or d.endswith("." + t) for t in TRUSTED_DOMAINS)


# ---- collectors ------------------------------------------------------
def from_google_news():
    out = []
    for q in QUERIES:
        url = f"https://news.google.com/rss/search?q={quote_plus(q)}&hl=en-US&gl=US&ceid=US:en"
        try:
            feed = feedparser.parse(url)
        except Exception as e:
            print(f"  google news '{q}' failed: {e}")
            continue
        for e in feed.entries[:12]:
            link = getattr(e, "link", "")
            # Google News wraps the publisher; try source link if present
            src = ""
            if getattr(e, "source", None) and getattr(e.source, "href", None):
                src = e.source.href
            out.append({
                "title": getattr(e, "title", "").strip(),
                "snippet": getattr(e, "summary", "")[:600],
                "url": link,
                "outlet": (getattr(e.source, "title", "") if getattr(e, "source", None) else "") or domain_of(src or link),
                "domain_hint": domain_of(src or link),
            })
    return out


def from_gdelt():
    out = []
    q = '(tennis) (sponsor OR sponsorship OR partnership)'
    url = ("https://api.gdeltproject.org/api/v2/doc/doc?query="
           f"{quote_plus(q)}&mode=ArtList&maxrecords=40&format=json&sort=DateDesc")
    try:
        r = requests.get(url, timeout=30, headers={"User-Agent": "GTS-news/1.0"})
        arts = r.json().get("articles", [])
    except Exception as e:
        print(f"  gdelt failed: {e}")
        return out
    for a in arts:
        out.append({
            "title": (a.get("title") or "").strip(),
            "snippet": "",
            "url": a.get("url", ""),
            "outlet": a.get("domain", ""),
            "domain_hint": domain_of(a.get("url", "")),
        })
    return out


# ---- dedupe against existing rows ------------------------------------
def existing_links():
    if not (SUPABASE_URL and SERVICE_ROLE):
        return set()
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/news_posts",
        params={"select": "link_url", "source": "eq.operator",
                "order": "created_at.desc", "limit": str(LOOKBACK_DEDUPE)},
        headers={"apikey": SERVICE_ROLE, "Authorization": f"Bearer {SERVICE_ROLE}"},
        timeout=30,
    )
    if r.status_code != 200:
        print(f"  dedupe fetch HTTP {r.status_code}: {r.text[:200]}")
        return set()
    return {row["link_url"] for row in r.json() if row.get("link_url")}


# ---- Claude: relevance + clean rewrite --------------------------------
PROMPT = """You are curating a tennis sponsorship news feed. Given a raw news item, decide if it is genuinely about a TENNIS sponsorship, partnership, or commercial deal (a player, club, tournament, tour, or federation gaining/announcing a sponsor or commercial partner).

Return ONLY compact JSON:
{{"relevant": true|false, "headline": "<clean English headline, <=90 chars, factual, no clickbait>", "blurb": "<1-2 factual English sentences>", "country": "<ISO 3166-1 alpha-2 if clearly identifiable, else null>"}}

If it is not clearly a tennis sponsorship/partnership/commercial deal, return {{"relevant": false}} only.

RAW ITEM:
title: {title}
outlet: {outlet}
snippet: {snippet}
"""


def classify(client, item):
    try:
        msg = client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=300,
            messages=[{"role": "user", "content": PROMPT.format(
                title=item["title"], outlet=item["outlet"], snippet=item["snippet"])}],
        )
        text = "".join(b.text for b in msg.content if b.type == "text").strip()
        # tolerate code fences
        text = text.strip("` \n")
        if text.lower().startswith("json"):
            text = text[4:].strip()
        data = json.loads(text)
        return data
    except Exception as e:
        print(f"  classify failed: {e}")
        return {"relevant": False}


# ---- insert ----------------------------------------------------------
def insert(item, cls):
    body = {
        "title": cls.get("headline") or item["title"][:120],
        "body": cls.get("blurb") or "",
        "author_name": item["outlet"] or domain_of(item["url"]) or "Curated",
        "author_type": "operator",
        "country": (cls.get("country") or None),
        "link_url": item["url"],
        "source": "operator",
        "status": "published",
    }
    if DRY_RUN:
        print(f"  [dry-run] would publish: {body['title']}  ({body['author_name']})")
        return True
    r = requests.post(
        f"{SUPABASE_URL}/rest/v1/news_posts",
        headers={"apikey": SERVICE_ROLE, "Authorization": f"Bearer {SERVICE_ROLE}",
                 "Content-Type": "application/json", "Prefer": "return=minimal"},
        data=json.dumps(body), timeout=30,
    )
    if r.status_code not in (200, 201, 204):
        print(f"  insert HTTP {r.status_code}: {r.text[:200]}")
        return False
    print(f"  published: {body['title']}  ({body['author_name']})")
    return True


def main():
    if not ANTHROPIC_KEY:
        die("ANTHROPIC_API_KEY not set")
    if not DRY_RUN and not (SUPABASE_URL and SERVICE_ROLE):
        die("SUPABASE_URL / SUPABASE_SERVICE_ROLE not set")

    client = anthropic.Anthropic(api_key=ANTHROPIC_KEY)

    raw = from_google_news() + from_gdelt()
    print(f"fetched {len(raw)} raw items")

    # filter: has url, trusted domain, dedupe by url
    seen_links = existing_links()
    print(f"{len(seen_links)} existing operator links (dedupe set)")

    candidates, seen_now = [], set()
    for it in raw:
        u = it["url"]
        if not it["title"] or not u:
            continue
        if not trusted(u):
            continue
        if u in seen_links or u in seen_now:
            continue
        seen_now.add(u)
        candidates.append(it)
    print(f"{len(candidates)} trusted, de-duplicated candidates")

    published = 0
    for it in candidates:
        if published >= MAX_PUBLISH:
            print(f"reached MAX_PUBLISH={MAX_PUBLISH}; stopping")
            break
        cls = classify(client, it)
        if not cls.get("relevant"):
            continue
        if insert(it, cls):
            published += 1
        time.sleep(0.4)  # gentle pacing

    print(f"done. published {published} item(s).")


if __name__ == "__main__":
    main()
