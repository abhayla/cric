-- Migrate existing single magic_over_number to array + add multiplier/penalty

-- Matches: add new columns (idempotent)
ALTER TABLE "matches" ADD COLUMN IF NOT EXISTS "magic_over_numbers" jsonb;
ALTER TABLE "matches" ADD COLUMN IF NOT EXISTS "magic_over_run_multiplier" integer NOT NULL DEFAULT 2;
ALTER TABLE "matches" ADD COLUMN IF NOT EXISTS "magic_over_wicket_penalty" integer NOT NULL DEFAULT -5;

-- Migrate existing data from magic_over_number to magic_over_numbers array (only if old column exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'matches' AND column_name = 'magic_over_number') THEN
    UPDATE "matches" SET magic_over_numbers = jsonb_build_array(magic_over_number) WHERE magic_over_number IS NOT NULL AND magic_over_numbers IS NULL;
    ALTER TABLE "matches" DROP COLUMN "magic_over_number";
  END IF;
END $$;

-- Tournaments: add magic over columns (idempotent)
ALTER TABLE "tournaments" ADD COLUMN IF NOT EXISTS "magic_over_numbers" jsonb;
ALTER TABLE "tournaments" ADD COLUMN IF NOT EXISTS "magic_over_run_multiplier" integer NOT NULL DEFAULT 2;
ALTER TABLE "tournaments" ADD COLUMN IF NOT EXISTS "magic_over_wicket_penalty" integer NOT NULL DEFAULT -5;
