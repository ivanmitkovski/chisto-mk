-- CreateIndex (CONCURRENTLY must be in its own migration — not inside a Prisma transaction block)
CREATE INDEX CONCURRENTLY IF NOT EXISTS "NewsPost_featured_publishedAt_idx" ON "NewsPost"("featured", "publishedAt" DESC);
