-- =====================================================================
-- The Paint Patch HQ — run the Outlook feed every 5 minutes
-- Run AFTER paint_patch_hq.sql, hq_complaints_bookings.sql and after
-- deploying the "outlook-feed" Edge Function. Safe to re-run.
-- Replace the 3 placeholders below first:
--   YOUR-PROJECT-REF   → Project Settings → General → Reference ID
--   YOUR-ANON-KEY      → Project Settings → API → anon public key
--   YOUR-CRON-SECRET   → the same random text you saved as the CRON_SECRET secret
-- =====================================================================

create extension if not exists pg_cron;
create extension if not exists pg_net;

-- one complaint per email conversation
create unique index if not exists hq_complaints_thread_uq on hq_complaints (thread_id) where thread_id is not null;

-- start of the feed: how far back the first run reads (60 days, so upcoming bookings made earlier are included)
insert into hq_settings (key, value) values
  ('outlook_since', to_jsonb(to_char((now() - interval '60 days') at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'))),
  ('outlook_mode',  '"monitor"')
on conflict (key) do nothing;

-- (re)schedule
do $$ begin perform cron.unschedule('hq-outlook-feed'); exception when others then null; end $$;
select cron.schedule('hq-outlook-feed', '*/5 * * * *', $cron$
  select net.http_post(
    url     := 'https://YOUR-PROJECT-REF.supabase.co/functions/v1/outlook-feed',
    headers := jsonb_build_object(
                 'Content-Type',  'application/json',
                 'Authorization', 'Bearer YOUR-ANON-KEY',
                 'x-cron-secret', 'YOUR-CRON-SECRET'),
    body    := '{}'::jsonb,
    timeout_milliseconds := 60000);
$cron$);

-- Daily: open root-cause reviews for recurring complaint types
do $$ begin perform cron.unschedule('hq-recurring'); exception when others then null; end $$;
select cron.schedule('hq-recurring', '15 7 * * *', 'select hq_check_recurring()');

-- Check it's working (after 5–10 minutes):
--   select status, last_sync, note from hq_integrations where id in ('outlook','roller');
--   select count(*) from hq_bookings where source = 'roller';
--   select * from cron.job_run_details order by start_time desc limit 5;
