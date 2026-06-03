-- Replace email link tokens with email OTP codes for password reset.
DROP TABLE IF EXISTS "PasswordResetEmailToken";

CREATE TABLE "PasswordResetEmailCode" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "codeHash" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "attemptCount" INTEGER NOT NULL DEFAULT 0,
    "lastSentAt" TIMESTAMP(3),
    "sendCountInWindow" INTEGER NOT NULL DEFAULT 0,
    "sendWindowStartedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PasswordResetEmailCode_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "PasswordResetEmailCode_userId_key" ON "PasswordResetEmailCode"("userId");

CREATE INDEX "PasswordResetEmailCode_expiresAt_idx" ON "PasswordResetEmailCode"("expiresAt");

ALTER TABLE "PasswordResetEmailCode" ADD CONSTRAINT "PasswordResetEmailCode_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
