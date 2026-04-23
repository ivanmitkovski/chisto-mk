-- Phase 2a–4: live impact metric, evidence photos, route segments, check-in risk signals

CREATE TYPE "EventEvidenceKind" AS ENUM ('BEFORE', 'AFTER', 'FIELD');

CREATE TYPE "RouteSegmentStatus" AS ENUM ('OPEN', 'CLAIMED', 'COMPLETED');

CREATE TYPE "CheckInRiskSignalType" AS ENUM ('FAR_FROM_SITE');

CREATE TABLE "EventLiveMetric" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "eventId" TEXT NOT NULL,
    "reportedBagsCollected" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "EventLiveMetric_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "EventLiveMetric_eventId_key" ON "EventLiveMetric"("eventId");

CREATE TABLE "EventEvidencePhoto" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "eventId" TEXT NOT NULL,
    "kind" "EventEvidenceKind" NOT NULL,
    "objectKey" TEXT NOT NULL,
    "caption" TEXT,
    "uploadedById" TEXT NOT NULL,

    CONSTRAINT "EventEvidencePhoto_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "EventRouteSegment" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "eventId" TEXT NOT NULL,
    "sortOrder" INTEGER NOT NULL,
    "label" TEXT,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "status" "RouteSegmentStatus" NOT NULL DEFAULT 'OPEN',
    "claimedByUserId" TEXT,
    "claimedAt" TIMESTAMP(3),
    "completedAt" TIMESTAMP(3),

    CONSTRAINT "EventRouteSegment_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "CheckInRiskSignal" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "eventId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "signalType" "CheckInRiskSignalType" NOT NULL,
    "metadata" JSONB,

    CONSTRAINT "CheckInRiskSignal_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "EventEvidencePhoto_eventId_kind_createdAt_idx" ON "EventEvidencePhoto"("eventId", "kind", "createdAt");

CREATE INDEX "EventRouteSegment_eventId_sortOrder_idx" ON "EventRouteSegment"("eventId", "sortOrder");

CREATE INDEX "EventRouteSegment_claimedByUserId_idx" ON "EventRouteSegment"("claimedByUserId");

CREATE INDEX "CheckInRiskSignal_eventId_createdAt_idx" ON "CheckInRiskSignal"("eventId", "createdAt");

CREATE INDEX "CheckInRiskSignal_expiresAt_idx" ON "CheckInRiskSignal"("expiresAt");

CREATE INDEX "CheckInRiskSignal_userId_createdAt_idx" ON "CheckInRiskSignal"("userId", "createdAt");

ALTER TABLE "EventLiveMetric" ADD CONSTRAINT "EventLiveMetric_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "CleanupEvent"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "EventEvidencePhoto" ADD CONSTRAINT "EventEvidencePhoto_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "CleanupEvent"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "EventEvidencePhoto" ADD CONSTRAINT "EventEvidencePhoto_uploadedById_fkey" FOREIGN KEY ("uploadedById") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "EventRouteSegment" ADD CONSTRAINT "EventRouteSegment_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "CleanupEvent"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "EventRouteSegment" ADD CONSTRAINT "EventRouteSegment_claimedByUserId_fkey" FOREIGN KEY ("claimedByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "CheckInRiskSignal" ADD CONSTRAINT "CheckInRiskSignal_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "CleanupEvent"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "CheckInRiskSignal" ADD CONSTRAINT "CheckInRiskSignal_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
