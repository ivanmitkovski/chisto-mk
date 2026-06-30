-- Clear read cursors pointing at missing messages before adding FK.
UPDATE "EventChatReadCursor" AS c
SET "lastReadMessageId" = NULL
WHERE c."lastReadMessageId" IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM "EventChatMessage" AS m WHERE m."id" = c."lastReadMessageId");

-- Optional FK: read position references a chat row (SetNull on message delete).
ALTER TABLE "EventChatReadCursor"
  ADD CONSTRAINT "EventChatReadCursor_lastReadMessageId_fkey"
  FOREIGN KEY ("lastReadMessageId") REFERENCES "EventChatMessage"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;

-- Partial index: list/search paths filter deletedAt IS NULL (Prisma cannot express partial indexes in schema).
CREATE INDEX IF NOT EXISTS "EventChatMessage_eventId_createdAt_active_idx"
  ON "EventChatMessage" ("eventId", "createdAt" DESC)
  WHERE "deletedAt" IS NULL;
