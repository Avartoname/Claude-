# Build: The Paint Patch HQ (Netlify + Supabase)

Build a private, mobile-first operations dashboard called **"The Paint Patch HQ"** for The Paint Patch, a UV/neon paint-splatter studio with two trading venues: **Xscape Milton Keynes (mk)** and **The Galleria Hatfield (hat)**. Planned venues: Birmingham, Brighton, Manchester, London (17&Central, Walthamstow), Dubai. It must scale to 10+ sites.

## Stack
- Vite + React + TypeScript, deployed on Netlify.
- Supabase for the database, auth and realtime. The schema already exists. Use the `hq_` tables (hq_venues, hq_profiles, hq_role_permissions, hq_access_requests, hq_knowledge, hq_customers, hq_bookings, hq_parties, hq_threads, hq_messages, hq_approvals, hq_tasks, hq_cases, hq_checklists, hq_checklist_items, hq_stock, hq_transactions, hq_vacancies, hq_candidates, hq_integrations, hq_automations, hq_activity_log). Row Level Security is already on. Do NOT disable it or use the service role key in the browser.
- Netlify Functions for anything secret. Env vars: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` (functions only), `ANTHROPIC_API_KEY`, `MS_TENANT_ID`, `MS_CLIENT_ID`, `MS_CLIENT_SECRET`, `MS_MAILBOX` (bookings@thepaintpatch.com).

## Sign-in and roles
- Supabase email magic-link sign-in.
- A new user gets an access request (hq_access_requests) and sees a "Request access" screen until approved.
- Roles: **owner, ops, lead, staff**. Permissions come from hq_role_permissions (all_sites, inbox, finance, contact, edit_knowledge, manage_automations, manage_people, hr, approve_kinds).
- **Settings & people:** the owner approves requests, sets each person's role and venue, and edits the permission matrix.
- The owner can "Preview as" any role.
- Staff only see their own venue. Inbox, money and HR are hidden without the permission. Sensitive complaints are only visible to people who approve complaints. Candidate records are owner-only by default.

## Screens (bottom tab bar on mobile: Today, Inbox, Parties, Approvals, More)
1. **Today:** "Ask HQ" search bar; customer-service banner (overdue / high priority / waiting); decisions waiting for me; today's parties per venue with ready/not-ready reasons; my tasks with overdue in red; checklists done/overdue; daily briefing.
2. **Customer service** (monitor only, no auto drafts). See "Outlook monitor" below.
3. **Inbox:** customer email threads with category, venue and state.
4. **Parties:** upcoming parties by venue. Each party has a host sheet (printable), food choices, allergies, room and host.
5. **Approvals:** approve / decline / delegate, with deadlines. Kinds: reply, reminder, refund, spend, discount, complaint, template, conflict.
6. **Operations:** opening/closing checklists per venue with tick-off and overdue flags; complaint and lost-artwork cases with promises and outcomes; stock levels with reorder flags.
7. **HR:** vacancies and an 11-stage candidate kanban (Applied → Probation).
   - **Wage check:** block "Offer" below the legal minimum. From 1 Apr 2026: apprentice £8.00 (under 19, or 19+ in first year); 18–20 £10.85; 21+ £12.71. Flag the £8 apprentice rate for review.
   - **Funding:** show as "college-provided, provisional", not verified.
   - **Probation:** creates a review task at 84 days.
8. **TPP PA** (marketing assistant): modes are Content bundle (optional photos), 2-week Content plan from real bookings, Review requests, Reply to review, Campaign plan, and Ask. Each section of the output has a Copy button, plus Refine and Save to library. Drafts only; nothing posts.
9. **Knowledge:** prices and policies, versioned, per venue, effective-dated. When sources conflict, raise a "conflict" approval.
10. **Activity log:** every automated or human action, filterable, with CSV export.
11. **Integrations:** status shown as Disconnected / Connected / Needs attention for Outlook, ROLLER, Xero, BrightHR/Blip, SharePoint and Instagram, plus a CSV bookings import with duplicate detection.

## Ask HQ (chat search)
- Floating "✦ Ask HQ" button plus the search bar on Today.
- Local keyword search over the records the user is allowed to see. Results are tappable cards.
- Then a Netlify function `ask` calls Claude (`claude-sonnet-5-5`). It sends a compact, permission-filtered context: today's summary plus the top 25 matching records as `[type:id] title — detail`.
- Claude must answer only from that data, cite records as `[type:id]` (render these as links) and say what's missing. It must never invent prices, dates or figures.
- The function verifies the Supabase JWT and checks the user is an HQ member before calling Claude.

## Outlook monitor (scheduled Netlify function every 5 minutes)
Use Microsoft Graph with app credentials to read `MS_MAILBOX` Inbox and Sent Items. Read only: never send or draft.

**New inbound mail:**
- Skip newsletters and no-reply senders.
- Parse "Website contact" form emails to get the real customer.
- Turn "Job application" emails into candidates.
- Upsert hq_threads and hq_messages.

**Triage each thread:**

| Category | Signals | Priority | Reply within |
|---|---|---|---|
| safety | injury, paint in eyes, A&E, safeguarding | high | 4h |
| legal | solicitor, chargeback, Trading Standards | high | 4h |
| complaint | rude, ruined, disappointed, bad review | medium | 24h |
| refund | — | medium | 24h |
| chasing | still waiting, no reply | medium | 24h |
| service | everything else | low | 48h |

- Complaint, safety and legal threads open a case once per thread. Safety and legal cases are sensitive and need owner approval.
- **Sent Items:** match replies by conversationId or recipient address. Mark the thread replied and record the response time.
- **Overdue:** create a task once per thread (high priority goes to the owner, the rest to the venue lead) and log it.
- **Customer service screen:** KPIs (overdue, complaints & issues, queries waiting, average reply time over 7 days). Sections for Overdue / Complaints & issues / Queries / Recently handled. Each row has Open in Outlook, Case and Handled buttons.

## Rules
- UK English, £, 24-hour time, Europe/London timezone throughout.
- **No invented data.** Where data is unavailable, show "Not connected" or "Awaiting data". No demo or example records in production.
- Every automation must be idempotent (no duplicate tasks, approvals or cases) and log its result to hq_activity_log. Respect pause and "integration down" states.
- **UK GDPR:**
  - Never put customers' or children's names into marketing content.
  - Mask contact details for roles without "contact".
  - Delete unsuccessful candidates after 180 days and activity log entries after 2 years.
- **Brand:** dark UI, hot pink #FF2E93, violet #8B5CFF, lime #C6FF3D; Space Grotesk headings, Inter body. Fast and thumb-friendly on a 390px-wide phone.

## Deliver in this order
1. Auth, roles and access requests, Settings & people.
2. Today, Customer service and the Outlook monitor function.
3. Inbox, Parties, Approvals, Operations.
4. Ask HQ and TPP PA (the `ask` function).
5. HR, Knowledge, Activity log, Integrations / CSV import.

Test each step on mobile before moving on.
