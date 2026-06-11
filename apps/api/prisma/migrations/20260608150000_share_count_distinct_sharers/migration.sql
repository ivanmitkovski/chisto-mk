-- Distinct-sharer semantics: one SiteShareEvent per (siteId, userId); sharesCount = distinct sharers.

-- 1. Dedupe existing rows (keep earliest createdAt per site/user).
DELETE FROM "SiteShareEvent" e
USING (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY "siteId", "userId"
      ORDER BY "createdAt" ASC, id ASC
    ) AS rn
  FROM "SiteShareEvent"
) ranked
WHERE e.id = ranked.id
  AND ranked.rn > 1;

-- 2. Enforce one share row per user per site.
CREATE UNIQUE INDEX "SiteShareEvent_siteId_userId_key" ON "SiteShareEvent"("siteId", "userId");

-- 3. Backfill Site.sharesCount from distinct sharers.
UPDATE "Site" s
SET "sharesCount" = COALESCE(sc.cnt, 0)
FROM (
  SELECT "siteId", COUNT(*)::int AS cnt
  FROM "SiteShareEvent"
  GROUP BY "siteId"
) sc
WHERE s.id = sc."siteId";

UPDATE "Site"
SET "sharesCount" = 0
WHERE id NOT IN (SELECT DISTINCT "siteId" FROM "SiteShareEvent");

-- 4. Sync map projection for immediate map consistency.
UPDATE "MapSiteProjection" m
SET "sharesCount" = s."sharesCount"
FROM "Site" s
WHERE m."siteId" = s.id;
