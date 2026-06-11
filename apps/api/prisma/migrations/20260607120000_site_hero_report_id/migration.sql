-- Add canonical hero report pointer (earliest APPROVED report with media).
ALTER TABLE "Site" ADD COLUMN "heroReportId" TEXT;

CREATE UNIQUE INDEX "Site_heroReportId_key" ON "Site"("heroReportId");

ALTER TABLE "Site" ADD CONSTRAINT "Site_heroReportId_fkey"
  FOREIGN KEY ("heroReportId") REFERENCES "Report"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Backfill: earliest approved report with at least one non-empty media URL per site.
UPDATE "Site" s
SET "heroReportId" = sub."id"
FROM (
  SELECT DISTINCT ON (r."siteId") r."id", r."siteId"
  FROM "Report" r
  WHERE r."status" = 'APPROVED'
    AND EXISTS (
      SELECT 1
      FROM unnest(r."mediaUrls") AS u(url)
      WHERE btrim(u.url) <> ''
    )
  ORDER BY r."siteId", r."createdAt" ASC, r."id" ASC
) sub
WHERE s."id" = sub."siteId";
