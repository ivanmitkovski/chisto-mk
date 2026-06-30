-- Add profile avatar storage fields.
ALTER TABLE "User"
ADD COLUMN "avatarObjectKey" TEXT,
ADD COLUMN "avatarUpdatedAt" TIMESTAMP(3);
