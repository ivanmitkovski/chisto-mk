-- Prevent duplicate history rows for the same report event on a site.
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS "SiteHistoryEntry_siteId_reportId_kind_key"
ON "SiteHistoryEntry" ("siteId", "reportId", "kind")
WHERE "reportId" IS NOT NULL;
