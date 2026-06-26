-- =====================================================================
-- GetTennisSponsors — more TOURNAMENT and PLAYER news (real, sourced)
-- ADDITIVE. Model = 07. image_url null -> run backfill-photos afterwards.
-- =====================================================================

insert into news_posts (title, body, author_name, sponsor_name, author_type, country, link_url, source, status, published_at) values

-- ---- TOURNAMENTS (title sponsors) -----------------------------------
('BNP Paribas renews its title sponsorship of the Indian Wells Open',
 'BNP Paribas renewed its long-running title sponsorship of the BNP Paribas Open at Indian Wells, a partnership in place since 2009. The deal keeps the bank''s name on one of the most prestigious events outside the Grand Slams, repeatedly voted Tournament of the Year by players. Title sponsorship of a premier Masters event is among the most visible assets in tennis.',
 'GetTennisSponsors','BNP Paribas','tournament','US','https://usa.bnpparibas/en/bnp-paribas-renews-its-title-sponsorship-of-the-bnp-paribas-open-tennis-tournament/','operator','published','2024-03-01'),
('BNL and BNP Paribas anchor the Internazionali BNL d''Italia in Rome',
 'BNL, part of BNP Paribas, has been the title sponsor of the Rome Masters — the Internazionali BNL d''Italia — since 2007, one of the longest-running naming deals on the ATP Tour. The partnership gives the bank sustained exposure at a flagship European clay event. Longevity turns a title sponsorship into a deeply associated brand asset.',
 'GetTennisSponsors','BNL (BNP Paribas)','tournament','IT','https://group.bnpparibas/en/group/about-us/tennis','operator','published','2023-05-10'),
('Mutua Madrid Open: a two-decade naming partnership with Mutua Madrileña',
 'Insurer Mutua Madrileña has given the Madrid Masters its name — the Mutua Madrid Open — since 2006, anchoring one of the biggest combined ATP and WTA events. The deal delivers the brand prime visibility across a fortnight of high-profile tennis. It shows how a domestic insurer can build national prominence through a marquee event.',
 'GetTennisSponsors','Mutua Madrileña','tournament','ES','https://mutuamadridopen.com/en/sponsors/','operator','published','2024-04-25'),
('National Bank Open keeps Canada''s Masters event front of mind',
 'Canada''s Masters event runs as the National Bank Open presented by Rogers, pairing two major Canadian brands on one of the tour''s most historic tournaments. The naming and presenting structure gives both partners strong domestic and international exposure. It is a model for layering title and presenting sponsors on a single property.',
 'GetTennisSponsors','National Bank','tournament','CA','https://en.wikipedia.org/wiki/2025_National_Bank_Open','operator','published','2025-08-05'),
('Western & Southern lent its name to the Cincinnati Masters for two decades',
 'Financial group Western & Southern was the long-time title sponsor of the Cincinnati Masters, branded the Western & Southern Open from 2011. The deal gave the Cincinnati-based firm national visibility through a top hard-court event in the US Open Series. It illustrates how a regional company can scale its profile via tennis.',
 'GetTennisSponsors','Western & Southern','tournament','US','https://en.wikipedia.org/wiki/Cincinnati_Open','operator','published','2023-08-15'),
('Wortmann AG secures naming rights to the Halle grass-court event',
 'Wortmann AG took the naming rights to the Halle ATP 500, rebranding it the Terra Wortmann Open from 2022. The German grass-court event is a key Wimbledon warm-up, giving the brand prime visibility during the grass swing. Acquiring a tournament''s name is a fast route to category-leading exposure.',
 'GetTennisSponsors','Terra Wortmann (Wortmann AG)','tournament','DE','https://en.wikipedia.org/wiki/Halle_Open','operator','published','2022-06-13'),
('Dubai Duty Free fronts one of the Middle East''s flagship tennis events',
 'Dubai Duty Free is the long-standing title sponsor of the Dubai Duty Free Tennis Championships, a premier stop drawing many of the world''s top players. The naming deal gives the retailer global broadcast exposure and ties it to Dubai''s status as a sports-events hub. It is a cornerstone of tennis''s growing Gulf presence.',
 'GetTennisSponsors','Dubai Duty Free','tournament','AE','https://www.atptour.com/en/tournaments','operator','published','2024-02-26'),
('Banc Sabadell names the Barcelona Open',
 'Banc Sabadell is the title sponsor of the Barcelona Open Banc Sabadell, a historic ATP 500 on clay. The partnership keeps the bank''s name on a beloved Spanish event with strong local and international following. Title sponsorship of a heritage tournament builds durable brand affinity.',
 'GetTennisSponsors','Banc Sabadell','tournament','ES','https://www.atptour.com/en/tournaments','operator','published','2024-04-15'),
('Kinoshita Group backs the Japan Open in Tokyo',
 'The Kinoshita Group is the title sponsor of the Kinoshita Group Japan Open Tennis Championships in Tokyo, one of Asia''s premier ATP events. The deal gives the Japanese company high-profile exposure in a key home market and across the tour''s Asian swing. It shows how domestic conglomerates use tennis to build brand stature.',
 'GetTennisSponsors','Kinoshita Group','tournament','JP','https://www.atptour.com/en/tournaments','operator','published','2023-10-16'),

-- ---- PLAYERS --------------------------------------------------------
('adidas expands its tennis roster with Tsitsipas, Pegula and Svitolina',
 'adidas added Stefanos Tsitsipas, Jessica Pegula and Elina Svitolina to a roster already including Alexander Zverev and Grigor Dimitrov for 2025. The signings deepen adidas''s on-court visibility across both tours at a time when it has been gaining ground on rivals. A broad stable of stars multiplies a brand''s exposure event after event.',
 'GetTennisSponsors','adidas','player',null,'https://www.tennisnerd.net/gear/pro-player-sponsorship-changes-in-2025/43834','operator','published','2025-01-10'),
('Nike counts Aryna Sabalenka among its marquee WTA faces',
 'World No. 1 Aryna Sabalenka is among the WTA stars with the biggest followings in Nike''s roster, giving the brand a dominant on-court presence in women''s tennis. After a standout 2024, her marketability has continued to climb. Top-ranked ambassadors deliver brands consistent visibility at the latter stages of every major.',
 'GetTennisSponsors','Nike','player','BY','https://www.si.com/onsi/serve/news/pay-her-aryna-sabalenka-deserves-more-endorsement-deals-after-2024','operator','published','2024-11-01'),
('Daniil Medvedev continues his racquet partnership with Tecnifibre',
 'Daniil Medvedev remained with Tecnifibre, tweaking his string setup for 2025 while keeping the French brand on his frame. The partnership gives Tecnifibre elite validation through a former Grand Slam champion. Racquet and string deals turn a player''s equipment choices into ongoing brand proof points.',
 'GetTennisSponsors','Tecnifibre','player','RU','https://www.tennisnerd.net/gear/pro-player-sponsorship-changes-in-2025/43834','operator','published','2024-01-15');
