-- =====================================================================
-- GetTennisSponsors — 5-year news backfill (2021–2026), incl. CLUBS
-- ADDITIVE: inserts new curated items (does not delete existing 06/07 rows).
-- Model = 07: author_name 'GetTennisSponsors', brand in sponsor_name,
-- author_type = tournament/club/player/other. image_url left null ->
-- run the backfill-photos workflow afterwards to attach photos.
-- Safe to run once. Re-running duplicates rows (dedupe by link_url if needed).
-- =====================================================================

insert into news_posts (title, body, author_name, sponsor_name, author_type, country, link_url, source, status, published_at) values

-- ---- CLUBS / ACADEMIES ----------------------------------------------
('Rafa Nadal Academy carries Movistar''s name in a long-running partnership',
 'Telefonica''s Movistar is the naming partner of the Rafa Nadal Academy by Movistar in Manacor, Spain — one of tennis''s most prominent training institutions. The partnership gives Movistar continuous brand association with elite player development and a global stream of visiting young athletes and families. It is a model for how a club or academy can anchor a long-term corporate naming deal.',
 'GetTennisSponsors','Movistar','club','ES','https://www.rafanadalacademy.com/en/sponsors/','operator','published','2021-09-01'),
('Rafa Nadal Academy expands to the Middle East with Tamdeen Group',
 'The Rafa Nadal Academy partnered with Kuwaiti property developer Tamdeen Group to launch a major international academy in the Middle East. For Tamdeen, attaching its name to the Nadal brand brings prestige and a destination tennis facility to its development. It shows how academies extend their brand — and their sponsors — across borders.',
 'GetTennisSponsors','Tamdeen Group','club','KW','https://international.rafanadalacademy.com/en/','operator','published','2021-11-01'),

-- ---- TOURS / GOVERNING BODIES (other) -------------------------------
('Hologic becomes the WTA''s title sponsor in the biggest deal in tour history',
 'In 2022 medical-technology company Hologic became title partner of the Hologic WTA Tour — the largest global sponsorship in WTA history and Hologic''s first worldwide sponsorship. Hologic is integrated across the tour, including net signage at all WTA events and virtual advertising at WTA 1000 and 500 tournaments. The deal tied a healthcare brand to a platform for women''s wellness and equality.',
 'GetTennisSponsors','Hologic','other','US','https://www.wtatennis.com/news/2512028/hologic-partners-with-wta-tour-in-landmark-title-sponsorship','operator','published','2022-03-08'),
('ATP and PIF launch a multi-year strategic partnership',
 'In February 2024 the ATP and Saudi Arabia''s Public Investment Fund unveiled a multi-year strategic partnership, with PIF becoming the official naming partner of the PIF ATP Rankings and a partner of marquee events including Indian Wells, Miami, Madrid, Beijing and the Nitto ATP Finals. The deal placed PIF at the centre of men''s tennis and signalled the Gulf''s growing role in the sport''s commercial future.',
 'GetTennisSponsors','Public Investment Fund (PIF)','other','SA','https://www.atptour.com/en/news/atp-pif-strategic-partnership-february-2024','operator','published','2024-02-22'),
('ATP and Haier announce a global partnership',
 'Home-appliance maker Haier signed a global partnership with the ATP Tour in 2023, earning on-court visibility at major events including the Nitto ATP Finals, the Internazionali BNL d''Italia, the Rolex Paris Masters and the Barcelona Open. The deal extended Haier''s tennis presence alongside its work with Roland-Garros, giving the brand pan-tour exposure.',
 'GetTennisSponsors','Haier','other','CN','https://www.atptour.com/en/news/atp-haier-global-partnership-april-2023','operator','published','2023-04-05'),
