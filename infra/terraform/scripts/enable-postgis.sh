#!/usr/bin/env bash
# Enable PostGIS on the production RDS instance (run once after RDS is available).
# Requires psql and network path to RDS (bastion/VPN) OR run from a one-off ECS task.
set -euo pipefail

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "Set DATABASE_URL to the production connection string (sslmode=require)."
  exit 1
fi

echo "==> Enabling PostGIS extension"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "CREATE EXTENSION IF NOT EXISTS postgis;"
echo "==> Done"
