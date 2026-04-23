-- Idempotent admin bulk mutations (cleanup event moderation jobs).
CREATE TABLE "admin_mutation_idempotency" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actorUserId" TEXT NOT NULL,
    "purpose" TEXT NOT NULL,
    "clientJobId" TEXT NOT NULL,

    CONSTRAINT "admin_mutation_idempotency_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "admin_mutation_idempotency_actorUserId_purpose_clientJobId_key" ON "admin_mutation_idempotency"("actorUserId", "purpose", "clientJobId");

CREATE INDEX "admin_mutation_idempotency_createdAt_idx" ON "admin_mutation_idempotency"("createdAt");
