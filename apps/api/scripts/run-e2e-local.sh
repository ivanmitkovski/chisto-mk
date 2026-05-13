#!/usr/bin/env bash
# Start Postgres (docker compose), Redis, and MinIO like CI, then run API e2e tests.
# Usage (from repo root): pnpm --filter @chisto/api run test:e2e:local
# Requires: Docker daemon running; ports 5432, 6379, 9000 free on localhost.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${API_ROOT}/../.." && pwd)"

if ! docker info >/dev/null 2>&1; then
  echo "error: Docker daemon is not running. Start Docker Desktop (or dockerd), then retry." >&2
  exit 1
fi

cleanup_sidecars() {
  docker rm -f chisto-e2e-redis chisto-e2e-minio >/dev/null 2>&1 || true
}
trap cleanup_sidecars EXIT

echo "[e2e-local] Starting Postgres (docker compose)…"
cd "${REPO_ROOT}"
docker compose up -d postgres
for _ in $(seq 1 45); do
  if docker compose exec -T postgres pg_isready -U chisto >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
docker compose exec -T postgres pg_isready -U chisto

echo "[e2e-local] Starting Redis and MinIO sidecars…"
cleanup_sidecars
docker run -d --name chisto-e2e-redis -p 6379:6379 redis:7-alpine >/dev/null
docker run -d --name chisto-e2e-minio \
  -p 9000:9000 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  minio/minio:latest server /data --console-address ":9001" >/dev/null

for _ in $(seq 1 45); do
  if curl -sf "http://127.0.0.1:9000/minio/health/live" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
curl -sf "http://127.0.0.1:9000/minio/health/live" >/dev/null

docker run --rm --add-host=host.docker.internal:host-gateway minio/mc:latest sh -c \
  "mc alias set ci http://host.docker.internal:9000 minioadmin minioadmin && mc mb --ignore-existing ci/chisto-e2e" >/dev/null

export DATABASE_URL="${DATABASE_URL:-postgresql://chisto:chisto@127.0.0.1:5432/chisto}"
export JWT_SECRET="${JWT_SECRET:-e2e_jwt_secret_must_be_at_least_thirty_two_chars}"
export NODE_ENV=test
export REDIS_URL="${REDIS_URL:-redis://127.0.0.1:6379}"
export S3_BUCKET_NAME="${S3_BUCKET_NAME:-chisto-e2e}"
export S3_ENDPOINT_URL="${S3_ENDPOINT_URL:-http://127.0.0.1:9000}"
export S3_FORCE_PATH_STYLE="${S3_FORCE_PATH_STYLE:-true}"
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-minioadmin}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-minioadmin}"
export AWS_REGION="${AWS_REGION:-us-east-1}"

echo "[e2e-local] prisma generate + migrate deploy…"
cd "${API_ROOT}"
pnpm exec prisma generate
pnpm exec prisma migrate deploy

echo "[e2e-local] jest e2e…"
pnpm exec jest --config test/e2e/jest-e2e.config.js --runInBand

echo "[e2e-local] done."
