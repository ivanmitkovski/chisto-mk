-- Backfill isPhoneVerified for legacy accounts that completed phone OTP before the gate existed.
-- Idempotent: only updates rows still marked false with a password and a PhoneOtp history row.
UPDATE "User" u
SET "isPhoneVerified" = true
WHERE u."isPhoneVerified" = false
  AND u."passwordHash" IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM "PhoneOtp" o
    WHERE o."phoneNumber" = u."phoneNumber"
  );
