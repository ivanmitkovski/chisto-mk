-- AlterEnum
ALTER TYPE "EventChatMessageType" ADD VALUE 'IMAGE';
ALTER TYPE "EventChatMessageType" ADD VALUE 'LOCATION';

-- AlterTable
ALTER TABLE "EventChatMessage" ADD COLUMN "locationLat" DOUBLE PRECISION,
ADD COLUMN "locationLng" DOUBLE PRECISION,
ADD COLUMN "locationLabel" TEXT;

-- CreateTable
CREATE TABLE "EventChatAttachment" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "messageId" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "fileName" TEXT NOT NULL,
    "sizeBytes" INTEGER NOT NULL,
    "width" INTEGER,
    "height" INTEGER,

    CONSTRAINT "EventChatAttachment_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "EventChatAttachment_messageId_idx" ON "EventChatAttachment"("messageId");

-- AddForeignKey
ALTER TABLE "EventChatAttachment" ADD CONSTRAINT "EventChatAttachment_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "EventChatMessage"("id") ON DELETE CASCADE ON UPDATE CASCADE;
