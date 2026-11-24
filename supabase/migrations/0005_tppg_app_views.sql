-- =====================================================================
-- tppg.io (React HQ) → Supabase: read views in the shape the app expects.
-- Run AFTER 0001_core_schema.sql and 0002_complaints_artwork_roller_bookings.sql.
-- Views use security_invoker, so every hq_ table's row-level security still applies
-- (staff see their own venue; money only for finance roles; etc.). Safe to re-run.
-- =====================================================================

-- Reviews (Google etc.) — new table; nothing invented, starts empty
create table if not exists hq_reviews (
  id            uuid primary key default gen_random_uuid(),
  venue_id      text references hq_venues(id),
  source        text not null default 'google',
  reviewer_name text,
  rating        smallint check (rating between 1 and 5),
  body          text,
  review_date   date not null default current_date,
  url           text,
  external_id   text,
  created_at    timestamptz not null default now(),
  unique (source, external_id)
);
alter table hq_reviews enable row level security;
drop policy if exists rv_read on hq_reviews;
create policy rv_read on hq_reviews for select to authenticated using (hq_sees_venue(venue_id));
drop policy if exists rv_write on hq_reviews;
create policy rv_write on hq_reviews for all to authenticated
  using (hq_my_role() in ('owner','ops')) with check (hq_my_role() in ('owner','ops'));

create or replace view app_bookings with (security_invoker = true) as
select b.id,
       to_char(b.booking_date, 'YYYY-MM-DD')        as date,
       to_char(b.start_time, 'HH24:MI')             as time,
       coalesce(c.name, 'Customer')                 as customer_name,
       b.product                                    as session_type,
       v.short_name                                 as location,
       b.venue_id,
       b.guests,
       coalesce(b.total, 0)                         as revenue,
       case b.status when 'confirmed' then 'confirmed' when 'completed' then 'completed'
                     when 'cancelled' then 'cancelled' else b.status end as status,
       b.source,
       b.external_ref                               as booking_ref,
       b.created_at                                 as created_date
from hq_bookings b
left join hq_customers c on c.id = b.customer_id
left join hq_venues v on v.id = b.venue_id;

create or replace view app_parties with (security_invoker = true) as
select p.id,
       to_char(p.party_date, 'YYYY-MM-DD') as date,
       to_char(p.start_time, 'HH24:MI')    as time,
       p.child_name, p.child_age, p.guests, p.room, p.status,
       v.short_name as location, p.venue_id,
       p.created_at as created_date
from hq_parties p left join hq_venues v on v.id = p.venue_id;

create or replace view app_inventory with (security_invoker = true) as
select s.id, s.item as name, s.unit, s.level as current_stock, s.min_level as low_stock_threshold,
       s.on_order, v.short_name as location, s.venue_id, s.updated_at as updated_date
from hq_stock s left join hq_venues v on v.id = s.venue_id;

create or replace view app_reviews with (security_invoker = true) as
select r.id, r.rating, r.reviewer_name, r.body as text, r.source, r.url,
       to_char(r.review_date, 'YYYY-MM-DD') as date, v.short_name as location, r.venue_id,
       r.created_at as created_date
from hq_reviews r left join hq_venues v on v.id = r.venue_id;

create or replace view app_staff with (security_invoker = true) as
select p.id, p.full_name, p.role,
       case when p.active then 'active' else 'inactive' end as status,
       v.short_name as location, p.venue_id, p.created_at as created_date
from hq_profiles p left join hq_venues v on v.id = p.venue_id;

-- POS / till sales: transactions of kind 'sale' (finance roles only, via hq_transactions RLS)
create or replace view app_pos_sales with (security_invoker = true) as
select t.id, t.amount as total, t.source, t.external_ref,
       v.short_name as location, t.venue_id,
       (t.tx_date::timestamp at time zone 'Europe/London') as created_date
from hq_transactions t left join hq_venues v on v.id = t.venue_id
where t.kind = 'sale';

grant select on app_bookings, app_parties, app_inventory, app_reviews, app_staff, app_pos_sales to authenticated;
revoke all on app_bookings, app_parties, app_inventory, app_reviews, app_staff, app_pos_sales from anon;
