-- User moderation notes and status action audit trail
CREATE TABLE "UserModerationNote" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UserModerationNote_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "UserStatusAction" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "actorId" TEXT NOT NULL,
    "fromStatus" "UserStatus" NOT NULL,
    "toStatus" "UserStatus" NOT NULL,
    "reasonCode" TEXT NOT NULL,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UserStatusAction_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "UserModerationNote_userId_createdAt_idx" ON "UserModerationNote"("userId", "createdAt");
CREATE INDEX "UserStatusAction_userId_createdAt_idx" ON "UserStatusAction"("userId", "createdAt");

ALTER TABLE "UserModerationNote" ADD CONSTRAINT "UserModerationNote_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "UserModerationNote" ADD CONSTRAINT "UserModerationNote_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "UserStatusAction" ADD CONSTRAINT "UserStatusAction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "UserStatusAction" ADD CONSTRAINT "UserStatusAction_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
