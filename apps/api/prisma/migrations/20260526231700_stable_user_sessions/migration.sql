-- Add stable per-device session metadata and one-step refresh-token grace support.
ALTER TABLE "UserSession"
  ADD COLUMN "previousTokenHash" TEXT,
  ADD COLUMN "rotatedAt" TIMESTAMP(3),
  ADD COLUMN "deviceId" TEXT;

CREATE INDEX "UserSession_userId_deviceId_idx" ON "UserSession"("userId", "deviceId");
