-- AlterTable
ALTER TABLE "CleanupEvent" ADD COLUMN "moderatedById" TEXT,
ADD COLUMN "moderatedAt" TIMESTAMP(3),
ADD COLUMN "declineReason" TEXT;

-- CreateTable
CREATE TABLE "CleanupEventModerationNote" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "eventId" TEXT NOT NULL,
    "authorId" TEXT,
    "authorEmailSnapshot" TEXT,
    "body" TEXT NOT NULL,

    CONSTRAINT "CleanupEventModerationNote_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "CleanupEventModerationNote_eventId_createdAt_idx" ON "CleanupEventModerationNote"("eventId", "createdAt");

-- CreateIndex
CREATE INDEX "CleanupEventModerationNote_authorId_idx" ON "CleanupEventModerationNote"("authorId");

-- AddForeignKey
ALTER TABLE "CleanupEvent" ADD CONSTRAINT "CleanupEvent_moderatedById_fkey" FOREIGN KEY ("moderatedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CleanupEventModerationNote" ADD CONSTRAINT "CleanupEventModerationNote_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "CleanupEvent"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CleanupEventModerationNote" ADD CONSTRAINT "CleanupEventModerationNote_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
