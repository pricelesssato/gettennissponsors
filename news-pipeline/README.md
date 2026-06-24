# news-pipeline — world tennis-sponsorship news curation

Daily job that collects tennis sponsorship/partnership news from **Google News RSS + GDELT**,
keeps only **trusted-source** items, uses **Claude** to verify relevance and write a clean
English headline + blurb, and **auto-publishes** into Supabase `news_posts`
(`source='operator'`, `status='published'`). Shows on gettennissponsors.com as **Curated**.

## How it runs
- `collect.py` — the job. `.github/workflows/news-curation.yml` — daily cron (22:00 UTC) + manual run.
- Auto-publish, trusted-source allowlist (edit `TRUSTED_DOMAINS` in `collect.py`).
- Dedupe by `link_url` against recent operator posts. Cap: `MAX_PUBLISH` (default 10/run).

## Keys (set as GitHub Actions secrets — do NOT commit, do NOT share service_role)
| Secret | Where to get it |
|---|---|
| `SUPABASE_URL` | `https://cvcpzzubmvqizykhcuog.supabase.co` |
| `SUPABASE_SERVICE_ROLE` | Supabase → Settings → API → `service_role` → Reveal/Copy (SECRET) |
| `ANTHROPIC_API_KEY` | console.anthropic.com → API Keys (reuse existing) |

Google News RSS and GDELT need **no API key**.

## Deploy (GitHub Actions — recommended, matches cs_pipeline)
1. Put this project in a GitHub repo (private is fine).
2. Repo → **Settings → Secrets and variables → Actions → New repository secret**: add the 3 above.
3. Repo → **Actions → news-curation → Run workflow** to test now. Daily cron runs automatically.

## Local test
```bash
pip install -r news-pipeline/requirements.txt
# preview without writing to DB (needs only Claude key):
DRY_RUN=1 ANTHROPIC_API_KEY=sk-ant-... python news-pipeline/collect.py
# real run (publishes):
SUPABASE_URL=https://cvcpzzubmvqizykhcuog.supabase.co \
SUPABASE_SERVICE_ROLE=... ANTHROPIC_API_KEY=sk-ant-... \
python news-pipeline/collect.py
```

## Tuning
- `TRUSTED_DOMAINS` — add/remove outlets (quality gate for auto-publish).
- `QUERIES` — search terms.
- `CLAUDE_MODEL` — default `claude-haiku-4-5-20251001` (cheap; fine for summarize/classify).
- To hide a published item before the admin console exists: Supabase → Table editor → `news_posts` → set `status='hidden'`.
