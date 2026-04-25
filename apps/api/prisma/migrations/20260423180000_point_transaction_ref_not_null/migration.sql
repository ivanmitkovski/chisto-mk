-- NULLs do not participate in PostgreSQL unique constraints; coalesce to empty string
-- so @@unique([userId, referenceType, referenceId, reasonCode]) enforces dedupe for all rows.
UPDATE "PointTransaction" SET "referenceId" = '' WHERE "referenceId" IS NULL;
UPDATE "PointTransaction" SET "referenceType" = '' WHERE "referenceType" IS NULL;

ALTER TABLE "PointTransaction" ALTER COLUMN "referenceId" SET DEFAULT '';
ALTER TABLE "PointTransaction" ALTER COLUMN "referenceId" SET NOT NULL;

ALTER TABLE "PointTransaction" ALTER COLUMN "referenceType" SET DEFAULT '';
ALTER TABLE "PointTransaction" ALTER COLUMN "referenceType" SET NOT NULL;
