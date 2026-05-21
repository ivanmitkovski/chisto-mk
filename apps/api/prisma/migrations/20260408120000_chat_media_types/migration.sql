-- Baseline: applied on awsDev as 20260408120000_chat_media_types (repo folder was renamed to event_chat_v1_enhancements).
-- Idempotent enum/column adds only.

DO $$ BEGIN
  ALTER TYPE "EventChatMessageType" ADD VALUE IF NOT EXISTS 'VIDEO';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TYPE "EventChatMessageType" ADD VALUE IF NOT EXISTS 'AUDIO';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TYPE "EventChatMessageType" ADD VALUE IF NOT EXISTS 'FILE';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE "EventChatAttachment" ADD COLUMN IF NOT EXISTS "duration" INTEGER;
ALTER TABLE "EventChatAttachment" ADD COLUMN IF NOT EXISTS "thumbnailUrl" TEXT;
