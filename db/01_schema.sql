-- =====================================================================
-- GetTennisSponsors / SPONSOR OS — Phase 1 schema
-- Supabase (Postgres). snake_case. English-only data (free text accepts JP).
-- Confirmed 2026-06-23. See docs/sponsor-os-claude-code-handoff.md §5.
-- Run order: 01_schema.sql -> 02_rls.sql -> 03_seed.sql
-- =====================================================================

-- ---- Extensions ------------------------------------------------------
create extension if not exists pgcrypto;  -- gen_random_uuid()

-- ---- Enums -----------------------------------------------------------
do $$ begin
  create type user_role          as enum ('admin','staff','agent');
exception when duplicate_object then null; end $$;
do $$ begin
  create type sponsorable_type    as enum ('player','club','tournament','other');
exception when duplicate_object then null; end $$;
do $$ begin
  create type sponsorable_status  as enum ('draft','pending','published');
exception when duplicate_object then null; end $$;
do $$ begin
  create type company_source      as enum ('form','agent','direct','inbound');
exception when duplicate_object then null; end $$;
do $$ begin
  -- need category: A sales/leads, B brand/trust, C people/recruiting, D milestone
  create type need_category       as enum ('A','B','C','D');
exception when duplicate_object then null; end $$;
do $$ begin
  create type deal_stage          as enum ('prospect','approach','negotiating','contracted','live','renewal','lost');
exception when duplicate_object then null; end $$;
do $$ begin
  create type payout_basis        as enum ('initial_term','every_year');
exception when duplicate_object then null; end $$;
do $$ begin
  create type activity_type       as enum ('mail','call','visit','form','memo');
exception when duplicate_object then null; end $$;
do $$ begin
  create type contact_parent      as enum ('company','sponsorable');
exception when duplicate_object then null; end $$;

-- ---- updated_at helper ----------------------------------------------
create or replace function set_updated_at() returns trigger as $$
begin new.updated_at = now(); return new; end;
$$ language plpgsql;

-- ---- profiles (mirrors auth.users) ----------------------------------
create table if not exists profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  role          user_role not null default 'staff',
  name          text,
  email         text,
  agent_code    text unique,          -- Phase 3 referral links
  agent_profile jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
drop trigger if exists trg_profiles_updated on profiles;
create trigger trg_profiles_updated before update on profiles
  for each row execute function set_updated_at();

