-- AlterTable
ALTER TABLE "CleanupEvent" ADD COLUMN "checkInSessionId" TEXT;
ALTER TABLE "CleanupEvent" ADD COLUMN "checkInOpen" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "CleanupEvent" ADD COLUMN "checkedInCount" INTEGER NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "EventCheckIn" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "eventId" TEXT NOT NULL,
    "dedupeKey" TEXT NOT NULL,
    "userId" TEXT,
    "guestDisplayName" TEXT,
    "checkedInAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "EventCheckIn_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EventCheckInRedemption" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "eventId" TEXT NOT NULL,
    "jti" TEXT NOT NULL,

    CONSTRAINT "EventCheckInRedemption_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "EventCheckIn_eventId_dedupeKey_key" ON "EventCheckIn"("eventId", "dedupeKey");

-- CreateIndex
CREATE INDEX "EventCheckIn_eventId_checkedInAt_idx" ON "EventCheckIn"("eventId", "checkedInAt");

-- CreateIndex
CREATE UNIQUE INDEX "EventCheckInRedemption_jti_key" ON "EventCheckInRedemption"("jti");

-- CreateIndex
CREATE INDEX "EventCheckInRedemption_eventId_idx" ON "EventCheckInRedemption"("eventId");

-- AddForeignKey
ALTER TABLE "EventCheckIn" ADD CONSTRAINT "EventCheckIn_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "CleanupEvent"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventCheckIn" ADD CONSTRAINT "EventCheckIn_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventCheckInRedemption" ADD CONSTRAINT "EventCheckInRedemption_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "CleanupEvent"("id") ON DELETE CASCADE ON UPDATE CASCADE;
