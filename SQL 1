-- =====================================================================
-- The Paint Patch HQ — Supabase schema
-- All HQ tables are prefixed hq_ so they never clash with tables already in
-- your Supabase project (e.g. an existing profiles table).
-- Paste into Supabase → SQL Editor → New query → Run. Safe to re-run.
-- Mirrors the records in HQ (hq_venues, people, hq_knowledge, hq_bookings, hq_parties,
-- inbox, hq_approvals, hq_tasks, hq_cases, hq_checklists, hq_stock, HR, hq_integrations, log)
-- with role-based Row Level Security: owner / ops / lead / staff.
-- UK GDPR: candidate and customer contact data are restricted by role;
-- set retention in the "retention" section at the bottom.
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------- types ----------
do $$ begin
  create type hq_role as enum ('owner','ops','lead','staff');
exception when duplicate_object then null; end $$;

-- ---------- hq_venues ----------
create table if not exists hq_venues (
  id          text primary key,                 -- 'mk', 'hat', 'bham' ...
  name        text not null,
  short_name  text not null,
  status      text not null default 'planned' check (status in ('trading','planned','closed')),
  address     text,
  created_at  timestamptz not null default now()
);

-- ---------- people (one row per login) ----------
create table if not exists hq_profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null default '',
  email       text,
  role        hq_role not null default 'staff',
  venue_id    text references hq_venues(id),
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);

-- Permission matrix per role (owner edits in Settings & people)
create table if not exists hq_role_permissions (
  role                hq_role primary key,
  all_sites           boolean not null default false,
  inbox               boolean not null default false,
  finance             boolean not null default false,
  contact             boolean not null default false,
  edit_knowledge      boolean not null default false,
  manage_automations  boolean not null default false,
  manage_people       boolean not null default false,
  hr                  boolean not null default false,
  approve_kinds       text[] not null default '{}'
);

alter table hq_role_permissions add column if not exists marketing boolean not null default false;

create table if not exists hq_access_requests (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  email       text,
  full_name   text,
  status      text not null default 'pending' check (status in ('pending','approved','declined')),
  decided_by  uuid references hq_profiles(id),
  created_at  timestamptz not null default now(),
  unique (user_id)
);

-- ---------- helper functions used by RLS ----------
create or replace function hq_my_role() returns hq_role
language sql stable security definer set search_path = public as $$
  select role from hq_profiles where id = auth.uid() and active
$$;

create or replace function hq_my_venue() returns text
language sql stable security definer set search_path = public as $$
  select venue_id from hq_profiles where id = auth.uid() and active
$$;

create or replace function hq_can(perm text) returns boolean
language sql stable security definer set search_path = public as $$
  select case
    when hq_my_role() = 'owner' then true
    when hq_my_role() is null then false
    else coalesce((
      select case perm
        when 'all_sites' then all_sites  when 'inbox' then inbox
        when 'finance' then finance      when 'contact' then contact
        when 'edit_knowledge' then edit_knowledge
        when 'manage_automations' then manage_automations
        when 'manage_people' then manage_people
        when 'hr' then hr when 'marketing' then marketing else false end
      from hq_role_permissions where role = hq_my_role()), false)
  end
$$;

-- Can the current user see records for this venue? (null venue = company-wide)
create or replace function hq_sees_venue(v text) returns boolean
language sql stable security definer set search_path = public as $$
  select hq_my_role() is not null
     and (v is null or hq_can('all_sites') or v = hq_my_venue())
$$;

create or replace function hq_can_approve(kind text) returns boolean
language sql stable security definer set search_path = public as $$
  select hq_my_role() = 'owner'
      or exists (select 1 from hq_role_permissions where role = hq_my_role() and kind = any(approve_kinds))
$$;

-- ---------- hq_knowledge (prices, policies, procedures, templates) ----------
create table if not exists hq_knowledge (
  id              uuid primary key default gen_random_uuid(),
  key             text not null,                 -- e.g. 'party.price', 'policy.ownCake'
  kind            text not null check (kind in ('price','policy','procedure','template','fact')),
  title           text not null,
  venue_id        text references hq_venues(id),    -- null = all sites
  value_num       numeric(10,2),
  value_text      text,
  source          text,                          -- 'Website', 'Owner', 'ROLLER' ...
  version         int not null default 1,
  effective_from  date not null default current_date,
  status          text not null default 'active' check (status in ('active','superseded','needs_review')),
  owner_id        uuid references hq_profiles(id),
  created_at      timestamptz not null default now()
);
create index if not exists knowledge_key_idx on hq_knowledge (key, venue_id, effective_from desc);

