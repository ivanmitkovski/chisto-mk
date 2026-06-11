-- Location eligibility & anti-spoofing: user eligibility state + verification audit trail.

CREATE TYPE "LocationEligibility" AS ENUM (
  'UNVERIFIED',
  'OUTSIDE_MACEDONIA',
  'VERIFIED_IN_MACEDONIA',
  'SUSPICIOUS'
);

ALTER TABLE "User" ADD COLUMN "locationEligibility" "LocationEligibility" NOT NULL DEFAULT 'UNVERIFIED';
ALTER TABLE "User" ADD COLUMN "locationVerifiedAt" TIMESTAMP(3);
ALTER TABLE "User" ADD COLUMN "lastVerifiedLatitude" DOUBLE PRECISION;
ALTER TABLE "User" ADD COLUMN "lastVerifiedLongitude" DOUBLE PRECISION;

CREATE INDEX "User_locationEligibility_idx" ON "User"("locationEligibility");

CREATE TABLE "LocationVerificationEvent" (
  "id" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "userId" TEXT NOT NULL,
  "decision" "LocationEligibility" NOT NULL,
  "gpsLatitude" DOUBLE PRECISION,
  "gpsLongitude" DOUBLE PRECISION,
  "gpsIsMocked" BOOLEAN,
  "gpsInMk" BOOLEAN,
  "accuracyM" DOUBLE PRECISION,
  "ipAddress" TEXT,
  "ipCountry" TEXT,
  "ipInMk" BOOLEAN,
  "networkRisk" TEXT,
  "asn" INTEGER,
  "timezone" TEXT,
  "locale" TEXT,
  "reasons" TEXT[] DEFAULT ARRAY[]::TEXT[],
  CONSTRAINT "LocationVerificationEvent_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "LocationVerificationEvent_userId_createdAt_idx" ON "LocationVerificationEvent"("userId", "createdAt" DESC);
CREATE INDEX "LocationVerificationEvent_decision_createdAt_idx" ON "LocationVerificationEvent"("decision", "createdAt" DESC);

ALTER TABLE "LocationVerificationEvent" ADD CONSTRAINT "LocationVerificationEvent_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Grandfather: users with an in-MK home location are treated as verified, dated to when they set it
-- (so the verification TTL governs and stale users re-verify just-in-time on their next restricted action).
UPDATE "User"
SET "locationEligibility" = 'VERIFIED_IN_MACEDONIA',
    "locationVerifiedAt" = "homeLocationSetAt",
    "lastVerifiedLatitude" = "homeLatitude",
    "lastVerifiedLongitude" = "homeLongitude"
WHERE "homeLocationSetAt" IS NOT NULL
  AND "homeLatitude" IS NOT NULL
  AND "homeLongitude" IS NOT NULL
  AND "homeLatitude" >= 40.8 AND "homeLatitude" <= 42.4
  AND "homeLongitude" >= 20.4 AND "homeLongitude" <= 23.1;
