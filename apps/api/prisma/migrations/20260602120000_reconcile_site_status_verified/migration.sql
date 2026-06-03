-- Align legacy rows: sites with an approved report should not remain REPORTED.
UPDATE "Site" s
SET "status" = 'VERIFIED', "updatedAt" = NOW()
WHERE s."status" = 'REPORTED'
  AND EXISTS (
    SELECT 1 FROM "Report" r
    WHERE r."siteId" = s."id" AND r."status" = 'APPROVED'
  );

UPDATE "MapSiteProjection" p
SET "status" = 'VERIFIED'
WHERE p."status" = 'REPORTED'
  AND EXISTS (
    SELECT 1 FROM "Report" r
    WHERE r."siteId" = p."siteId" AND r."status" = 'APPROVED'
  );
