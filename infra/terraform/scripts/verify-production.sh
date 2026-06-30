#!/usr/bin/env bash
# Post-deploy verification checklist for production API.
set -euo pipefail

API_BASE="${API_BASE:-https://api.chisto.mk}"
REGION="${AWS_REGION:-eu-central-1}"
CLUSTER="${ECS_CLUSTER:-chisto-prod}"
SERVICE="${ECS_SERVICE:-chisto-api}"
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

echo "==> Target group health"
TG_ARN=$(aws elbv2 describe-target-groups --names chisto-prod-tg --region "$REGION" --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --region "$REGION" \
  --query 'TargetHealthDescriptions[].{Target:Target.Id,State:TargetHealth.State}' \
  --output json

echo "==> Optional API verify (requires AUTH_TOKEN):"
echo "    API_BASE=$API_BASE AUTH_TOKEN=... pnpm --filter @chisto/api run verify:v1"
echo "    API_BASE=$API_BASE node apps/api/scripts/blackbox-probe.mjs"
echo "==> If ECS tasks fail with P1000, sync DATABASE_URL from RDS managed secret:"
echo "    bash infra/scripts/sync-production-database-url.sh"
