#!/usr/bin/env bash
# Print GitHub Actions secrets/variables from Terraform outputs (no secret values).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../envs/production" && pwd)"
cd "$ROOT"

if ! terraform output -json github_actions_configuration >/dev/null 2>&1; then
  echo "Run 'terraform apply' in $ROOT first."
  exit 1
fi

echo "==> GitHub repository configuration for api-deploy.yml"
echo
terraform output -json github_actions_configuration | jq -r '
  "Repository secret AWS_ROLE_ARN=" + .AWS_ROLE_ARN,
  "Repository secret ECS_CLUSTER=" + .ECS_CLUSTER,
  "Repository secret ECS_SERVICE=" + .ECS_SERVICE,
  "Repository secret ECS_MIGRATE_TASK_DEFINITION=" + .ECS_MIGRATE_TASK_DEFINITION,
  "Repository secret ECS_SUBNETS=" + .ECS_SUBNETS,
  "Repository secret ECS_SECURITY_GROUP=" + .ECS_SECURITY_GROUP,
  "Repository variable AWS_REGION=" + .AWS_REGION,
  "Repository variable ECR_REPOSITORY=" + .ECR_REPOSITORY,
  "Repository variable API_AWS_DEPLOY=" + .API_AWS_DEPLOY_repo_variable
'
echo
echo "Confirm SNS alarm subscription email after apply (check inbox)."
