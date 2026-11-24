-- =====================================================================
-- The Paint Patch HQ — Customer Experience & Complaints, Artwork
-- Fulfilment Tracker, and ROLLER bookings (from Outlook order emails)
-- Run AFTER paint_patch_hq.sql. Safe to re-run.
-- Based on the Complaints Assessment, 22 Nov 2026. Seeded cases are
-- PROVISIONAL (verified = false) until staff confirm their status.
-- =====================================================================

-- ---------- 1. Complaints register ----------
create table if not exists hq_complaints (
  id                 uuid primary key default gen_random_uuid(),
  ref                text unique,                          -- e.g. CX-0001
  kind               text not null default 'complaint' check (kind in ('complaint','fulfilment','incident')),
  -- customer
  customer_name      text not null,
  customer_email     text,
  customer_phone     text,
  booking_ref        text,                                 -- ROLLER booking number
  booking_id         uuid references hq_bookings(id),
  venue_id           text references hq_venues(id),        -- null = to verify
  -- complaint
  received_at        timestamptz not null default now(),
  activity           text,                                 -- drip bears, slime, foam, smash room, UV ...
  category           text not null default 'other' check (category in
                       ('artwork','communication','event_delivery','stock','booking','staff','safety','refund','other')),
  severity           text not null default 'medium' check (severity in ('critical','high','medium','low')),
  description        text,
  -- workflow & accountability
  stage              text not null default 'received' check (stage in ('received','assigned','action','resolved')),
  owner_id           uuid references hq_profiles(id),
  owner_label        text,                                 -- until staff have logins (e.g. "Mum", "Site manager")
  next_action        text,
  next_action_due    timestamptz,
  acknowledged_at    timestamptz,
  last_progress_at   timestamptz,
  -- financials
  refund_requested   numeric(10,2),
  refund_authorised  numeric(10,2),
  refund_authorised_by uuid references hq_profiles(id),
  refund_issued      numeric(10,2),
  refund_issued_at   timestamptz,
  compensation_cost  numeric(10,2),                        -- remakes, postage, vouchers
  -- resolution
  outcome            text,
  resolved_at        timestamptz,
  customer_notified  boolean not null default false,
  customer_accepted  boolean,                              -- null = not yet known
  satisfaction       smallint check (satisfaction between 1 and 5),
  -- data quality & links
  verified           boolean not null default false,       -- false = provisional, needs staff confirmation
  source             text not null default 'manual' check (source in ('manual','outlook','roller','assessment')),
  thread_id          uuid references hq_threads(id),
  case_id            uuid references hq_cases(id),
  created_by         uuid references hq_profiles(id) default auth.uid(),
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index if not exists hq_complaints_open_idx on hq_complaints (stage, severity, received_at);

create sequence if not exists hq_complaint_seq;
create or replace function hq_complaint_defaults() returns trigger language plpgsql as $$
begin
  if new.ref is null then new.ref = 'CX-' || lpad(nextval('hq_complaint_seq')::text, 4, '0'); end if;
  if tg_op = 'UPDATE' then
    new.updated_at = now();
    if new.stage is distinct from old.stage or new.next_action is distinct from old.next_action
       or new.refund_issued is distinct from old.refund_issued then new.last_progress_at = now(); end if;
    if new.stage = 'resolved' and old.stage <> 'resolved' and new.resolved_at is null then new.resolved_at = now(); end if;
  end if;
  if new.owner_id is not null and new.stage = 'received' then new.stage = 'assigned'; end if;
  return new;
end $$;
drop trigger if exists hq_complaints_defaults on hq_complaints;
create trigger hq_complaints_defaults before insert or update on hq_complaints for each row execute function hq_complaint_defaults();

-- Evidence: original email, photos, staff notes, ROLLER booking
create table if not exists hq_complaint_evidence (
  id            uuid primary key default gen_random_uuid(),
  complaint_id  uuid not null references hq_complaints(id) on delete cascade,
  kind          text not null check (kind in ('email','photo','note','roller','other')),
  url           text,                                      -- Outlook web link, storage URL, ROLLER link
  note          text,
  added_by      uuid references hq_profiles(id) default auth.uid(),
  added_at      timestamptz not null default now()
);

-- Timeline of every step (for "no meaningful progress" checks and audits)
create table if not exists hq_complaint_events (
  id            bigserial primary key,
  complaint_id  uuid not null references hq_complaints(id) on delete cascade,
  at            timestamptz not null default now(),
  actor_id      uuid references hq_profiles(id) default auth.uid(),
  event         text not null,                             -- acknowledged, assigned, refund authorised, artwork posted ...
  detail        text
);

-- Root-cause investigations (raised when a category keeps recurring)
create table if not exists hq_root_cause_reviews (
  id            uuid primary key default gen_random_uuid(),
  category      text not null,
  venue_id      text references hq_venues(id),
  opened_at     timestamptz not null default now(),
  complaints    int not null default 0,
  findings      text,
  corrective_action text,
  owner_label   text,
  status        text not null default 'open' check (status in ('open','actioned','closed')),
  unique (category, venue_id, status)
);

-- ---------- 2. Artwork fulfilment tracker ----------
create table if not exists hq_artwork_items (
  id            uuid primary key default gen_random_uuid(),
  item_type     text not null default 'drip bear' check (item_type in ('drip bear','canvas','t-shirt','slime','other')),
  quantity      int not null default 1,
  venue_id      text references hq_venues(id),
  booking_ref   text,
  booking_id    uuid references hq_bookings(id),
  customer_name text,
  customer_email text,
  customer_phone text,
  label         text,                                       -- name on the item / bag
  stage         text not null default 'drying' check (stage in
                  ('drying','quality_check','labelled','ready','collected','dispatched','delivered','remake','lost')),
  made_on       date,
  ready_by      date,                                       -- promised date
  fulfilment    text not null default 'collect' check (fulfilment in ('collect','post')),
  postal_address text,
  tracking_ref  text,
  qc_passed     boolean,
  qc_notes      text,
  complaint_id  uuid references hq_complaints(id),
  updated_at    timestamptz not null default now(),
  created_at    timestamptz not null default now()
);
create index if not exists hq_artwork_stage_idx on hq_artwork_items (stage, ready_by);

-- ---------- 3. ROLLER bookings from Outlook order-confirmation emails ----------
alter table hq_bookings
  add column if not exists end_time_text  text,
  add column if not exists ordered_at     timestamptz,
  add column if not exists outlook_web_link text;

create table if not exists hq_booking_items (
  id          uuid primary key default gen_random_uuid(),
  booking_id  uuid not null references hq_bookings(id) on delete cascade,
  qty         int not null,
  product     text not null,                               -- UV Room, Slime Workshop, Patch Party Plus ...
  ticket      text,                                        -- Adult, Junior, General admission ...
  item_date   date,
  start_time  time,
  end_time    time
);
create index if not exists hq_booking_items_booking_idx on hq_booking_items (booking_id);

-- Raw ROLLER emails (the importer writes here; hq_roller_apply turns them into bookings)
create table if not exists hq_roller_emails (
  outlook_id   text primary key,
  received_at  timestamptz not null,
  subject      text,
  parsed       jsonb not null,                             -- {ref, venue, lines[], extras[], total, customer{}}
  applied_at   timestamptz,
  web_link     text
);

create or replace function hq_roller_apply() returns int
language plpgsql security definer set search_path = public as $$
declare r record; b uuid; c uuid; n int := 0; l jsonb; p jsonb;
begin
  for r in select * from hq_roller_emails where applied_at is null order by received_at loop
    p := r.parsed;
    if coalesce(p->>'ref','') = '' or coalesce(p->>'date','') = '' then
      update hq_roller_emails set applied_at = now() where outlook_id = r.outlook_id; continue;
    end if;
    c := null;
    if coalesce(p->'customer'->>'email','') <> '' then
      insert into hq_customers (name, email, phone)
      values (coalesce(nullif(p->'customer'->>'name',''), 'ROLLER customer'), p->'customer'->>'email', p->'customer'->>'phone')
      on conflict (lower(email)) where email is not null
      do update set name = excluded.name, phone = coalesce(excluded.phone, hq_customers.phone)
      returning id into c;
    end if;
    insert into hq_bookings (external_ref, source, venue_id, customer_id, product, kind, booking_date, start_time, end_time,
                             guests, status, total, paid, ordered_at, outlook_web_link)
    values (p->>'ref', 'roller', coalesce(p->>'venue','mk'), c, p->>'product',
            case when p->>'product' ilike '%party%' then 'party' else 'session' end,
            (p->>'date')::date, nullif(p->>'time','')::time, nullif(p->>'end','')::time,
            nullif(p->>'guests','')::int, 'confirmed', nullif(p->>'total','')::numeric, nullif(p->>'total','')::numeric,
            r.received_at, r.web_link)
    on conflict (source, external_ref) do update set
      venue_id = excluded.venue_id, customer_id = coalesce(excluded.customer_id, hq_bookings.customer_id),
      product = excluded.product, booking_date = excluded.booking_date, start_time = excluded.start_time,
      end_time = excluded.end_time, guests = excluded.guests, total = excluded.total, paid = excluded.paid
    returning id into b;
    delete from hq_booking_items where booking_id = b;
    for l in select * from jsonb_array_elements(coalesce(p->'lines','[]'::jsonb)) loop
      insert into hq_booking_items (booking_id, qty, product, ticket, item_date, start_time, end_time)
      values (b, (l->>'qty')::int, l->>'product', l->>'ticket', nullif(l->>'date','')::date,
              nullif(l->>'start','')::time, nullif(l->>'end','')::time);
    end loop;
    for l in select * from jsonb_array_elements(coalesce(p->'extras','[]'::jsonb)) loop
      insert into hq_booking_items (booking_id, qty, product) values (b, (l->>'qty')::int, l->>'product');
    end loop;
    update hq_roller_emails set applied_at = now() where outlook_id = r.outlook_id;
    n := n + 1;
  end loop;
  return n;
end $$;

-- Apply automatically whenever a new email row lands
create or replace function hq_roller_apply_trg() returns trigger language plpgsql security definer set search_path = public as $$
begin perform hq_roller_apply(); return null; end $$;
drop trigger if exists hq_roller_emails_apply on hq_roller_emails;
create trigger hq_roller_emails_apply after insert on hq_roller_emails for each statement execute function hq_roller_apply_trg();

-- ---------- 4. Escalation rules (proposed internal targets) ----------
-- Working hours are approximated as clock hours; adjust here if needed.
create or replace view hq_complaint_flags with (security_invoker = true) as
select c.id, c.ref, c.customer_name, c.venue_id, c.severity, c.stage, c.owner_label, c.next_action,
  (c.acknowledged_at is null and c.received_at < now() - interval '4 hours')                         as not_acknowledged_4h,
  (c.stage <> 'resolved' and coalesce(c.last_progress_at, c.acknowledged_at, c.received_at) < now() - interval '24 hours') as no_progress_24h,
  (c.stage <> 'resolved' and c.received_at < now() - interval '72 hours')                            as open_over_72h,
  (c.refund_requested is not null and c.refund_authorised is null)                                   as refund_awaiting_approval,
  (c.refund_authorised is not null and c.refund_issued is null)                                      as refund_not_paid,
  exists (select 1 from hq_artwork_items a where a.complaint_id = c.id
          and a.stage not in ('collected','delivered') and a.ready_by < current_date)                as artwork_overdue,
  (not c.verified)                                                                                   as needs_verification
from hq_complaints c
where c.stage <> 'resolved' or c.resolved_at > now() - interval '7 days';

-- Same category 3+ times in 30 days at a venue → open a root-cause review
create or replace function hq_check_recurring() returns int
language plpgsql security definer set search_path = public as $$
declare r record; n int := 0;
begin
  for r in select category, venue_id, count(*) cnt from hq_complaints
           where kind = 'complaint' and received_at > now() - interval '30 days'
           group by category, venue_id having count(*) >= 3 loop
    insert into hq_root_cause_reviews (category, venue_id, complaints)
    values (r.category, r.venue_id, r.cnt)
    on conflict (category, venue_id, status) do update set complaints = excluded.complaints;
    n := n + 1;
  end loop;
  return n;
end $$;

-- Dashboard figures (from verified records only, as the assessment requires)
create or replace view hq_cx_kpis with (security_invoker = true) as
select
  count(*) filter (where stage <> 'resolved')                                                     as open_cases,
  count(*) filter (where stage <> 'resolved' and not verified)                                    as open_unverified,
  count(*) filter (where stage <> 'resolved' and (
      (acknowledged_at is null and received_at < now() - interval '4 hours')
      or coalesce(last_progress_at, acknowledged_at, received_at) < now() - interval '24 hours'))  as overdue,
  count(*) filter (where stage = 'resolved' and resolved_at >= date_trunc('month', now()))        as resolved_this_month,
  round(avg(extract(epoch from (acknowledged_at - received_at)) / 3600.0)
        filter (where verified and acknowledged_at is not null), 1)                               as avg_response_hours,
  coalesce(sum(coalesce(refund_issued,0) + coalesce(compensation_cost,0)) filter (where verified), 0) as refund_costs,
  round(avg(satisfaction) filter (where verified), 1)                                             as satisfaction
from hq_complaints;

create or replace view hq_cx_by_location with (security_invoker = true) as
select coalesce(venue_id, 'to verify') as venue, category, count(*) as cases,
       count(*) filter (where stage <> 'resolved') as open,
       coalesce(sum(coalesce(refund_issued,0) + coalesce(compensation_cost,0)), 0) as cost,
       round(avg(extract(epoch from (coalesce(resolved_at, now()) - received_at)) / 86400.0), 1) as avg_days_open
from hq_complaints where kind = 'complaint'
group by 1, 2;

create or replace view hq_artwork_queue with (security_invoker = true) as
select a.*, (a.stage not in ('collected','delivered') and a.ready_by < current_date) as overdue
from hq_artwork_items a
where a.stage not in ('collected','delivered') or a.updated_at > now() - interval '14 days';

-- ---------- 5. Access rules ----------
alter table hq_complaints          enable row level security;
alter table hq_complaint_evidence  enable row level security;
alter table hq_complaint_events    enable row level security;
alter table hq_root_cause_reviews  enable row level security;
alter table hq_artwork_items       enable row level security;
alter table hq_booking_items       enable row level security;
alter table hq_roller_emails       enable row level security;

-- Complaints: people with Inbox access at that venue (unverified venue = owner/ops only)
drop policy if exists cx_read on hq_complaints;
create policy cx_read on hq_complaints for select to authenticated
  using (hq_can('inbox') and (venue_id is null and hq_can('all_sites') or venue_id is not null and hq_sees_venue(venue_id)));
drop policy if exists cx_write on hq_complaints;
create policy cx_write on hq_complaints for all to authenticated
  using (hq_can('inbox') and (venue_id is null and hq_can('all_sites') or venue_id is not null and hq_sees_venue(venue_id)))
  with check (hq_can('inbox') and (venue_id is null and hq_can('all_sites') or venue_id is not null and hq_sees_venue(venue_id))
              -- only refund approvers may authorise refunds
              and (refund_authorised is null or hq_can_approve('refund')));

drop policy if exists cxe_all on hq_complaint_evidence;
create policy cxe_all on hq_complaint_evidence for all to authenticated
  using (exists (select 1 from hq_complaints c where c.id = complaint_id))
  with check (exists (select 1 from hq_complaints c where c.id = complaint_id));
drop policy if exists cxv_read on hq_complaint_events;
create policy cxv_read on hq_complaint_events for select to authenticated using (exists (select 1 from hq_complaints c where c.id = complaint_id));
drop policy if exists cxv_insert on hq_complaint_events;
create policy cxv_insert on hq_complaint_events for insert to authenticated with check (exists (select 1 from hq_complaints c where c.id = complaint_id));

drop policy if exists rca_all on hq_root_cause_reviews;
create policy rca_all on hq_root_cause_reviews for all to authenticated
  using (hq_my_role() in ('owner','ops')) with check (hq_my_role() in ('owner','ops'));

-- Artwork: whole venue team can move items along; contact details follow the bookings rules
drop policy if exists art_read on hq_artwork_items;
create policy art_read on hq_artwork_items for select to authenticated using (hq_sees_venue(venue_id));
drop policy if exists art_write on hq_artwork_items;
create policy art_write on hq_artwork_items for all to authenticated using (hq_sees_venue(venue_id)) with check (hq_sees_venue(venue_id));

drop policy if exists bki_read on hq_booking_items;
create policy bki_read on hq_booking_items for select to authenticated
  using (exists (select 1 from hq_bookings b where b.id = booking_id and hq_sees_venue(b.venue_id)));

-- Raw emails: owner / ops only (the importer uses the service key)
drop policy if exists rol_all on hq_roller_emails;
create policy rol_all on hq_roller_emails for all to authenticated
  using (hq_my_role() in ('owner','ops')) with check (hq_my_role() in ('owner','ops'));

do $$ declare t text; begin
  foreach t in array array['hq_complaints','hq_artwork_items','hq_bookings'] loop
    begin execute format('alter publication supabase_realtime add table %I', t);
    exception when duplicate_object then null; when undefined_object then null; end;
  end loop;
end $$;

-- ---------- 6. Starting register (from the 22 Nov assessment — PROVISIONAL) ----------
insert into hq_complaints (kind, customer_name, venue_id, activity, category, severity, description, next_action, owner_label, booking_ref, verified, source, received_at)
select * from (values
  ('complaint','Alison','hat','Birthday party — drip bears','artwork','critical',
   'Birthday party, 23 drip bears, refund dispute.','Verify bear collection, compensation and final agreement','Mum', null, false, 'assessment', now()),
  ('complaint','Michael O''Flynn','hat','Slime and foam event','event_delivery','critical',
   'Slime and foam event complaint; full refund requested for two children.','Review full refund request for two children','Mum', null, false, 'assessment', now()),
  ('complaint','Becky O','hat','Smash room','communication','high',
   'Smash room complaint from 4 October; response was delayed.','Confirm resolution after delayed response','Mum', null, false, 'assessment', timestamptz '2026-10-04 12:00+00'),
  ('complaint','Nadine Perera',null,'Drip bears','artwork','high',
   'Bears not delivered.','Trace dispatch and provide delivery confirmation','Site manager', null, false, 'assessment', now()),
  ('complaint','Lucy',null,'Drip bear','event_delivery','high',
   'Rushed experience and half-painted bear.','Review artwork, staff delivery and remedy','Site manager', null, false, 'assessment', now()),
  ('complaint','Lauren',null,'Drip bear','artwork','medium',
   'Unsatisfactory drip bear finish.','Review photographs and agree remake or refund','Site manager', null, false, 'assessment', now()),
  ('complaint','Two grandchildren (customer to confirm)','mk','Drip bears','artwork','medium',
   'Mislabelled bears; £40 refund offered.','Confirm refund processed and case closed','Mum', null, false, 'assessment', now()),
  ('fulfilment','Hannah',null,'Drip bear postage','artwork','low',
   'Bear postage requested — service request, not yet a complaint.','Confirm postal details and dispatch','Site manager', null, false, 'assessment', now()),
  ('incident','Glue shortage — booking 179517048',null,'Session','stock','medium',
   '30-minute delay caused by glue shortage; 50% refund to verify.','Verify 50% refund issued','Site manager', '179517048', false, 'assessment', now()),
  ('incident','Double booking — 30-minute wait',null,'Session','booking','medium',
   'Double booking led to a 30-minute wait.','Confirm refund decision and booking fix','Site manager', null, false, 'assessment', now())
) v(kind, customer_name, venue_id, activity, category, severity, description, next_action, owner_label, booking_ref, verified, source, received_at)
where not exists (select 1 from hq_complaints where source = 'assessment');

-- Refund offered on the mislabelled-bears case (amount from the assessment, still to verify)
update hq_complaints set refund_authorised = 40
where source = 'assessment' and customer_name like 'Two grandchildren%' and refund_authorised is null;

-- ---------- 7. Implementation checklist (from section 7) ----------
insert into hq_tasks (title, kind, status, idem_key)
select t, 'task', 'open', 'cx-setup:' || n from (values
  (1,'Verify the current status of every identified complaint'),
  (2,'Contact customers awaiting refunds, artwork or delivery'),
  (3,'Introduce a single artwork collection and dispatch register'),
  (4,'Require daily checks of unresolved complaints'),
  (5,'Connect Outlook complaint emails to the HQ dashboard'),
  (6,'Link ROLLER booking references and refund transactions'),
  (7,'Introduce weekly complaint reporting by location')
) v(n, t)
on conflict (idem_key) do nothing;

-- Schedule (Database → Extensions → enable pg_cron), optional:
--   select cron.schedule('hq-recurring', '15 7 * * *', 'select hq_check_recurring()');
--   select cron.schedule('hq-roller',    '*/5 * * * *', 'select hq_roller_apply()');
