-- =====================================================================
-- The Paint Patch HQ — storage for the Netlify version of HQ
-- Run AFTER paint_patch_hq.sql. Safe to re-run.
-- HQ saves its records as documents (one per area: tasks, parties, ...),
-- exactly as it does on claude.ai, so every feature works unchanged.
-- Roles come from HQ's own "Settings & people" list; the owner comes
-- from hq_profiles (see the snippet at the end of paint_patch_hq.sql).
-- =====================================================================

create table if not exists hq_docs (
  path        text primary key,          -- 'state/tasks', 'requests/<user id>' ...
  data        jsonb not null,
  updated_at  timestamptz not null default now()
);
alter table hq_docs replica identity full;

-- Role of the signed-in user: owner from hq_profiles, otherwise from HQ's people list
create or replace function hq_doc_role() returns text
language sql stable security definer set search_path = public as $$
  select coalesce(
    (select 'owner' from hq_profiles where id = auth.uid() and role = 'owner' and active),
    (select p->>'role'
       from hq_docs d, jsonb_array_elements((d.data->>'json')::jsonb) p
      where d.path = 'state/people' and p->>'uid' = auth.uid()::text
      limit 1))
$$;

create or replace function hq_is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(hq_doc_role() in ('owner','ops'), false)
$$;

create or replace function hq_is_member() returns boolean
language sql stable security definer set search_path = public as $$
  select hq_doc_role() is not null
$$;

-- paths only owner / Ops Manager may read, and only they may write
create or replace function hq_admin_read(p text) returns boolean
language sql immutable as $$
  select p in ('state/threads','state/transactions','state/hr') or p = 'requests' or (p like 'requests/%')
$$;
create or replace function hq_admin_write(p text) returns boolean
language sql immutable as $$
  select p in ('state/threads','state/transactions','state/hr','state/people','state/settings','state/knowledge',
               'state/integrations','state/automations','state/venues','state/bookings') or p like 'requests/%'
$$;

alter table hq_docs enable row level security;

drop policy if exists hq_docs_read on hq_docs;
create policy hq_docs_read on hq_docs for select to authenticated using (
  path = 'requests/' || auth.uid()::text
  or (hq_is_member() and (not hq_admin_read(path) or hq_is_admin()))
);

drop policy if exists hq_docs_insert on hq_docs;
create policy hq_docs_insert on hq_docs for insert to authenticated with check (
  path = 'requests/' || auth.uid()::text
  or (hq_is_member() and (not hq_admin_write(path) or hq_is_admin()))
);

drop policy if exists hq_docs_update on hq_docs;
create policy hq_docs_update on hq_docs for update to authenticated
  using (path = 'requests/' || auth.uid()::text or (hq_is_member() and (not hq_admin_write(path) or hq_is_admin())))
  with check (path = 'requests/' || auth.uid()::text or (hq_is_member() and (not hq_admin_write(path) or hq_is_admin())));

drop policy if exists hq_docs_delete on hq_docs;
create policy hq_docs_delete on hq_docs for delete to authenticated using (
  path = 'requests/' || auth.uid()::text or hq_is_admin()
);

-- Live updates between devices
do $$ begin
  alter publication supabase_realtime add table hq_docs;
exception when duplicate_object then null; when undefined_object then null; end $$;

-- Who am I (used at sign-in)
create or replace function hq_me() returns jsonb
language sql stable security definer set search_path = public, auth as $$
  select jsonb_build_object(
    'id', u.id, 'email', u.email,
    'name', coalesce(nullif(pr.full_name, ''), u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)),
    'role', hq_doc_role())
  from auth.users u left join hq_profiles pr on pr.id = u.id
  where u.id = auth.uid()
$$;

-- Names for people / access requests (members only)
create or replace function hq_user_names(ids uuid[]) returns table (id uuid, name text, email text)
language sql stable security definer set search_path = public, auth as $$
  select u.id, coalesce(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)),
         case when hq_is_admin() then u.email end
  from auth.users u where u.id = any(ids) and hq_is_member()
$$;

-- "Add a person" search in Settings & people (owner / Ops only)
create or replace function hq_find_users(q text) returns table (id uuid, name text, email text)
language sql stable security definer set search_path = public, auth as $$
  select u.id, coalesce(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)), u.email
  from auth.users u
  where hq_is_admin() and length(q) >= 2
    and (u.email ilike '%' || q || '%' or (u.raw_user_meta_data->>'full_name') ilike '%' || q || '%')
  limit 8
$$;

grant execute on function hq_me(), hq_user_names(uuid[]), hq_find_users(text) to authenticated;
