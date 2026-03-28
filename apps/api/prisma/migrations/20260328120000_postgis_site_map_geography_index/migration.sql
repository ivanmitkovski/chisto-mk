-- Geodesic map queries (ST_DWithin) and viewport containment (ST_Within).
-- Requires a role that can CREATE EXTENSION (e.g. RDS master, local superuser).
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE INDEX IF NOT EXISTS "Site_location_geog_gist" ON "Site" USING GIST (
  (ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326)::geography)
);
