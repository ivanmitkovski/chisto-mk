-- Idempotent POST /reports (per user + client key)
CREATE TABLE "ReportSubmitIdempotency" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "userId" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "reportId" TEXT NOT NULL,

    CONSTRAINT "ReportSubmitIdempotency_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "ReportSubmitIdempotency_userId_key_key" ON "ReportSubmitIdempotency"("userId", "key");

CREATE INDEX "ReportSubmitIdempotency_createdAt_idx" ON "ReportSubmitIdempotency"("createdAt");

ALTER TABLE "ReportSubmitIdempotency" ADD CONSTRAINT "ReportSubmitIdempotency_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ReportSubmitIdempotency" ADD CONSTRAINT "ReportSubmitIdempotency_reportId_fkey" FOREIGN KEY ("reportId") REFERENCES "Report"("id") ON DELETE CASCADE ON UPDATE CASCADE;
