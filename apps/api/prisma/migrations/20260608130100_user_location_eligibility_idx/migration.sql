-- Only needed while User.locationEligibility exists (removed in 20260608170000).
-- If column is already gone (e.g. awsDev), mark applied instead of re-running:
--   pnpm exec prisma migrate resolve --applied 20260608130100_user_location_eligibility_idx
CREATE INDEX CONCURRENTLY IF NOT EXISTS "User_locationEligibility_idx"
  ON "User"("locationEligibility");
