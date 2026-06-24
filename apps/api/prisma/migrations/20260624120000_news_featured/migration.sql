-- AlterTable
ALTER TABLE "NewsPost" ADD COLUMN "featured" BOOLEAN NOT NULL DEFAULT false;

-- CreateIndex
CREATE INDEX "NewsPost_featured_publishedAt_idx" ON "NewsPost"("featured", "publishedAt" DESC);
