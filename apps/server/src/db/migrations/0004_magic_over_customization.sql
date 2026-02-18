-- Migrate existing single magic_over_number to array + add multiplier/penalty

-- Matches: add new columns
ALTER TABLE "matches" ADD COLUMN "magic_over_numbers" jsonb;
ALTER TABLE "matches" ADD COLUMN "magic_over_run_multiplier" integer NOT NULL DEFAULT 2;
ALTER TABLE "matches" ADD COLUMN "magic_over_wicket_penalty" integer NOT NULL DEFAULT -5;

-- Migrate existing data from magic_over_number to magic_over_numbers array
UPDATE "matches" SET magic_over_numbers = jsonb_build_array(magic_over_number) WHERE magic_over_number IS NOT NULL;

-- Drop old column
ALTER TABLE "matches" DROP COLUMN "magic_over_number";

-- Tournaments: add magic over columns
ALTER TABLE "tournaments" ADD COLUMN "magic_over_numbers" jsonb;
ALTER TABLE "tournaments" ADD COLUMN "magic_over_run_multiplier" integer NOT NULL DEFAULT 2;
ALTER TABLE "tournaments" ADD COLUMN "magic_over_wicket_penalty" integer NOT NULL DEFAULT -5;
