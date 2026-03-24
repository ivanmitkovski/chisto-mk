-- Create sequence for report numbers
CREATE SEQUENCE IF NOT EXISTS "report_number_seq";

-- Add column (nullable for backfill)
ALTER TABLE "Report" ADD COLUMN IF NOT EXISTS "reportNumber" TEXT;

-- Backfill existing reports: CH-000001, CH-000002, ...
WITH numbered AS (
  SELECT id, row_number() OVER (ORDER BY "createdAt") AS rn
  FROM "Report"
)
UPDATE "Report"
SET "reportNumber" = 'CH-' || LPAD(n.rn::text, 6, '0')
FROM numbered n
WHERE "Report".id = n.id AND "Report"."reportNumber" IS NULL;

-- Set sequence to continue after highest assigned number (min 1: setval(0) is invalid)
SELECT setval(
  'report_number_seq',
  GREATEST(
    COALESCE(
      (SELECT MAX(CAST(SUBSTRING("reportNumber" FROM 4) AS INTEGER)) FROM "Report"),
      0
    ),
    1
  )
);

-- Make column required and unique
ALTER TABLE "Report" ALTER COLUMN "reportNumber" SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "Report_reportNumber_key" ON "Report"("reportNumber");

-- Trigger: auto-assign report number for new inserts
CREATE OR REPLACE FUNCTION set_report_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."reportNumber" IS NULL OR NEW."reportNumber" = '' THEN
    NEW."reportNumber" := 'CH-' || LPAD(nextval('report_number_seq')::text, 6, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS report_number_trigger ON "Report";
CREATE TRIGGER report_number_trigger
  BEFORE INSERT ON "Report"
  FOR EACH ROW
  EXECUTE FUNCTION set_report_number();
