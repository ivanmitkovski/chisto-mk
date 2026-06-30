-- AlterTable
ALTER TABLE "UserSession" ADD COLUMN "tokenId" TEXT;

-- Backfill: use id so existing rows have a value (old refresh tokens will stop working)
UPDATE "UserSession" SET "tokenId" = "id" WHERE "tokenId" IS NULL;

-- Make tokenId required and unique
ALTER TABLE "UserSession" ALTER COLUMN "tokenId" SET NOT NULL;
CREATE UNIQUE INDEX "UserSession_tokenId_key" ON "UserSession"("tokenId");
