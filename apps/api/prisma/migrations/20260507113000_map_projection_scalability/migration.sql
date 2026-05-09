CREATE TABLE "MapSiteProjection" (
  "siteId" TEXT NOT NULL,
  "latitude" DOUBLE PRECISION NOT NULL,
  "longitude" DOUBLE PRECISION NOT NULL,
  "status" "SiteStatus" NOT NULL,
  "address" TEXT,
  "description" TEXT,
  "thumbnailUrl" TEXT,
  "pollutionCategory" TEXT,
  "latestReportTitle" TEXT,
  "latestReportDescription" TEXT,
  "latestReportNumber" TEXT,
  "reportCount" INTEGER NOT NULL DEFAULT 0,
  "upvotesCount" INTEGER NOT NULL DEFAULT 0,
  "commentsCount" INTEGER NOT NULL DEFAULT 0,
  "savesCount" INTEGER NOT NULL DEFAULT 0,
  "sharesCount" INTEGER NOT NULL DEFAULT 0,
  "latestReportAt" TIMESTAMP(3),
  "siteCreatedAt" TIMESTAMP(3) NOT NULL,
  "siteUpdatedAt" TIMESTAMP(3) NOT NULL,
  "projectedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "isHot" BOOLEAN NOT NULL DEFAULT true,
  CONSTRAINT "MapSiteProjection_pkey" PRIMARY KEY ("siteId")
);

CREATE TABLE "MapMunicipalitySummary" (
  "municipalityId" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "centerLat" DOUBLE PRECISION NOT NULL,
  "centerLng" DOUBLE PRECISION NOT NULL,
  "hotSiteCount" INTEGER NOT NULL DEFAULT 0,
  "activeSiteCount" INTEGER NOT NULL DEFAULT 0,
  "cleanedSiteCount" INTEGER NOT NULL DEFAULT 0,
  "totalReportCount" INTEGER NOT NULL DEFAULT 0,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "MapMunicipalitySummary_pkey" PRIMARY KEY ("municipalityId")
);

ALTER TABLE "MapSiteProjection"
  ADD CONSTRAINT "MapSiteProjection_siteId_fkey"
  FOREIGN KEY ("siteId") REFERENCES "Site"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE INDEX "MapSiteProjection_isHot_status_latitude_longitude_idx"
  ON "MapSiteProjection"("isHot", "status", "latitude", "longitude");

CREATE INDEX "MapSiteProjection_isHot_siteUpdatedAt_idx"
  ON "MapSiteProjection"("isHot", "siteUpdatedAt");

CREATE INDEX "MapSiteProjection_status_siteCreatedAt_idx"
  ON "MapSiteProjection"("status", "siteCreatedAt");

CREATE INDEX "idx_map_proj_hot_geo"
  ON "MapSiteProjection"("latitude", "longitude")
  WHERE "isHot" = true;

CREATE INDEX "idx_map_proj_hot_status_geo"
  ON "MapSiteProjection"("status", "latitude", "longitude")
  WHERE "isHot" = true;

CREATE INDEX "idx_site_active_created"
  ON "Site"("createdAt" DESC)
  WHERE status <> 'CLEANED'::"SiteStatus";

CREATE INDEX "idx_outbox_dispatched_cleanup"
  ON "MapEventOutbox"("dispatchedAt")
  WHERE status = 'DISPATCHED'::"MapEventOutboxStatus";
