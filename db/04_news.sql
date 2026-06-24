-- =====================================================================
-- GetTennisSponsors — News / Press module
-- Login REQUIRED to post (no anonymous). Publish immediately.
-- Operator can hide + email a correction request.
-- Run after 01-03. Idempotent-ish (guards on enum/table).
-- =====================================================================

do $$ begin
  create type news_author_type as enum ('player','club','tournament','operator','other');
exception when duplicate_object then null; end $$;
do $$ begin
  create type news_source as enum ('self','operator');
exception when duplicate_object then null; end $$;
do $$ begin
  create type news_status as enum ('published','hidden');
exception when duplicate_object then null; end $$;

create table if not exists news_posts (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  body         text,
  author_name  text not null,                       -- displayed poster (e.g. tournament name)
  author_type  news_author_type not null default 'other',
  country      char(2),
  link_url     text,                                -- source link (esp. operator-curated)
  image_url    text,
  source       news_source not null default 'self',
  status       news_status not null default 'published',
  owner_id     uuid references auth.users(id) on delete set null,  -- the logged-in poster
  author_email text,                                -- denormalized for operator correction email
  published_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists idx_news_status on news_posts(status);
create index if not exists idx_news_owner  on news_posts(owner_id);

-- updated_at
drop trigger if exists trg_news_updated on news_posts;
create trigger trg_news_updated before update on news_posts
  for each row execute function set_updated_at();

-- on insert: force owner/email from the JWT (prevents spoofing); stamp published_at.
create or replace function news_set_owner() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null then
    new.owner_id := auth.uid();
    new.author_email := coalesce(auth.jwt()->>'email', new.author_email);
  end if;
  if new.status = 'published' and new.published_at is null then
    new.published_at := now();
  end if;
  return new;
end $$;
drop trigger if exists trg_news_owner on news_posts;
create trigger trg_news_owner before insert on news_posts
  for each row execute function news_set_owner();

-- ---- RLS -------------------------------------------------------------
alter table news_posts enable row level security;

-- read: anyone may read PUBLISHED; owner reads own; admin reads all
drop policy if exists p_news_read_pub on news_posts;
create policy p_news_read_pub on news_posts for select using (status = 'published');
drop policy if exists p_news_read_own on news_posts;
create policy p_news_read_own on news_posts for select using (owner_id = auth.uid());
drop policy if exists p_news_read_admin on news_posts;
create policy p_news_read_admin on news_posts for select using (is_admin());

-- insert: must be authenticated and own the row (login REQUIRED)
drop policy if exists p_news_insert on news_posts;
create policy p_news_insert on news_posts for insert to authenticated
  with check (owner_id = auth.uid());

-- update: owner edits own; admin can hide/edit any
drop policy if exists p_news_update on news_posts;
create policy p_news_update on news_posts for update
  using (owner_id = auth.uid() or is_admin())
  with check (owner_id = auth.uid() or is_admin());

-- delete: owner or admin
drop policy if exists p_news_delete on news_posts;
create policy p_news_delete on news_posts for delete
  using (owner_id = auth.uid() or is_admin());

-- ---- public view (safe columns; no email) ---------------------------
create or replace view public_news as
  select id, title, body, author_name, author_type, country, link_url, image_url, source,
         coalesce(published_at, created_at) as published_at
  from news_posts
  where status = 'published';

grant select on public_news to anon, authenticated;
grant select, insert, update, delete on news_posts to authenticated;

-- ---- seed: a couple of operator-curated + self posts ----------------
insert into news_posts (title, body, author_name, author_type, country, link_url, source, status, published_at)
values
('ITF Maebashi Open secures title sponsor for 2026',
 'The ITF Maebashi Open has signed a title sponsor for its July 2026 edition, expanding on-site and year-round digital activation.',
 'ITF Maebashi Open','tournament','JP',null,'self','published', now()),
('Bangkok Smash Academy partners with regional apparel brand',
 'Bangkok Smash Academy announced a multi-year apparel partnership supporting its junior program.',
 'Bangkok Smash Academy','club','TH',null,'self','published', now()),
('Global: luxury brands deepen tennis sponsorship in 2026',
 'Operator-curated roundup of how global brands are expanding tennis sponsorships this season.',
 'Reuters (curated)','operator','GB','https://www.reuters.com/','operator','published', now());
