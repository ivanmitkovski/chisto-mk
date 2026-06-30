-- CreateTable
CREATE TABLE "AdminPendingMfa" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "userId" TEXT NOT NULL,
    "secret" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AdminPendingMfa_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AdminPendingMfa_expiresAt_idx" ON "AdminPendingMfa"("expiresAt");

-- CreateIndex
CREATE UNIQUE INDEX "AdminPendingMfa_userId_key" ON "AdminPendingMfa"("userId");

-- AddForeignKey
ALTER TABLE "AdminPendingMfa" ADD CONSTRAINT "AdminPendingMfa_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
