-- Add nested comment support for site discussions
ALTER TABLE "SiteComment"
ADD COLUMN "parentId" TEXT;

ALTER TABLE "SiteComment"
ADD CONSTRAINT "SiteComment_parentId_fkey"
FOREIGN KEY ("parentId") REFERENCES "SiteComment"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

CREATE INDEX "SiteComment_siteId_parentId_createdAt_idx"
ON "SiteComment"("siteId", "parentId", "createdAt");
