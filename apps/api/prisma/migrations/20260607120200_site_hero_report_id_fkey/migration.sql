-- Idempotent: dev may already have this FK from db push or a partial apply.
DO $$ BEGIN
  ALTER TABLE "Site" ADD CONSTRAINT "Site_heroReportId_fkey"
    FOREIGN KEY ("heroReportId") REFERENCES "Report"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;
