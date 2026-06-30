-- Drop orphan home coordinates that were never confirmed via homeLocationSetAt.
UPDATE "User"
SET "homeLatitude" = NULL,
    "homeLongitude" = NULL,
    "homeLocationLabel" = NULL
WHERE "homeLocationSetAt" IS NULL
  AND ("homeLatitude" IS NOT NULL OR "homeLongitude" IS NOT NULL);