-- ---------- hq_customers & hq_bookings ----------
create table if not exists hq_customers (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  email       text,
  phone       text,
  marketing_consent boolean not null default false,
  consent_at  timestamptz,
  created_at  timestamptz not null default now()
);
create unique index if not exists customers_email_uq on hq_customers (lower(email)) where email is not null;

create table if not exists hq_bookings (
  id          uuid primary key default gen_random_uuid(),
  external_ref text,                             -- ROLLER booking ref
  source      text not null default 'manual',    -- 'roller','csv','manual','outlook'
  venue_id    text not null references hq_venues(id),
  customer_id uuid references hq_customers(id),
  product     text,
  kind        text not null default 'session' check (kind in ('session','party','group','event')),
  room        text,
  booking_date date not null,
  start_time  time,
  end_time    time,
  guests      int,
  status      text not null default 'confirmed' check (status in ('enquiry','confirmed','moved','cancelled','completed')),
  total       numeric(10,2),
  paid        numeric(10,2),
  deposit     numeric(10,2),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (source, external_ref)
);
create index if not exists bookings_venue_date_idx on hq_bookings (venue_id, booking_date);

create table if not exists hq_parties (
  id          uuid primary key default gen_random_uuid(),
  booking_id  uuid references hq_bookings(id) on delete cascade,
  venue_id    text not null references hq_venues(id),
  child_name  text,
  child_age   int,
  party_date  date not null,
  start_time  time,
  end_time    time,
  room        text,
  guests      int,
  host_id     uuid references hq_profiles(id),
  food        jsonb not null default '{}',       -- pizza choices etc.
  allergies   text,
  activities  text[] not null default '{}',
  status      text not null default 'planning' check (status in ('planning','ready','cancelled','done')),
  notes       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ---------- inbox ----------
create table if not exists hq_threads (
  id          uuid primary key default gen_random_uuid(),
  outlook_conversation_id text unique,
  venue_id    text references hq_venues(id),
  customer_id uuid references hq_customers(id),
  from_name   text,
  from_email  text,
  subject     text,
  category    text,                               -- birthday, group, general, job ...
  state       text not null default 'new' check (state in ('new','needs-choice','awaiting-approval','replied','closed')),
  party_id    uuid references hq_parties(id),
  booking_id  uuid references hq_bookings(id),
  draft_text  text,
  updated_at  timestamptz not null default now(),
  created_at  timestamptz not null default now()
);

create table if not exists hq_messages (
  id          uuid primary key default gen_random_uuid(),
  thread_id   uuid not null references hq_threads(id) on delete cascade,
  direction   text not null check (direction in ('in','out')),
  outlook_message_id text unique,
  body        text not null,
  sent_at     timestamptz not null default now()
);

-- ---------- hq_approvals, hq_tasks, hq_cases ----------
create table if not exists hq_approvals (
  id          uuid primary key default gen_random_uuid(),
  kind        text not null check (kind in ('reply','reminder','refund','spend','discount','complaint','template','conflict')),
  title       text not null,
  issue       text,
  venue_id    text references hq_venues(id),
  ref_type    text,
  ref_id      text,
  payload     jsonb not null default '{}',
  recommended text,
  deadline    timestamptz,
  status      text not null default 'pending' check (status in ('pending','approved','declined','delegated')),
  approver_id uuid references hq_profiles(id),       -- set when delegated to a person
  decided_by  uuid references hq_profiles(id),
  decided_at  timestamptz,
  note        text,
  idem_key    text unique,                        -- stops duplicate hq_approvals
  created_at  timestamptz not null default now()
);

create table if not exists hq_tasks (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  kind        text not null default 'task' check (kind in ('task','promise','follow-up','decision','review')),
  venue_id    text references hq_venues(id),
  owner_id    uuid references hq_profiles(id),
  due_date    date,
  due_at      timestamptz,
  status      text not null default 'open' check (status in ('open','done','cancelled')),
  ref_type    text,
  ref_id      text,
  done_at     timestamptz,
  done_by     uuid references hq_profiles(id),
  idem_key    text unique,
  created_at  timestamptz not null default now()
);
create index if not exists tasks_open_idx on hq_tasks (status, due_date);

create table if not exists hq_cases (
  id          uuid primary key default gen_random_uuid(),
  kind        text not null check (kind in ('complaint','artwork')),
  venue_id    text references hq_venues(id),
  customer_name text not null,
  customer_id uuid references hq_customers(id),
  summary     text,
  sensitive   boolean not null default false,
  owner_id    uuid references hq_profiles(id),
  status      text not null default 'open' check (status in ('open','resolved')),
  outcome     jsonb not null default '{}',
  respond_by  date,
  created_at  timestamptz not null default now(),
  resolved_at timestamptz
);

-- ---------- operations ----------
create table if not exists hq_checklists (
  id          uuid primary key default gen_random_uuid(),
  venue_id    text not null references hq_venues(id),
  title       text not null,
  list_date   date not null default current_date,
  due_time    time,
  procedure_id uuid references hq_knowledge(id),
  ref_type    text,
  ref_id      text,
  done_at     timestamptz,
  created_at  timestamptz not null default now()
);

create table if not exists hq_checklist_items (
  id          uuid primary key default gen_random_uuid(),
  checklist_id uuid not null references hq_checklists(id) on delete cascade,
  position    int not null default 0,
  label       text not null,
  done        boolean not null default false,
  done_by     uuid references hq_profiles(id),
  done_at     timestamptz
);

create table if not exists hq_stock (
  id          uuid primary key default gen_random_uuid(),
  venue_id    text not null references hq_venues(id),
  item        text not null,
  unit        text,
  level       numeric(10,2) not null default 0,
  min_level   numeric(10,2) not null default 0,
  unit_cost   numeric(10,2),
  on_order    boolean not null default false,
  updated_at  timestamptz not null default now()
);

create table if not exists hq_transactions (            -- from ROLLER / Xero
  id          uuid primary key default gen_random_uuid(),
  source      text not null,
  external_ref text,
  venue_id    text references hq_venues(id),
  tx_date     date not null,
  kind        text not null check (kind in ('sale','refund','deposit','expense')),
  amount      numeric(10,2) not null,
  booking_id  uuid references hq_bookings(id),
  created_at  timestamptz not null default now(),
  unique (source, external_ref)
);

-- ---------- HR & recruitment (restricted) ----------
create table if not exists hq_vacancies (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  positions   int not null default 1,
  hours_per_week numeric(5,2),
  hourly_rate numeric(6,2),
  apprenticeship boolean not null default false,
  venue_id    text references hq_venues(id),
  status      text not null default 'open' check (status in ('draft','open','filled','closed')),
  notes       text,
  created_at  timestamptz not null default now()
);

create table if not exists hq_candidates (
  id          uuid primary key default gen_random_uuid(),
  vacancy_id  uuid references hq_vacancies(id),
  venue_id    text references hq_venues(id),
  full_name   text not null,
  email       text,
  phone       text,
  age         int,
  stage       text not null default 'Applied',
  checks      jsonb not null default '{}',        -- right to work, college check ...
  about       text,
  source      text,
  history     jsonb not null default '[]',
  created_at  timestamptz not null default now(),
  delete_after date default (current_date + 180)  -- UK GDPR: unsuccessful applicants
);

-- ---------- hq_integrations, hq_automations, activity log ----------
create table if not exists hq_integrations (
  id          text primary key,                   -- 'outlook','roller','xero','brighthr' ...
  name        text not null,
  status      text not null default 'disconnected' check (status in ('disconnected','connected','needs_attention')),
  last_sync   timestamptz,
  note        text                                -- never store secrets here
);

create table if not exists hq_automations (
  id          text primary key,
  name        text not null,
  mode        text not null default 'draft' check (mode in ('draft','approve','auto')),
  paused      boolean not null default false,
  last_status text,
  last_result text,
  last_run    timestamptz
);

create table if not exists hq_activity_log (
  id          bigserial primary key,
  at          timestamptz not null default now(),
  actor_id    uuid references hq_profiles(id),
  actor_name  text,
  automated   boolean not null default false,
  action      text not null,
  detail      text,
  venue_id    text references hq_venues(id),
  ref_type    text,
  ref_id      text,
  level       text not null default 'info' check (level in ('info','warn','error'))
);
create index if not exists activity_log_at_idx on hq_activity_log (at desc);

-- ---------- updated_at triggers ----------
create or replace function hq_touch() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
do $$ declare t text; begin
  foreach t in array array['hq_bookings','hq_parties','hq_threads','hq_stock'] loop
    execute format('drop trigger if exists %I_touch on %I', t, t);
    execute format('create trigger %I_touch before update on %I for each row execute function hq_touch()', t, t);
  end loop;
end $$;

-- New sign-ups get an access request, not access
create or replace function hq_on_signup() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into hq_access_requests (user_id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (user_id) do nothing;
  return new;
end $$;
drop trigger if exists hq_on_signup on auth.users;
create trigger hq_on_signup after insert on auth.users for each row execute function hq_on_signup();

-- =====================================================================
-- Row Level Security
-- =====================================================================
do $$ declare t text; begin
  foreach t in array array['hq_venues','hq_profiles','hq_role_permissions','hq_access_requests','hq_knowledge','hq_customers','hq_bookings','hq_parties','hq_threads','hq_messages','hq_approvals','hq_tasks','hq_cases','hq_checklists','hq_checklist_items','hq_stock','hq_transactions','hq_vacancies','hq_candidates','hq_integrations','hq_automations','hq_activity_log'] loop
    execute format('alter table %I enable row level security', t);
  end loop;
end $$;

-- helper to (re)create a policy idempotently
create or replace function hq_policy(tbl text, name text, cmd text, using_expr text, check_expr text default null)
returns void language plpgsql as $$
begin
  execute format('drop policy if exists %I on %I', name, tbl);
  execute format('create policy %I on %I for %s to authenticated %s %s', name, tbl, cmd,
    case when cmd = 'insert' then '' else 'using (' || using_expr || ')' end,
    case when cmd in ('insert','update','all') then 'with check (' || coalesce(check_expr, using_expr) || ')' else '' end);
end $$;

-- hq_venues: everyone with access reads; owner edits
select hq_policy('hq_venues','venues_read','select','hq_my_role() is not null');
select hq_policy('hq_venues','venues_write','all','hq_my_role() = ''owner''');

-- hq_profiles: see colleagues; owner / manage_people edit
select hq_policy('hq_profiles','profiles_read','select','id = auth.uid() or hq_my_role() is not null');
select hq_policy('hq_profiles','profiles_write','all','hq_can(''manage_people'')');
select hq_policy('hq_role_permissions','perms_read','select','hq_my_role() is not null');
select hq_policy('hq_role_permissions','perms_write','all','hq_my_role() = ''owner''');

-- access requests: you see your own; managers see all
select hq_policy('hq_access_requests','req_own','select','user_id = auth.uid() or hq_can(''manage_people'')');
select hq_policy('hq_access_requests','req_insert','insert',null,'user_id = auth.uid()');
select hq_policy('hq_access_requests','req_decide','update','hq_can(''manage_people'')');

-- hq_knowledge: everyone reads their hq_venues; editors write
select hq_policy('hq_knowledge','kn_read','select','hq_sees_venue(venue_id)');
select hq_policy('hq_knowledge','kn_write','all','hq_can(''edit_knowledge'')');

-- hq_customers: contact details only for roles with "contact"
select hq_policy('hq_customers','cust_read','select','hq_can(''contact'')');
select hq_policy('hq_customers','cust_write','all','hq_can(''contact'')');

-- hq_bookings & hq_parties: by venue; ops/lead/owner write, staff read
select hq_policy('hq_bookings','bk_read','select','hq_sees_venue(venue_id)');
select hq_policy('hq_bookings','bk_write','all','hq_sees_venue(venue_id) and hq_my_role() in (''owner'',''ops'',''lead'')');
select hq_policy('hq_parties','pt_read','select','hq_sees_venue(venue_id)');
select hq_policy('hq_parties','pt_write','all','hq_sees_venue(venue_id) and hq_my_role() in (''owner'',''ops'',''lead'')');

-- inbox: only roles with inbox permission
select hq_policy('hq_threads','th_read','select','hq_can(''inbox'') and hq_sees_venue(venue_id)');
select hq_policy('hq_threads','th_write','all','hq_can(''inbox'') and hq_sees_venue(venue_id)');
select hq_policy('hq_messages','msg_read','select','exists (select 1 from hq_threads t where t.id = thread_id and hq_can(''inbox'') and hq_sees_venue(t.venue_id))');
select hq_policy('hq_messages','msg_write','all','exists (select 1 from hq_threads t where t.id = thread_id and hq_can(''inbox'') and hq_sees_venue(t.venue_id))');

-- hq_approvals: see/decide what you may approve, or what was delegated to you
select hq_policy('hq_approvals','ap_read','select','hq_sees_venue(venue_id) and (hq_can_approve(kind) or approver_id = auth.uid())');
select hq_policy('hq_approvals','ap_insert','insert',null,'hq_my_role() is not null');
select hq_policy('hq_approvals','ap_decide','update','hq_sees_venue(venue_id) and (hq_can_approve(kind) or approver_id = auth.uid())');

-- hq_tasks: staff see their own + their venue; managers see their hq_venues
select hq_policy('hq_tasks','tk_read','select','hq_sees_venue(venue_id) or owner_id = auth.uid()');
select hq_policy('hq_tasks','tk_insert','insert',null,'hq_my_role() is not null');
select hq_policy('hq_tasks','tk_update','update','owner_id = auth.uid() or (hq_sees_venue(venue_id) and hq_my_role() in (''owner'',''ops'',''lead''))');

-- hq_cases: sensitive complaints only for those who approve complaints
select hq_policy('hq_cases','cs_read','select','hq_sees_venue(venue_id) and (not sensitive or hq_can_approve(''complaint''))');
select hq_policy('hq_cases','cs_write','all','hq_sees_venue(venue_id) and hq_my_role() in (''owner'',''ops'',''lead'') and (not sensitive or hq_can_approve(''complaint''))');

-- operations: everyone on the venue can tick hq_checklists and update hq_stock
select hq_policy('hq_checklists','cl_read','select','hq_sees_venue(venue_id)');
select hq_policy('hq_checklists','cl_write','all','hq_sees_venue(venue_id)');
select hq_policy('hq_checklist_items','ci_all','all','exists (select 1 from hq_checklists c where c.id = checklist_id and hq_sees_venue(c.venue_id))');
select hq_policy('hq_stock','st_read','select','hq_sees_venue(venue_id)');
select hq_policy('hq_stock','st_write','all','hq_sees_venue(venue_id)');

-- money: finance permission only
select hq_policy('hq_transactions','tx_read','select','hq_can(''finance'') and hq_sees_venue(venue_id)');
select hq_policy('hq_transactions','tx_write','all','hq_my_role() = ''owner''');

-- HR: hr permission only (owner by default)
select hq_policy('hq_vacancies','vac_all','all','hq_can(''hr'')');
select hq_policy('hq_candidates','cand_all','all','hq_can(''hr'')');

-- hq_integrations & hq_automations
select hq_policy('hq_integrations','int_read','select','hq_my_role() is not null');
select hq_policy('hq_integrations','int_write','all','hq_my_role() = ''owner''');
select hq_policy('hq_automations','auto_read','select','hq_my_role() is not null');
select hq_policy('hq_automations','auto_write','all','hq_can(''manage_automations'')');

-- activity log: append-only; inbox-level roles read
select hq_policy('hq_activity_log','log_read','select','hq_can(''inbox'') and hq_sees_venue(venue_id)');
select hq_policy('hq_activity_log','log_insert','insert',null,'hq_my_role() is not null');

drop function hq_policy(text,text,text,text,text);

-- =====================================================================
-- Seed data (real hq_venues + default role permissions; no demo records)
-- =====================================================================
insert into hq_venues (id, name, short_name, status) values
  ('mk',       'The Paint Patch — Xscape Milton Keynes', 'Milton Keynes', 'trading'),
  ('hat',      'The Paint Patch — The Galleria Hatfield', 'Hatfield',     'trading'),
  ('bham',     'Birmingham (planned)',                    'Birmingham',   'planned'),
  ('brighton', 'Brighton (planned)',                      'Brighton',     'planned'),
  ('manchester','Manchester (planned)',                   'Manchester',   'planned'),
  ('london',   'London — 17&Central, Walthamstow (planned)', 'London',    'planned'),
  ('dubai',    'Dubai (planned)',                         'Dubai',        'planned')
on conflict (id) do nothing;

insert into hq_role_permissions (role, all_sites, inbox, finance, contact, edit_knowledge, manage_automations, manage_people, hr, approve_kinds) values
  ('owner', true,  true,  true,  true,  true,  true,  true,  true,  '{reply,reminder,refund,spend,discount,complaint,template,conflict}'),
  ('ops',   true,  true,  true,  true,  true,  true,  false, false, '{reply,reminder,spend,template,complaint}'),
  ('lead',  false, true,  false, true,  false, false, false, false, '{reply,reminder}'),
  ('staff', false, false, false, false, false, false, false, false, '{}')
on conflict (role) do nothing;

insert into hq_integrations (id, name, status) values
  ('outlook','Outlook (hq_bookings mailbox)','connected'),
  ('roller','ROLLER','disconnected'),
  ('xero','Xero','disconnected'),
  ('brighthr','BrightHR / Blip','disconnected'),
  ('sharepoint','SharePoint','disconnected'),
  ('instagram','Instagram','disconnected')
on conflict (id) do nothing;


-- =====================================================================
-- Customer service monitor, TPP PA, settings & briefings (Netlify build)
-- =====================================================================

-- Customer-service tracking on each email thread (monitor only, no drafting)
alter table hq_threads
  add column if not exists reply_to          text,            -- real customer address from website forms
  add column if not exists outlook_web_link  text,
  add column if not exists cs_category       text check (cs_category in ('safety','legal','complaint','refund','chasing','service')),
  add column if not exists cs_priority       text check (cs_priority in ('high','medium','low')),
  add column if not exists cs_signals        text[] not null default '{}',
  add column if not exists cs_status         text not null default 'waiting' check (cs_status in ('waiting','replied','closed')),
  add column if not exists cs_since          timestamptz,     -- last customer message
  add column if not exists cs_due_at         timestamptz,     -- reply deadline: high 4h, medium 24h, low 48h
  add column if not exists cs_replied_at     timestamptz,
  add column if not exists cs_response_hours numeric(6,1),
  add column if not exists cs_closed_at      timestamptz,
  add column if not exists cs_closed_by      uuid references hq_profiles(id),
  add column if not exists case_id           uuid references hq_cases(id);
create index if not exists hq_threads_cs_idx on hq_threads (cs_status, cs_due_at);

alter table hq_messages
  add column if not exists via_outlook_sent  boolean not null default false;   -- reply found in Sent Items

alter table hq_cases
  add column if not exists thread_id uuid references hq_threads(id);

-- Reply-deadline hours by priority, in one place
create or replace function hq_cs_hours(priority text) returns int
language sql immutable as $$ select case priority when 'high' then 4 when 'medium' then 24 else 48 end $$;

-- Keep cs_due_at in step with priority / last customer message
create or replace function hq_cs_due() returns trigger language plpgsql as $$
begin
  if new.cs_since is not null and new.cs_priority is not null then
    new.cs_due_at = new.cs_since + make_interval(hours => hq_cs_hours(new.cs_priority));
  end if;
  if new.cs_replied_at is not null and new.cs_since is not null and new.cs_replied_at > new.cs_since then
    new.cs_status = case when new.cs_status = 'closed' then 'closed' else 'replied' end;
    new.cs_response_hours = coalesce(new.cs_response_hours, round(extract(epoch from (new.cs_replied_at - new.cs_since)) / 3600.0, 1));
  end if;
  return new;
end $$;
drop trigger if exists hq_threads_cs_due on hq_threads;
create trigger hq_threads_cs_due before insert or update on hq_threads for each row execute function hq_cs_due();

-- Customer service dashboard (respects the same access rules as hq_threads)
create or replace view hq_cs_queue with (security_invoker = true) as
select t.id, t.venue_id, t.from_name, t.subject, t.cs_category, t.cs_priority, t.cs_status,
       t.cs_since, t.cs_due_at, t.cs_replied_at, t.cs_response_hours, t.case_id, t.outlook_web_link,
       (t.cs_status = 'waiting' and t.cs_due_at < now()) as overdue
from hq_threads t
where t.cs_category is not null;

create or replace view hq_cs_kpis with (security_invoker = true) as
select
  count(*) filter (where cs_status = 'waiting' and cs_due_at < now())                       as overdue,
  count(*) filter (where cs_status = 'waiting' and cs_priority in ('high','medium'))        as issues_waiting,
  count(*) filter (where cs_status = 'waiting' and cs_priority = 'low')                     as queries_waiting,
  round(avg(cs_response_hours) filter (where cs_replied_at > now() - interval '7 days'), 1) as avg_reply_hours_7d
from hq_threads where cs_category is not null;

-- TPP PA library (saved marketing drafts)
create table if not exists hq_pa_library (
  id          uuid primary key default gen_random_uuid(),
  mode        text not null check (mode in ('bundle','plan','review','reply','campaign','ask')),
  venue_id    text references hq_venues(id),          -- null = both venues
  title       text not null,
  body        text not null,
  created_by  uuid references hq_profiles(id) default auth.uid(),
  created_at  timestamptz not null default now()
);

-- App settings (briefing time, Outlook sync markers, etc.)
create table if not exists hq_settings (
  key         text primary key,
  value       jsonb not null,
  updated_at  timestamptz not null default now()
);

-- Daily briefings
create table if not exists hq_briefings (
  id          uuid primary key default gen_random_uuid(),
  brief_date  date not null,
  venue_id    text references hq_venues(id),
  lines       jsonb not null default '[]',
  created_at  timestamptz not null default now(),
  unique (brief_date, venue_id)
);

alter table hq_pa_library enable row level security;
alter table hq_settings   enable row level security;
alter table hq_briefings  enable row level security;

drop policy if exists pa_read on hq_pa_library;
create policy pa_read on hq_pa_library for select to authenticated using (hq_can('marketing') and hq_sees_venue(venue_id));
drop policy if exists pa_insert on hq_pa_library;
create policy pa_insert on hq_pa_library for insert to authenticated with check (hq_can('marketing'));
drop policy if exists pa_delete on hq_pa_library;
create policy pa_delete on hq_pa_library for delete to authenticated using (hq_can('marketing') and (created_by = auth.uid() or hq_my_role() in ('owner','ops')));

drop policy if exists set_read on hq_settings;
create policy set_read on hq_settings for select to authenticated using (hq_my_role() is not null);
drop policy if exists set_write on hq_settings;
create policy set_write on hq_settings for all to authenticated using (hq_my_role() = 'owner') with check (hq_my_role() = 'owner');

drop policy if exists brief_read on hq_briefings;
create policy brief_read on hq_briefings for select to authenticated using (hq_sees_venue(venue_id));
drop policy if exists brief_write on hq_briefings;
create policy brief_write on hq_briefings for all to authenticated using (hq_my_role() in ('owner','ops')) with check (hq_my_role() in ('owner','ops'));

-- Who may use TPP PA by default
update hq_role_permissions set marketing = true where role in ('owner','ops','lead') and marketing = false;

insert into hq_settings (key, value) values
  ('briefing_time', '"07:00"'),
  ('outlook_mode',  '"monitor"'),
  ('timezone',      '"Europe/London"')
on conflict (key) do nothing;

-- Retention (UK GDPR). Run monthly, or schedule it (Database → Extensions → pg_cron):
--   select cron.schedule('hq-retention', '0 3 1 * *', 'select hq_retention()');
create or replace function hq_retention() returns void
language sql security definer set search_path = public as $$
  delete from hq_candidates where delete_after < current_date and stage in ('Rejected','Withdrawn');
  delete from hq_activity_log where at < now() - interval '2 years';
$$;
revoke execute on function hq_retention() from public, anon, authenticated;

-- Live updates for the dashboard
do $$ declare t text; begin
  foreach t in array array['hq_threads','hq_tasks','hq_approvals','hq_parties','hq_cases','hq_checklist_items'] loop
    begin execute format('alter publication supabase_realtime add table %I', t);
    exception when duplicate_object then null; when undefined_object then null; end;
  end loop;
end $$;

-- =====================================================================
-- AFTER RUNNING: make yourself owner.
-- 1) Sign up once in your app (or Authentication → Users → Add user).
-- 2) Then run, with your email:
--
--   insert into hq_profiles (id, full_name, email, role)
--   select id, 'Aliyah Alowooja', email, 'owner' from auth.users
--   where email = 'YOUR-EMAIL-HERE'
--   on conflict (id) do update set role = 'owner';
--
-- Retention (UK GDPR) — run monthly, or schedule with pg_cron:
--   delete from hq_candidates where delete_after < current_date and stage in ('Rejected','Withdrawn');
--   delete from hq_activity_log where at < now() - interval '2 years';
-- =====================================================================
