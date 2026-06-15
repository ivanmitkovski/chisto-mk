#!/usr/bin/env bash
# Recover from P3009 when 20260607120200_site_hero_report_id_fkey is stuck failed.
# Safe when the FK already exists (common on awsDev after partial apply / db push).
set -euo pipefail
cd "$(dirname "$0")/.."

MIGRATION_NAME="20260607120200_site_hero_report_id_fkey"

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "ERROR: set DATABASE_URL to the target Postgres (e.g. awsDev RDS from Secrets Manager)."
  exit 1
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "ERROR: psql is required (install PostgreSQL client)."
  exit 1
fi

echo "==> Clear orphan Site.heroReportId values (if any)"
pnpm exec prisma db execute --stdin <<'SQL'
UPDATE "Site" s
SET "heroReportId" = NULL
WHERE s."heroReportId" IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM "Report" r WHERE r."id" = s."heroReportId");
SQL

FK_EXISTS=$(psql "$DATABASE_URL" -tA -c \
  "SELECT COUNT(*) FROM pg_constraint c
   INNER JOIN pg_class t ON c.conrelid = t.oid
   INNER JOIN pg_namespace n ON t.relnamespace = n.oid
   WHERE n.nspname = 'public' AND t.relname = 'Site' AND c.conname = 'Site_heroReportId_fkey';")

FAILED=$(psql "$DATABASE_URL" -tA -c \
  "SELECT COUNT(*) FROM _prisma_migrations
   WHERE migration_name = '${MIGRATION_NAME}' AND finished_at IS NULL AND rolled_back_at IS NULL;")

echo "==> FK present: ${FK_EXISTS}, migration failed row: ${FAILED}"

if [[ "$FAILED" == "0" ]]; then
  echo "No failed ${MIGRATION_NAME} row — running migrate deploy only."
  pnpm exec prisma migrate deploy
  pnpm exec prisma migrate status
  exit 0
fi

if [[ "$FK_EXISTS" == "1" ]]; then
  echo "==> FK already exists — mark migration applied"
  pnpm exec prisma migrate resolve --applied "$MIGRATION_NAME"
else
  echo "==> Mark failed migration rolled back, then redeploy (uses hardened migration.sql)"
  pnpm exec prisma migrate resolve --rolled-back "$MIGRATION_NAME"
fi

echo "==> prisma migrate deploy"
if ! pnpm exec prisma migrate deploy; then
  echo ""
  echo "migrate deploy failed. Common follow-up on awsDev:"
  echo "  - 20260608130100_user_location_eligibility_idx (column removed by 170000):"
  echo "      pnpm exec prisma migrate resolve --applied 20260608130100_user_location_eligibility_idx"
  echo "    then re-run: pnpm run db:repair:site-hero-fkey  # or migrate deploy"
  exit 1
fi

echo "==> prisma migrate status"
pnpm exec prisma migrate status

echo "OK — restart ECS service if this was awsDev/staging/prod."
