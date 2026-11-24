CREATE TABLE "hq_ai_library" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"owner_id" uuid NOT NULL,
	"venue_id" text,
	"mode" text NOT NULL,
	"title" text NOT NULL,
	"sections" jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "hq_mail_queue" (
	"id" text PRIMARY KEY,
	"payload" jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "hq_monitor_state" (
	"id" text PRIMARY KEY,
	"inbox_cursor" text,
	"sent_cursor" text,
	"locked_until" timestamp with time zone,
	"paused" boolean DEFAULT true NOT NULL,
	"last_error" text,
	"last_success" timestamp with time zone
);
--> statement-breakpoint
ALTER TABLE "hq_candidates" ADD COLUMN "source_message_id" text;--> statement-breakpoint
ALTER TABLE "hq_candidates" ADD COLUMN "apprenticeship" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "hq_candidates" ADD COLUMN "apprentice_first_year" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "hq_candidates" ADD COLUMN "hourly_rate" numeric(10,2);--> statement-breakpoint
ALTER TABLE "hq_candidates" ADD COLUMN "start_date" date;--> statement-breakpoint
ALTER TABLE "hq_cases" ADD COLUMN "thread_id" uuid;--> statement-breakpoint
ALTER TABLE "hq_threads" ADD COLUMN "priority" text DEFAULT 'low' NOT NULL;--> statement-breakpoint
ALTER TABLE "hq_threads" ADD COLUMN "sensitive" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "hq_threads" ADD COLUMN "monitor_source" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "hq_threads" ADD COLUMN "received_at" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "hq_threads" ADD COLUMN "reply_due_at" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "hq_threads" ADD COLUMN "replied_at" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "hq_threads" ADD COLUMN "response_minutes" integer;--> statement-breakpoint
ALTER TABLE "hq_threads" ADD COLUMN "case_id" uuid;--> statement-breakpoint
ALTER TABLE "hq_threads" ADD COLUMN "outlook_web_link" text;--> statement-breakpoint
ALTER TABLE "hq_candidates" ADD CONSTRAINT "hq_candidates_source_message_id_key" UNIQUE("source_message_id");--> statement-breakpoint
ALTER TABLE "hq_cases" ADD CONSTRAINT "hq_cases_thread_id_key" UNIQUE("thread_id");--> statement-breakpoint
ALTER TABLE "hq_ai_library" ADD CONSTRAINT "hq_ai_library_owner_id_hq_profiles_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "hq_profiles"("id");--> statement-breakpoint
ALTER TABLE "hq_ai_library" ADD CONSTRAINT "hq_ai_library_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");--> statement-breakpoint
ALTER TABLE "hq_candidates" DROP CONSTRAINT "hq_candidates_stage_check", ADD CONSTRAINT "hq_candidates_stage_check" CHECK ("stage" in ('Applied','Screening','Phone screen','Interview','Trial','References','Checks','Offer','Accepted','Onboarding','Probation','Hired','Rejected','Withdrawn'));