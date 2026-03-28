-- Supports map list queries that constrain status and geographic bounds.
CREATE INDEX "Site_status_latitude_longitude_idx" ON "Site"("status", "latitude", "longitude");
