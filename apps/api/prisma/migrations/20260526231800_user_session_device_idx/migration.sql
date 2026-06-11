CREATE INDEX CONCURRENTLY IF NOT EXISTS "UserSession_userId_deviceId_idx"
  ON "UserSession"("userId", "deviceId");
