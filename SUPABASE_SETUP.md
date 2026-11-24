# Paint Patch HQ (tppg.io) on Supabase

Base44 has been removed. Sign-in and data now come from your Supabase project.

## 1. Supabase — SQL Editor (in this order; each is safe to re-run)
1. `supabase/migrations/0001_core_schema.sql` (skip if already run) → then its "make yourself owner" snippet with your email
2. `supabase/migrations/0002_complaints_artwork_roller_bookings.sql` (skip if already run)
3. `supabase/migrations/0005_tppg_app_views.sql` ← new: the views this app reads
4. Optional: `0003` (only for the single-file HQ build) and `0004` + `supabase/functions/outlook-feed` for the Outlook/ROLLER feed

## 2. Supabase — Authentication → URL Configuration
- Site URL: `https://tppg.io`
- Redirect URLs: add `https://tppg.io/**` and your Netlify preview URL pattern

## 3. Netlify — Environment variables
| Name | Value |
|---|---|
| `VITE_SUPABASE_URL` | Supabase → Project Settings → API → Project URL |
| `VITE_SUPABASE_ANON_KEY` | Supabase → Project Settings → API → anon public key |
| `SUPABASE_URL` | same Project URL (for functions) |
| `SUPABASE_ANON_KEY` | same anon key (for functions) |
| `STRIPE_SECRET_KEY` | optional — a restricted, read-only Stripe key |

Remove the old `VITE_BASE44_*` variables. Keep `SUPABASE_SERVICE_ROLE_KEY` out of anything starting `VITE_`.

## Roles
HQ roles in `hq_profiles` map to the app's menu roles: owner → admin, ops → manager, lead → team leader, staff → assistant.
New sign-ups appear in `hq_access_requests`; approve by inserting a row in `hq_profiles` with their role and venue.

## What reads what
| App data | Supabase view | Source table |
|---|---|---|
| Bookings | `app_bookings` | `hq_bookings` (+ ROLLER emails via the Outlook feed) |
| Parties | `app_parties` | `hq_parties` |
| Inventory | `app_inventory` | `hq_stock` |
| Reviews | `app_reviews` | `hq_reviews` |
| Staff | `app_staff` | `hq_profiles` |
| POS sales | `app_pos_sales` | `hq_transactions` (kind = sale) |
| Stripe card | Netlify function `getStripeData` | Stripe API |
