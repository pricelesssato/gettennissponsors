-- =====================================================================
-- GetTennisSponsors — Member Studio
-- Member profiles + avatars, news image uploads, self publish/unpublish,
-- scheduled publishing (timezone-correct), all on Supabase Storage + RLS.
--
-- ⚠️ If Supabase errors "ALTER TYPE ... ADD VALUE cannot run inside a
-- transaction block", run the two ALTER TYPE lines on their own first,
-- then run the rest.
-- Run in SQL Editor after 11_news_slug.sql. Safe to re-run.
-- =====================================================================

-- ---- news status: add draft + scheduled (members manage visibility) --
alter type news_status add value if not exists 'draft';
alter type news_status add value if not exists 'scheduled';

-- ---- member profiles (SEPARATE from admin `profiles`; no role column) -
create table if not exists member_profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  member_type  text,          -- player / club / tournament / other
  country      char(2),
  bio          text,
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
drop trigger if exists trg_member_profiles_updated on member_profiles;
create trigger trg_member_profiles_updated before update on member_profiles
  for each row execute function set_updated_at();

alter table member_profiles enable row level security;
drop policy if exists p_member_self on member_profiles;
create policy p_member_self on member_profiles
  for all using (id = auth.uid()) with check (id = auth.uid());
drop policy if exists p_member_admin on member_profiles;
create policy p_member_admin on member_profiles
  for select using (is_admin());

-- ---- denormalized author avatar on posts (public display) ------------
alter table news_posts add column if not exists author_avatar text;

-- public view: expose author_avatar; still only status='published'
drop view if exists public_news;
create view public_news as
  select id, slug, title, body, author_name, author_avatar, sponsor_name, author_type,
         country, link_url, image_url, source,
         coalesce(published_at, created_at) as published_at
  from news_posts
  where status = 'published';
grant select on public_news to anon, authenticated;

-- ---- scheduled auto-publish: flip due posts to published -------------
-- (called hourly by the publish-scheduled workflow via service_role)
create or replace function publish_due() returns integer
language sql security definer set search_path = public as $$
  with upd as (
    update news_posts set status = 'published'
    where status::text = 'scheduled'
      and published_at is not null
      and published_at <= now()
    returning 1)
  select count(*)::int from upd;
$$;
revoke all on function publish_due() from public, anon, authenticated;
grant execute on function publish_due() to service_role;

-- ---- Storage buckets (public read) -----------------------------------
insert into storage.buckets (id, name, public) values ('avatars','avatars',true)
  on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('news-images','news-images',true)
  on conflict (id) do nothing;

-- Storage policies: anyone can READ; a signed-in user can WRITE only into
-- their own folder  <uid>/...  (prevents overwriting others' files).
drop policy if exists p_avatars_read on storage.objects;
create policy p_avatars_read on storage.objects for select using (bucket_id = 'avatars');
drop policy if exists p_avatars_write on storage.objects;
create policy p_avatars_write on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists p_avatars_update on storage.objects;
create policy p_avatars_update on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists p_newsimg_read on storage.objects;
create policy p_newsimg_read on storage.objects for select using (bucket_id = 'news-images');
drop policy if exists p_newsimg_write on storage.objects;
create policy p_newsimg_write on storage.objects for insert to authenticated
  with check (bucket_id = 'news-images' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists p_newsimg_update on storage.objects;
create policy p_newsimg_update on storage.objects for update to authenticated
  using (bucket_id = 'news-images' and (storage.foldername(name))[1] = auth.uid()::text);
