-- Dedupe "cleanup ending soon" push per scheduled end instant; cleared when endAt changes.
ALTER TABLE "CleanupEvent" ADD COLUMN "endSoonNotifiedForEndAt" TIMESTAMP(3);

CREATE INDEX "CleanupEvent_lifecycleStatus_endAt_idx" ON "CleanupEvent" ("lifecycleStatus", "endAt");
