-- CreateEnum
CREATE TYPE "AdminModerationCategory" AS ENUM ('NEW_REPORT', 'EVENT_PENDING', 'UGC_REPORT', 'CHECKIN_RISK');

-- CreateEnum
CREATE TYPE "AdminEmailOutboxStatus" AS ENUM ('PENDING', 'SENT', 'FAILED');

-- CreateTable
CREATE TABLE "AdminEmailPreference" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "userId" TEXT NOT NULL,
    "category" "AdminModerationCategory" NOT NULL,
    "enabled" BOOLEAN NOT NULL,

    CONSTRAINT "AdminEmailPreference_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AdminEmailOutbox" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "recipientUserId" TEXT NOT NULL,
    "recipientEmail" TEXT NOT NULL,
    "category" "AdminModerationCategory" NOT NULL,
    "templateId" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "status" "AdminEmailOutboxStatus" NOT NULL DEFAULT 'PENDING',
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "maxAttempts" INTEGER NOT NULL DEFAULT 5,
    "nextAttemptAt" TIMESTAMP(3),
    "processingAt" TIMESTAMP(3),
    "leaseOwner" TEXT,
    "lastAttemptAt" TIMESTAMP(3),
    "lastError" TEXT,
    "idempotencyKey" TEXT NOT NULL,

    CONSTRAINT "AdminEmailOutbox_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "AdminEmailPreference_userId_category_key" ON "AdminEmailPreference"("userId", "category");

-- CreateIndex
CREATE INDEX "AdminEmailPreference_userId_idx" ON "AdminEmailPreference"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "AdminEmailOutbox_idempotencyKey_key" ON "AdminEmailOutbox"("idempotencyKey");

-- CreateIndex
CREATE INDEX "AdminEmailOutbox_status_nextAttemptAt_processingAt_idx" ON "AdminEmailOutbox"("status", "nextAttemptAt", "processingAt");

-- CreateIndex
CREATE INDEX "AdminEmailOutbox_createdAt_idx" ON "AdminEmailOutbox"("createdAt");

-- AddForeignKey
ALTER TABLE "AdminEmailPreference" ADD CONSTRAINT "AdminEmailPreference_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AdminEmailOutbox" ADD CONSTRAINT "AdminEmailOutbox_recipientUserId_fkey" FOREIGN KEY ("recipientUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
