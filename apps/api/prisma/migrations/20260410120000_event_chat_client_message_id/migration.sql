-- AlterTable
ALTER TABLE "EventChatMessage" ADD COLUMN "clientMessageId" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "EventChatMessage_eventId_clientMessageId_key" ON "EventChatMessage"("eventId", "clientMessageId");
