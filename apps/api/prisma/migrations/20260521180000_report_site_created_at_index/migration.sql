-- Feed hot path: latest report per site ordered by createdAt
CREATE INDEX CONCURRENTLY IF NOT EXISTS "Report_siteId_createdAt_idx"
  ON "Report"("siteId", "createdAt" DESC);
