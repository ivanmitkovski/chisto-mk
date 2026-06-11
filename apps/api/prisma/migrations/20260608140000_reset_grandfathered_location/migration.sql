-- Reset users who were grandfathered to VERIFIED_IN_MACEDONIA without a real GPS verification event.
-- They must pass just-in-time location verify on their next point-giving action.
UPDATE "User" u
SET "locationEligibility" = 'UNVERIFIED',
    "locationVerifiedAt" = NULL,
    "lastVerifiedLatitude" = NULL,
    "lastVerifiedLongitude" = NULL
WHERE u."locationEligibility" = 'VERIFIED_IN_MACEDONIA'
  AND NOT EXISTS (
    SELECT 1
    FROM "LocationVerificationEvent" e
    WHERE e."userId" = u."id"
  );
