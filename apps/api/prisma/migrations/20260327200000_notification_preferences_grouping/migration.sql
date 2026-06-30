-- Add optional grouping metadata to user notifications
ALTER TABLE "UserNotification"
ADD COLUMN "threadKey" TEXT,
ADD COLUMN "groupKey" TEXT;

-- Add user notification preferences (mute by type)
CREATE TABLE "UserNotificationPreference" (
  "id" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  "userId" TEXT NOT NULL,
  "type" "NotificationType" NOT NULL,
  "muted" BOOLEAN NOT NULL DEFAULT false,
  "mutedUntil" TIMESTAMP(3),
  CONSTRAINT "UserNotificationPreference_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "UserNotificationPreference_userId_type_key"
ON "UserNotificationPreference"("userId", "type");

CREATE INDEX "UserNotificationPreference_userId_muted_idx"
ON "UserNotificationPreference"("userId", "muted");

CREATE INDEX "UserNotification_userId_type_idx"
ON "UserNotification"("userId", "type");

CREATE INDEX "UserNotification_userId_groupKey_createdAt_idx"
ON "UserNotification"("userId", "groupKey", "createdAt");

ALTER TABLE "UserNotificationPreference"
ADD CONSTRAINT "UserNotificationPreference_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
