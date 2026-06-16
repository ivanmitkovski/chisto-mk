# Chisto.mk Terraform

Production AWS infrastructure for the Chisto API. Dev (`chisto-dev`) was built manually in the console; **production is greenfield Terraform** in a dedicated VPC (`10.1.0.0/16`) and does not modify dev.

## Layout

```
infra/terraform/
  bootstrap/              # One-time remote state bucket + DynamoDB lock
  modules/                # Reusable modules (network, ecs, rds, …)
  envs/production/        # Production root module
  scripts/                # Secrets population, GitHub config, verification
```

## Prerequisites

- Terraform >= 1.6, AWS CLI v2
- AWS credentials for account `975829620383` (or your target account)
- Free disk space for provider downloads
- External DNS access for `chisto.mk` (ACM validation + `api.chisto.mk` CNAME)

## 1. Bootstrap remote state (once)

```bash
cd infra/terraform/bootstrap
terraform init
terraform apply
```

Note the `state_bucket_name` output and ensure `envs/production/backend.tf` matches.

## 2. Configure production variables

```bash
cp envs/production/production.tfvars.example envs/production/production.tfvars
# Edit alarm_email and any overrides (production.tfvars is gitignored)
```

For the **first infra-only apply** (before any ECR image exists), set:

```hcl
ecs_desired_count = 0
```

## 3. Apply production

```bash
cd infra/terraform/envs/production
terraform init
terraform plan -var-file=production.tfvars
terraform apply -var-file=production.tfvars
```

Phased apply is optional; modules are ordered to respect dependencies.

## 4. DNS (external registrar)

After apply:

```bash
terraform output acm_certificate_validation_records
terraform output dns_records_required
```

1. Add ACM validation CNAME records; wait until certificate status is **ISSUED**.
2. Add `api.chisto.mk` CNAME → ALB DNS name.

## 5. Populate Secrets Manager

RDS master credentials are in the AWS-managed secret (`terraform output rds_master_user_secret_arn`). Build `DATABASE_URL` and merge with other keys from [`.env.production.example`](../../.env.production.example).

Redis URL (sensitive):

```bash
terraform output -raw redis_url   # rediss://… — set as REDIS_URL in the secret bundle
```

Populate the app secret bundle (values never printed):

```bash
chmod +x ../../scripts/populate-production-secrets.sh
../../scripts/populate-production-secrets.sh /path/to/production.env
```

Enable PostGIS (once, from a host that can reach RDS):

```bash
../../scripts/enable-postgis.sh   # requires DATABASE_URL
```

## 6. Deploy API image

Push to ECR (`terraform output ecr_repository_url`), then set `ecs_desired_count = 2` and re-apply, or run GitHub Actions.

## 7. Wire GitHub Actions

```bash
chmod +x ../../scripts/github-actions-config.sh
../../scripts/github-actions-config.sh
```

Set the printed secrets/variables on the GitHub repo. Enable `API_AWS_DEPLOY=true`, then run **API deploy** workflow for `production`.

## 8. Verify

```bash
chmod +x ../../scripts/verify-production.sh
../../scripts/verify-production.sh
```

Confirm SNS alarm email subscription. Schedule RDS PITR drill per [`apps/api/docs/runbooks/db-restore.md`](../../apps/api/docs/runbooks/db-restore.md).

## Prod database access (TablePlus)

Production RDS is **private** (no direct internet access). Use the SSM bastion (`chisto-prod-db-bastion`) and port forwarding:

1. Install [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) (`brew install --cask session-manager-plugin`).
2. Run the tunnel (keep the terminal open):

```bash
./infra/scripts/prod-db-tunnel.sh
```

3. In TablePlus → PostgreSQL:

| Field | Value |
|-------|-------|
| Host | `127.0.0.1` |
| Port | `15432` (or `LOCAL_PORT=5433 ./infra/scripts/prod-db-tunnel.sh`) |
| User | `chisto` |
| Database | `chisto_prod` |
| SSL | require |

The script prints the password from Secrets Manager (`chisto/production/api`).

**Dev** (`chisto-dev`) is publicly reachable from the admin CIDR and can connect directly using credentials in your local `.env`.

## Modules

| Module | Purpose |
|--------|---------|
| `network` | VPC, subnets, NAT/AZ, VPC endpoints |
| `kms` | CMKs for RDS, S3, Secrets Manager, logs |
| `security_groups` | ALB → ECS → RDS/Redis chain |
| `ecr` | `chisto-api` immutable repo |
| `s3_media` | `chisto-prod-media` |
| `secrets` | `chisto/production/api` container (values out-of-band) |
| `rds` | Postgres Multi-AZ private |
| `elasticache` | Redis replication group (TLS + AUTH) |
| `iam` | ECS roles + GitHub OIDC deploy role |
| `ecs` | Fargate cluster, API + migrate tasks, autoscaling |
| `alb` | HTTPS, stickiness, ACM |
| `waf` | Managed rules + rate limit |
| `observability` | Alarms, SNS, dashboard |

Legacy scaffold: [`main.tf`](main.tf) (superseded by `envs/production`).
