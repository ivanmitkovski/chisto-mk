-- Feed Algorithm V2 state tables (additive migration, rolling-safe)

CREATE TABLE "UserFeedState" (
    "userId" TEXT NOT NULL,
    "mutedCategoryIds" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "hiddenSiteIds" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "followReporterIds" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "engagementProfile" JSONB,
    "recencyDecayFactor" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "lastFeedAt" TIMESTAMP(3),
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "UserFeedState_pkey" PRIMARY KEY ("userId")
);

CREATE TABLE "SiteFeatureSnapshot" (
    "siteId" TEXT NOT NULL,
    "velocity1h" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "velocity6h" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "velocity24h" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "discussionRatio" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "intentRatio" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "qualityScore" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "freshnessHours" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "severityIndex" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "verifiedAgeDays" INTEGER NOT NULL DEFAULT 0,
    "lastReportAt" TIMESTAMP(3),
    "denormHash" TEXT NOT NULL DEFAULT '',
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "SiteFeatureSnapshot_pkey" PRIMARY KEY ("siteId")
);

CREATE TABLE "FeedImpression" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "userId" TEXT NOT NULL,
    "siteId" TEXT NOT NULL,
    "variant" TEXT NOT NULL,
    "position" INTEGER,
    "dwellMs" INTEGER,
    "engaged" BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT "FeedImpression_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "FeedExperimentAssignment" (
    "userId" TEXT NOT NULL,
    "experimentKey" TEXT NOT NULL,
    "variant" TEXT NOT NULL,
    "assignedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "FeedExperimentAssignment_pkey" PRIMARY KEY ("userId","experimentKey")
);

CREATE INDEX "FeedImpression_userId_createdAt_idx" ON "FeedImpression"("userId", "createdAt");
CREATE INDEX "FeedImpression_siteId_createdAt_idx" ON "FeedImpression"("siteId", "createdAt");

ALTER TABLE "UserFeedState" ADD CONSTRAINT "UserFeedState_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SiteFeatureSnapshot" ADD CONSTRAINT "SiteFeatureSnapshot_siteId_fkey"
FOREIGN KEY ("siteId") REFERENCES "Site"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "FeedImpression" ADD CONSTRAINT "FeedImpression_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "FeedImpression" ADD CONSTRAINT "FeedImpression_siteId_fkey"
FOREIGN KEY ("siteId") REFERENCES "Site"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "FeedExperimentAssignment" ADD CONSTRAINT "FeedExperimentAssignment_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
