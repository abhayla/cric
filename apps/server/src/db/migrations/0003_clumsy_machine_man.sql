ALTER TABLE "users" ADD COLUMN "is_verified" boolean DEFAULT false NOT NULL;--> statement-breakpoint
UPDATE "users" SET "is_verified" = true WHERE "firebase_uid" NOT LIKE 'placeholder-%';