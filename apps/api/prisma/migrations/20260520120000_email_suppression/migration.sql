-- CreateTable
CREATE TABLE "EmailSuppression" (
    "email" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "source" TEXT NOT NULL DEFAULT 'postmark',
    "payload" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EmailSuppression_pkey" PRIMARY KEY ("email")
);

-- CreateIndex
CREATE INDEX "EmailSuppression_createdAt_idx" ON "EmailSuppression"("createdAt");
