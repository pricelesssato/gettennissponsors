#!/usr/bin/env python3
"""
Fill news_posts.image_url with relevant, license-clear photos from Pexels.
Pexels License = free for commercial use, no attribution required.

Strategy (variety + coverage in few API calls):
  1. Build a large per-category PHOTO POOL once (several queries x up to 80
     results each), de-duplicated GLOBALLY so no photo repeats across cats.
  2. Assign each post a DISTINCT photo from its category pool (round-robin),
     so the same image never shows up twice on one screen.
This needs only ~dozens of Pexels calls total (not one per post), so it scales
to thousands of posts without hitting the hourly rate limit.

Env: SUPABASE_URL, SUPABASE_SERVICE_ROLE, PEXELS_API_KEY
Optional: OVERWRITE=1  (re-assign photos to ALL posts, not just missing ones)
"""
import os, sys, json, hashlib
import requests

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SERVICE_ROLE = os.environ.get("SUPABASE_SERVICE_ROLE", "")
PEXELS_KEY = os.environ.get("PEXELS_API_KEY", "")
OVERWRITE = os.environ.get("OVERWRITE") == "1"

QUERIES = {
    "tournament": ["tennis tournament", "tennis stadium crowd", "tennis arena", "tennis court aerial",
                   "tennis umpire", "grand slam tennis", "tennis match night", "tennis spectators"],
    "player":     ["tennis player serve", "tennis forehand", "professional tennis match", "tennis backhand",
                   "tennis player celebration", "woman tennis player", "tennis player action", "tennis volley"],
    "club":       ["tennis club", "tennis court", "clay tennis court", "tennis net",
                   "tennis academy", "grass tennis court", "indoor tennis court", "tennis lesson"],
    "other":      ["tennis racket and ball", "tennis court lines", "tennis equipment", "tennis ball close up",
                   "tennis racquet", "tennis sponsorship", "tennis branding", "tennis fans"],
}

def die(m): print("ERROR:", m, file=sys.stderr); sys.exit(1)
def h(s): return int(hashlib.md5(str(s).encode()).hexdigest(), 16)

def search(q, seen):
    out = []
    r = requests.get("https://api.pexels.com/v1/search",
                     params={"query": q, "per_page": 80, "orientation": "landscape"},
                     headers={"Authorization": PEXELS_KEY}, timeout=30)
    if r.status_code != 200:
        print(f"  pexels HTTP {r.status_code} for '{q}': {r.text[:100]}"); return out
    for p in r.json().get("photos", []):
        u = p.get("src", {}).get("landscape") or p.get("src", {}).get("large")
        if u and u not in seen:
            seen.add(u); out.append(u)
    return out

def build_pools():
    seen, pools = set(), {}
    for cat, qs in QUERIES.items():
        pool = []
        for q in qs:
            pool += search(q, seen)
        pools[cat] = pool
        print(f"  pool[{cat}] = {len(pool)} photos")
    return pools

def rows():
    out, offset = [], 0
    while True:
        r = requests.get(f"{SUPABASE_URL}/rest/v1/news_posts",
                         params={"select": "id,author_type,image_url", "order": "id",
                                 "limit": "1000", "offset": str(offset)},
                         headers={"apikey": SERVICE_ROLE, "Authorization": f"Bearer {SERVICE_ROLE}"}, timeout=40)
        r.raise_for_status(); batch = r.json()
        out += batch
        if len(batch) < 1000: break
        offset += 1000
    return out

def update(id, url):
    r = requests.patch(f"{SUPABASE_URL}/rest/v1/news_posts", params={"id": f"eq.{id}"},
                       headers={"apikey": SERVICE_ROLE, "Authorization": f"Bearer {SERVICE_ROLE}",
                                "Content-Type": "application/json", "Prefer": "return=minimal"},
                       data=json.dumps({"image_url": url}), timeout=30)
    return r.status_code in (200, 204)

def main():
    if not (SUPABASE_URL and SERVICE_ROLE): die("SUPABASE env not set")
    if not PEXELS_KEY: die("PEXELS_API_KEY not set (free: https://www.pexels.com/api/)")

    print("Building photo pools…")
    pools = build_pools()
    allrows = rows()
    print(f"{len(allrows)} posts total")

    # group by category, assign distinct photos round-robin
    bycat = {}
    for row in allrows:
        c = row.get("author_type") if row.get("author_type") in pools else "other"
        bycat.setdefault(c, []).append(row)

    done = 0
    for cat, items in bycat.items():
        pool = pools.get(cat) or pools.get("other") or []
        if not pool:
            print(f"  no pool for {cat}; skipping"); continue
        items.sort(key=lambda r: r["id"])              # stable order
        start = h(cat) % len(pool)                       # spread categories apart
        for i, row in enumerate(items):
            if row.get("image_url") and not OVERWRITE:
                continue
            url = pool[(start + i) % len(pool)]
            if update(row["id"], url):
                done += 1
        print(f"  {cat}: assigned ({len(items)} posts)")
    print(f"done. updated {done} post(s).")

if __name__ == "__main__":
    main()
