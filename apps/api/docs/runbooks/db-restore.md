# Runbook — Database restore (RDS PITR)

Referenced from [infra/README.md](../../../../infra/README.md). Quarterly restore drill + emergency recovery for the production Postgres (RDS). (Authored in the launch-readiness audit, Phase 9; see [phase-04-aws-production-readiness.md](../../../../docs/launch-readiness/phase-04-aws-production-readiness.md) §10 for the DR strategy.)

## Targets

- **RPO** ≤ 5 min (RDS automated backups + PITR).
- **RTO** ≤ 1–2 h (restore + repoint + redeploy).
- **Retention:** 7 days (staging) / 30 days (production).

## Emergency restore (data loss / corruption)

1. **Declare incident**; freeze writes (scale ECS service to 0 or enable maintenance) to stop further drift.
2. **Identify restore point** — last-known-good timestamp (before the bad migration/incident).
3. **PITR restore to a NEW instance** (never overwrite the source):
   ```sh
   aws rds restore-db-instance-to-point-in-time \
     --source-db-instance-identifier chisto-prod \
     --target-db-instance-identifier chisto-prod-restore-$(date +%Y%m%d%H%M) \
     --restore-time 2026-06-09T12:00:00Z \
     --db-subnet-group-name <private-subnet-group> \
     --vpc-security-group-ids <rds-sg>
   ```
4. **Verify** the restored instance: `CREATE EXTENSION IF NOT EXISTS postgis;` present, row counts/spot-checks on `Site`/`Report`/`User`, latest `prisma migrate status`.
5. **Repoint** `DATABASE_URL` in the Secrets Manager bundle (`chisto/production/api`) to the restored endpoint (keep `sslmode=require`).
6. **Redeploy** the API (`api-deploy.yml` or `aws ecs update-service --force-new-deployment`); confirm `/health/ready` = 200.
7. **Resume writes**; monitor 5xx/latency alarms.
8. **Post-incident:** snapshot the restored instance, retire the corrupted one after confirmation, write the postmortem.

## Quarterly drill (non-prod, no downtime)

1. PITR-restore prod (or staging) to a throwaway instance (steps 3–4 above).
2. Point a short-lived API task at it (`SKIP_MIGRATE_STATUS_CHECK=1` not needed if migrations match); run `pnpm --filter @chisto/api run verify:v1` + `blackbox-probe`.
3. Record restore duration (validates RTO) and delete the throwaway instance.
4. Log the drill date + duration in the team ops log.

## Notes

- Before any **major migration**, take a manual snapshot: `aws rds create-db-snapshot --db-instance-identifier chisto-prod --db-snapshot-identifier pre-migrate-<name>`.
- Migrations apply via `prisma migrate deploy` (CI migrate task), never `db:push` in prod.
- Redis (ElastiCache) is ephemeral by design; on loss, realtime/throttle/idempotency rebuild — no DB restore needed for cache.
