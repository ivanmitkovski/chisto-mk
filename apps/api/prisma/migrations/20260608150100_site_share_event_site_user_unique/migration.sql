-- Enforce one share row per user per site (after dedupe in prior migration).
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS "SiteShareEvent_siteId_userId_key"
  ON "SiteShareEvent"("siteId", "userId");
