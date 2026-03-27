-- AlterTable
ALTER TABLE "NotificationOutbox"
ADD COLUMN "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN "nextRetryAt" TIMESTAMP(3),
ADD COLUMN "processingAt" TIMESTAMP(3),
ADD COLUMN "leaseOwner" TEXT,
ADD COLUMN "lastErrorCode" TEXT,
ADD COLUMN "lastErrorMessage" TEXT;

-- CreateIndex
CREATE INDEX "NotificationOutbox_processingAt_nextRetryAt_idx"
ON "NotificationOutbox"("processingAt", "nextRetryAt");
