-- AlterTable
ALTER TABLE "User" ADD COLUMN "homeLatitude" DOUBLE PRECISION,
ADD COLUMN "homeLongitude" DOUBLE PRECISION,
ADD COLUMN "homeLocationLabel" TEXT,
ADD COLUMN "homeLocationSetAt" TIMESTAMP(3);
