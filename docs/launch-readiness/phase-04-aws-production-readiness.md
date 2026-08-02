# Phase 4: AWS production readiness

> **Historical.** This records the AWS `eu-central-1` posture as audited. The platform is migrating to a single VPS running Docker Compose, and the Terraform described below no longer exists on this branch — it lives on `main` until `terraform destroy` runs. See [infra/README.md](../../infra/README.md).

Production disaster-recovery targets and infrastructure posture for Chisto.mk on AWS `eu-central-1`.

## DR targets

| Metric | Target |
|--------|--------|
| RPO | ≤ 5 minutes (RDS automated backups + PITR) |
| RTO | ≤ 1–2 hours (restore + repoint + redeploy) |
| Backup retention | 7 days (staging) / 30 days (production) |

Detailed restore procedure: [db-restore.md](../../apps/api/docs/runbooks/db-restore.md).

## Production topology

- **ECS**: `chisto-prod` cluster, `chisto-api` service
- **RDS**: PostgreSQL with PostGIS; credentials in Secrets Manager (`chisto/production/api`)
- **ElastiCache Redis**: required for multi-task API (`REDIS_URL`); see [redis-realtime.md](../../apps/api/docs/runbooks/redis-realtime.md)
- **ALB**: `api.chisto.mk`, target-group stickiness for WebSocket/polling handovers
- **S3**: report media buckets
- **WAF**: edge protection (multipart upload rules tuned for photo reports)

Terraform: `infra/terraform/envs/production/` on `main`.

## Deploy pipeline

GitHub Actions `api-deploy.yml` on `main`, configured per `infra/terraform/GITHUB_ACTIONS.md` on that branch.

Post-deploy: `GET https://api.chisto.mk/health/ready` returns `status: ok`, `redis: ok`, `s3: ok`.

RDS master password rotation is automated: `chisto-prod-rds-password-sync` Lambda syncs `DATABASE_URL` on `RotationSucceeded` and reconciles every 15 minutes. Manual fallback: `infra/scripts/sync-production-database-url.sh` on `main`.

## Session and realtime prerequisites

Before scaling API `desiredCount` ≥ 2:

1. Configure `REDIS_URL` (Socket.IO adapter + refresh replay cache)
2. Enable ALB stickiness on the API target group
3. Document JWT rotation: [auth-session-deploy.md](../../apps/api/docs/runbooks/auth-session-deploy.md)

## Quarterly drill

Non-prod PITR restore exercise. Steps in [db-restore.md](../../apps/api/docs/runbooks/db-restore.md) § Quarterly drill.
