-- AlterTable
ALTER TABLE "User" ADD COLUMN     "mfaBackupCodes" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "totpSecret" TEXT;

-- CreateTable
CREATE TABLE "AdminLoginFailure" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "firstFailedAt" TIMESTAMP(3) NOT NULL,
    "attemptCount" INTEGER NOT NULL,

    CONSTRAINT "AdminLoginFailure_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AdminTempToken" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "tokenHash" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AdminTempToken_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "AdminTempToken" ADD CONSTRAINT "AdminTempToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- CreateIndex
CREATE UNIQUE INDEX "AdminLoginFailure_email_key" ON "AdminLoginFailure"("email");

-- CreateIndex
CREATE INDEX "AdminLoginFailure_email_idx" ON "AdminLoginFailure"("email");

-- CreateIndex
CREATE UNIQUE INDEX "AdminTempToken_tokenHash_key" ON "AdminTempToken"("tokenHash");

-- CreateIndex
CREATE INDEX "AdminTempToken_expiresAt_idx" ON "AdminTempToken"("expiresAt");

-- CreateIndex
CREATE INDEX "AdminTempToken_userId_idx" ON "AdminTempToken"("userId");
