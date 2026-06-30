CREATE INDEX CONCURRENTLY IF NOT EXISTS "UserSession_lastSeenAt_idx"
  ON "UserSession"("lastSeenAt");
