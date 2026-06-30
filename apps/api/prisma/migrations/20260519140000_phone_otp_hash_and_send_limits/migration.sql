-- OTP at rest (bcrypt hash) and send-rate metadata
ALTER TABLE "PhoneOtp" ADD COLUMN IF NOT EXISTS "codeHash" TEXT;
ALTER TABLE "PhoneOtp" ADD COLUMN IF NOT EXISTS "lastSentAt" TIMESTAMP(3);
ALTER TABLE "PhoneOtp" ADD COLUMN IF NOT EXISTS "sendCountInWindow" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "PhoneOtp" ADD COLUMN IF NOT EXISTS "sendWindowStartedAt" TIMESTAMP(3);

-- Existing rows keep legacy plaintext in "code" until they expire.
