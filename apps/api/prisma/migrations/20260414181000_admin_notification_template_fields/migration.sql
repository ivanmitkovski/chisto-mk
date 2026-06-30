-- Optional template key + ICU-style params for future locale-aware admin notification rendering.
ALTER TABLE "AdminNotification" ADD COLUMN "messageTemplateKey" TEXT;
ALTER TABLE "AdminNotification" ADD COLUMN "messageTemplateParams" JSONB;
