-- Only needed while User.locationEligibility exists (removed in 20260608170000).
-- awsDev applied removal before this index migration ran — skip safely.
DO $do$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'User'
      AND column_name = 'locationEligibility'
  ) AND NOT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'User'
      AND indexname = 'User_locationEligibility_idx'
  ) THEN
    EXECUTE 'CREATE INDEX "User_locationEligibility_idx" ON "User"("locationEligibility")';
  END IF;
END $do$;
