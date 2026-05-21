-- AlterTable
ALTER TABLE "UserNotification" ADD COLUMN "openedAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "UserNotificationPreference" ADD COLUMN "quietHoursStart" INTEGER;
ALTER TABLE "UserNotificationPreference" ADD COLUMN "quietHoursEnd" INTEGER;
ALTER TABLE "UserNotificationPreference" ADD COLUMN "quietHoursTimezone" TEXT;
