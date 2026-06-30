DO $$ BEGIN
  CREATE TYPE "SiteShareAttributionEventType" AS ENUM ('CLICK', 'OPEN');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE "SiteShareAttributionSource" AS ENUM ('WEB', 'APP', 'OTHER');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS "SiteShareLink" (
  "id" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  "cid" TEXT NOT NULL,
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "countedAt" TIMESTAMP(3),
  "siteId" TEXT NOT NULL,
  "sharedByUserId" TEXT,
  "channel" "SiteShareChannel" NOT NULL DEFAULT 'native',
  CONSTRAINT "SiteShareLink_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "SiteShareAttributionEvent" (
  "id" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "shareLinkId" TEXT NOT NULL,
  "eventType" "SiteShareAttributionEventType" NOT NULL,
  "source" "SiteShareAttributionSource" NOT NULL DEFAULT 'OTHER',
  "dedupeKey" TEXT NOT NULL,
  "ipHash" TEXT,
  "userAgentHash" TEXT,
  "openedByUserId" TEXT,
  CONSTRAINT "SiteShareAttributionEvent_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "SiteShareLink_cid_key" ON "SiteShareLink"("cid");
CREATE INDEX IF NOT EXISTS "SiteShareLink_siteId_createdAt_idx" ON "SiteShareLink"("siteId", "createdAt");
CREATE INDEX IF NOT EXISTS "SiteShareLink_sharedByUserId_createdAt_idx" ON "SiteShareLink"("sharedByUserId", "createdAt");
CREATE INDEX IF NOT EXISTS "SiteShareLink_expiresAt_idx" ON "SiteShareLink"("expiresAt");

CREATE UNIQUE INDEX IF NOT EXISTS "SiteShareAttributionEvent_shareLinkId_eventType_dedupeKey_key"
  ON "SiteShareAttributionEvent"("shareLinkId", "eventType", "dedupeKey");
CREATE INDEX IF NOT EXISTS "SiteShareAttributionEvent_shareLinkId_createdAt_idx"
  ON "SiteShareAttributionEvent"("shareLinkId", "createdAt");
CREATE INDEX IF NOT EXISTS "SiteShareAttributionEvent_eventType_createdAt_idx"
  ON "SiteShareAttributionEvent"("eventType", "createdAt");

DO $$ BEGIN
  ALTER TABLE "SiteShareLink"
    ADD CONSTRAINT "SiteShareLink_siteId_fkey"
    FOREIGN KEY ("siteId") REFERENCES "Site"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE "SiteShareLink"
    ADD CONSTRAINT "SiteShareLink_sharedByUserId_fkey"
    FOREIGN KEY ("sharedByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE "SiteShareAttributionEvent"
    ADD CONSTRAINT "SiteShareAttributionEvent_shareLinkId_fkey"
    FOREIGN KEY ("shareLinkId") REFERENCES "SiteShareLink"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;
