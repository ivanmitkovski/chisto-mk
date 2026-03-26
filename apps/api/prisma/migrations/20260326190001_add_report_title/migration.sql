-- Idempotent: safe if "title" was already added (e.g. partial deploy, manual hotfix).
ALTER TABLE "Report" ADD COLUMN IF NOT EXISTS "title" TEXT;

-- Backfill only rows that still need a title (avoids clobbering existing values).
UPDATE "Report"
SET "title" = CASE
  WHEN "description" IS NOT NULL AND LENGTH(TRIM("description")) > 0
  THEN LEFT(TRIM("description"), 120)
  ELSE 'Reported site'
END
WHERE "title" IS NULL;

ALTER TABLE "Report" ALTER COLUMN "title" SET NOT NULL;
