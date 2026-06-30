#!/usr/bin/env bash
# Reconcile split news featured migrations after 20260624120000 was edited post-apply.
# Safe when production already has the column + index from the original combined migration.
set -euo pipefail
cd "$(dirname "$0")/.."

MIGRATION_COLUMN="20260624120000_news_featured"
MIGRATION_INDEX="20260624120001_news_featured_published_at_idx"

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "ERROR: set DATABASE_URL to the target Postgres."
  exit 1
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "ERROR: psql is required (install PostgreSQL client)."
  exit 1
fi

checksum_for() {
  python3 -c "import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" \
    "prisma/migrations/${1}/migration.sql"
}

COLUMN_CHECKSUM=$(checksum_for "$MIGRATION_COLUMN")
INDEX_CHECKSUM=$(checksum_for "$MIGRATION_INDEX")

echo "==> Align checksum for ${MIGRATION_COLUMN} (if already applied)"
pnpm exec prisma db execute --stdin <<SQL
UPDATE "_prisma_migrations"
SET checksum = '${COLUMN_CHECKSUM}'
WHERE migration_name = '${MIGRATION_COLUMN}';
SQL

INDEX_EXISTS=$(psql "$DATABASE_URL" -tA -c \
  "SELECT COUNT(*) FROM pg_indexes
   WHERE schemaname = 'public'
     AND tablename = 'NewsPost'
     AND indexname = 'NewsPost_featured_publishedAt_idx';")

echo "==> Index present: ${INDEX_EXISTS}"

if [[ "$INDEX_EXISTS" == "1" ]]; then
  echo "==> Mark index migration applied (index already exists)"
  if pnpm exec prisma migrate resolve --applied "$MIGRATION_INDEX" 2>/dev/null; then
    echo "resolve --applied OK"
  else
    pnpm exec prisma db execute --stdin <<SQL
INSERT INTO "_prisma_migrations" (
  id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count
)
SELECT gen_random_uuid()::text, '${INDEX_CHECKSUM}', NOW(), '${MIGRATION_INDEX}', NULL, NULL, NOW(), 1
WHERE NOT EXISTS (
  SELECT 1 FROM "_prisma_migrations" WHERE migration_name = '${MIGRATION_INDEX}'
);
SQL
  fi
else
  echo "==> Index missing — migrate deploy will create it"
fi

echo "==> prisma migrate deploy"
pnpm exec prisma migrate deploy

echo "==> prisma migrate status"
pnpm exec prisma migrate status

echo "OK"
