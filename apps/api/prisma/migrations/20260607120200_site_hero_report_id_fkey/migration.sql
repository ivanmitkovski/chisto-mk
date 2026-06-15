-- Clear hero pointers that no longer reference a Report (e.g. after duplicate-merge hard-delete).
UPDATE "Site" s
SET "heroReportId" = NULL
WHERE s."heroReportId" IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM "Report" r WHERE r."id" = s."heroReportId"
  );

-- Idempotent: dev/staging may already have this FK from db push or a partial apply.
-- Use an existence guard (not EXCEPTION duplicate_object) so Prisma records success reliably.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint c
    INNER JOIN pg_class t ON c.conrelid = t.oid
    INNER JOIN pg_namespace n ON t.relnamespace = n.oid
    WHERE n.nspname = 'public'
      AND t.relname = 'Site'
      AND c.conname = 'Site_heroReportId_fkey'
  ) THEN
    ALTER TABLE "Site" ADD CONSTRAINT "Site_heroReportId_fkey"
      FOREIGN KEY ("heroReportId") REFERENCES "Report"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;
