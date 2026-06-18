# Chisto.mk infrastructure

Terraform for production lives under [`terraform/envs/production/`](terraform/envs/production/).

Operational runbooks:

- DB restore: [`apps/api/docs/runbooks/db-restore.md`](../apps/api/docs/runbooks/db-restore.md)
- Redis realtime: [`apps/api/docs/runbooks/redis-realtime.md`](../apps/api/docs/runbooks/redis-realtime.md)

Deploy migrations via CI (`db:migrate:deploy`), not app container boot. See `apps/api/docker-entrypoint.sh`.
