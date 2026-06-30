-- CreateEnum
CREATE TYPE "SiteHistoryEntryKind" AS ENUM (
  'SITE_CREATED',
  'REPORT_SUBMITTED',
  'REPORT_APPROVED',
  'REPORT_REJECTED',
  'REPORT_MERGED',
  'STATUS_CHANGED',
  'CLEANUP_EVENT_SCHEDULED',
  'CLEANUP_EVENT_STARTED',
  'CLEANUP_EVENT_COMPLETED',
  'CLEANUP_EVENT_CANCELLED',
  'ARCHIVED_BY_ADMIN',
  'UNARCHIVED_BY_ADMIN',
  'ADMIN_NOTE'
);

-- CreateTable
CREATE TABLE "SiteHistoryEntry" (
  "id" TEXT NOT NULL,
  "siteId" TEXT NOT NULL,
  "kind" "SiteHistoryEntryKind" NOT NULL,
  "occurredAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "fromStatus" "SiteStatus",
  "toStatus" "SiteStatus",
  "reportId" TEXT,
  "cleanupEventId" TEXT,
  "actorUserId" TEXT,
  "actorRole" TEXT,
  "note" TEXT,
  "metadata" JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "SiteHistoryEntry_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "SiteHistoryEntry_siteId_occurredAt_idx" ON "SiteHistoryEntry"("siteId", "occurredAt" DESC);

-- CreateIndex
CREATE INDEX "SiteHistoryEntry_reportId_idx" ON "SiteHistoryEntry"("reportId");

-- CreateIndex
CREATE INDEX "SiteHistoryEntry_cleanupEventId_idx" ON "SiteHistoryEntry"("cleanupEventId");

-- AddForeignKey
ALTER TABLE "SiteHistoryEntry" ADD CONSTRAINT "SiteHistoryEntry_siteId_fkey" FOREIGN KEY ("siteId") REFERENCES "Site"("id") ON DELETE CASCADE ON UPDATE CASCADE;
