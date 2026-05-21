#!/bin/sh
set -e
cd /app
prisma generate

# Optional manual overrides (set on the ECS task for one deploy, then remove):
# PRISMA_RESOLVE_APPLIED_MIGRATION   — prisma migrate resolve --applied <name>
# PRISMA_RESOLVE_ROLLED_BACK_MIGRATION — prisma migrate resolve --rolled-back <name>
if [ -n "$PRISMA_RESOLVE_APPLIED_MIGRATION" ]; then
  echo "prisma migrate resolve --applied ${PRISMA_RESOLVE_APPLIED_MIGRATION}"
  prisma migrate resolve --applied "$PRISMA_RESOLVE_APPLIED_MIGRATION"
fi
if [ -n "$PRISMA_RESOLVE_ROLLED_BACK_MIGRATION" ]; then
  echo "prisma migrate resolve --rolled-back ${PRISMA_RESOLVE_ROLLED_BACK_MIGRATION}"
  prisma migrate resolve --rolled-back "$PRISMA_RESOLVE_ROLLED_BACK_MIGRATION"
fi

# Apply pending migrations on start (Prisma advisory lock — safe with multiple ECS tasks).
# Set MIGRATE_DEPLOY_ON_START=0 on production when a one-off migrate task runs deploy first.
if [ "${SKIP_MIGRATE_STATUS_CHECK:-}" != "1" ] && [ "${MIGRATE_DEPLOY_ON_START:-1}" != "0" ]; then
  echo "Running prisma migrate deploy..."
  prisma migrate deploy
fi

if [ "${SKIP_MIGRATE_STATUS_CHECK:-}" != "1" ]; then
  echo "Checking migration status..."
  prisma migrate status || {
    echo "ERROR: Database migrations are pending or failed after migrate deploy."
    echo "  From a machine with RDS access: cd apps/api && bash scripts/run-migrate-deploy.sh"
    echo "  Emergency only: SKIP_MIGRATE_STATUS_CHECK=1 (schema drift risk)."
    exit 1
  }
  echo "Database migrations are up to date."
fi

exec node dist/main.js
