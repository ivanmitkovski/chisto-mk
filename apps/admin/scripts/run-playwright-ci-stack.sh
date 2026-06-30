#!/usr/bin/env bash
# Starts API + admin for Playwright smoke/perf/a11y in CI. Requires postgres, redis, and prior `pnpm build`.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
API_PORT="${API_PORT:-3000}"
ADMIN_PORT="${ADMIN_PORT:-3001}"
API_URL="http://127.0.0.1:${API_PORT}"
ADMIN_URL="http://127.0.0.1:${ADMIN_PORT}"

cleanup() {
  if [[ -n "${ADMIN_PID:-}" ]]; then kill "$ADMIN_PID" 2>/dev/null || true; fi
  if [[ -n "${API_PID:-}" ]]; then kill "$API_PID" 2>/dev/null || true; fi
}
trap cleanup EXIT

wait_for_url() {
  local url="$1"
  local label="$2"
  for _ in $(seq 1 60); do
    if curl -sf "$url" >/dev/null 2>&1; then
      echo "${label} ready at ${url}"
      return 0
    fi
    sleep 2
  done
  echo "Timed out waiting for ${label} at ${url}" >&2
  return 1
}

echo "Seeding CI database for admin E2E..."
(cd "$ROOT" && pnpm --filter @chisto/api run seed)

echo "Starting API on port ${API_PORT}..."
(
  cd "$ROOT/apps/api"
  export PORT="$API_PORT"
  export SMS_PROVIDER="${SMS_PROVIDER:-none}"
  export EMAIL_ENABLED="${EMAIL_ENABLED:-false}"
  pnpm start
) &
API_PID=$!

wait_for_url "${API_URL}/health" "API"

echo "Starting admin on port ${ADMIN_PORT}..."
(
  cd "$ROOT/apps/admin"
  export SERVER_API_BASE_URL="$API_URL"
  pnpm exec next start -p "$ADMIN_PORT"
) &
ADMIN_PID=$!

wait_for_url "${ADMIN_URL}/api/health" "Admin BFF"

export CI=true
export ADMIN_E2E_BASE_URL="$ADMIN_URL"
export ADMIN_E2E_EMAIL="${ADMIN_E2E_EMAIL:-admin@chisto.mk}"
export ADMIN_E2E_PASSWORD="${ADMIN_E2E_PASSWORD:-Password123!}"

echo "Running Playwright smoke..."
pnpm --filter @chisto/admin run test:smoke

echo "Running Playwright perf smoke..."
pnpm --filter @chisto/admin run test:perf

echo "Running Playwright a11y..."
pnpm --filter @chisto/admin run test:a11y

echo "Playwright CI stack: OK"
