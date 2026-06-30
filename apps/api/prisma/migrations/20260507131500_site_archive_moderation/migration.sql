ALTER TABLE "Site"
ADD COLUMN "isArchivedByAdmin" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN "archivedAt" TIMESTAMP(3),
ADD COLUMN "archivedById" TEXT,
ADD COLUMN "archiveReason" TEXT;

ALTER TABLE "Site"
ADD CONSTRAINT "Site_archivedById_fkey"
FOREIGN KEY ("archivedById") REFERENCES "User"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX "Site_isArchivedByAdmin_idx" ON "Site"("isArchivedByAdmin");
CREATE INDEX "Site_status_isArchivedByAdmin_updatedAt_idx" ON "Site"("status", "isArchivedByAdmin", "updatedAt");

ALTER TABLE "MapSiteProjection"
ADD COLUMN "isArchivedByAdmin" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN "archivedAt" TIMESTAMP(3);

CREATE INDEX "MapSiteProjection_isArchivedByAdmin_status_latitude_longitude_idx"
ON "MapSiteProjection"("isArchivedByAdmin", "status", "latitude", "longitude");
