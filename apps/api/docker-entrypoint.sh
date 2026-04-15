#!/bin/sh
set -e
cd /app
prisma generate

# Optional manual overrides (set on the ECS task for one deploy, then remove):
# PRISMA_RESOLVE_APPLIED_MIGRATION   — prisma migrate resolve --applied <name>
# PRISMA_RESOLVE_ROLLED_BACK_MIGRATION — prisma migrate resolve --rolled-back <name>
if [ -n "$PRISMA_RESOLVE_APPLIED_MIGRATION" ]; then
  echo "prisma migrate resolve --applied ${PRISMA_RESOLVE_APPLIED_MIGRATION}"
  prisma migrate resolve --applied "$PRISMA_RESOLVE_APPLIED_MIGRATION" || true
fi
if [ -n "$PRISMA_RESOLVE_ROLLED_BACK_MIGRATION" ]; then
  echo "prisma migrate resolve --rolled-back ${PRISMA_RESOLVE_ROLLED_BACK_MIGRATION}"
  prisma migrate resolve --rolled-back "$PRISMA_RESOLVE_ROLLED_BACK_MIGRATION" || true
fi

set +e
prisma migrate deploy > /tmp/prisma-migrate.log 2>&1
migrate_status=$?
set -e

cat /tmp/prisma-migrate.log

if [ "$migrate_status" -ne 0 ]; then
  # P3009 / P3018: failed migration in DB. Best-effort retry (legacy report_title drift).
  if grep -qE 'P3009|P3018|failed migrations' /tmp/prisma-migrate.log; then
    echo "Attempting recovery: resolve + redeploy..."
    prisma migrate resolve --applied "20260326190001_add_report_title" 2>/dev/null || true
    if [ -n "$PRISMA_RESOLVE_ROLLED_BACK_MIGRATION" ]; then
      prisma migrate resolve --rolled-back "$PRISMA_RESOLVE_ROLLED_BACK_MIGRATION" 2>/dev/null || true
    fi
    prisma migrate deploy
  else
    exit "$migrate_status"
  fi
fi

exec node dist/main.js
