-- Enable pg_trgm for typo-tolerant similarity()
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Add generated tsvector column for full-text search
ALTER TABLE "Site"
  ADD COLUMN IF NOT EXISTS "searchVector" tsvector
  GENERATED ALWAYS AS (
    to_tsvector('simple',
      coalesce("description", '') || ' ' ||
      coalesce("address", ''))
  ) STORED;

-- GIN index for fast full-text search
CREATE INDEX IF NOT EXISTS idx_site_search_vector ON "Site" USING GIN ("searchVector");

-- Trigram index for typo-tolerant similarity queries
CREATE INDEX IF NOT EXISTS idx_site_search_trgm ON "Site" USING GIN (
  (coalesce("description", '') || ' ' || coalesce("address", '')) gin_trgm_ops
);
