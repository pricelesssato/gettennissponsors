-- =====================================================================
-- GetTennisSponsors — global CLUB / academy / team-league sponsorship news
-- ADDITIVE (does not delete). Boosts the thin "Clubs" category worldwide.
-- Model = 07. image_url null -> run backfill-photos afterwards.
-- =====================================================================

insert into news_posts (title, body, author_name, sponsor_name, author_type, country, link_url, source, status, published_at) values

('ASICS and the Mouratoglou Academy announce a global partnership',
 'ASICS signed a global partnership with the Mouratoglou Academy, equipping more than 100 coaches across its sites in France, Atlanta, Florida and Kuala Lumpur with ASICS performance footwear. The deal gives ASICS visibility at one of the world''s best-known academies and a direct line to the next generation of players and coaches. It shows how equipment brands invest in development pipelines, not just touring pros.',
 'GetTennisSponsors','ASICS','club','FR','https://corp.asics.com/en/press/article/2025-06-18_mouratoglou-academy','operator','published','2025-06-18'),
('Dunlop (Sumitomo Rubber) becomes an official supplier to the Mouratoglou Academy',
 'Sumitomo Rubber Industries'' Dunlop brand established an official supplier agreement with the Mouratoglou Academy to support the development and training of top young players. The partnership puts Dunlop equipment in front of elite juniors and coaches across the academy''s programmes. Supplier deals at academies build brand loyalty early in a player''s career.',
 'GetTennisSponsors','Dunlop (Sumitomo Rubber)','club','FR','https://www.srigroup.co.jp/english/newsrelease/2019/sp/2019_s13.html','operator','published','2021-03-10'),
('Mouratoglou Academy opens its first U.S. location in Florida',
 'Patrick Mouratoglou''s academy expanded to the United States, opening a Zephyrhills, Florida site through a partnership with a local tennis operator and announced during the US Open. The move extends the Mouratoglou brand — and the sponsors attached to it — into the large American market. Academy expansion is a growth engine for everyone partnered with the brand.',
 'GetTennisSponsors',null,'club','US','https://floridatennis.com/blogs/news/the-grand-opening-of-mouratoglou-academy-zephyrhills','operator','published','2024-09-07'),
('ASICS and the Rohan Bopanna Tennis Academy partner to develop Indian talent',
 'ASICS India and the Rohan Bopanna Tennis Academy partnered to support young Indian players with products, technology-led education and grassroots access. For ASICS, the tie-up builds brand presence in one of tennis''s fastest-growing markets through a respected national academy. It is a blueprint for brand-building via local development partnerships.',
 'GetTennisSponsors','ASICS','club','IN','https://www.business-standard.com/sports/business/asics-rohan-bopanna-academy-join-hands-to-nurture-young-tennis-players-126062400783_1.html','operator','published','2026-06-24'),
('ATP and Juss launch a Performance & Development Center in Shanghai',
 'The ATP and Juss established an ATP Performance & Development Center with the Juss International Tennis Academy in Shanghai, providing world-class training, rehabilitation and technology for players from China and across Asia. The flagship facility deepens the ATP''s footprint in a strategic growth market. Development hubs like this create premium environments that attract partners.',
 'GetTennisSponsors',null,'club','CN','https://www.atptour.com/en/news/shanghai-welcomes-key-tennis-developments','operator','published','2023-10-01'),
('ATP partners with PacificPine Sports across China and Hong Kong',
 'The ATP began a multi-year partnership with PacificPine Sports to engage junior players and young fans in China and Hong Kong and expand grassroots opportunities. The deal gives PacificPine association with the men''s tour while growing the game regionally. It reflects how clubs and development operators leverage tour partnerships for credibility.',
 'GetTennisSponsors','PacificPine Sports','club','CN','https://www.pacificpinesports.com/tennis','operator','published','2023-02-01'),
('Tennis-Point holds the naming rights to Germany''s top team-tennis league',
 'Retailer Tennis-Point holds the naming rights to Germany''s premier team competition, played as the Tennis-Point-Bundesliga, where ten clubs compete each summer. In the league, club sponsors are often woven directly into team names, turning local businesses into visible backers. It is one of the most developed club-sponsorship ecosystems in tennis.',
 'GetTennisSponsors','Tennis-Point','club','DE','https://en.wikipedia.org/wiki/Tennis_Bundesliga_(men)','operator','published','2022-07-01'),
('GEICO served as presenting sponsor of World TeamTennis',
 'Insurance brand GEICO was the presenting sponsor of World TeamTennis, the U.S. team competition co-founded by Billie Jean King that fields city-based franchises. The deal gave GEICO league-wide exposure across a broadcast-friendly, fan-focused format. Team-tennis franchises offer brands a club-style platform distinct from the individual tour.',
 'GetTennisSponsors','GEICO','club','US','https://en.wikipedia.org/wiki/World_TeamTennis','operator','published','2021-07-01'),
('David Lloyd Clubs extends its tennis partnership with Judy Murray',
 'UK health-and-racquet operator David Lloyd Clubs renewed a multi-year partnership with coach Judy Murray after a double-digit rise in junior tennis participation across its clubs. The tie-up strengthens David Lloyd''s tennis credentials across its large UK and European club network. Club chains increasingly use marquee tennis figures to drive participation and membership.',
 'GetTennisSponsors','David Lloyd Clubs','club','GB','https://www.davidlloyd.co.uk/','operator','published','2023-04-01'),

-- ---- developmental tours / media (other) ----------------------------
('Diadem Sports becomes the official ball partner of the UTR Pro Tennis Tour Europe',
 'Diadem Sports was named official ball partner of the UTR Pro Tennis Tour Europe, the developmental circuit giving aspiring pros a pathway upward. The deal puts Diadem equipment in play across a fast-growing tour and in front of up-and-coming talent. Developmental tours are an efficient way for equipment brands to reach the next wave of players.',
 'GetTennisSponsors','Diadem Sports','other','US','https://www.utrsports.net/blogs/press/diadem-sports-becomes-official-ball-partner-for-utr-pro-tennis-tour-europe','operator','published','2024-05-01'),
('Sportradar partners with the UTR Pro Tennis Tour for data and streaming',
 'Sportradar partnered with UTR Sports to deliver real-time data and streaming for more than 20,000 UTR Pro Tennis Tour matches a year from January 2025. The deal expands the commercial and broadcast footprint of grassroots-to-pro tennis. Data partnerships like this make smaller events sponsor- and bettor-friendly at scale.',
 'GetTennisSponsors','Sportradar','other','CH','https://sportradar.com/content-hub/blog/ace-your-game-utr-pro-tennis-tour-serves-up-a-new-era-with-sportradar/','operator','published','2025-01-15'),
('The WTA extends its media-rights partnership with Tennis Channel through 2032',
 'The WTA extended its media-rights deal with Tennis Channel through 2032, securing a long-term U.S. home for women''s tennis. The agreement gives the tour and its sponsors a stable, premium broadcast platform for years to come. Long media deals underpin the commercial value brands buy into.',
 'GetTennisSponsors','Tennis Channel','other','US','https://www.nbcdfw.com/news/business/money-report/womens-tennis-association-extends-media-rights-deal-with-tennis-channel-through-2032/3871512/','operator','published','2024-06-01');
