#!/usr/bin/env bash
# Apply pending Prisma migrations against DATABASE_URL (awsDev RDS or local).
# Run from repo root or apps/api. Requires network access to the database.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "ERROR: set DATABASE_URL to the awsDev RDS connection string (Secrets Manager)."
  echo "Example: export DATABASE_URL='postgresql://user:pass@chisto-dev....rds.amazonaws.com:5432/postgres?schema=public'"
  exit 1
fi

echo "==> prisma migrate status (before)"
pnpm exec prisma migrate status || true

echo "==> prisma migrate deploy"
pnpm exec prisma migrate deploy

echo "==> prisma migrate status (after)"
pnpm exec prisma migrate status

echo "OK — restart ECS service after deploy succeeds."
