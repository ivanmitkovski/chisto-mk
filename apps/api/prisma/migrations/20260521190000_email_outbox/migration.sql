CREATE TABLE "EmailOutbox" (
  "id" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  "userId" TEXT NOT NULL,
  "templateId" TEXT NOT NULL,
  "payload" JSONB NOT NULL,
  "attempts" INTEGER NOT NULL DEFAULT 0,
  "nextRetryAt" TIMESTAMP(3),
  "processingAt" TIMESTAMP(3),
  "leaseOwner" TEXT,
  "lastAttemptAt" TIMESTAMP(3),
  "lastError" TEXT,
  "deliveredAt" TIMESTAMP(3),
  "failedPermanently" BOOLEAN NOT NULL DEFAULT false,
  "idempotencyKey" TEXT NOT NULL,
  CONSTRAINT "EmailOutbox_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "EmailOutbox_idempotencyKey_key" ON "EmailOutbox"("idempotencyKey");
CREATE INDEX "EmailOutbox_deliveredAt_failedPermanently_attempts_idx" ON "EmailOutbox"("deliveredAt", "failedPermanently", "attempts");
CREATE INDEX "EmailOutbox_processingAt_nextRetryAt_idx" ON "EmailOutbox"("processingAt", "nextRetryAt");
