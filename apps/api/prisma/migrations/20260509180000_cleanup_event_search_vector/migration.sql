-- Full-text search support for cleanup events (ranked search + GIN).
ALTER TABLE "CleanupEvent"
  ADD COLUMN IF NOT EXISTS "searchVector" tsvector
  GENERATED ALWAYS AS (
    to_tsvector('simple', coalesce("title", '') || ' ' || coalesce("description", ''))
  ) STORED;

CREATE INDEX IF NOT EXISTS "CleanupEvent_searchVector_idx" ON "CleanupEvent" USING GIN ("searchVector");