-- ---- contacts (polymorphic parent; no hard FK on parent) ------------
create table if not exists contacts (
  id          uuid primary key default gen_random_uuid(),
  name        text,
  title       text,
  email       text,
  phone       text,
  country     char(2),               -- ISO 3166-1 alpha-2
  belongs_to  contact_parent,        -- 'company' | 'sponsorable'
  parent_id   uuid,                  -- soft ref to companies.id or sponsorables.id
  note        text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
drop trigger if exists trg_contacts_updated on contacts;
create trigger trg_contacts_updated before update on contacts
  for each row execute function set_updated_at();

-- ---- sponsorables (single table; UI splits by type) -----------------
create table if not exists sponsorables (
  id                 uuid primary key default gen_random_uuid(),
  type               sponsorable_type not null,
  sport              text not null default 'tennis',     -- sport-agnostic schema, tennis-only launch
  name               text not null,
  location           text,
  country            char(2),
  period             text,                               -- e.g. 'Jul 2026'
  operator           text,                               -- tournament organiser
  details            jsonb not null default '{}'::jsonb, -- type-specific fields (rank, members, ITF class…)
  tiers              jsonb not null default '[]'::jsonb, -- ['Title','Main','Support','Supplier']
  open_slots         integer,
  price_range        text,                               -- internal asking range (not public)
  status             sponsorable_status not null default 'draft',
  is_published       boolean generated always as (status = 'published') stored,
  public_summary     text,                               -- safe teaser text (public)
  primary_contact_id uuid references contacts(id) on delete set null,
  notes              text,
  owner_id           uuid references profiles(id) on delete set null,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index if not exists idx_sponsorables_type    on sponsorables(type);
create index if not exists idx_sponsorables_pub      on sponsorables(is_published);
create index if not exists idx_sponsorables_country  on sponsorables(country);
drop trigger if exists trg_sponsorables_updated on sponsorables;
create trigger trg_sponsorables_updated before update on sponsorables
  for each row execute function set_updated_at();

-- ---- companies (demand side) ----------------------------------------
create table if not exists companies (
  id                 uuid primary key default gen_random_uuid(),
  name               text not null,
  industry           text,
  size               text,
  country            char(2),
  need_category      need_category,
  source             company_source not null default 'direct',
  primary_contact_id uuid references contacts(id) on delete set null,
  notes              text,
  owner_id           uuid references profiles(id) on delete set null,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index if not exists idx_companies_need on companies(need_category);
drop trigger if exists trg_companies_updated on companies;
create trigger trg_companies_updated before update on companies
  for each row execute function set_updated_at();

-- ---- deals (spine: company x sponsorable) ---------------------------
create table if not exists deals (
  id              uuid primary key default gen_random_uuid(),
  company_id      uuid references companies(id) on delete set null,
  sponsorable_id  uuid references sponsorables(id) on delete set null,
  stage           deal_stage not null default 'prospect',
  proposed_tier   text,
  activations     jsonb not null default '[]'::jsonb,   -- activation menu numbers
  amount          numeric(14,2),
  currency        char(3) not null default 'JPY',
  tc_fee_pct      numeric(5,2) not null default 20,
  -- generated: TC fee amount = amount * tc_fee_pct / 100
  tc_fee_amount   numeric(14,2) generated always as (round(coalesce(amount,0) * tc_fee_pct / 100, 2)) stored,
  agent_fee_pct   numeric(5,2),                          -- nullable; 5-10 typical
  payout_basis    payout_basis not null default 'initial_term',
  agent_id        uuid references profiles(id) on delete set null,
  owner_id        uuid references profiles(id) on delete set null,
  next_action     text,
  next_action_due date,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index if not exists idx_deals_stage        on deals(stage);
create index if not exists idx_deals_owner        on deals(owner_id);
create index if not exists idx_deals_company      on deals(company_id);
create index if not exists idx_deals_sponsorable  on deals(sponsorable_id);
drop trigger if exists trg_deals_updated on deals;
create trigger trg_deals_updated before update on deals
  for each row execute function set_updated_at();

-- agent payout (derived, not stored): amount * agent_fee_pct / 100
-- tc_net (derived): tc_fee_amount - agent_payout
-- Kept in views / app layer to avoid double-write. See public view below.

-- ---- activities (deal timeline) -------------------------------------
create table if not exists activities (
  id          uuid primary key default gen_random_uuid(),
  deal_id     uuid not null references deals(id) on delete cascade,
  occurred_on date not null default (now()::date),
  type        activity_type,
  body        text,
  user_id     uuid references profiles(id) on delete set null,
  created_at  timestamptz not null default now()
);
create index if not exists idx_activities_deal on activities(deal_id);

-- =====================================================================
-- Public teaser view (column-level safety for anon/agent).
-- Exposes ONLY safe columns of published sponsorables. No amount/contact.
-- =====================================================================
create or replace view public_sponsorables as
  select id, type, sport, name, location, country, period, tiers, public_summary
  from sponsorables
  where is_published = true;

-- Deal economics view (admin/staff use): adds agent payout + TC net.
create or replace view deal_economics as
  select d.*,
         round(coalesce(d.amount,0) * coalesce(d.agent_fee_pct,0) / 100, 2) as agent_payout,
         d.tc_fee_amount - round(coalesce(d.amount,0) * coalesce(d.agent_fee_pct,0) / 100, 2) as tc_net
  from deals d;
