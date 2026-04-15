-- Count duplicate child reports merged into the canonical report (same or other reporters).
ALTER TABLE "Report" ADD COLUMN "mergedDuplicateChildCount" INTEGER NOT NULL DEFAULT 0;

-- Backfill from moderation audit rows (historical merges before this column existed).
UPDATE "Report" AS r
SET "mergedDuplicateChildCount" = COALESCE(
  (
    SELECT SUM((al."metadata"->>'mergedChildCount')::integer)
    FROM "AuditLog" AS al
    WHERE al."action" = 'REPORT_MERGE'
      AND al."resourceType" = 'Report'
      AND al."resourceId" = r."id"
      AND al."metadata" IS NOT NULL
      AND al."metadata" ? 'mergedChildCount'
  ),
  0
);
