-- AlterTable
ALTER TABLE "CheckInRiskSignal" ADD COLUMN "resolvedAt" TIMESTAMP(3),
ADD COLUMN "resolvedByUserId" TEXT;

-- AddForeignKey
ALTER TABLE "CheckInRiskSignal" ADD CONSTRAINT "CheckInRiskSignal_resolvedByUserId_fkey" FOREIGN KEY ("resolvedByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
