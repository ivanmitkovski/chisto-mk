-- CreateEnum
CREATE TYPE "ReportCleanupEffort" AS ENUM ('ONE_TO_TWO', 'THREE_TO_FIVE', 'SIX_TO_TEN', 'TEN_PLUS', 'NOT_SURE');

-- AlterTable
ALTER TABLE "Site" ADD COLUMN "address" TEXT;

-- AlterTable
ALTER TABLE "Report" ADD COLUMN "cleanupEffort" "ReportCleanupEffort";
