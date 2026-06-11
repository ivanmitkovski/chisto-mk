-- Partial index for NEARBY_REPORT home-location proximity queries (non-null coords only).
CREATE INDEX CONCURRENTLY IF NOT EXISTS "User_home_location_idx"
ON "User" ("homeLatitude", "homeLongitude")
WHERE "homeLatitude" IS NOT NULL AND "homeLongitude" IS NOT NULL;
