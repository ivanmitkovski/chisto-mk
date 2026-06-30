-- Email channel preferences (independent from push/in-app mute)
ALTER TABLE "UserNotificationPreference" ADD COLUMN "emailMuted" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "UserNotificationPreference" ADD COLUMN "emailMutedUntil" TIMESTAMP(3);
