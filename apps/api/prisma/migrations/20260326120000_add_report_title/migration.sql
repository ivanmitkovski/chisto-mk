-- Baseline: applied on awsDev as 20260326120000_add_report_title (folder renamed locally to 20260326190001).
-- Idempotent so migrate deploy is safe if this row already exists in _prisma_migrations.

ALTER TABLE "Report" ADD COLUMN IF NOT EXISTS "title" TEXT;

UPDATE "Report"
SET "title" = CASE
  WHEN "description" IS NOT NULL AND LENGTH(TRIM("description")) > 0
  THEN LEFT(TRIM("description"), 120)
  ELSE 'Reported site'
END
WHERE "title" IS NULL;

DO $$ BEGIN
  ALTER TABLE "Report" ALTER COLUMN "title" SET NOT NULL;
EXCEPTION
  WHEN others THEN NULL;
END $$;