('Sky secures five-year media partnerships with the ATP and WTA Tours',
 'Broadcaster Sky agreed new five-year partnerships with ATP Media and WTA Ventures, bringing more than 80 tournaments and 4,000 matches to Sky Sports, NOW and WOW. The agreement deepens Sky''s tennis rights and gives tour sponsors a major European broadcast window. It reflects rising demand for premium tennis content.',
 'GetTennisSponsors','Sky','other','GB','https://www.atptour.com/en/news/sky-partnerships-atp-wta-2024','operator','published','2024-09-01'),
('ATP Tour reports record sponsorship growth for 2024',
 'The ATP Tour grew sponsorship revenue by 50% versus 2023, with new global partners since 2023 including PIF, Lexus, Yokohama, Haier, Waterdrop, LONGi Solar, OFX and FitLine, alongside renewals with Infosys, Lacoste and Dunlop. The figures show how much commercial momentum tennis has built and why brands are buying in.',
 'GetTennisSponsors',null,'other','GB','https://www.atptour.com/en/news/atp-tour-delivers-record-sponsorship-revenues-growth-2024','operator','published','2024-12-05'),
('Emirates and Rolex remain the only brands to sponsor all four Grand Slams',
 'Emirates and Rolex stand out as the only companies sponsoring every Grand Slam, giving each brand year-round presence at the sport''s biggest stages. For sponsors, Grand Slam portfolios offer unmatched global reach across the Australian Open, Roland-Garros, Wimbledon and the US Open. It illustrates the premium placed on the majors.',
 'GetTennisSponsors','Emirates','other','AE','https://www.scoreandchange.com/grand-slam-sponsors/','operator','published','2022-06-01'),

-- ---- TOURNAMENTS ----------------------------------------------------
('Kia extends its Australian Open partnership through 2028',
 'Kia extended its long-running Australian Open agreement in January 2023, continuing one of tennis''s most established automotive sponsorships through 2028. The deal keeps Kia visible across the season''s first Grand Slam, from fleet and on-site branding to broadcast. Long renewals like this anchor a tournament''s commercial identity.',
 'GetTennisSponsors','Kia','tournament','AU','https://ausopen.com/partners','operator','published','2023-01-18'),
('Aperol becomes the Official Aperitif of the Australian Open',
 'Tennis Australia announced a partnership with Campari Australia in December 2023, making Aperol the Official Aperitif of the Australian Open from AO 2024 in a multi-year collaboration. The deal links a leading drinks brand to the festival atmosphere of the season-opening Grand Slam. It shows how lifestyle brands buy into the AO''s entertainment appeal.',
 'GetTennisSponsors','Aperol (Campari)','tournament','AU','https://www.tennis.com.au/about-tennis-australia/our-partners','operator','published','2023-12-12'),
('Haier partners with Roland-Garros and the French Tennis Federation',
 'Haier extended its tennis push with a partnership around Roland-Garros in association with the French Tennis Federation. The deal gives the appliance brand exposure at one of the sport''s most-watched events and complements its ATP Tour partnership. It is part of Haier''s broader strategy to build global brand awareness through tennis.',
 'GetTennisSponsors','Haier','tournament','FR','https://www.atptour.com/en/news/atp-haier-global-partnership-april-2023','operator','published','2023-05-20'),

-- ---- PLAYERS --------------------------------------------------------
('Naomi Osaka attracts a wave of global sponsors after back-to-back majors',
 'After winning the 2020 US Open and the 2021 Australian Open, Naomi Osaka became one of the most marketable athletes in the world, with brands lining up behind her Nike-led portfolio. Her appeal showed how a Grand Slam champion can deliver cross-category exposure for apparel and lifestyle partners. Osaka helped redefine the commercial ceiling for tennis players.',
 'GetTennisSponsors','Nike','player','JP','https://www.tennismajors.com/others-news/top-sponsored-tennis-players-and-their-biggest-brand-deals-814901.html','operator','published','2021-02-20'),
('Emma Raducanu signs a string of blue-chip deals after her US Open title',
 'Emma Raducanu''s breakthrough 2021 US Open win triggered a run of premium partnerships, with Dior among the luxury brands building campaigns around her. For those brands, Raducanu offered youth, global appeal and a compelling story. It was one of the fastest commercial rises tennis has seen.',
 'GetTennisSponsors','Dior','player','GB','https://www.tennismajors.com/others-news/top-sponsored-tennis-players-and-their-biggest-brand-deals-814901.html','operator','published','2022-02-01'),
