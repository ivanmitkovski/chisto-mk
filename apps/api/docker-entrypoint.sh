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

prisma migrate deploy
exec node dist/main.js
