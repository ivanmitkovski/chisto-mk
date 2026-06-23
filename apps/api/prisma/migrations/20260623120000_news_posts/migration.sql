-- CreateEnum
CREATE TYPE "NewsPostStatus" AS ENUM ('DRAFT', 'SCHEDULED', 'PUBLISHED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "NewsCategory" AS ENUM ('RELEASE', 'PARTNERSHIP', 'COMMUNITY', 'PRODUCT');

-- CreateEnum
CREATE TYPE "NewsMediaKind" AS ENUM ('COVER', 'INLINE_IMAGE', 'INLINE_VIDEO');

-- CreateTable
CREATE TABLE "NewsPost" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "slug" TEXT NOT NULL,
    "category" "NewsCategory" NOT NULL,
    "status" "NewsPostStatus" NOT NULL DEFAULT 'DRAFT',
    "publishedAt" TIMESTAMP(3),
    "scheduledAt" TIMESTAMP(3),
    "coverMediaId" TEXT,
    "translations" JSONB NOT NULL,
    "createdById" TEXT,
    "updatedById" TEXT,

    CONSTRAINT "NewsPost_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "NewsMedia" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "postId" TEXT NOT NULL,
    "kind" "NewsMediaKind" NOT NULL,
    "objectKey" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "fileName" TEXT,
    "sizeBytes" INTEGER NOT NULL,
    "width" INTEGER,
    "height" INTEGER,
    "durationSeconds" INTEGER,
    "altText" JSONB,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "NewsMedia_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "NewsPost_slug_key" ON "NewsPost"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "NewsPost_coverMediaId_key" ON "NewsPost"("coverMediaId");

-- CreateIndex
CREATE INDEX "NewsPost_status_publishedAt_idx" ON "NewsPost"("status", "publishedAt" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "NewsMedia_objectKey_key" ON "NewsMedia"("objectKey");

-- AddForeignKey
ALTER TABLE "NewsPost" ADD CONSTRAINT "NewsPost_coverMediaId_fkey" FOREIGN KEY ("coverMediaId") REFERENCES "NewsMedia"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NewsMedia" ADD CONSTRAINT "NewsMedia_postId_fkey" FOREIGN KEY ("postId") REFERENCES "NewsPost"("id") ON DELETE CASCADE ON UPDATE CASCADE;