('Rolex signs Alexander Zverev as a brand ambassador',
 'Watchmaker Rolex added Alexander Zverev to its roster of tennis ambassadors, reinforcing the brand''s deep ties to the sport''s elite. The partnership gives Rolex visibility through a top-ranked player across the global calendar. Watch brands remain among tennis''s most prestigious and enduring sponsors.',
 'GetTennisSponsors','Rolex','player','DE','https://www.tennismajors.com/others-news/top-sponsored-tennis-players-and-their-biggest-brand-deals-814901.html','operator','published','2021-06-10'),
('Roger Federer remains a sponsorship powerhouse with Uniqlo',
 'Even while playing a limited 2021 schedule, Roger Federer earned a reported $80m-plus from sponsors, anchored by his apparel deal with Uniqlo. Federer''s enduring marketability shows how brand value in tennis can outlast on-court activity. He set the template for the modern athlete-as-brand.',
 'GetTennisSponsors','Uniqlo','player','CH','https://www.globaldata.com/data-insights/sport/most-active-brands-sponsoring-tennis/','operator','published','2021-08-15'),
('HUGO BOSS builds its tennis presence with Matteo Berrettini',
 'HUGO BOSS deepened its tennis sponsorship through ambassador Matteo Berrettini, dressing the Italian on and off court. The partnership gives the fashion house visibility at premier events and aligns it with a marketable European star. It reflects fashion''s growing appetite for tennis.',
 'GetTennisSponsors','HUGO BOSS','player','IT','https://group.hugoboss.com/en/sponsorship/sports-sponsorship/tennis','operator','published','2022-05-10'),
('Jannik Sinner signs a landmark apparel deal with Nike',
 'Jannik Sinner agreed a major multi-year apparel partnership with Nike — reported as one of the largest in tennis — placing the Italian among the brand''s flagship faces. For Nike, Sinner offers global reach and a rising-champion narrative. The scale of the deal underlined tennis''s commercial pull in 2023.',
 'GetTennisSponsors','Nike','player','IT','https://www.tennisnerd.net/gear/tennis-clothing-sponsorships-in-2023/30967','operator','published','2023-03-15'),
('Andrey Rublev teams with Bulgari to launch his own line',
 'Andrey Rublev partnered with luxury house Bulgari, joining the wave of tennis players collaborating with high-end brands. The tie-up gives Bulgari association with a Top-10 player and his global following. Player-brand collaborations like this turn athletes into co-creators rather than just endorsers.',
 'GetTennisSponsors','Bulgari','player','RU','https://www.tennisnerd.net/gear/tennis-clothing-sponsorships-in-2023/30967','operator','published','2023-04-20'),
('Sloane Stephens joins Free People',
 'Former US Open champion Sloane Stephens signed with lifestyle brand Free People, broadening the brand''s move into tennis. The partnership pairs a Grand Slam champion with a fashion label seeking athletic credibility. It is another sign of lifestyle brands entering the tennis space.',
 'GetTennisSponsors','Free People','player','US','https://www.tennisnerd.net/gear/tennis-clothing-sponsorships-in-2023/30967','operator','published','2023-05-05'),
('Waterdrop signs Novak Djokovic as a global partner',
 'Hydration brand Waterdrop partnered with Novak Djokovic, one of the sport''s most recognisable champions, as it scaled internationally — and later became an ATP Tour partner too. The association gives Waterdrop reach through a global icon and a presence across the men''s tour. It shows how a challenger brand can use tennis to go global fast.',
 'GetTennisSponsors','Waterdrop','player','RS','https://www.tennismajors.com/others-news/top-sponsored-tennis-players-and-their-biggest-brand-deals-814901.html','operator','published','2022-07-15');
