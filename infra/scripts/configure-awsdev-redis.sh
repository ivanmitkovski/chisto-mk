#!/usr/bin/env bash
# Provision ElastiCache Redis for awsDev and wire REDIS_URL into chisto-api ECS task.
# Idempotent: reuses existing subnet group, SG, and cluster when present.
set -euo pipefail

REGION="${AWS_REGION:-eu-central-1}"
CLUSTER="${ECS_CLUSTER:-chisto-dev}"
SERVICE="${ECS_SERVICE:-chisto-api}"
TASK_FAMILY="${ECS_TASK_FAMILY:-chisto-api-task}"
CACHE_CLUSTER_ID="${REDIS_CLUSTER_ID:-chisto-dev-redis}"
SUBNET_GROUP="${REDIS_SUBNET_GROUP:-chisto-redis-subnet-group}"
REDIS_SG_NAME="${REDIS_SG_NAME:-chisto-dev-redis-sg}"

echo "==> Resolving ECS network (VPC + task security group)..."
NETWORK=$(aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region "$REGION" \
  --query 'services[0].networkConfiguration.awsvpcConfiguration' \
  --output json)
VPC_ID=$(aws ec2 describe-subnets \
  --subnet-ids "$(echo "$NETWORK" | jq -r '.subnets[0]')" \
  --region "$REGION" \
  --query 'Subnets[0].VpcId' \
  --output text)
TASK_SG=$(echo "$NETWORK" | jq -r '.securityGroups[0]')
echo "    VPC=$VPC_ID task_sg=$TASK_SG"

echo "==> Ensuring Redis security group..."
REDIS_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=$REDIS_SG_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --region "$REGION" \
  --query 'SecurityGroups[0].GroupId' \
  --output text 2>/dev/null || true)
if [[ -z "$REDIS_SG" || "$REDIS_SG" == "None" ]]; then
  REDIS_SG=$(aws ec2 create-security-group \
    --group-name "$REDIS_SG_NAME" \
    --description "ElastiCache Redis for chisto dev API" \
    --vpc-id "$VPC_ID" \
    --region "$REGION" \
    --query 'GroupId' \
    --output text)
fi
aws ec2 authorize-security-group-ingress \
  --group-id "$REDIS_SG" \
  --protocol tcp \
  --port 6379 \
  --source-group "$TASK_SG" \
  --region "$REGION" 2>/dev/null || true
echo "    redis_sg=$REDIS_SG"

echo "==> Ensuring ElastiCache cluster $CACHE_CLUSTER_ID..."
if ! aws elasticache describe-cache-clusters \
  --cache-cluster-id "$CACHE_CLUSTER_ID" \
  --region "$REGION" >/dev/null 2>&1; then
  aws elasticache create-cache-cluster \
    --cache-cluster-id "$CACHE_CLUSTER_ID" \
    --engine redis \
    --engine-version 7.1 \
    --cache-node-type cache.t4g.micro \
    --num-cache-nodes 1 \
    --cache-subnet-group-name "$SUBNET_GROUP" \
    --security-group-ids "$REDIS_SG" \
    --region "$REGION" >/dev/null
fi

echo "==> Waiting for Redis cluster (available)..."
aws elasticache wait cache-cluster-available \
  --cache-cluster-id "$CACHE_CLUSTER_ID" \
  --region "$REGION"

REDIS_HOST=$(aws elasticache describe-cache-clusters \
  --cache-cluster-id "$CACHE_CLUSTER_ID" \
  --show-cache-node-info \
  --region "$REGION" \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
  --output text)
REDIS_PORT=$(aws elasticache describe-cache-clusters \
  --cache-cluster-id "$CACHE_CLUSTER_ID" \
  --show-cache-node-info \
  --region "$REGION" \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Port' \
  --output text)
REDIS_URL="redis://${REDIS_HOST}:${REDIS_PORT}"
echo "    REDIS_URL=$REDIS_URL"

echo "==> Registering new ECS task definition revision with REDIS_URL..."
CURRENT_ARN=$(aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region "$REGION" \
  --query 'services[0].taskDefinition' \
  --output text)
TASK_JSON=$(aws ecs describe-task-definition \
  --task-definition "$CURRENT_ARN" \
  --region "$REGION" \
  --query 'taskDefinition')

NEW_TASK=$(echo "$TASK_JSON" | jq --arg url "$REDIS_URL" \
  'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy) | .containerDefinitions[0].environment = ((.containerDefinitions[0].environment // []) | map(select(.name != "REDIS_URL"))) + [{name: "REDIS_URL", value: $url}]')

NEW_ARN=$(aws ecs register-task-definition \
  --region "$REGION" \
  --cli-input-json "$NEW_TASK" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)
echo "    registered $NEW_ARN"

echo "==> Updating ECS service..."
aws ecs update-service \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --task-definition "$NEW_ARN" \
  --force-new-deployment \
  --region "$REGION" >/dev/null

echo "==> Done. After deploy, verify:"
echo "    curl -s \"\${API_URL}/health/ready\" | jq .redis   # expect \"ok\""
