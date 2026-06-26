-- =====================================================================
-- GetTennisSponsors — short shareable permalinks (YouTube-style codes)
-- Adds an 8-char base62 `slug` to each post -> /s/<slug>.
-- Run in Supabase SQL Editor. Safe to re-run.
-- =====================================================================

-- 8-char base62 code generator (volatile -> unique per row)
create or replace function gts_slug() returns text
language plpgsql volatile as $$
declare s text := ''; chars text := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'; i int;
begin
  for i in 1..8 loop
    s := s || substr(chars, floor(random()*length(chars))::int + 1, 1);
  end loop;
  return s;
end $$;

alter table news_posts add column if not exists slug text;

-- backfill any missing slugs (retry-safe for the tiny chance of a collision)
do $$
declare r record; cand text;
begin
  for r in select id from news_posts where slug is null loop
    loop
      cand := gts_slug();
      begin
        update news_posts set slug = cand where id = r.id;
        exit;
      exception when unique_violation then
        -- try another code
      end;
    end loop;
  end loop;
end $$;

create unique index if not exists idx_news_slug on news_posts(slug);
alter table news_posts alter column slug set default gts_slug();

-- expose slug in the public view
drop view if exists public_news;
create view public_news as
  select id, slug, title, body, author_name, sponsor_name, author_type, country, link_url, image_url, source,
         coalesce(published_at, created_at) as published_at
  from news_posts
  where status = 'published';
grant select on public_news to anon, authenticated;
