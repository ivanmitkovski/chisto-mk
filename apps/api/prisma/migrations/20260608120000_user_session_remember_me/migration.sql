-- Persist remember-me choice on sessions for consistent sliding TTL.

ALTER TABLE "UserSession" ADD COLUMN "rememberMe" BOOLEAN NOT NULL DEFAULT true;
