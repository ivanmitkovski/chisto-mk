-- Composite index for lookups by reference (citizen report / event attribution paths).
CREATE INDEX IF NOT EXISTS "PointTransaction_referenceType_referenceId_idx"
  ON "PointTransaction" ("referenceType", "referenceId");

-- Trigram search on chat message bodies (requires extension once per database).
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS "EventChatMessage_body_trgm_idx"
  ON "EventChatMessage"
  USING gin ("body" gin_trgm_ops);
