CREATE TYPE "MapEventOutboxStatus" AS ENUM ('PENDING', 'DISPATCHED', 'FAILED');

CREATE TABLE "MapEventOutbox" (
  "id" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  "eventId" TEXT NOT NULL,
  "siteId" TEXT NOT NULL,
  "eventType" TEXT NOT NULL,
  "payload" JSONB NOT NULL,
  "status" "MapEventOutboxStatus" NOT NULL DEFAULT 'PENDING',
  "attempts" INTEGER NOT NULL DEFAULT 0,
  "lastError" TEXT,
  "dispatchedAt" TIMESTAMP(3),
  "leaseOwner" TEXT,
  "processingAt" TIMESTAMP(3),
  CONSTRAINT "MapEventOutbox_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "MapEventOutbox_eventId_key" ON "MapEventOutbox"("eventId");
CREATE INDEX "MapEventOutbox_status_createdAt_idx" ON "MapEventOutbox"("status", "createdAt");
CREATE INDEX "MapEventOutbox_siteId_createdAt_idx" ON "MapEventOutbox"("siteId", "createdAt");
CREATE INDEX "MapEventOutbox_processingAt_idx" ON "MapEventOutbox"("processingAt");
