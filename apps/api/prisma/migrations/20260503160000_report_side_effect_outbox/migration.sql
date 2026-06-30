-- CreateEnum
CREATE TYPE "ReportSideEffectKind" AS ENUM ('MERGE_DUPLICATE_POST', 'MODERATION_STATUS_POST');

-- CreateEnum
CREATE TYPE "ReportSideEffectStatus" AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED');

-- CreateTable
CREATE TABLE "ReportSideEffect" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "kind" "ReportSideEffectKind" NOT NULL,
    "status" "ReportSideEffectStatus" NOT NULL DEFAULT 'PENDING',
    "payload" JSONB NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "lastError" TEXT,
    "processedAt" TIMESTAMP(3),

    CONSTRAINT "ReportSideEffect_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ReportSideEffect_status_createdAt_idx" ON "ReportSideEffect"("status", "createdAt");
