-- Reporting capacity + emergency allowance defaults for citizen submissions.
ALTER TABLE "User"
ADD COLUMN "reportCreditsAvailable" INTEGER NOT NULL DEFAULT 10,
ADD COLUMN "reportCreditsSpentTotal" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN "reportEmergencyWindowDays" INTEGER NOT NULL DEFAULT 7,
ADD COLUMN "reportEmergencyUsedAt" TIMESTAMP(3);

