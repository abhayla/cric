CREATE TABLE IF NOT EXISTS "activity_feed" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "user_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "event_type" varchar(30) NOT NULL,
  "title" varchar(100) NOT NULL,
  "description" text,
  "reference_type" varchar(20),
  "reference_id" uuid,
  "is_read" boolean DEFAULT false NOT NULL,
  "created_at" timestamp DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "idx_activity_feed_user_created" ON "activity_feed" ("user_id", "created_at");
