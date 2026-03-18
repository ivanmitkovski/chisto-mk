-- CreateTable
CREATE TABLE "LoginFailure" (
    "id" TEXT NOT NULL,
    "phoneNumber" TEXT NOT NULL,
    "firstFailedAt" TIMESTAMP(3) NOT NULL,
    "attemptCount" INTEGER NOT NULL,

    CONSTRAINT "LoginFailure_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "LoginFailure_phoneNumber_key" ON "LoginFailure"("phoneNumber");

-- CreateIndex
CREATE INDEX "LoginFailure_phoneNumber_idx" ON "LoginFailure"("phoneNumber");
