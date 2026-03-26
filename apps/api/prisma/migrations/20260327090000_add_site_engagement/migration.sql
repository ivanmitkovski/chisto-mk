-- Add denormalized counters for fast feed reads.
ALTER TABLE "Site" ADD COLUMN IF NOT EXISTS "upvotesCount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "Site" ADD COLUMN IF NOT EXISTS "commentsCount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "Site" ADD COLUMN IF NOT EXISTS "savesCount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "Site" ADD COLUMN IF NOT EXISTS "sharesCount" INTEGER NOT NULL DEFAULT 0;

-- New enum for share channels.
DO $$ BEGIN
  CREATE TYPE "SiteShareChannel" AS ENUM ('native', 'link', 'whatsapp', 'facebook', 'x', 'other');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS "SiteVote" (
  "id" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  "siteId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  CONSTRAINT "SiteVote_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "SiteSave" (
  "id" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  "siteId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  CONSTRAINT "SiteSave_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "SiteComment" (
  "id" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  "siteId" TEXT NOT NULL,
  "authorId" TEXT NOT NULL,
  "body" TEXT NOT NULL,
  "isDeleted" BOOLEAN NOT NULL DEFAULT false,
  CONSTRAINT "SiteComment_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "SiteShareEvent" (
  "id" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "siteId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "channel" "SiteShareChannel" NOT NULL DEFAULT 'native',
  CONSTRAINT "SiteShareEvent_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "SiteVote_siteId_userId_key" ON "SiteVote"("siteId", "userId");
CREATE INDEX IF NOT EXISTS "SiteVote_userId_createdAt_idx" ON "SiteVote"("userId", "createdAt");
CREATE INDEX IF NOT EXISTS "SiteVote_siteId_createdAt_idx" ON "SiteVote"("siteId", "createdAt");

CREATE UNIQUE INDEX IF NOT EXISTS "SiteSave_siteId_userId_key" ON "SiteSave"("siteId", "userId");
CREATE INDEX IF NOT EXISTS "SiteSave_userId_createdAt_idx" ON "SiteSave"("userId", "createdAt");
CREATE INDEX IF NOT EXISTS "SiteSave_siteId_createdAt_idx" ON "SiteSave"("siteId", "createdAt");

CREATE INDEX IF NOT EXISTS "SiteComment_siteId_createdAt_idx" ON "SiteComment"("siteId", "createdAt");
CREATE INDEX IF NOT EXISTS "SiteComment_authorId_createdAt_idx" ON "SiteComment"("authorId", "createdAt");

CREATE INDEX IF NOT EXISTS "SiteShareEvent_siteId_createdAt_idx" ON "SiteShareEvent"("siteId", "createdAt");
CREATE INDEX IF NOT EXISTS "SiteShareEvent_userId_createdAt_idx" ON "SiteShareEvent"("userId", "createdAt");

CREATE INDEX IF NOT EXISTS "Site_createdAt_idx" ON "Site"("createdAt");

DO $$ BEGIN
  ALTER TABLE "SiteVote"
    ADD CONSTRAINT "SiteVote_siteId_fkey"
    FOREIGN KEY ("siteId") REFERENCES "Site"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE "SiteVote"
    ADD CONSTRAINT "SiteVote_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE "SiteSave"
    ADD CONSTRAINT "SiteSave_siteId_fkey"
    FOREIGN KEY ("siteId") REFERENCES "Site"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE "SiteSave"
    ADD CONSTRAINT "SiteSave_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE "SiteComment"
    ADD CONSTRAINT "SiteComment_siteId_fkey"
    FOREIGN KEY ("siteId") REFERENCES "Site"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE "SiteComment"
    ADD CONSTRAINT "SiteComment_authorId_fkey"
    FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE "SiteShareEvent"
    ADD CONSTRAINT "SiteShareEvent_siteId_fkey"
    FOREIGN KEY ("siteId") REFERENCES "Site"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  ALTER TABLE "SiteShareEvent"
    ADD CONSTRAINT "SiteShareEvent_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;
