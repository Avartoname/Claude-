# The Paint Patch HQ

Operations workspace for venues, knowledge, bookings and parties, customer contacts, inbox records, approvals, tasks, cases, checklists, stock, finance, recruitment, people, integrations, automation rules and activity history.

## Deployment and storage

Netlify publishes `public/` and runs API requests through `netlify/server/index.mjs` on Node 24. No frontend build is required. React, HTM and the Netlify Identity browser SDK are version-pinned ES modules served through esm.sh. Netlify Database supplies managed Postgres through Drizzle and `@netlify/database`. The initial migration creates all 22 `hq_` tables, seven real venues, four role permission rows and six disconnected integration entries. No demonstration customer or operational records are inserted.

The supplied Supabase model has been adapted to Netlify Database and Netlify Identity. The API enforces permissions, reference visibility, venue boundaries, finance field redaction and audit recording. The database is never exposed directly to browsers. There is no dependency on Supabase RLS or its `auth.users` table. The previous Compliance HQ source remains in the original root `index.html`; it is outside the publish directory. This release replaces the public entry point and does not import existing Supabase accounts or data.

## First owner

The project owner designated `contact@thepaintpatch.com` as the HQ owner. Confirm that account's email using the Identity confirmation email, then sign in. HQ creates its owner profile automatically from the verified Identity account. No separate owner approval is needed for that mailbox. Email matching ignores case and surrounding spaces; user-editable metadata cannot grant ownership.

Other first-owner accounts require an administrator-assigned `owner` role in Identity app metadata and a confirmed email. Existing HQ profiles, including disabled profiles, are never automatically promoted or reactivated. Other staff accounts still need owner approval through HQ.

## Permissions

Owners manage people, permissions, venues, integrations and finance writes. Operations users work across venues. Leads manage their assigned venue; staff can view its operational records, complete checklist items, update stock, create their own tasks and mark their tasks complete. Customer contact, inbox, finance and HR permissions are checked separately. Sensitive cases require complaint approval permission. An approval requester cannot set a decision or delegate restricted kinds to themselves. Approval decisions and access grants are atomic and audited.

Role permission records can be adjusted by an owner. For protection against account escalation, only an owner can change profiles and decide access requests, even when another role has `manage_people` enabled. HR records are additionally scoped to the user's venues.

## Integrations and automation

These screens are honest registers rather than configured external services. Outlook, ROLLER, Xero, BrightHR, SharePoint and Instagram start disconnected. Messages can be recorded manually and replies saved as drafts; no email is sent. Automation rules can be drafted and set to approval mode; there is no execution worker. The server prevents marking unconnected integrations as connected or enabling automatic execution. No third-party service has been authorized or connected.

## Retention

Candidates default to a delete-after date 180 days after creation. Owners can run **Candidates → Review retention cleanup**, which deletes expired rejected/withdrawn applicants and activity entries older than two years, then records the cleanup. This action requires explicit confirmation in the UI. Cleanup is manual and should form part of a monthly retention review; no automatic schedule is configured. This is a retention mechanism, not a statement of GDPR compliance.

## Development and verification

Use Node 24, `npm ci`, then `netlify dev --port 8889`. Netlify Identity is not emulated locally. The installed CLI may also lack Netlify Server emulation; deployed verification remains necessary for live Identity and managed database access.

`npm test` applies the real migration to an isolated PGlite test database and exercises API authorisation, venue boundaries, financial redaction, access decisions, task ownership, approval finality, checklist actors, retention and validation. It does not read or modify production data. `npm run test:browser` checks the frontend against an isolated database and a test-only authenticated identity while the local development server runs on port 8889. Install the Playwright Chromium browser first if needed.

Collections currently show at most the latest 2,000 records; search and filters operate within that loaded set. No bulk import or general record deletion is exposed. Add schema changes in `db/schema.ts` and generate a named migration with `npm run db:generate -- --name add_descriptive_change` before deployment.
