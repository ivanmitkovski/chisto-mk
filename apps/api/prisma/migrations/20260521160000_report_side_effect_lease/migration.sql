-- Lease fields for report side-effect worker (stale PROCESSING recovery)
ALTER TABLE "ReportSideEffect" ADD COLUMN IF NOT EXISTS "processingAt" TIMESTAMP(3);
ALTER TABLE "ReportSideEffect" ADD COLUMN IF NOT EXISTS "leaseOwner" TEXT;
