-- AlterEnum
ALTER TYPE "NotificationType" ADD VALUE 'EVENT_CHAT';

-- CreateTable
CREATE TABLE "EventChatMessage" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "eventId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "replyToId" TEXT,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "EventChatMessage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventChatReadCursor" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "eventId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "lastReadMessageId" TEXT,

    CONSTRAINT "EventChatReadCursor_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "EventChatMessage_eventId_createdAt_idx" ON "EventChatMessage"("eventId", "createdAt");

-- CreateIndex
CREATE INDEX "EventChatMessage_authorId_idx" ON "EventChatMessage"("authorId");

-- CreateIndex
CREATE INDEX "EventChatReadCursor_userId_idx" ON "EventChatReadCursor"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "EventChatReadCursor_eventId_userId_key" ON "EventChatReadCursor"("eventId", "userId");

-- AddForeignKey
ALTER TABLE "EventChatMessage" ADD CONSTRAINT "EventChatMessage_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "CleanupEvent"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventChatMessage" ADD CONSTRAINT "EventChatMessage_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventChatMessage" ADD CONSTRAINT "EventChatMessage_replyToId_fkey" FOREIGN KEY ("replyToId") REFERENCES "EventChatMessage"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventChatReadCursor" ADD CONSTRAINT "EventChatReadCursor_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "CleanupEvent"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventChatReadCursor" ADD CONSTRAINT "EventChatReadCursor_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
