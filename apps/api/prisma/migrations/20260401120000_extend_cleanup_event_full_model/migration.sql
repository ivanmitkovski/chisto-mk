-- CreateEnum
CREATE TYPE "EcoEventLifecycleStatus" AS ENUM ('UPCOMING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "EcoEventCategory" AS ENUM (
  'GENERAL_CLEANUP',
  'RIVER_AND_LAKE',
  'TREE_AND_GREEN',
  'RECYCLING_DRIVE',
  'HAZARDOUS_REMOVAL',
  'AWARENESS_AND_EDUCATION',
  'OTHER'
);

-- CreateEnum
CREATE TYPE "EcoCleanupScale" AS ENUM ('SMALL', 'MEDIUM', 'LARGE', 'MASSIVE');

-- CreateEnum
CREATE TYPE "EcoEventDifficulty" AS ENUM ('EASY', 'MODERATE', 'HARD');

-- AlterTable
ALTER TABLE "CleanupEvent" ADD COLUMN "title" TEXT NOT NULL DEFAULT 'Cleanup event';
ALTER TABLE "CleanupEvent" ADD COLUMN "description" TEXT NOT NULL DEFAULT '';
ALTER TABLE "CleanupEvent" ADD COLUMN "category" "EcoEventCategory" NOT NULL DEFAULT 'GENERAL_CLEANUP';
ALTER TABLE "CleanupEvent" ADD COLUMN "endAt" TIMESTAMP(3);
ALTER TABLE "CleanupEvent" ADD COLUMN "lifecycleStatus" "EcoEventLifecycleStatus" NOT NULL DEFAULT 'UPCOMING';
ALTER TABLE "CleanupEvent" ADD COLUMN "gear" TEXT[] DEFAULT ARRAY[]::TEXT[];
ALTER TABLE "CleanupEvent" ADD COLUMN "scale" "EcoCleanupScale";
ALTER TABLE "CleanupEvent" ADD COLUMN "difficulty" "EcoEventDifficulty";
ALTER TABLE "CleanupEvent" ADD COLUMN "afterImageKeys" TEXT[] DEFAULT ARRAY[]::TEXT[];
ALTER TABLE "CleanupEvent" ADD COLUMN "maxParticipants" INTEGER;

-- Align lifecycle with legacy completedAt marker
UPDATE "CleanupEvent" SET "lifecycleStatus" = 'COMPLETED' WHERE "completedAt" IS NOT NULL;

-- Drop column defaults used only for backfill (Prisma supplies values on insert)
ALTER TABLE "CleanupEvent" ALTER COLUMN "title" DROP DEFAULT;
ALTER TABLE "CleanupEvent" ALTER COLUMN "description" DROP DEFAULT;

-- CreateTable
CREATE TABLE "EventParticipant" (
    "id" TEXT NOT NULL,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "eventId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "reminderEnabled" BOOLEAN NOT NULL DEFAULT false,
    "reminderAt" TIMESTAMP(3),

    CONSTRAINT "EventParticipant_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "EventParticipant_eventId_userId_key" ON "EventParticipant"("eventId", "userId");

-- CreateIndex
CREATE INDEX "EventParticipant_userId_idx" ON "EventParticipant"("userId");

-- CreateIndex
CREATE INDEX "CleanupEvent_lifecycleStatus_scheduledAt_idx" ON "CleanupEvent"("lifecycleStatus", "scheduledAt");

-- CreateIndex
CREATE INDEX "CleanupEvent_organizerId_idx" ON "CleanupEvent"("organizerId");

-- AddForeignKey
ALTER TABLE "EventParticipant" ADD CONSTRAINT "EventParticipant_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "CleanupEvent"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EventParticipant" ADD CONSTRAINT "EventParticipant_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CleanupEvent" ADD CONSTRAINT "CleanupEvent_organizerId_fkey" FOREIGN KEY ("organizerId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
