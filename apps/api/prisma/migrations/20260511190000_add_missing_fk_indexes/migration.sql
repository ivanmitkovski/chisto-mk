-- Add missing FK indexes for foreign-key columns that lacked them.
-- (No CONCURRENTLY — Prisma wraps migrations in a transaction.)

CREATE INDEX IF NOT EXISTS "Site_archivedById_idx" ON "Site" ("archivedById");
CREATE INDEX IF NOT EXISTS "Report_moderatedById_idx" ON "Report" ("moderatedById");
CREATE INDEX IF NOT EXISTS "ReportSubmitIdempotency_reportId_idx" ON "ReportSubmitIdempotency" ("reportId");
CREATE INDEX IF NOT EXISTS "EventChatMessage_replyToId_idx" ON "EventChatMessage" ("replyToId");
CREATE INDEX IF NOT EXISTS "EventChatMessage_pinnedById_idx" ON "EventChatMessage" ("pinnedById");
CREATE INDEX IF NOT EXISTS "EventChatReadCursor_lastReadMessageId_idx" ON "EventChatReadCursor" ("lastReadMessageId");
CREATE INDEX IF NOT EXISTS "EventEvidencePhoto_uploadedById_idx" ON "EventEvidencePhoto" ("uploadedById");
