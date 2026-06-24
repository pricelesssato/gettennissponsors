-- =====================================================================
-- GetTennisSponsors / SPONSOR OS — Phase 1 RLS & public intake
-- Run after 01_schema.sql. See handoff §6.
-- Principles:
--   admin = all; staff = read all + own deals write; agent = published list only;
--   anon (public site) = read public_sponsorables view + submit intake via RPC only.
-- =====================================================================

-- ---- role helpers (SECURITY DEFINER to read profiles safely) --------
create or replace function auth_role() returns user_role
language sql stable security definer set search_path = public as $$
  select role from profiles where id = auth.uid();
$$;
create or replace function is_admin() returns boolean
language sql stable as $$ select auth_role() = 'admin'; $$;
create or replace function is_staff_or_admin() returns boolean
language sql stable as $$ select auth_role() in ('admin','staff'); $$;

-- ---- enable RLS ------------------------------------------------------
alter table profiles      enable row level security;
alter table contacts      enable row level security;
alter table sponsorables  enable row level security;
alter table companies     enable row level security;
alter table deals         enable row level security;
alter table activities    enable row level security;

-- ---- profiles --------------------------------------------------------
drop policy if exists p_profiles_self on profiles;
create policy p_profiles_self on profiles
  for select using (id = auth.uid() or is_admin());
drop policy if exists p_profiles_admin on profiles;
create policy p_profiles_admin on profiles
  for all using (is_admin()) with check (is_admin());

-- ---- sponsorables ----------------------------------------------------
-- staff/admin: full. agent: read published only. (anon uses the view, not the table)
drop policy if exists p_sp_staff_all on sponsorables;
create policy p_sp_staff_all on sponsorables
  for all using (is_staff_or_admin()) with check (is_staff_or_admin());
drop policy if exists p_sp_agent_read on sponsorables;
create policy p_sp_agent_read on sponsorables
  for select using (is_published and auth_role() = 'agent');

-- ---- companies / contacts / deals / activities: staff+admin only -----
drop policy if exists p_companies_staff on companies;
create policy p_companies_staff on companies
  for all using (is_staff_or_admin()) with check (is_staff_or_admin());

drop policy if exists p_contacts_staff on contacts;
create policy p_contacts_staff on contacts
  for all using (is_staff_or_admin()) with check (is_staff_or_admin());

-- deals: admin all; staff read all but only writes own (owner_id) unless admin
drop policy if exists p_deals_read on deals;
create policy p_deals_read on deals
  for select using (is_staff_or_admin());
drop policy if exists p_deals_write on deals;
create policy p_deals_write on deals
  for all using (is_admin() or owner_id = auth.uid())
  with check (is_admin() or owner_id = auth.uid());

drop policy if exists p_activities_staff on activities;
create policy p_activities_staff on activities
  for all using (is_staff_or_admin()) with check (is_staff_or_admin());

-- =====================================================================
-- Public read: grant the safe VIEW to anon (no base-table access)
-- =====================================================================
grant usage on schema public to anon;
grant select on public_sponsorables to anon;

-- =====================================================================
-- Public intake RPCs (SECURITY DEFINER) — the ONLY anon write path.
-- Supply: list-your-opening -> sponsorables(status='pending', unpublished).
-- Demand: become-a-sponsor  -> companies(source='inbound') + intake note.
-- Returns void; never exposes internal rows back to anon.
-- =====================================================================

-- Supply-side application (player/club/tournament/other)
create or replace function submit_sponsor_application(
  p_type    text,
  p_name    text,
  p_country text,
  p_reach   text,
  p_email   text
) returns void
language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if p_name is null or length(trim(p_name)) = 0 then
    raise exception 'name required';
  end if;
  insert into sponsorables(type, name, country, public_summary, status, details)
  values (
    coalesce(nullif(p_type,'')::sponsorable_type, 'other'),
    p_name,
    nullif(p_country,''),
    left(coalesce(p_reach,''), 2000),
    'pending',
    jsonb_build_object('applicant_email', p_email, 'submitted_at', now())
  )
  returning id into v_id;
end $$;

-- Demand-side consultation request (sponsor company)
create or replace function submit_consult_request(
  p_company text,
  p_country text,
  p_goal    text,   -- 'A'|'B'|'C'|'D'
  p_message text,
  p_email   text
) returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_company is null or length(trim(p_company)) = 0 then
    raise exception 'company required';
  end if;
  insert into companies(name, country, need_category, source, notes)
  values (
    p_company,
    nullif(p_country,''),
    nullif(p_goal,'')::need_category,
    'inbound',
    concat_ws(E'\n', 'Inbound consult request', concat('email: ', p_email), p_message)
  );
end $$;

revoke all on function submit_sponsor_application(text,text,text,text,text) from public;
revoke all on function submit_consult_request(text,text,text,text,text)   from public;
grant execute on function submit_sponsor_application(text,text,text,text,text) to anon;
grant execute on function submit_consult_request(text,text,text,text,text)   to anon;
