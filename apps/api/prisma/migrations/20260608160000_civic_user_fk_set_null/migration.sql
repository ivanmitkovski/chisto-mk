-- Preserve civic contribution rows when a user is hard-purged after erasure grace.
-- Nullable user FKs are set to NULL instead of cascade-deleting engagement rows.

-- ReportCoReporter
ALTER TABLE "ReportCoReporter" DROP CONSTRAINT IF EXISTS "ReportCoReporter_userId_fkey";
ALTER TABLE "ReportCoReporter" ALTER COLUMN "userId" DROP NOT NULL;
ALTER TABLE "ReportCoReporter" ADD CONSTRAINT "ReportCoReporter_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- EventParticipant
ALTER TABLE "EventParticipant" DROP CONSTRAINT IF EXISTS "EventParticipant_userId_fkey";
ALTER TABLE "EventParticipant" ALTER COLUMN "userId" DROP NOT NULL;
ALTER TABLE "EventParticipant" ADD CONSTRAINT "EventParticipant_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- EventCheckIn
ALTER TABLE "EventCheckIn" DROP CONSTRAINT IF EXISTS "EventCheckIn_userId_fkey";
ALTER TABLE "EventCheckIn" ADD CONSTRAINT "EventCheckIn_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- EventChatMessage
ALTER TABLE "EventChatMessage" DROP CONSTRAINT IF EXISTS "EventChatMessage_authorId_fkey";
ALTER TABLE "EventChatMessage" ALTER COLUMN "authorId" DROP NOT NULL;
ALTER TABLE "EventChatMessage" ADD CONSTRAINT "EventChatMessage_authorId_fkey"
  FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- EventEvidencePhoto
ALTER TABLE "EventEvidencePhoto" DROP CONSTRAINT IF EXISTS "EventEvidencePhoto_uploadedById_fkey";
ALTER TABLE "EventEvidencePhoto" ALTER COLUMN "uploadedById" DROP NOT NULL;
ALTER TABLE "EventEvidencePhoto" ADD CONSTRAINT "EventEvidencePhoto_uploadedById_fkey"
  FOREIGN KEY ("uploadedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- SiteVote
ALTER TABLE "SiteVote" DROP CONSTRAINT IF EXISTS "SiteVote_userId_fkey";
ALTER TABLE "SiteVote" ALTER COLUMN "userId" DROP NOT NULL;
ALTER TABLE "SiteVote" ADD CONSTRAINT "SiteVote_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- SiteComment
ALTER TABLE "SiteComment" DROP CONSTRAINT IF EXISTS "SiteComment_authorId_fkey";
ALTER TABLE "SiteComment" ALTER COLUMN "authorId" DROP NOT NULL;
ALTER TABLE "SiteComment" ADD CONSTRAINT "SiteComment_authorId_fkey"
  FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- SiteShareEvent
ALTER TABLE "SiteShareEvent" DROP CONSTRAINT IF EXISTS "SiteShareEvent_userId_fkey";
ALTER TABLE "SiteShareEvent" ALTER COLUMN "userId" DROP NOT NULL;
ALTER TABLE "SiteShareEvent" ADD CONSTRAINT "SiteShareEvent_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
