-- Authoritative per-user app locale for localized notifications (en | mk | sq).
ALTER TABLE "User" ADD COLUMN "locale" TEXT;
