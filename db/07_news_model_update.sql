-- =====================================================================
-- GetTennisSponsors — news model update
-- (1) Separate POSTER (GetTennisSponsors for AI-curated) from the SPONSOR
--     brand we highlight -> new column sponsor_name.
-- (2) Re-categorise: drop the "Editorial" category; classify by subject
--     into tournament / club / player / other (Other includes events/misc).
-- Run in Supabase SQL Editor after 06_news_backfill.sql. Safe to re-run.
-- =====================================================================

alter table news_posts add column if not exists sponsor_name text;

-- poster becomes GetTennisSponsors for AI-curated items; keep the brand in sponsor_name
update news_posts set sponsor_name = author_name where source = 'operator' and sponsor_name is null;
update news_posts set author_name = 'GetTennisSponsors' where source = 'operator';

-- ---- categorise by subject ------------------------------------------
update news_posts set author_type = 'player' where source = 'operator' and title in (
  'Danone signs Carlos Alcaraz as a global ambassador',
  'Carlos Alcaraz tops 2025 endorsement earnings with a deep brand roster',
  'Gucci and Lavazza headline Jannik Sinner''s commercial portfolio',
  'New Balance powers Coco Gauff, the world''s highest-paid female athlete',
  'Oshee becomes a headline sponsor for Iga Swiatek',
  'ASICS signs Lorenzo Musetti to a multi-year apparel deal',
  'Hubert Hurkacz switches to adidas apparel and a new Wilson racquet',
  'Madison Keys switches to a Yonex Ezone',
  'Lululemon expands into tennis with Frances Tiafoe');

update news_posts set author_type = 'tournament' where source = 'operator' and title in (
  'PIF and EQT named official partners of the 2026 HSBC Championships',
  'HSBC becomes title sponsor of the Queen''s Club Championships',
  'Nitto Denko extends ATP Finals title partnership through 2030',
  'Bank of China (Hong Kong) renews title sponsorship of the Hong Kong Tennis Open',
  'Miami Open expands its global partnership portfolio for 2026',
  'Betsson named Official Sports Betting Partner of the Davis Cup',
  'US Open confirms its 2026 partner roster');

update news_posts set author_type = 'other' where source = 'operator' and title in (
  'Mercedes-Benz becomes the WTA''s Premier and Exclusive Automobile Partner',
  'ATP and EQT announce global partnership through 2030',
  'Verizon lands landmark U.S. partnership with the ATP and WTA Tours',
  'Tennis Channel and Sinclair open a single U.S. sponsorship gateway for the ATP and WTA',
  'adidas overtakes Nike for on-court presence at the 2025 US Open');

-- event-roster items have no single sponsor brand to highlight
update news_posts set sponsor_name = null  where source = 'operator' and title = 'US Open confirms its 2026 partner roster';
update news_posts set sponsor_name = 'Itaú' where source = 'operator' and title = 'Miami Open expands its global partnership portfolio for 2026';

-- public view: expose sponsor_name too.
-- DROP first — create-or-replace cannot reorder/rename existing view columns.
drop view if exists public_news;
create view public_news as
  select id, title, body, author_name, sponsor_name, author_type, country, link_url, image_url, source,
         coalesce(published_at, created_at) as published_at
  from news_posts
  where status = 'published';
grant select on public_news to anon, authenticated;
