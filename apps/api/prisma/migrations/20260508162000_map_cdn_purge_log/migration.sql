CREATE TABLE IF NOT EXISTS "MapCdnPurgeLog" (
  "id" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "provider" TEXT NOT NULL,
  "status" TEXT NOT NULL,
  "keys" JSONB NOT NULL,
  "errorMessage" TEXT,
  CONSTRAINT "MapCdnPurgeLog_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "MapCdnPurgeLog_createdAt_idx"
  ON "MapCdnPurgeLog" ("createdAt");
