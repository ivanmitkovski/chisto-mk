-- CreateEnum
CREATE TYPE "EventChatMessageType" AS ENUM ('TEXT', 'SYSTEM');

-- AlterTable
ALTER TABLE "EventChatMessage" ADD COLUMN     "editedAt" TIMESTAMP(3),
ADD COLUMN     "isPinned" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "pinnedAt" TIMESTAMP(3),
ADD COLUMN     "pinnedById" TEXT,
ADD COLUMN     "messageType" "EventChatMessageType" NOT NULL DEFAULT 'TEXT',
ADD COLUMN     "systemPayload" JSONB;

-- CreateIndex
CREATE INDEX "EventChatMessage_eventId_isPinned_pinnedAt_idx" ON "EventChatMessage"("eventId", "isPinned", "pinnedAt");

-- AddForeignKey
ALTER TABLE "EventChatMessage" ADD CONSTRAINT "EventChatMessage_pinnedById_fkey" FOREIGN KEY ("pinnedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- CreateTable
CREATE TABLE "EventChatMute" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "eventId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,

    CONSTRAINT "EventChatMute_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "EventChatMute_eventId_userId_key" ON "EventChatMute"("eventId", "userId");

-- CreateIndex
CREATE INDEX "EventChatMute_userId_idx" ON "EventChatMute"("userId");

-- AddForeignKey
ALTER TABLE "EventChatMute" ADD CONSTRAINT "EventChatMute_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "CleanupEvent"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventChatMute" ADD CONSTRAINT "EventChatMute_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
