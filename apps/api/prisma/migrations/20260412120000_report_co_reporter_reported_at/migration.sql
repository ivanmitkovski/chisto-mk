-- Track original submission time for co-reporters (merge + duplicate flows).
ALTER TABLE "ReportCoReporter" ADD COLUMN "reportedAt" TIMESTAMP(3);

UPDATE "ReportCoReporter" SET "reportedAt" = "createdAt" WHERE "reportedAt" IS NULL;

ALTER TABLE "ReportCoReporter" ALTER COLUMN "reportedAt" SET NOT NULL;
