#!/usr/bin/env bash
# Fails CI when a new migration adds CREATE INDEX without CONCURRENTLY (except PK/unique constraints).
# Indexes on tables created in the same migration file are exempt (empty table; no lock risk).
# Migrations at or before INDEX_LINT_BASELINE are grandfathered (legacy non-concurrent indexes).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX_LINT_BASELINE="${INDEX_LINT_BASELINE:-20260520120000}"
FAILED=0

index_targets_new_table_in_file() {
  local file="$1"
  local line="$2"
  local table
  table="$(printf '%s\n' "$line" | sed -nE 's/.*ON[[:space:]]+"([^"]+)".*/\1/p')"
  if [[ -z "$table" ]]; then
    return 1
  fi
  grep -q "CREATE TABLE \"$table\"" "$file"
}

while IFS= read -r -d '' file; do
  dir="$(basename "$(dirname "$file")")"
  if [[ "$dir" =~ ^[0-9]+ ]]; then
    ts="${dir%%_*}"
    if [[ "$ts" -le "$INDEX_LINT_BASELINE" ]]; then
      continue
    fi
  fi
  while IFS= read -r line; do
    if index_targets_new_table_in_file "$file" "$line"; then
      continue
    fi
    echo "::error file=$file::CREATE INDEX must use CONCURRENTLY"
    FAILED=1
    break
  done < <(grep -Ei 'CREATE[[:space:]]+(UNIQUE[[:space:]]+)?INDEX[[:space:]]' "$file" | grep -vi 'CONCURRENTLY' || true)
done < <(find "$ROOT/prisma/migrations" -name 'migration.sql' -print0 2>/dev/null)
exit "$FAILED"
