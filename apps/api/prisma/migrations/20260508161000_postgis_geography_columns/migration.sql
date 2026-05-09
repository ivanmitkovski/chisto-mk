-- Ensure PostGIS is available
CREATE EXTENSION IF NOT EXISTS postgis;

-- Add geography column to MapSiteProjection
ALTER TABLE "MapSiteProjection"
  ADD COLUMN IF NOT EXISTS "geo" geography(Point, 4326);

-- Backfill existing rows
UPDATE "MapSiteProjection"
  SET "geo" = ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326)::geography
  WHERE "geo" IS NULL;

-- Partial GiST index for hot projection rows (primary query path)
CREATE INDEX IF NOT EXISTS idx_map_proj_geo_gist
  ON "MapSiteProjection" USING GIST ("geo")
  WHERE "isHot" = true;

-- Add geography column to Site
ALTER TABLE "Site"
  ADD COLUMN IF NOT EXISTS "geo" geography(Point, 4326);

-- Backfill existing rows
UPDATE "Site"
  SET "geo" = ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326)::geography
  WHERE "geo" IS NULL;

-- Full GiST index on Site
CREATE INDEX IF NOT EXISTS idx_site_geo_gist
  ON "Site" USING GIST ("geo");

-- Trigger function: auto-populate geo on INSERT/UPDATE when lat/lng change
CREATE OR REPLACE FUNCTION sync_geo_from_latlng()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."latitude" IS NOT NULL AND NEW."longitude" IS NOT NULL THEN
    NEW."geo" := ST_SetSRID(ST_MakePoint(NEW."longitude", NEW."latitude"), 4326)::geography;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to MapSiteProjection
DROP TRIGGER IF EXISTS trg_map_proj_sync_geo ON "MapSiteProjection";
CREATE TRIGGER trg_map_proj_sync_geo
  BEFORE INSERT OR UPDATE OF "latitude", "longitude" ON "MapSiteProjection"
  FOR EACH ROW EXECUTE FUNCTION sync_geo_from_latlng();

-- Apply trigger to Site
DROP TRIGGER IF EXISTS trg_site_sync_geo ON "Site";
CREATE TRIGGER trg_site_sync_geo
  BEFORE INSERT OR UPDATE OF "latitude", "longitude" ON "Site"
  FOR EACH ROW EXECUTE FUNCTION sync_geo_from_latlng();
