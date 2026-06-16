# GitHub Actions — production API deploy

After `terraform apply` in `infra/terraform/envs/production`, configure the repository:

```bash
cd infra/terraform/envs/production
../scripts/github-actions-config.sh
```

## Repository secrets

| Secret | Source |
|--------|--------|
| `AWS_ROLE_ARN` | `terraform output -raw github_deploy_role_arn` |
| `ECS_CLUSTER` | `chisto-prod` |
| `ECS_SERVICE` | `chisto-api` |
| `ECS_MIGRATE_TASK_DEFINITION` | `chisto-prod-api-migrate` |
| `ECS_SUBNETS` | comma-separated private subnet IDs from output |
| `ECS_SECURITY_GROUP` | task security group ID from output |

## Repository variables

| Variable | Value |
|----------|-------|
| `API_AWS_DEPLOY` | `true` |
| `AWS_REGION` | `eu-central-1` |
| `ECR_REPOSITORY` | `chisto-api` |

## Using GitHub CLI (optional)

```bash
cd infra/terraform/envs/production
ROLE=$(terraform output -raw github_deploy_role_arn)
CFG=$(terraform output -json github_actions_configuration)

gh secret set AWS_ROLE_ARN --body "$ROLE"
gh secret set ECS_CLUSTER --body "$(echo "$CFG" | jq -r .ECS_CLUSTER)"
gh secret set ECS_SERVICE --body "$(echo "$CFG" | jq -r .ECS_SERVICE)"
gh secret set ECS_MIGRATE_TASK_DEFINITION --body "$(echo "$CFG" | jq -r .ECS_MIGRATE_TASK_DEFINITION)"
gh secret set ECS_SUBNETS --body "$(echo "$CFG" | jq -r .ECS_SUBNETS)"
gh secret set ECS_SECURITY_GROUP --body "$(echo "$CFG" | jq -r .ECS_SECURITY_GROUP)"

gh variable set API_AWS_DEPLOY --body true
gh variable set AWS_REGION --body eu-central-1
gh variable set ECR_REPOSITORY --body chisto-api
```

Then run **API deploy** workflow (`workflow_dispatch`, environment `production`) from `main`.
