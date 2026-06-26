#!/usr/bin/env python3
"""
Fill news_posts.image_url with relevant, license-clear photos from Pexels.
Pexels License = free for commercial use, no attribution required.

Picks a tennis photo whose query matches the article category (and varies by
row id so the feed isn't repetitive). Updates only rows missing image_url.

Env:
  SUPABASE_URL, SUPABASE_SERVICE_ROLE   (service_role — server-side only)
  PEXELS_API_KEY                        (free: https://www.pexels.com/api/)
Optional:
  OVERWRITE=1   refresh image_url even if already set
"""
import os, sys, json, hashlib
import requests

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SERVICE_ROLE = os.environ.get("SUPABASE_SERVICE_ROLE", "")
PEXELS_KEY = os.environ.get("PEXELS_API_KEY", "")
OVERWRITE = os.environ.get("OVERWRITE") == "1"

# category -> rotation of search queries (variety + relevance)
QUERIES = {
    "tournament": ["tennis stadium crowd", "tennis tournament court", "tennis arena night", "tennis umpire court"],
    "player":     ["tennis player serve", "professional tennis action", "tennis player celebration", "tennis forehand"],
    "club":       ["tennis club court", "tennis court aerial", "clay tennis court", "tennis net close up"],
    "other":      ["tennis racket and ball", "tennis court lines", "tennis grand slam", "tennis equipment"],
}

def die(m): print("ERROR:", m, file=sys.stderr); sys.exit(1)

def h(s): return int(hashlib.md5(str(s).encode()).hexdigest(), 16)

def pexels(query, pick):
    r = requests.get("https://api.pexels.com/v1/search",
                     params={"query": query, "per_page": 15, "orientation": "landscape"},
                     headers={"Authorization": PEXELS_KEY}, timeout=30)
    if r.status_code != 200:
        print(f"  pexels HTTP {r.status_code} for '{query}': {r.text[:120]}"); return None
    photos = r.json().get("photos", [])
    if not photos: return None
    p = photos[pick % len(photos)]
    return p.get("src", {}).get("landscape") or p.get("src", {}).get("large")

def rows():
    params = {"select": "id,title,author_type,image_url", "source": "eq.operator", "limit": "500"}
    r = requests.get(f"{SUPABASE_URL}/rest/v1/news_posts", params=params,
                     headers={"apikey": SERVICE_ROLE, "Authorization": f"Bearer {SERVICE_ROLE}"}, timeout=30)
    r.raise_for_status(); return r.json()

def update(id, url):
    r = requests.patch(f"{SUPABASE_URL}/rest/v1/news_posts",
                       params={"id": f"eq.{id}"},
                       headers={"apikey": SERVICE_ROLE, "Authorization": f"Bearer {SERVICE_ROLE}",
                                "Content-Type": "application/json", "Prefer": "return=minimal"},
                       data=json.dumps({"image_url": url}), timeout=30)
    return r.status_code in (200, 204)

def main():
    if not (SUPABASE_URL and SERVICE_ROLE): die("SUPABASE_URL / SUPABASE_SERVICE_ROLE not set")
    if not PEXELS_KEY: die("PEXELS_API_KEY not set (free key: https://www.pexels.com/api/)")
    data = rows(); done = 0
    for row in data:
        if row.get("image_url") and not OVERWRITE: continue
        cat = row.get("author_type") if row.get("author_type") in QUERIES else "other"
        qs = QUERIES[cat]
        hid = h(row["id"])
        url = pexels(qs[hid % len(qs)], hid // 7)
        if not url: print(f"  no photo for {row['title'][:50]}"); continue
        if update(row["id"], url): done += 1; print(f"  set photo: {row['title'][:50]}")
    print(f"done. updated {done} row(s).")

if __name__ == "__main__":
    main()
