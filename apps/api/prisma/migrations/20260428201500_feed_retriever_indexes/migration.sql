-- Feed v2 retriever index hardening

CREATE INDEX "Site_status_createdAt_idx" ON "Site"("status", "createdAt");
CREATE INDEX "Site_status_sharesCount_upvotesCount_commentsCount_createdAt_idx"
ON "Site"("status", "sharesCount", "upvotesCount", "commentsCount", "createdAt");
