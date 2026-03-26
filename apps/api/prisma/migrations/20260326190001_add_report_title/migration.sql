-- AlterTable
ALTER TABLE "Report" ADD COLUMN "title" TEXT;

-- Backfill from legacy description (truncated); fallback matches prior list fallback copy
UPDATE "Report"
SET "title" = CASE
  WHEN "description" IS NOT NULL AND LENGTH(TRIM("description")) > 0
  THEN LEFT(TRIM("description"), 120)
  ELSE 'Reported site'
END;

ALTER TABLE "Report" ALTER COLUMN "title" SET NOT NULL;
