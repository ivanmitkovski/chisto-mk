# Chisto.mk infrastructure

The platform is migrating off AWS onto a single VPS running Docker Compose (API + Postgres/PostGIS + Redis + MinIO, Caddy for TLS). This branch carries no AWS infrastructure code.

**The authoritative AWS Terraform lives on `main`** and stays there until `terraform destroy` has actually run — it is the only clean way to switch off billable resources. Do not delete it there first.

## Current state

| | |
|---|---|
| Target | One VPS, Docker Compose, everything local including media |
| Object storage | MinIO (the API already honours `S3_ENDPOINT_URL` / `S3_FORCE_PATH_STYLE`) |
| TLS | Caddy in front of `api.chisto.mk` |
| Backups | Provider snapshots for now; `pg_dump` routine deferred |

Compose stack: [`../docker-compose.yml`](../docker-compose.yml).

Platform context: [docs/README.md](../docs/README.md)

## Operational runbooks

- DB restore: [`apps/api/docs/runbooks/db-restore.md`](../apps/api/docs/runbooks/db-restore.md)
- Redis realtime: [`apps/api/docs/runbooks/redis-realtime.md`](../apps/api/docs/runbooks/redis-realtime.md)
- Auth session / JWT rotation: [`apps/api/docs/runbooks/auth-session-deploy.md`](../apps/api/docs/runbooks/auth-session-deploy.md)

These runbooks still describe the AWS topology and are accurate only while it is serving traffic.

Deploy migrations as an explicit step (`db:migrate:deploy`), not at app container boot. See `apps/api/docker-entrypoint.sh`.
