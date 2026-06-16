# Chisto.mk infrastructure

Production AWS layout is implemented as modular Terraform under [`terraform/`](terraform/README.md).

## Production (Terraform)

- **VPC** `10.1.0.0/16` — dedicated prod network (dev remains `10.0.0.0/16`)
- **ECS Fargate** — API service + one-shot migration task
- **ALB + WAF** — HTTPS termination, rate limits at edge
- **RDS PostgreSQL** — Multi-AZ, 30d backups, private subnets
- **ElastiCache Redis** — replication group, TLS, multi-AZ
- **S3** — `chisto-prod-media`
- **Secrets Manager** — `chisto/production/api` (no plaintext env on tasks)

Quick start: [`terraform/README.md`](terraform/README.md)

## Dev (manual / CLI)

Dev resources (`chisto-dev`) were created via console/CLI. Redis bootstrap: [`scripts/configure-awsdev-redis.sh`](scripts/configure-awsdev-redis.sh)

## Runbooks

- DB restore: [`apps/api/docs/runbooks/db-restore.md`](../apps/api/docs/runbooks/db-restore.md)
- Redis realtime: [`apps/api/docs/runbooks/redis-realtime.md`](../apps/api/docs/runbooks/redis-realtime.md)

Deploy migrations via CI (`db:migrate:deploy`), not app container boot. See `apps/api/docker-entrypoint.sh`.
