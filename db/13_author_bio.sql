-- =====================================================================
-- GetTennisSponsors — denormalize author bio onto posts (for article display)
-- Run in SQL Editor after 12_member_studio.sql. Safe to re-run.
-- =====================================================================
alter table news_posts add column if not exists author_bio text;

drop view if exists public_news;
create view public_news as
  select id, slug, title, body, author_name, author_avatar, author_bio, sponsor_name,
         author_type, country, link_url, image_url, source,
         coalesce(published_at, created_at) as published_at
  from news_posts
  where status = 'published';
grant select on public_news to anon, authenticated;
