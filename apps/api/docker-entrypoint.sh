#!/bin/sh
set -e
cd /app
prisma generate

# Optional manual override (e.g. other failed migrations): set on the task once, then remove.
if [ -n "$PRISMA_RESOLVE_APPLIED_MIGRATION" ]; then
  echo "prisma migrate resolve --applied ${PRISMA_RESOLVE_APPLIED_MIGRATION}"
  prisma migrate resolve --applied "$PRISMA_RESOLVE_APPLIED_MIGRATION" || true
fi

set +e
prisma migrate deploy > /tmp/prisma-migrate.log 2>&1
migrate_status=$?
set -e

cat /tmp/prisma-migrate.log

if [ "$migrate_status" -ne 0 ]; then
  # P3009 / P3018: failed migration in DB (e.g. column already existed). Resolve then retry once.
  if grep -qE 'P3009|P3018|failed migrations|20260326190001_add_report_title' /tmp/prisma-migrate.log; then
    echo "Attempting recovery: prisma migrate resolve --applied 20260326190001_add_report_title"
    prisma migrate resolve --applied "20260326190001_add_report_title" || true
    prisma migrate deploy
  else
    exit "$migrate_status"
  fi
fi

exec node dist/main.js
