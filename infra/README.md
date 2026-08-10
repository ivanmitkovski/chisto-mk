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

**Deploying to the VPS: [`vps-deploy.md`](vps-deploy.md)** — step-by-step runbook covering
the AWS data extraction, the rehearsal hostname, cutover and rollback.

**Automated deploys: [`deploy/README.md`](deploy/README.md)** — CI builds the image and
ships it to the box over ssh, where a forced command restricts the CI key to one
script. Live since 2026-08-08 for `infra-migration`; a push deploys with no manual
step. The image is pinned by digest, so what runs is bit-for-bit what was smoke-tested.

Compose stack: [`../docker-compose.yml`](../docker-compose.yml) — `docker compose up --build`
runs the production API image against local Postgres 17 + PostGIS, Redis and MinIO,
with Caddy in front on `http://chisto.localhost`. Postgres is pinned to 17 to match
production RDS (engine 17.9) so a `pg_dump` restores cleanly onto it.

The production overlay is [`../docker-compose.prod.yml`](../docker-compose.prod.yml);
secrets come from `infra/vps.env` ([template](vps.env.example)).

Migrations run in a dedicated one-shot `migrate` service that must exit 0 before the API
starts; the API sets `MIGRATE_DEPLOY_ON_START=0` so it verifies migration status without
applying anything itself.

The base stack runs as `NODE_ENV=development` so it boots with no secrets. Production
values (`CHAT_ENCRYPTION_KEY`, `METRICS_BEARER_TOKEN`, Twilio, real `CORS_ORIGINS`) live
in the overlay, which uses `${VAR:?}` so a missing secret aborts the deploy rather than
silently falling back to a local default.

Platform context: [docs/README.md](../docs/README.md)

## Operational runbooks

- DB restore: [`apps/api/docs/runbooks/db-restore.md`](../apps/api/docs/runbooks/db-restore.md)
- Redis realtime: [`apps/api/docs/runbooks/redis-realtime.md`](../apps/api/docs/runbooks/redis-realtime.md)
- Auth session / JWT rotation: [`apps/api/docs/runbooks/auth-session-deploy.md`](../apps/api/docs/runbooks/auth-session-deploy.md)

These runbooks still describe the AWS topology and are accurate only while it is serving traffic.

Deploy migrations as an explicit step (`db:migrate:deploy`), not at app container boot. See `apps/api/docker-entrypoint.sh`.
