-- CreateTable
CREATE TABLE "PasswordResetEmailToken" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "usedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PasswordResetEmailToken_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "PasswordResetEmailToken_userId_idx" ON "PasswordResetEmailToken"("userId");

-- CreateIndex
CREATE INDEX "PasswordResetEmailToken_tokenHash_idx" ON "PasswordResetEmailToken"("tokenHash");

-- AddForeignKey
ALTER TABLE "PasswordResetEmailToken" ADD CONSTRAINT "PasswordResetEmailToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
