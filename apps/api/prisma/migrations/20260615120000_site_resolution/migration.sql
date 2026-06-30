-- CreateEnum
CREATE TYPE "SiteResolutionStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- AlterEnum
ALTER TYPE "SiteHistoryEntryKind" ADD VALUE 'RESOLUTION_SUBMITTED';
ALTER TYPE "SiteHistoryEntryKind" ADD VALUE 'RESOLUTION_APPROVED';
ALTER TYPE "SiteHistoryEntryKind" ADD VALUE 'RESOLUTION_REJECTED';

-- CreateTable
CREATE TABLE "SiteResolution" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "siteId" TEXT NOT NULL,
    "submittedById" TEXT,
    "note" TEXT,
    "mediaUrls" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "status" "SiteResolutionStatus" NOT NULL DEFAULT 'PENDING',
    "isReporterSubmission" BOOLEAN NOT NULL DEFAULT false,
    "moderatedAt" TIMESTAMP(3),
    "moderationReason" TEXT,
    "moderatedById" TEXT,

    CONSTRAINT "SiteResolution_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "SiteResolution_siteId_status_createdAt_idx" ON "SiteResolution"("siteId", "status", "createdAt" DESC);

-- CreateIndex
CREATE INDEX "SiteResolution_submittedById_idx" ON "SiteResolution"("submittedById");

-- CreateIndex
CREATE INDEX "SiteResolution_status_createdAt_idx" ON "SiteResolution"("status", "createdAt" DESC);

-- AddForeignKey
ALTER TABLE "SiteResolution" ADD CONSTRAINT "SiteResolution_siteId_fkey" FOREIGN KEY ("siteId") REFERENCES "Site"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SiteResolution" ADD CONSTRAINT "SiteResolution_submittedById_fkey" FOREIGN KEY ("submittedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SiteResolution" ADD CONSTRAINT "SiteResolution_moderatedById_fkey" FOREIGN KEY ("moderatedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
