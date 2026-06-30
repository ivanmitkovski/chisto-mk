-- CreateEnum
CREATE TYPE "CleanupEventStatus" AS ENUM ('PENDING', 'APPROVED', 'DECLINED');

-- AlterTable
ALTER TABLE "CleanupEvent" ADD COLUMN     "status" "CleanupEventStatus" NOT NULL DEFAULT 'APPROVED';

-- AlterTable
ALTER TABLE "Report" ALTER COLUMN "reportNumber" DROP NOT NULL;

-- CreateIndex
CREATE INDEX "CleanupEvent_status_idx" ON "CleanupEvent"("status");
