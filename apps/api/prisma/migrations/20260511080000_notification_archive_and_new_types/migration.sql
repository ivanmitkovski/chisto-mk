-- AlterEnum
ALTER TYPE "NotificationType" ADD VALUE 'ACHIEVEMENT';
ALTER TYPE "NotificationType" ADD VALUE 'WELCOME';

-- AlterTable
ALTER TABLE "UserNotification" ADD COLUMN "archivedAt" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "UserNotification_userId_archivedAt_createdAt_idx" ON "UserNotification"("userId", "archivedAt", "createdAt");
