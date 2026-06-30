-- CreateEnum
CREATE TYPE "AdminNotificationTone" AS ENUM ('success', 'warning', 'info', 'neutral');

-- CreateEnum
CREATE TYPE "AdminNotificationCategory" AS ENUM ('reports', 'system', 'analytics');

-- AlterTable
ALTER TABLE "Report" ADD COLUMN     "potentialDuplicateOfId" TEXT;

-- CreateTable
CREATE TABLE "AdminNotification" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "userId" TEXT,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "timeLabel" TEXT NOT NULL,
    "tone" "AdminNotificationTone" NOT NULL,
    "category" "AdminNotificationCategory" NOT NULL,
    "isUnread" BOOLEAN NOT NULL DEFAULT true,
    "href" TEXT,

    CONSTRAINT "AdminNotification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ReportCoReporter" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reportId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,

    CONSTRAINT "ReportCoReporter_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AdminNotification_userId_createdAt_idx" ON "AdminNotification"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "AdminNotification_category_createdAt_idx" ON "AdminNotification"("category", "createdAt");

-- CreateIndex
CREATE INDEX "ReportCoReporter_userId_idx" ON "ReportCoReporter"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "ReportCoReporter_reportId_userId_key" ON "ReportCoReporter"("reportId", "userId");

-- CreateIndex
CREATE INDEX "Report_potentialDuplicateOfId_idx" ON "Report"("potentialDuplicateOfId");

-- AddForeignKey
ALTER TABLE "AdminNotification" ADD CONSTRAINT "AdminNotification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Report" ADD CONSTRAINT "Report_potentialDuplicateOfId_fkey" FOREIGN KEY ("potentialDuplicateOfId") REFERENCES "Report"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReportCoReporter" ADD CONSTRAINT "ReportCoReporter_reportId_fkey" FOREIGN KEY ("reportId") REFERENCES "Report"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReportCoReporter" ADD CONSTRAINT "ReportCoReporter_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
