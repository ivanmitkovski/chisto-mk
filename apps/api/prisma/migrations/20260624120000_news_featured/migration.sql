-- AlterTable
ALTER TABLE "NewsPost" ADD COLUMN "featured" BOOLEAN NOT NULL DEFAULT false;

-- CreateIndex
CREATE INDEX CONCURRENTLY IF NOT EXISTS "NewsPost_featured_publishedAt_idx" ON "NewsPost"("featured", "publishedAt" DESC);
