-- Deduplicate eco-event style rows before enforcing uniqueness (keep oldest row per key).
DELETE FROM "PointTransaction" AS pt1
USING "PointTransaction" AS pt2
WHERE pt1."id" > pt2."id"
  AND pt1."userId" = pt2."userId"
  AND pt1."reasonCode" = pt2."reasonCode"
  AND pt1."referenceType" IS NOT DISTINCT FROM pt2."referenceType"
  AND pt1."referenceId" IS NOT DISTINCT FROM pt2."referenceId";

-- Create unique index to match Prisma @@unique(map: "point_transaction_user_ref_reason_key")
CREATE UNIQUE INDEX "point_transaction_user_ref_reason_key" ON "PointTransaction" ("userId", "referenceType", "referenceId", "reasonCode");
