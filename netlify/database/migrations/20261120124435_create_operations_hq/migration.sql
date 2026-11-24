CREATE TABLE "hq_access_requests" (
	"user_id" uuid NOT NULL,
	"email" text,
	"full_name" text,
	"status" text DEFAULT 'pending' NOT NULL,
	"decided_by" uuid,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "hq_access_requests_status_check" CHECK ("status" in ('pending','approved','declined'))
);
--> statement-breakpoint
CREATE TABLE "hq_activity_log" (
	"actor_id" uuid,
	"actor_name" text,
	"automated" boolean DEFAULT false NOT NULL,
	"action" text NOT NULL,
	"detail" text,
	"venue_id" text,
	"ref_type" text,
	"ref_id" text,
	"level" text DEFAULT 'info' NOT NULL,
	"id" bigserial PRIMARY KEY,
	"at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "hq_activity_log_level_check" CHECK ("level" in ('info','warn','error'))
);
--> statement-breakpoint
CREATE TABLE "hq_approvals" (
	"kind" text DEFAULT 'reply' NOT NULL,
	"title" text NOT NULL,
	"issue" text,
	"venue_id" text,
	"ref_type" text,
	"ref_id" text,
	"payload" jsonb DEFAULT '{}' NOT NULL,
	"recommended" text,
	"deadline" timestamp with time zone,
	"status" text DEFAULT 'pending' NOT NULL,
	"approver_id" uuid,
	"decided_by" uuid,
	"decided_at" timestamp with time zone,
	"note" text,
	"idem_key" text,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "hq_approvals_kind_check" CHECK ("kind" in ('reply','reminder','refund','spend','discount','complaint','template','conflict')),
	CONSTRAINT "hq_approvals_status_check" CHECK ("status" in ('pending','approved','declined','delegated'))
);
--> statement-breakpoint
CREATE TABLE "hq_automations" (
	"id" text PRIMARY KEY,
	"name" text NOT NULL,
	"mode" text DEFAULT 'draft' NOT NULL,
	"paused" boolean DEFAULT false NOT NULL,
	"last_status" text,
	"last_result" text,
	"last_run" timestamp with time zone,
	CONSTRAINT "hq_automations_mode_check" CHECK ("mode" in ('draft','approve','auto'))
);
--> statement-breakpoint
CREATE TABLE "hq_bookings" (
	"external_ref" text,
	"source" text DEFAULT 'manual' NOT NULL,
	"venue_id" text NOT NULL,
	"customer_id" uuid,
	"product" text,
	"kind" text DEFAULT 'session' NOT NULL,
	"room" text,
	"booking_date" date NOT NULL,
	"start_time" time,
	"end_time" time,
	"guests" integer,
	"status" text DEFAULT 'confirmed' NOT NULL,
	"total" numeric(10,2),
	"paid" numeric(10,2),
	"deposit" numeric(10,2),
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "hq_bookings_kind_check" CHECK ("kind" in ('session','party','group','event')),
	CONSTRAINT "hq_bookings_status_check" CHECK ("status" in ('enquiry','confirmed','moved','cancelled','completed'))
);
--> statement-breakpoint
CREATE TABLE "hq_candidates" (
	"vacancy_id" uuid,
	"venue_id" text,
	"full_name" text NOT NULL,
	"email" text,
	"phone" text,
	"age" integer,
	"stage" text DEFAULT 'Applied' NOT NULL,
	"checks" jsonb DEFAULT '{}' NOT NULL,
	"about" text,
	"source" text,
	"history" jsonb DEFAULT '[]' NOT NULL,
	"delete_after" date,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "hq_candidates_stage_check" CHECK ("stage" in ('Applied','Screening','Interview','Offer','Hired','Rejected','Withdrawn'))
);
--> statement-breakpoint
CREATE TABLE "hq_cases" (
	"kind" text DEFAULT 'complaint' NOT NULL,
	"venue_id" text,
	"customer_name" text NOT NULL,
	"customer_id" uuid,
	"summary" text,
	"sensitive" boolean DEFAULT false NOT NULL,
	"owner_id" uuid,
	"status" text DEFAULT 'open' NOT NULL,
	"outcome" jsonb DEFAULT '{}' NOT NULL,
	"respond_by" date,
	"resolved_at" timestamp with time zone,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "hq_cases_kind_check" CHECK ("kind" in ('complaint','artwork')),
	CONSTRAINT "hq_cases_status_check" CHECK ("status" in ('open','resolved'))
);
--> statement-breakpoint
CREATE TABLE "hq_checklist_items" (
	"checklist_id" uuid NOT NULL,
	"position" integer DEFAULT 0 NOT NULL,
	"label" text NOT NULL,
	"done" boolean DEFAULT false NOT NULL,
	"done_by" uuid,
	"done_at" timestamp with time zone,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid()
);
--> statement-breakpoint
CREATE TABLE "hq_checklists" (
	"venue_id" text NOT NULL,
	"title" text NOT NULL,
	"list_date" date NOT NULL,
	"due_time" time,
	"procedure_id" uuid,
	"ref_type" text,
	"ref_id" text,
	"done_at" timestamp with time zone,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "hq_customers" (
	"name" text NOT NULL,
	"email" text,
	"phone" text,
	"marketing_consent" boolean DEFAULT false NOT NULL,
	"consent_at" timestamp with time zone,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "hq_integrations" (
	"id" text PRIMARY KEY,
	"name" text NOT NULL,
	"status" text DEFAULT 'disconnected' NOT NULL,
	"last_sync" timestamp with time zone,
	"note" text,
	CONSTRAINT "hq_integrations_status_check" CHECK ("status" in ('disconnected','connected','needs_attention'))
);
--> statement-breakpoint
CREATE TABLE "hq_knowledge" (
	"key" text NOT NULL,
	"kind" text DEFAULT 'fact' NOT NULL,
	"title" text NOT NULL,
	"venue_id" text,
	"value_num" numeric(10,2),
	"value_text" text,
	"source" text,
	"version" integer DEFAULT 1 NOT NULL,
	"effective_from" date NOT NULL,
	"status" text DEFAULT 'active' NOT NULL,
	"owner_id" uuid,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "hq_knowledge_kind_check" CHECK ("kind" in ('price','policy','procedure','template','fact')),
	CONSTRAINT "hq_knowledge_status_check" CHECK ("status" in ('active','superseded','needs_review'))
);
--> statement-breakpoint
CREATE TABLE "hq_messages" (
	"thread_id" uuid NOT NULL,
	"direction" text DEFAULT 'in' NOT NULL,
	"outlook_message_id" text,
	"body" text NOT NULL,
	"sent_at" timestamp with time zone,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	CONSTRAINT "hq_messages_direction_check" CHECK ("direction" in ('in','out'))
);
--> statement-breakpoint
CREATE TABLE "hq_parties" (
	"booking_id" uuid,
	"venue_id" text NOT NULL,
	"child_name" text,
	"child_age" integer,
	"party_date" date NOT NULL,
	"start_time" time,
	"end_time" time,
	"room" text,
	"guests" integer,
	"host_id" uuid,
	"food" jsonb DEFAULT '{}' NOT NULL,
	"allergies" text,
	"activities" text[] DEFAULT '{}'::text[] NOT NULL,
	"status" text DEFAULT 'planning' NOT NULL,
	"notes" text,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "hq_parties_status_check" CHECK ("status" in ('planning','ready','cancelled','done'))
);
--> statement-breakpoint
CREATE TABLE "hq_profiles" (
	"id" uuid PRIMARY KEY,
	"full_name" text NOT NULL,
	"email" text,
	"role" text DEFAULT 'staff' NOT NULL,
	"venue_id" text,
	"active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "hq_profiles_role_check" CHECK ("role" in ('owner','ops','lead','staff'))
);
--> statement-breakpoint
CREATE TABLE "hq_role_permissions" (
	"role" text PRIMARY KEY,
	"all_sites" boolean DEFAULT false NOT NULL,
	"inbox" boolean DEFAULT false NOT NULL,
	"finance" boolean DEFAULT false NOT NULL,
	"contact" boolean DEFAULT false NOT NULL,
	"edit_knowledge" boolean DEFAULT false NOT NULL,
	"manage_automations" boolean DEFAULT false NOT NULL,
	"manage_people" boolean DEFAULT false NOT NULL,
	"hr" boolean DEFAULT false NOT NULL,
	"approve_kinds" text[] DEFAULT '{}'::text[] NOT NULL,
	CONSTRAINT "hq_role_permissions_role_check" CHECK ("role" in ('owner','ops','lead','staff'))
);
--> statement-breakpoint
CREATE TABLE "hq_stock" (
	"venue_id" text NOT NULL,
	"item" text NOT NULL,
	"unit" text,
	"level" numeric(10,2) DEFAULT '0' NOT NULL,
	"min_level" numeric(10,2) DEFAULT '0' NOT NULL,
	"unit_cost" numeric(10,2),
	"on_order" boolean DEFAULT false NOT NULL,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "hq_tasks" (
	"title" text NOT NULL,
	"kind" text DEFAULT 'task' NOT NULL,
	"venue_id" text,
	"owner_id" uuid,
	"due_date" date,
	"due_at" timestamp with time zone,
	"status" text DEFAULT 'open' NOT NULL,
	"ref_type" text,
	"ref_id" text,
	"done_at" timestamp with time zone,
	"done_by" uuid,
	"idem_key" text,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "hq_tasks_kind_check" CHECK ("kind" in ('task','promise','follow-up','decision','review')),
	CONSTRAINT "hq_tasks_status_check" CHECK ("status" in ('open','done','cancelled'))
);
--> statement-breakpoint
CREATE TABLE "hq_threads" (
	"outlook_conversation_id" text,
	"venue_id" text,
	"customer_id" uuid,
	"from_name" text,
	"from_email" text,
	"subject" text,
	"category" text,
	"state" text DEFAULT 'new' NOT NULL,
	"party_id" uuid,
	"booking_id" uuid,
	"draft_text" text,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "hq_threads_state_check" CHECK ("state" in ('new','needs-choice','awaiting-approval','replied','closed'))
);
--> statement-breakpoint
CREATE TABLE "hq_transactions" (
	"source" text NOT NULL,
	"external_ref" text,
	"venue_id" text,
	"tx_date" date NOT NULL,
	"kind" text DEFAULT 'sale' NOT NULL,
	"amount" numeric(10,2) NOT NULL,
	"booking_id" uuid,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "hq_transactions_kind_check" CHECK ("kind" in ('sale','refund','deposit','expense'))
);
--> statement-breakpoint
CREATE TABLE "hq_vacancies" (
	"title" text NOT NULL,
	"positions" integer DEFAULT 1 NOT NULL,
	"hours_per_week" numeric(10,2),
	"hourly_rate" numeric(10,2),
	"apprenticeship" boolean DEFAULT false NOT NULL,
	"venue_id" text,
	"status" text DEFAULT 'open' NOT NULL,
	"notes" text,
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "hq_vacancies_status_check" CHECK ("status" in ('draft','open','filled','closed'))
);
--> statement-breakpoint
CREATE TABLE "hq_venues" (
	"id" text PRIMARY KEY,
	"name" text NOT NULL,
	"short_name" text NOT NULL,
	"status" text DEFAULT 'planned' NOT NULL,
	"address" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "hq_venues_status_check" CHECK ("status" in ('trading','planned','closed'))
);
--> statement-breakpoint
CREATE UNIQUE INDEX "hq_access_user_uq" ON "hq_access_requests" ("user_id");--> statement-breakpoint
CREATE INDEX "hq_activity_at_idx" ON "hq_activity_log" ("at");--> statement-breakpoint
CREATE UNIQUE INDEX "hq_approvals_idem_key_uq" ON "hq_approvals" ("idem_key");--> statement-breakpoint
CREATE UNIQUE INDEX "hq_bookings_external_uq" ON "hq_bookings" ("source","external_ref");--> statement-breakpoint
CREATE INDEX "hq_bookings_venue_date_idx" ON "hq_bookings" ("venue_id","booking_date");--> statement-breakpoint
CREATE UNIQUE INDEX "hq_customers_email_uq" ON "hq_customers" (lower("email")) WHERE "email" is not null;--> statement-breakpoint
CREATE INDEX "hq_knowledge_key_idx" ON "hq_knowledge" ("key","venue_id","effective_from");--> statement-breakpoint
CREATE UNIQUE INDEX "hq_messages_outlook_message_id_uq" ON "hq_messages" ("outlook_message_id");--> statement-breakpoint
CREATE UNIQUE INDEX "hq_tasks_idem_key_uq" ON "hq_tasks" ("idem_key");--> statement-breakpoint
CREATE INDEX "hq_tasks_open_idx" ON "hq_tasks" ("status","due_date");--> statement-breakpoint
CREATE UNIQUE INDEX "hq_threads_outlook_conversation_id_uq" ON "hq_threads" ("outlook_conversation_id");--> statement-breakpoint
CREATE UNIQUE INDEX "hq_transactions_external_uq" ON "hq_transactions" ("source","external_ref");--> statement-breakpoint
ALTER TABLE "hq_access_requests" ADD CONSTRAINT "hq_access_requests_decided_by_hq_profiles_id_fkey" FOREIGN KEY ("decided_by") REFERENCES "hq_profiles"("id");--> statement-breakpoint
ALTER TABLE "hq_activity_log" ADD CONSTRAINT "hq_activity_log_actor_id_hq_profiles_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "hq_profiles"("id");--> statement-breakpoint
ALTER TABLE "hq_activity_log" ADD CONSTRAINT "hq_activity_log_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");--> statement-breakpoint
ALTER TABLE "hq_approvals" ADD CONSTRAINT "hq_approvals_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");--> statement-breakpoint
ALTER TABLE "hq_approvals" ADD CONSTRAINT "hq_approvals_approver_id_hq_profiles_id_fkey" FOREIGN KEY ("approver_id") REFERENCES "hq_profiles"("id");--> statement-breakpoint
ALTER TABLE "hq_approvals" ADD CONSTRAINT "hq_approvals_decided_by_hq_profiles_id_fkey" FOREIGN KEY ("decided_by") REFERENCES "hq_profiles"("id");--> statement-breakpoint
ALTER TABLE "hq_bookings" ADD CONSTRAINT "hq_bookings_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");--> statement-breakpoint
ALTER TABLE "hq_bookings" ADD CONSTRAINT "hq_bookings_customer_id_hq_customers_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "hq_customers"("id");--> statement-breakpoint
ALTER TABLE "hq_candidates" ADD CONSTRAINT "hq_candidates_vacancy_id_hq_vacancies_id_fkey" FOREIGN KEY ("vacancy_id") REFERENCES "hq_vacancies"("id");--> statement-breakpoint
ALTER TABLE "hq_candidates" ADD CONSTRAINT "hq_candidates_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");--> statement-breakpoint
ALTER TABLE "hq_cases" ADD CONSTRAINT "hq_cases_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");--> statement-breakpoint
ALTER TABLE "hq_cases" ADD CONSTRAINT "hq_cases_customer_id_hq_customers_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "hq_customers"("id");--> statement-breakpoint
ALTER TABLE "hq_cases" ADD CONSTRAINT "hq_cases_owner_id_hq_profiles_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "hq_profiles"("id");--> statement-breakpoint
ALTER TABLE "hq_checklist_items" ADD CONSTRAINT "hq_checklist_items_checklist_id_hq_checklists_id_fkey" FOREIGN KEY ("checklist_id") REFERENCES "hq_checklists"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "hq_checklist_items" ADD CONSTRAINT "hq_checklist_items_done_by_hq_profiles_id_fkey" FOREIGN KEY ("done_by") REFERENCES "hq_profiles"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "hq_checklists" ADD CONSTRAINT "hq_checklists_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");--> statement-breakpoint
ALTER TABLE "hq_checklists" ADD CONSTRAINT "hq_checklists_procedure_id_hq_knowledge_id_fkey" FOREIGN KEY ("procedure_id") REFERENCES "hq_knowledge"("id");--> statement-breakpoint
ALTER TABLE "hq_knowledge" ADD CONSTRAINT "hq_knowledge_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");--> statement-breakpoint
ALTER TABLE "hq_knowledge" ADD CONSTRAINT "hq_knowledge_owner_id_hq_profiles_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "hq_profiles"("id");--> statement-breakpoint
ALTER TABLE "hq_messages" ADD CONSTRAINT "hq_messages_thread_id_hq_threads_id_fkey" FOREIGN KEY ("thread_id") REFERENCES "hq_threads"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "hq_parties" ADD CONSTRAINT "hq_parties_booking_id_hq_bookings_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "hq_bookings"("id");--> statement-breakpoint
ALTER TABLE "hq_parties" ADD CONSTRAINT "hq_parties_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");--> statement-breakpoint
ALTER TABLE "hq_parties" ADD CONSTRAINT "hq_parties_host_id_hq_profiles_id_fkey" FOREIGN KEY ("host_id") REFERENCES "hq_profiles"("id");--> statement-breakpoint
ALTER TABLE "hq_profiles" ADD CONSTRAINT "hq_profiles_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");--> statement-breakpoint
ALTER TABLE "hq_stock" ADD CONSTRAINT "hq_stock_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");--> statement-breakpoint
ALTER TABLE "hq_tasks" ADD CONSTRAINT "hq_tasks_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");--> statement-breakpoint
ALTER TABLE "hq_tasks" ADD CONSTRAINT "hq_tasks_owner_id_hq_profiles_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "hq_profiles"("id");--> statement-breakpoint
ALTER TABLE "hq_tasks" ADD CONSTRAINT "hq_tasks_done_by_hq_profiles_id_fkey" FOREIGN KEY ("done_by") REFERENCES "hq_profiles"("id");--> statement-breakpoint
ALTER TABLE "hq_threads" ADD CONSTRAINT "hq_threads_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");--> statement-breakpoint
ALTER TABLE "hq_threads" ADD CONSTRAINT "hq_threads_customer_id_hq_customers_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "hq_customers"("id");--> statement-breakpoint
ALTER TABLE "hq_threads" ADD CONSTRAINT "hq_threads_party_id_hq_parties_id_fkey" FOREIGN KEY ("party_id") REFERENCES "hq_parties"("id");--> statement-breakpoint
ALTER TABLE "hq_threads" ADD CONSTRAINT "hq_threads_booking_id_hq_bookings_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "hq_bookings"("id");--> statement-breakpoint
ALTER TABLE "hq_transactions" ADD CONSTRAINT "hq_transactions_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");--> statement-breakpoint
ALTER TABLE "hq_transactions" ADD CONSTRAINT "hq_transactions_booking_id_hq_bookings_id_fkey" FOREIGN KEY ("booking_id") REFERENCES "hq_bookings"("id");--> statement-breakpoint
ALTER TABLE "hq_vacancies" ADD CONSTRAINT "hq_vacancies_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");
--> statement-breakpoint
INSERT INTO hq_venues(id,name,short_name,status) VALUES ('mk','The Paint Patch — Xscape Milton Keynes','Milton Keynes','trading'),('hat','The Paint Patch — The Galleria Hatfield','Hatfield','trading'),('bham','Birmingham (planned)','Birmingham','planned'),('brighton','Brighton (planned)','Brighton','planned'),('manchester','Manchester (planned)','Manchester','planned'),('london','London — 17&Central, Walthamstow (planned)','London','planned'),('dubai','Dubai (planned)','Dubai','planned') ON CONFLICT DO NOTHING;
--> statement-breakpoint
INSERT INTO hq_role_permissions(role,all_sites,inbox,finance,contact,edit_knowledge,manage_automations,manage_people,hr,approve_kinds) VALUES ('owner',true,true,true,true,true,true,true,true,ARRAY['reply','reminder','refund','spend','discount','complaint','template','conflict']::text[]) ON CONFLICT DO NOTHING;
--> statement-breakpoint
INSERT INTO hq_role_permissions(role,all_sites,inbox,finance,contact,edit_knowledge,manage_automations,approve_kinds) VALUES ('ops',true,true,true,true,true,true,ARRAY['reply','reminder','spend','template','complaint']::text[]) ON CONFLICT DO NOTHING;
--> statement-breakpoint
INSERT INTO hq_role_permissions(role,inbox,contact,approve_kinds) VALUES ('lead',true,true,ARRAY['reply','reminder']::text[]) ON CONFLICT DO NOTHING;
--> statement-breakpoint
INSERT INTO hq_role_permissions(role,approve_kinds) VALUES ('staff',ARRAY[]::text[]) ON CONFLICT DO NOTHING;
--> statement-breakpoint
INSERT INTO hq_integrations(id,name) VALUES ('outlook','Outlook'),('roller','ROLLER'),('xero','Xero'),('brighthr','BrightHR / Blip'),('sharepoint','SharePoint'),('instagram','Instagram') ON CONFLICT DO NOTHING;
