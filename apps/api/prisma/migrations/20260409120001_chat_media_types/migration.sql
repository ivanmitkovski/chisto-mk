-- AlterEnum (IF NOT EXISTS handles the case where the failed 20260408 migration already added these)
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

-- AlterTable
ALTER TABLE "EventChatAttachment" ADD COLUMN IF NOT EXISTS "duration" INTEGER,
ADD COLUMN IF NOT EXISTS "thumbnailUrl" TEXT;
