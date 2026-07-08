# Chisto.mk infrastructure

AWS production infrastructure for the Chisto.mk platform (API on ECS, RDS PostgreSQL, ElastiCache Redis, S3, ALB). Region: `eu-central-1`.

Terraform for production lives under [`terraform/envs/production/`](terraform/envs/production/). Deploy pipeline and secrets: [`terraform/GITHUB_ACTIONS.md`](terraform/GITHUB_ACTIONS.md).

Platform context: [docs/README.md](../docs/README.md) · [AWS production readiness](../docs/launch-readiness/phase-04-aws-production-readiness.md)

## Operational runbooks

- DB restore: [`apps/api/docs/runbooks/db-restore.md`](../apps/api/docs/runbooks/db-restore.md)
- Redis realtime: [`apps/api/docs/runbooks/redis-realtime.md`](../apps/api/docs/runbooks/redis-realtime.md)
- Auth session / JWT rotation: [`apps/api/docs/runbooks/auth-session-deploy.md`](../apps/api/docs/runbooks/auth-session-deploy.md)
- RDS password sync (automated): `terraform/modules/rds-password-sync/` — manual fallback `scripts/sync-production-database-url.sh`

Deploy migrations via CI (`db:migrate:deploy`), not app container boot. See `apps/api/docker-entrypoint.sh`.
