ALTER TABLE "SiteComment"
ADD COLUMN "likesCount" INTEGER NOT NULL DEFAULT 0;

CREATE TABLE "SiteCommentLike" (
  "id" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "commentId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  CONSTRAINT "SiteCommentLike_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "SiteCommentLike_commentId_userId_key"
ON "SiteCommentLike"("commentId", "userId");

CREATE INDEX "SiteCommentLike_commentId_createdAt_idx"
ON "SiteCommentLike"("commentId", "createdAt");

CREATE INDEX "SiteCommentLike_userId_createdAt_idx"
ON "SiteCommentLike"("userId", "createdAt");

ALTER TABLE "SiteCommentLike"
ADD CONSTRAINT "SiteCommentLike_commentId_fkey"
FOREIGN KEY ("commentId") REFERENCES "SiteComment"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "SiteCommentLike"
ADD CONSTRAINT "SiteCommentLike_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
