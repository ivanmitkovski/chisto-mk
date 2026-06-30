-- CreateTable
CREATE TABLE "NewsPostRevision" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "postId" TEXT NOT NULL,
    "snapshot" JSONB NOT NULL,
    "createdById" TEXT,

    CONSTRAINT "NewsPostRevision_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "NewsPostRevision_postId_createdAt_idx" ON "NewsPostRevision"("postId", "createdAt" DESC);

-- AddForeignKey
ALTER TABLE "NewsPostRevision" ADD CONSTRAINT "NewsPostRevision_postId_fkey" FOREIGN KEY ("postId") REFERENCES "NewsPost"("id") ON DELETE CASCADE ON UPDATE CASCADE;
