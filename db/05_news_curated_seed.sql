-- =====================================================================
-- GetTennisSponsors — real curated news seed (manual, for the ITF demo)
-- Replaces the fictional sample news with real, sourced items.
-- Run in Supabase SQL Editor after 04_news.sql. Safe to re-run (delete+insert).
-- This is a manual preview of what news-pipeline/ will automate.
-- =====================================================================

delete from news_posts where title in (
  'ITF Maebashi Open secures title sponsor for 2026',
  'Bangkok Smash Academy partners with regional apparel brand',
  'Global: luxury brands deepen tennis sponsorship in 2026'
);

insert into news_posts (title, body, author_name, author_type, country, link_url, source, status, published_at) values
('ATP and EQT announce global partnership through 2030',
 'The ATP named investment firm EQT its first official private markets partner and a Platinum Partner, activating across ATP Masters 1000, 500 and 250 events through 2030.',
 'ATP Tour','operator',null,'https://www.atptour.com/en/news/atp-eqt-partnership-announcement-june-2026','operator','published', now()),
('ATP and WTA secure landmark U.S. partnership with Verizon',
 'Verizon became the first telecommunications partner of the ATP and the official telecoms partner of both tours in the U.S., with 5G category exclusivity under a multi-year deal.',
 'ATP Tour','operator','US','https://www.atptour.com/en/news/verizon-announcement-2025','operator','published', now() - interval '6 hours'),
('PIF and EQT become official partners of the HSBC Championships',
 'Saudi Arabia''s Public Investment Fund and EQT signed multi-year deals as official partners of the LTA''s Queen''s Club Championships (the HSBC Championships).',
 'LTA','operator','GB','https://www.lta.org.uk/news/2026/june/new-atp-global-partners-announced-for-2026-hsbc-championships/','operator','published', now() - interval '12 hours'),
('Miami Open expands its global partnership portfolio for 2026',
 'The Miami Open presented by Itau confirmed returning platinum sponsors — including PIF, Cadillac, Emirates and Lacoste — and added new partners for 2026.',
 'Miami Open','operator','US','https://www.miamiopen.com/latest-news/miami-open-expands-global-partnership-portfolio/','operator','published', now() - interval '1 day'),
('LTA unveils major sponsors ahead of the 2026 grass-court season',
 'The LTA announced its sponsor line-up ahead of the 2026 British grass-court swing.',
 'Sportcal','operator','GB','https://www.sportcal.com/news/lta-unveils-major-sponsors-ahead-of-2026-grass-court-tournaments/','operator','published', now() - interval '2 days'),
('Betsson named Official Sports Betting Partner of the Davis Cup',
 'Betsson partnered with the Davis Cup, the World Cup of Tennis, as its official sports betting partner for 2026.',
 'ITF','operator',null,'https://www.itftennis.com/en/about-us/organisation/commercial-partners/','operator','published', now() - interval '3 days'),
('US Open confirms its 2026 partner roster',
 'The US Open published its slate of official partners for the 2026 championships.',
 'US Open','operator','US','https://www.usopen.org/en_US/about/partners.html','operator','published', now() - interval '4 days');
