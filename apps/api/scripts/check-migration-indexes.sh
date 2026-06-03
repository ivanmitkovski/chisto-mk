#!/usr/bin/env bash
# Fails CI when a new migration adds CREATE INDEX without CONCURRENTLY (except PK/unique constraints).
# Migrations at or before INDEX_LINT_BASELINE are grandfathered (legacy non-concurrent indexes).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX_LINT_BASELINE="${INDEX_LINT_BASELINE:-20260520120000}"
FAILED=0
while IFS= read -r -d '' file; do
  dir="$(basename "$(dirname "$file")")"
  if [[ "$dir" =~ ^[0-9]+ ]]; then
    ts="${dir%%_*}"
    if [[ "$ts" -le "$INDEX_LINT_BASELINE" ]]; then
      continue
    fi
  fi
  if grep -Ei 'CREATE[[:space:]]+(UNIQUE[[:space:]]+)?INDEX[[:space:]]' "$file" | grep -vi 'CONCURRENTLY' | grep -q .; then
    echo "::error file=$file::CREATE INDEX must use CONCURRENTLY"
    FAILED=1
  fi
done < <(find "$ROOT/prisma/migrations" -name 'migration.sql' -print0 2>/dev/null)
exit "$FAILED"
