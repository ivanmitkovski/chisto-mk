-- Reconcile denormalized Site.commentsCount with non-deleted SiteComment rows.
UPDATE "Site" s
SET "commentsCount" = (
  SELECT COUNT(*)::integer
  FROM "SiteComment" c
  WHERE c."siteId" = s.id AND c."isDeleted" = false
);
