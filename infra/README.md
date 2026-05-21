# Chisto.mk infrastructure

Target AWS layout (Terraform modules under `terraform/`):

- **ECS Fargate** — API service (non-root container), separate one-shot migration task
- **ALB + WAF** — HTTPS termination, rate limits at edge
- **RDS PostgreSQL** — PITR backups (7d staging, 30d production), quarterly restore drill per `apps/api/docs/runbooks/db-restore.md`
- **ElastiCache Redis** — throttler, Socket.IO adapter, idempotency, feed cache L2
- **S3** — report media, avatars
- **Secrets Manager** — `JWT_SECRET`, provider keys, Firebase service account

Deploy migrations via CI (`db:migrate:deploy`), not app container boot. See `apps/api/docker-entrypoint.sh`.
