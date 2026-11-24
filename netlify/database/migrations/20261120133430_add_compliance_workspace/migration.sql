CREATE TABLE "hq_compliance_records" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	"collection" text NOT NULL,
	"venue_id" text,
	"data" jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE INDEX "hq_compliance_collection_venue_idx" ON "hq_compliance_records" ("collection","venue_id");--> statement-breakpoint
ALTER TABLE "hq_compliance_records" ADD CONSTRAINT "hq_compliance_records_venue_id_hq_venues_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "hq_venues"("id");
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('inspection_templates','{"frequency": "Daily", "question": "Fire exits and escape routes are clear", "critical": true, "position": 0, "active": true}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('inspection_templates','{"frequency": "Daily", "question": "First aid supplies and incident reporting are available", "critical": true, "position": 1, "active": true}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('inspection_templates','{"frequency": "Daily", "question": "Activity equipment and surfaces are safe to use", "critical": true, "position": 2, "active": true}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('inspection_templates','{"frequency": "Daily", "question": "Paints, chemicals and cleaning products are stored safely", "critical": true, "position": 3, "active": true}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('inspection_templates','{"frequency": "Daily", "question": "Walkways, toilets and customer areas are clean and safe", "critical": false, "position": 4, "active": true}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('inspection_templates','{"frequency": "Weekly", "question": "Fire alarm test has been recorded", "critical": true, "position": 0, "active": true}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('inspection_templates','{"frequency": "Weekly", "question": "Electrical leads and portable equipment have been visually checked", "critical": true, "position": 1, "active": true}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('inspection_templates','{"frequency": "Weekly", "question": "Stock and chemical safety information are up to date", "critical": false, "position": 2, "active": true}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('inspection_templates','{"frequency": "Weekly", "question": "Outstanding safety actions have been reviewed", "critical": false, "position": 3, "active": true}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('inspection_templates','{"frequency": "Monthly", "question": "Fire safety equipment and emergency lighting checks are recorded", "critical": true, "position": 0, "active": true}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('inspection_templates','{"frequency": "Monthly", "question": "Training renewals and staff certificates have been reviewed", "critical": false, "position": 1, "active": true}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('inspection_templates','{"frequency": "Monthly", "question": "Risk assessments and operating procedures have been reviewed", "critical": true, "position": 2, "active": true}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('inspection_templates','{"frequency": "Monthly", "question": "Insurance and statutory inspection expiry dates have been checked", "critical": true, "position": 3, "active": true}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('training_courses','{"name": "Fire safety awareness", "validity_months": 12, "roles": ["Director", "Site Manager", "Team Leader", "Staff"], "sort": 0}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('training_courses','{"name": "First aid", "validity_months": 36, "roles": ["Director", "Site Manager", "Team Leader", "Staff"], "sort": 1}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('training_courses','{"name": "Safeguarding awareness", "validity_months": 12, "roles": ["Director", "Site Manager", "Team Leader", "Staff"], "sort": 2}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('training_courses','{"name": "COSHH awareness", "validity_months": 12, "roles": ["Director", "Site Manager", "Team Leader", "Staff"], "sort": 3}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,data) VALUES ('training_courses','{"name": "Health and safety induction", "validity_months": 12, "roles": ["Director", "Site Manager", "Team Leader", "Staff"], "sort": 4}'::jsonb);
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,venue_id,data) SELECT 'requirements',id,'{"code": "FIRE-01", "title": "Review the fire risk assessment", "category": "Fire safety", "priority": "Critical", "type": "Best practice", "review_days": 365, "status": "Unverified", "legal_basis": "Confirm applicable obligations with the responsible manager", "notes": "Starter review prompt. Confirm applicability, evidence and review dates; this is not an imported record or a complete legal checklist."}'::jsonb FROM hq_venues WHERE status <> 'closed';
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,venue_id,data) SELECT 'requirements',id,'{"code": "FIRE-02", "title": "Record fire alarm and emergency lighting checks", "category": "Fire safety", "priority": "High", "type": "Best practice", "review_days": 365, "status": "Unverified", "legal_basis": "Confirm applicable obligations with the responsible manager", "notes": "Starter review prompt. Confirm applicability, evidence and review dates; this is not an imported record or a complete legal checklist."}'::jsonb FROM hq_venues WHERE status <> 'closed';
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,venue_id,data) SELECT 'requirements',id,'{"code": "INS-01", "title": "Review public and employer liability insurance", "category": "Insurance", "priority": "High", "type": "Best practice", "review_days": 365, "status": "Unverified", "legal_basis": "Confirm applicable obligations with the responsible manager", "notes": "Starter review prompt. Confirm applicability, evidence and review dates; this is not an imported record or a complete legal checklist."}'::jsonb FROM hq_venues WHERE status <> 'closed';
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,venue_id,data) SELECT 'requirements',id,'{"code": "COSHH-01", "title": "Review substances, safety data sheets and COSHH assessments", "category": "COSHH & substances", "priority": "High", "type": "Best practice", "review_days": 365, "status": "Unverified", "legal_basis": "Confirm applicable obligations with the responsible manager", "notes": "Starter review prompt. Confirm applicability, evidence and review dates; this is not an imported record or a complete legal checklist."}'::jsonb FROM hq_venues WHERE status <> 'closed';
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,venue_id,data) SELECT 'requirements',id,'{"code": "RISK-01", "title": "Review risk assessments for each activity", "category": "Activity risk assessments & procedures", "priority": "High", "type": "Best practice", "review_days": 365, "status": "Unverified", "legal_basis": "Confirm applicable obligations with the responsible manager", "notes": "Starter review prompt. Confirm applicability, evidence and review dates; this is not an imported record or a complete legal checklist."}'::jsonb FROM hq_venues WHERE status <> 'closed';
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,venue_id,data) SELECT 'requirements',id,'{"code": "ELEC-01", "title": "Review electrical safety inspections and testing", "category": "Electrical safety", "priority": "High", "type": "Best practice", "review_days": 365, "status": "Unverified", "legal_basis": "Confirm applicable obligations with the responsible manager", "notes": "Starter review prompt. Confirm applicability, evidence and review dates; this is not an imported record or a complete legal checklist."}'::jsonb FROM hq_venues WHERE status <> 'closed';
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,venue_id,data) SELECT 'requirements',id,'{"code": "HR-01", "title": "Review staff training and first aid coverage", "category": "HR & employment", "priority": "High", "type": "Best practice", "review_days": 365, "status": "Unverified", "legal_basis": "Confirm applicable obligations with the responsible manager", "notes": "Starter review prompt. Confirm applicability, evidence and review dates; this is not an imported record or a complete legal checklist."}'::jsonb FROM hq_venues WHERE status <> 'closed';
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,venue_id,data) SELECT 'requirements',id,'{"code": "SAFE-01", "title": "Review safeguarding policy and reporting procedures", "category": "Safeguarding", "priority": "Critical", "type": "Best practice", "review_days": 365, "status": "Unverified", "legal_basis": "Confirm applicable obligations with the responsible manager", "notes": "Starter review prompt. Confirm applicability, evidence and review dates; this is not an imported record or a complete legal checklist."}'::jsonb FROM hq_venues WHERE status <> 'closed';
--> statement-breakpoint
INSERT INTO hq_compliance_records (collection,venue_id,data) SELECT 'requirements',id,'{"code": "DATA-01", "title": "Review privacy, access and retention arrangements", "category": "Data protection", "priority": "High", "type": "Best practice", "review_days": 365, "status": "Unverified", "legal_basis": "Confirm applicable obligations with the responsible manager", "notes": "Starter review prompt. Confirm applicability, evidence and review dates; this is not an imported record or a complete legal checklist."}'::jsonb FROM hq_venues WHERE status <> 'closed';
