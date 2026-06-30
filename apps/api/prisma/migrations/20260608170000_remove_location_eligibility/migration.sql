-- Remove location eligibility subsystem (replaced by home-location onboarding gate + content geofence).

DROP TABLE IF EXISTS "LocationVerificationEvent";

DROP INDEX IF EXISTS "User_locationEligibility_idx";

ALTER TABLE "User" DROP COLUMN IF EXISTS "locationEligibility";
ALTER TABLE "User" DROP COLUMN IF EXISTS "locationVerifiedAt";
ALTER TABLE "User" DROP COLUMN IF EXISTS "lastVerifiedLatitude";
ALTER TABLE "User" DROP COLUMN IF EXISTS "lastVerifiedLongitude";

DROP TYPE IF EXISTS "LocationEligibility";
