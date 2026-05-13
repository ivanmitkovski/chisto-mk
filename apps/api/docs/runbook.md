# Chisto.mk API — Operational Runbook

## Table of contents

1. [Database connection pool exhaustion](#1-database-connection-pool-exhaustion)
2. [Redis connection failures](#2-redis-connection-failures)
3. [FCM push delivery backlog](#3-fcm-push-delivery-backlog)
4. [Map projection staleness](#4-map-projection-staleness)
5. [S3 upload failures](#5-s3-upload-failures)
6. [High error rate triage](#6-high-error-rate-triage)
7. [Database backup and restore](#7-database-backup-and-restore)
8. [Rollback after failed migrations](#8-rollback-after-failed-migrations)
9. [SLOs, alerting rules, and synthetics](#9-slos-alerting-rules-and-synthetics)
10. [Quarterly restore drill](#10-quarterly-restore-drill)
11. [First 30 minutes of an incident](#11-first-30-minutes-of-an-incident)
12. [S3 readiness in CI](#12-s3-readiness-in-ci)
13. [External acceptance](#13-external-acceptance-staging-soak-game-day-pen-test)
14. [Grafana dashboard checklist](#14-grafana-dashboard-checklist)
15. [Deploy-side alerting and synthetic wiring](#15-deploy-side-alerting-and-synthetic-wiring)

---

## 1. Database connection pool exhaustion

**Symptoms:** Elevated latency, `DATABASE_TIMEOUT` / Prisma `P1008`, `/health/ready` failing on DB step, logs mentioning connection timeouts.

**Diagnosis:**

- Check RDS/Postgres `max_connections` vs app pool size (`DATABASE_URL` / Prisma pool settings).
- Inspect active connections: `SELECT count(*), state FROM pg_stat_activity GROUP BY state;`
- Correlate with deploys or traffic spikes.

**Remediation:**

- Scale API replicas down temporarily to reduce total open connections.
- Increase `max_connections` on the DB (with DBA review) or reduce per-instance pool size.
- Restart stuck API pods after fixing pool misconfiguration.
- Kill long-running idle sessions only after confirming they are safe (`pg_terminate_backend`).

---

## 2. Redis connection failures

**Symptoms:** `/health/ready` returns 503 with `Redis unavailable`, feed cache misses, WS/SSE churn, leader election issues.

**Diagnosis:**

- `redis-cli -u "$REDIS_URL" PING` from a jump host or task shell.
- Check ElastiCache/memory limits, eviction policy, and network security groups.
- Review API logs for `ECONNREFUSED` / timeout patterns.

**Remediation:**

- Failover to replica or restart Redis node (managed service: use provider console).
- Verify `REDIS_URL` and TLS settings match the deployment.
- Temporarily disable non-critical Redis-dependent features only if product accepts the tradeoff (document any flag).

---

## 3. FCM push delivery backlog

**Symptoms:** Delayed notifications, high `pushQueueDepth` in `/metrics` or observability snapshot, FCM circuit breaker open in logs.

**Diagnosis:**

- Inspect notification dispatcher / outbox tables and worker logs.
- Check Firebase quotas and error rates in Firebase console.
- Confirm `PUSH_FCM_ENABLED` and `FIREBASE_SERVICE_ACCOUNT_JSON` in the failing environment.

**Remediation:**

- Scale notification workers if horizontally sharded.
- Fix invalid credentials or rotate service account.
- Drain dead-letter queue after root cause is fixed; reprocess with idempotent handlers.

---

## 4. Map projection staleness

**Symptoms:** Admin `/health/map` alerts, high `MapEventOutbox` pending count, stale hot rows in `MapSiteProjection`.

**Diagnosis:**

- Query outbox: `SELECT status, count(*) FROM "MapEventOutbox" GROUP BY status;`
- Check `projectedAt` for hot rows vs `NOW()`.
- Confirm `MAP_PROJECTION_WORKER_ENABLED` and leader lock (Redis) if used.

**Remediation:**

- Ensure projection worker process is running and elected leader.
- Manually trigger projection job (if operator script exists) or redeploy worker.
- Investigate DB load blocking projection writes.

---

## 5. S3 upload failures

**Symptoms:** Report/evidence uploads fail with 5xx or structured `S3` errors, presign failures.

**Diagnosis:**

- Verify bucket policy, KMS keys, and IAM role (`AWS_CONTAINER_CREDENTIALS_RELATIVE_URI` / static keys).
- `aws s3api head-bucket --bucket <name>` from a task with the same role.
- Check circuit breaker / rate limits in logs.

**Remediation:**

- Fix IAM policy or bucket CORS as needed.
- Rotate credentials if compromised or expired.
- Restore service after upstream AWS incident.

---

## 6. High error rate triage

**Symptoms:** Alert on 5xx rate, Sentry spike, user reports.

**Diagnosis:**

- Correlate deploy time with error onset.
- Sample Sentry issues and request logs (`requestId`, `traceId`).
- Check `/health/ready` and dependency dashboards (DB, Redis, S3).

**Remediation:**

- Roll back bad release if correlated.
- Hotfix forward for data or code bugs.
- Scale or restart if resource exhaustion.

---

## 7. Database backup and restore

**Logical backup (pg_dump):**

```bash
pg_dump "$DATABASE_URL" -Fc -f chisto_backup_$(date +%Y%m%d).dump
```

**Restore to a new database:**

```bash
createdb chisto_restore
pg_restore -d chisto_restore --no-owner --jobs=4 chisto_backup_YYYYMMDD.dump
```

**RDS:** Use automated snapshots or `CreateDBSnapshot` in AWS Console; restore to a new instance and swap `DATABASE_URL` during maintenance.

---

## 8. Rollback after failed migrations

1. Stop new deploys writing to the broken schema.
2. `pnpm --filter @chisto/api exec prisma migrate status` — identify failed migration.
3. Prefer **forward fix**: add a new migration that repairs schema; avoid editing committed migration history.
4. If you must roll back: restore DB from snapshot taken **before** the migration, then deploy a git revision that matches that schema (last resort — data loss for rows created after snapshot).

---

## 9. SLOs, alerting rules, and synthetics

**SLO targets (draft — tune with real traffic):**

| Objective | Target | Measurement |
|-----------|--------|-------------|
| Availability (readiness) | 99.9% monthly | Blackbox or synthetic `GET /health/ready` success ratio |
| API latency | p95 below 500 ms on core REST paths | OTel traces, `chisto_request_duration_p95_ms` when Pushgateway is enabled, or ALB `TargetResponseTime` |
| Error budget | below 0.1% 5xx on authenticated traffic | `chisto_requests_failed_total / chisto_requests_total` or ALB `HTTPCode_Target_5XX_Count` |

**Alerting rules in this repo:** `docs/alerting-rules.yml` is a **Prometheus rule file template**. It is not applied automatically from this repository. In the deployment or monitoring repository, copy or import that file into the Prometheus / Mimir / Alertmanager stack, adjust `job` / `instance` labels to match your scrape config, and wire `METRICS_PUSH_GATEWAY_URL` on API tasks so gauges align with the expressions (see comments at the top of the YAML file). **Operator checklist:** [§15 Deploy-side alerting and synthetic wiring](#15-deploy-side-alerting-and-synthetic-wiring).

**In-process metrics (Pushgateway):** `chisto_requests_total`, `chisto_requests_failed_total`, `chisto_request_duration_p95_ms`, feed/map latency and cache gauges, `chisto_push_*`, `chisto_reports_submit_*`, `chisto_map_outbox_pending`, counter `chisto_prisma_p1008_total` — emitted from `ObservabilityStore` / exception filter (see `src/observability/observability.store.ts`). Rules in `alerting-rules.yml` reference these names; any rule without a matching emitter is called out in YAML comments.

**Synthetic checks:** Run an external probe (Grafana Cloud Synthetics, UptimeRobot, or blackbox exporter) against `GET /health/ready` and optionally one authenticated smoke (staging service account). Keep the same paths the mobile app uses for cold start (e.g. feature flags or public config) if product agrees. Name the blackbox job **`chisto_api_health_ready`** so `HealthCheckFiring` in `alerting-rules.yml` matches. **CI / staging overlap:** when repository variable `API_STAGING_BASE_URL` is set, [`.github/workflows/api-perf-baseline.yml`](../../../.github/workflows/api-perf-baseline.yml) runs k6 [`perf/smoke.js`](../perf/smoke.js), which includes **`GET /health/ready`** (tag `readiness`) with the same success semantics as the blackbox probe — not a substitute for Prometheus `job` labels, but a repeatable pre-prod check.

**Tracing overlap:** When both Sentry performance sampling and OTLP tracing are enabled, set `SENTRY_TRACES_SAMPLE_RATE=0` and keep Sentry for errors only (see `.env.example`).

---

## 10. Quarterly restore drill

**Goal:** Prove backups are restorable and operators know the runbook.

1. Schedule a calendar event with infra + on-call; use a **non-production** snapshot first, then production snapshot in a dedicated VPC/account if policy allows.
2. Restore from the latest automated snapshot (or `pg_dump` artifact) into a throwaway database; run `pnpm --filter @chisto/api exec prisma migrate status` against the restored URL and a read-only smoke (`/health`, optional `SELECT 1`).
3. Record: restore duration, who executed steps, blockers, and follow-up tickets (e.g. missing indexes, wrong retention).
4. Sign off in your incident or compliance tracker; keep a link in the deployment wiki.

---

## 11. First 30 minutes of an incident

1. Confirm scope: all regions/users or single dependency (DB, Redis, S3, third party).
2. Open `/health/ready` from outside the VPC (same path as blackbox job `chisto_api_health_ready`).
3. Check deploy timeline vs error rate; consider fast rollback if release-correlated.
4. Pull last 50 structured log lines filtered by `requestId` / `traceId` from the logging backend.
5. Check Prometheus (or Pushgateway scrape) for `chisto_requests_failed_total`, `chisto_request_duration_p95_ms`, `chisto_map_outbox_pending`, `chisto_prisma_p1008_total`.
6. Open Sentry (if configured) for new issues in the last hour.
7. Post status in the incident channel with **known vs unknown** and next checkpoint time.

---

## 12. S3 readiness in CI

The **API E2E** GitHub Actions job starts **MinIO** via Docker (`minio/minio`), creates bucket `chisto-e2e`, and exports:

- `S3_BUCKET_NAME`, `S3_ENDPOINT_URL` (e.g. `http://127.0.0.1:9000`), `S3_FORCE_PATH_STYLE=true`
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` (MinIO root user), `AWS_REGION`

The API enables an **S3-compatible endpoint** when `S3_ENDPOINT_URL` is set (see [`S3StorageClient`](../src/storage/s3-storage.client.ts)). E2e asserts `GET /health/ready` returns `s3: ok` in [`test/e2e/cluster-redis.e2e-spec.ts`](../test/e2e/cluster-redis.e2e-spec.ts).

Local parity: run MinIO, set the same env vars, then `pnpm --filter @chisto/api run test:e2e`.

**One-shot local stack:** with Docker running, from the monorepo root run `pnpm --filter @chisto/api run test:e2e:local` — this uses [`scripts/run-e2e-local.sh`](../scripts/run-e2e-local.sh) to start Postgres (`docker compose`), Redis and MinIO sidecars, `prisma migrate deploy`, and the full e2e suite (including WebSocket smoke). Free ports **5432**, **6379**, and **9000** on localhost.

---

## 13. External acceptance (staging soak, game day, pen test)

| Activity | Purpose | Owner |
|-----------|---------|-------|
| **Staging soak** | Run synthetic traffic (or replay) for **48–72h** after a major release | Engineering |
| **Game day** | Controlled failover: Redis reboot, DB credential rotation, validate Sections 1–2 of this runbook | Infra + on-call |
| **Pen test / ASVS** | Third-party or internal checklist — track findings in the issue tracker | Security |

### Staging soak (exit criteria)

- Minimum duration **48 hours** (72 hours preferred) on the release candidate build with **production-equivalent** env flags (Redis, S3, push, outbox workers as in prod).
- **No** open S1/S2 defects; S3 deferred only with written product risk acceptance.
- Rollback criterion: sustained `/health/ready` failure **> 15 minutes** or error budget burn **> 50%** in the soak window — stop soak and open a release blocker.

### Game day (annual or before first multi-AZ scale-up)

1. **Redis**: fail primary (or flush test cluster), confirm API degrades per design and recovers; map SSE limits and check-in paths match runbook §2.
2. **Database**: rotate application password in staging; confirm pool recovery and zero unexpected `DATABASE_TIMEOUT` spikes (`chisto_prisma_p1008_total`).
3. **S3**: revoke task role temporarily; confirm structured errors and no silent data loss on upload paths; restore role.

Record outcomes in the incident or “game day” doc; link from the scorecard sign-off row.

### Pen test / ASVS

- Scope: **OWASP ASVS Level 2** alignment for auth, reports, events, admin surfaces touching this API — use [`security-asvs-checklist.md`](security-asvs-checklist.md) as the internal pre-flight; external vendor scope should reference the same areas.
- Deliverable: written report stored per org policy (link only in scorecard if report is not in git).

Internal checklist (lightweight): [`security-asvs-checklist.md`](security-asvs-checklist.md).

**Monitoring repo:** Import [`alerting-rules.yml`](alerting-rules.yml) in the **deploy/monitoring** repository; wire blackbox job **`chisto_api_health_ready`** (HTTP GET `/health/ready`, expect 200, same host as public API). Document the monitoring repo URL or ticket in the scorecard sign-off table.

---

## 14. Grafana dashboard checklist

Minimum panels when scraping Pushgateway or remote-write metrics:

- Request volume: `chisto_requests_total`, failure ratio with `chisto_requests_failed_total`
- Latency: `chisto_request_duration_p95_ms`
- Feed/map: `chisto_feed_duration_p95_ms`, `chisto_map_duration_p95_ms`, `chisto_map_outbox_pending`
- DB pressure from API surface: `rate(chisto_prisma_p1008_total[5m])`
- Push pipeline: `chisto_push_queue_depth`, `chisto_push_sends_failure`

---

## 15. Deploy-side alerting and synthetic wiring

Use this checklist when onboarding a new environment (staging / production). Paths are relative to the **deploy / monitoring** repository unless noted.

1. **Prometheus / Mimir rules**
   - Copy [`alerting-rules.yml`](alerting-rules.yml) into your rules directory (e.g. `prometheus/rules/chisto-api.yml`) or use your vendor’s “import from Git” flow.
   - Reload or hot-reload the rule set; confirm no parse errors in the ruler UI.
   - Adjust `job` / `instance` labels in recording rules only if your scrape config differs from the comments in the YAML header.

2. **Pushgateway scrape**
   - Set `METRICS_PUSH_GATEWAY_URL` on API tasks/pods so `ObservabilityStore` can push `chisto_*` gauges (see `src/observability/observability.store.ts`).
   - Ensure Prometheus scrapes that Pushgateway job with a stable `job` label (e.g. `pushgateway` or `chisto_api_push`) and that alert expressions match.

3. **Blackbox synthetic `chisto_api_health_ready`**
   - Add a **blackbox exporter** module `http_2xx` (or Grafana Cloud Synthetic check) targeting `GET https://<public-api-host>/health/ready`.
   - Set the Prometheus `job` label to **`chisto_api_health_ready`** so `HealthCheckFailing` in `alerting-rules.yml` matches.
   - Expect HTTP **200** and body containing `"status":"ok"` (readiness may include `redis` / `s3` fields depending on env).

4. **Grafana**
   - Import or extend dashboards using the panel list in [§14 Grafana dashboard checklist](#14-grafana-dashboard-checklist). Optional template: [`docs/grafana/map-dashboard.json`](../../docs/grafana/map-dashboard.json) in the monorepo (tune `expr` to your metric names).

5. **Sign-off**
   - Record the monitoring repo path or ticket in [`production-readiness-scorecard.md`](production-readiness-scorecard.md) (criteria #7–#8) and in the external sign-off log when ops accepts the wiring.

### Appendix A — Blackbox exporter snippets (reference)

Use these in the **monitoring / deploy** repo; replace `PUBLIC_API_HOST` with your real hostname (no secrets in URLs).

**1) Module** (e.g. `blackbox.yml`):

```yaml
modules:
  http_2xx:
    prober: http
    timeout: 10s
    http:
      method: GET
      valid_http_versions: ['HTTP/1.1', 'HTTP/2.0']
      preferred_ip_protocol: ip4
      fail_if_ssl: false
      fail_if_not_ssl: false
      valid_status_codes: [200]
      body: '"status":"ok"'
```

**2) Static target + relabel** so the time series carries `job="chisto_api_health_ready"` (matches `HealthCheckFailing` in [`alerting-rules.yml`](alerting-rules.yml)):

```yaml
scrape_configs:
  - job_name: blackbox
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - https://PUBLIC_API_HOST/health/ready
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
      - target_label: job
        replacement: chisto_api_health_ready
```

Adjust `replacement` for `__address__` to wherever your blackbox exporter listens inside the scrape network.

**3) Operator pre-merge check**

From a machine with Docker:

```bash
docker run --rm -v "$PWD:/work:ro" prom/prometheus:v2.55.1 promtool check rules /work/apps/api/docs/alerting-rules.yml
```

The **`validate`** CI job runs the same check against this monorepo path on every PR.

**4) Staging k6 (readiness path parity)** — Not a replacement for blackbox metrics, but the same HTTP semantics: [`perf/smoke.js`](../perf/smoke.js) performs **`GET /health/ready`** (k6 tag `readiness`) when [`.github/workflows/api-perf-baseline.yml`](../../../.github/workflows/api-perf-baseline.yml) runs with `API_STAGING_BASE_URL` set. Use a green workflow run as supplementary evidence while wiring §15 in production.

---

## Escalation

- Page on-call for sustained `/health/ready` failure or complete auth outage.
- Document incident timeline, root cause, and follow-up tickets before closing.
