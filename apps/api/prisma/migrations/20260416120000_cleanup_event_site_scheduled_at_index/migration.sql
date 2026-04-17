-- Composite index for duplicate schedule checks at the same site.
CREATE INDEX "CleanupEvent_siteId_scheduledAt_idx" ON "CleanupEvent"("siteId", "scheduledAt");
