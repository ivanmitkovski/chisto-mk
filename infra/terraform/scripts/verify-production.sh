#!/usr/bin/env bash
# Post-deploy verification checklist for production API.
set -euo pipefail

API_BASE="${API_BASE:-https://api.chisto.mk}"
REGION="${AWS_REGION:-eu-central-1}"
CLUSTER="${ECS_CLUSTER:-chisto-prod}"
SERVICE="${ECS_SERVICE:-chisto-api}"
TARGET_GROUP_NAME="${TARGET_GROUP_NAME:-chisto-prod-tg}"
MIN_RUNNING="${MIN_RUNNING:-2}"

echo "==> Health ready: $API_BASE/health/ready"
curl -sf "$API_BASE/health/ready" | jq .

echo "==> ECS service stable (expect runningCount >= $MIN_RUNNING)"
SERVICE_JSON=$(aws ecs describe-services \
  --region "$REGION" \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --query 'services[0].{desired:desiredCount,running:runningCount,deployments:deployments[0].rolloutState}' \
  --output json)
echo "$SERVICE_JSON" | jq .
RUNNING=$(echo "$SERVICE_JSON" | jq -r '.running')
DESIRED=$(echo "$SERVICE_JSON" | jq -r '.desired')
if [[ "$RUNNING" -lt "$MIN_RUNNING" || "$RUNNING" -lt "$DESIRED" ]]; then
  echo "ERROR: runningCount ($RUNNING) below minimum ($MIN_RUNNING) or desired ($DESIRED)"
  exit 1
fi

echo "==> Target group health ($TARGET_GROUP_NAME)"
set +e
TG_JSON=$(aws elbv2 describe-target-health \
  --region "$REGION" \
  --target-group-arn "$(aws elbv2 describe-target-groups \
    --names "$TARGET_GROUP_NAME" \
    --region "$REGION" \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)" \
  --query 'TargetHealthDescriptions[].{Target:Target.Id,State:TargetHealth.State}' \
  --output json 2>&1)
TG_EXIT=$?
set -e

if [[ "$TG_EXIT" -ne 0 ]]; then
  echo "WARNING: Could not read ALB target health (check GitHub deploy role ELB permissions):"
  echo "$TG_JSON"
  echo "Skipping target group assertion; ECS and /health/ready checks passed."
else
  echo "$TG_JSON" | jq .
  HEALTHY=$(echo "$TG_JSON" | jq '[.[] | select(.State == "healthy")] | length')
  if [[ "$HEALTHY" -lt "$MIN_RUNNING" ]]; then
    echo "ERROR: healthy target count ($HEALTHY) below minimum ($MIN_RUNNING)"
    exit 1
  fi
fi

echo "==> Optional API verify (requires AUTH_TOKEN):"
echo "    API_BASE=$API_BASE AUTH_TOKEN=... pnpm --filter @chisto/api run verify:v1"
echo "    API_BASE=$API_BASE node apps/api/scripts/blackbox-probe.mjs"
echo "==> If ECS tasks fail with P1000, sync DATABASE_URL from RDS managed secret:"
echo "    bash infra/scripts/sync-production-database-url.sh"
