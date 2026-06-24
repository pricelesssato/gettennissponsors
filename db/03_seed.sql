-- =====================================================================
-- GetTennisSponsors / SPONSOR OS — Phase 1 seed (mirrors the mock)
-- Safe to run on an empty DB. owner_id left null (set after creating admin).
-- =====================================================================

-- ---- sponsorables (single table; mixed types) -----------------------
insert into sponsorables (type, name, country, location, period, operator, details, tiers, open_slots, price_range, status, public_summary)
values
('player','Yuki Nakamura','JP','Gunma, JP',null,null,
   '{"itf_rank":420,"instagram":12000}','["Apparel","Racquet","Social"]',3,'¥0.3–0.8M','published',
   'Rising Japanese junior climbing the ITF ranks. Strong, growing social following — a fit for brands wanting an authentic, early athlete story.'),
('player','Mei Tanaka','JP','Tokyo, JP',null,null,
   '{"title":"National U18 champion","followers":28000}','["Apparel","Equipment"]',2,'¥0.5–1.2M','published',
   'National U18 champion with an engaged audience. Ideal for brands targeting youth, family and aspirational sport.'),
('player','Liam Carter','GB','London, GB',null,null,
   '{"discipline":"wheelchair","world_rank":15}','["Apparel","Travel","Social"]',3,'£3–9k','pending',
   'Top-20 wheelchair player with a powerful inclusion & resilience narrative. Excellent CSR and brand-values alignment.'),
('club','Maebashi Tennis Club','JP','Gunma, JP',null,null,
   '{"members":800,"courts":12}','["Naming","Court","Event"]',3,'¥0.4–1.5M','published',
   'Established regional club with 800 members and steady local footfall. Great for businesses wanting durable local awareness and goodwill.'),
('club','Bangkok Smash Academy','TH','Bangkok, TH',null,null,
   '{"students":300}','["Naming","Apparel","Event"]',3,'$5–15k','published',
   'Fast-growing junior academy in Bangkok. A way into the Southeast Asian youth tennis market with kit and event branding.'),
('tournament','ITF Maebashi Open','JP','Gunma, JP','Jul 2026','Sports Sunrise',
   '{"itf_class":"World Tennis Tour","surface":"hard"}','["Title","Main","Support","Supplier"]',5,'¥0.4–1.5M','published',
   'International ITF tournament in Gunma, Japan. On-site exposure plus year-round digital exposure and measured results.'),
('tournament','ITF Asia Circuit Package','SG','5 events across Asia','Jul–Dec 2026','Sports Sunrise',
   '{"events":5}','["Title","Main"]',4,'¥3.0–6.0M','published',
   'Six months of pan-Asian exposure across five ITF events in one package. Built for brands expanding across Asia.'),
('tournament','ITF Takasaki Challenge','JP','Gunma, JP','Sep 2026','Sports Sunrise',
   '{"itf_class":"World Tennis Tour"}','["Main","Support"]',6,'¥0.3–0.9M','published',
   'ITF tournament with recruiting-booth and community options. A fit for employer branding and local presence.'),
('other','Junior Development Program','JP','6 prefectures, JP',null,null,
   '{"scope":"grassroots","prefectures":6}','["Naming","Scholarship"]',2,'¥1.0–3.0M','published',
   'A grassroots junior development program across six prefectures. Long-term CSR and pipeline-building for community-minded brands.'),
('other','AceCam (tennis creator)','JP','JP',null,null,
   '{"youtube":85000,"niche":"technique"}','["Integration","Product"]',2,'¥0.2–0.6M','pending',
   'Popular tennis technique creator on YouTube. Product placement and integrated content for equipment and lifestyle brands.');

-- ---- companies (demand side) ----------------------------------------
insert into companies (name, industry, size, country, need_category, source, notes) values
('Yamada Sports','Retail','SME','JP','A','agent','Interested via form outreach; leads + awareness.'),
('Aozora Foods','Food','SME','JP','A','inbound','Referred by agent T. Tanaka.'),
('Maebashi Tech','IT','SME','JP','C','direct','Employer branding via recruiting booth.'),
('Gunma Seikotsu Group','Healthcare','SME','JP','B','direct','Renewal pending; CSR + expertise proof.'),
('North Resort','Travel','SME','JP','B','agent','Referred by agent R. Sasaki.'),
('Apex Rackets','Equipment','SME','SG','B','agent','International + expertise. Won via agent M. Wong.');

-- ---- deals (spine) — link company x sponsorable ---------------------
insert into deals (company_id, sponsorable_id, stage, amount, currency, tc_fee_pct, agent_fee_pct, payout_basis, proposed_tier, activations)
select c.id, s.id, v.stage::deal_stage, v.amount, 'JPY', 20, v.agent_pct, 'initial_term'::payout_basis, v.tier, v.activations::jsonb
from (values
  ('Yamada Sports','ITF Asia Circuit Package','negotiating',1200000, null, 'Main','[3,4,11]'),
  ('Aozora Foods','ITF Maebashi Open','prospect',         600000, 5,    'Support','[1,12]'),
  ('Maebashi Tech','ITF Maebashi Open','live',            900000, null, 'Main','[9,4,11]'),
  ('Gunma Seikotsu Group','ITF Maebashi Open','renewal',  500000, null, 'Support','[5,6]'),
  ('North Resort','ITF Takasaki Challenge','prospect',    400000, 7,    'Support','[4,7]'),
  ('Apex Rackets','ITF Asia Circuit Package','live',     1500000, 8,    'Main','[4,7,11]')
) as v(company, sponsorable, stage, amount, agent_pct, tier, activations)
join companies c     on c.name = v.company
join sponsorables s  on s.name = v.sponsorable;

-- sanity: derived economics
-- select name, amount, tc_fee_amount, agent_payout, tc_net from deal_economics
--   join companies using (...) ;  -- see deal_economics view
