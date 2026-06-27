-- =====================================================================
-- GetTennisSponsors / SPONSOR OS — CRM admin console support
-- Run after 03_seed.sql (and anytime after). Safe to re-run.
--   * companies.referrer  — who introduced this prospect (紹介者)
--   * companies.website    — prospect company URL
--   * activities can now attach to a COMPANY (not only a deal):
--       deal_id becomes nullable, new company_id column added.
--       => per-prospect communication log (やりとり) without a deal.
-- =====================================================================

alter table companies  add column if not exists referrer text;
alter table companies  add column if not exists website  text;

alter table activities alter column deal_id drop not null;
alter table activities add column if not exists company_id uuid
  references companies(id) on delete cascade;
create index if not exists idx_activities_company on activities(company_id);

-- Optional integrity: an activity should hang off a deal OR a company.
do $$ begin
  alter table activities
    add constraint activities_parent_chk
    check (deal_id is not null or company_id is not null);
exception when duplicate_object then null; end $$;
