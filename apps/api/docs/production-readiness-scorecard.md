# API production readiness scorecard (10/10 definition)

This document is the **internal exit checklist** for claiming maximum production maturity for `apps/api`. It links repo artifacts to measurable criteria. “100% bug-free” is out of scope; criteria are **verifiable** in CI, tests, or ops sign-off.

## Two definitions of “10/10”

| Scope | Meaning | When you can claim it |
|-------|---------|------------------------|
| **Engineering / repo 10/10** | Everything the **codebase + GitHub Actions** can prove without production-only artifacts. | Criteria **#1–#6**, **#9** (k6 smoke green when `API_STAGING_BASE_URL` is set, or manual dispatch with a URL), **#10** are satisfied; **repo-owned** sign-off rows below have links to green runs; **#8** documentation and **promtool** validation for **#7**’s rule *file* are in place. **#7** “imported in deploy repo” and live **blackbox `job` labels** remain ops-owned. |
| **Operational / enterprise 10/10** | Full organizational and production **monitoring + process** closure. | Above, **plus** external sign-off log (**#11** and deploy rows for **#7–#8**) completed with dated evidence (soak, game day, pen/ASVS, monitoring PRs, live blackbox matching `chisto_api_health_ready`). |

Use **Engineering 10/10** for portfolio and merge-bar language; reserve **Operational 10/10** for release-to-production gates.

## Sign-off table

| # | Criterion | Verify with | Owner sign-off |
|---|-----------|-------------|----------------|
| 1 | **Supply chain**: no `apps__api` advisories at `AUDIT_SEVERITY=high` without waivers (waivers file may stay empty) | `pnpm --filter @chisto/api run audit:high` with `AUDIT_SEVERITY=critical` then `high` in [`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml); [`apps/api/scripts/audit-api-deps.mjs`](../scripts/audit-api-deps.mjs); [`audit-waivers.json`](../scripts/audit-waivers.json) | |
| 2 | **CI dependency parity**: API e2e runs with **Postgres, Redis, and S3-compatible (MinIO)**; `validate` runs **Postgres + Redis** for Jest | `e2e` + `validate` jobs in [`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml) | |
| 3 | **Readiness / S3 in CI**: `/health/ready` returns `s3: ok` in e2e when MinIO + env are set | [`test/e2e/cluster-redis.e2e-spec.ts`](../test/e2e/cluster-redis.e2e-spec.ts); [Runbook §12](runbook.md#12-s3-readiness-in-ci) | |
| 4 | **Integration**: e2e exercises **Redis-backed** readiness and at least one **HTTP** path using Redis (map rate limit) | [`test/e2e/`](../test/e2e/) | |
| 5 | **Jest hygiene**: `test:cov` green; `test:cov:leaks` on `main`; no ignored worker force-exit regressions | `pnpm --filter @chisto/api run test:cov` / `test:cov:leaks` | |
| 6 | **Coverage**: global thresholds in [`jest.config.js`](../jest.config.js); per-area gates via [`scripts/check-coverage-areas.mjs`](../scripts/check-coverage-areas.mjs) | CI `test:cov` + `test:cov:areas` | |
| 7 | **Metrics vs alerts**: Pushgateway gauges match [alerting-rules.yml](alerting-rules.yml); rules imported in deploy repo | [Runbook §15](runbook.md#15-deploy-side-alerting-and-synthetic-wiring); Prometheus/Mimir rule review in monitoring repo | |
| 8 | **SLOs & synthetics**: draft SLOs + blackbox job name `chisto_api_health_ready` documented | [Runbook §9](runbook.md#9-slos-alerting-rules-and-synthetics) + [§15](runbook.md#15-deploy-side-alerting-and-synthetic-wiring) | |
| 9 | **Performance**: k6 smoke vs staging (**includes `GET /health/ready`**); weekly schedule when `API_STAGING_BASE_URL` repo variable is set | [`.github/workflows/api-perf-baseline.yml`](../../../.github/workflows/api-perf-baseline.yml); [`perf/smoke.js`](../perf/smoke.js); [`perf/baseline-thresholds.json`](../perf/baseline-thresholds.json) | |
| 10 | **Architecture**: `service-size-exemptions.json` is **`{}`**; `check:god-services` green; services over the soft line cap resolved by **splitting/refactoring** (no waiver entries) | `pnpm --filter @chisto/api run check:god-services`; [`service-size-exemptions.json`](../scripts/service-size-exemptions.json); [`check-no-god-services.mjs`](../scripts/check-no-god-services.mjs) | |
| 11 | **External** (outside repo): staging soak, game day, pen test / ASVS — criteria in runbook §13 | [Runbook §13](runbook.md#13-external-acceptance-staging-soak-game-day-pen-test); [sign-off log](#external-sign-off-log) below | |

**Criteria #7–#8 (deploy):** Do not mark owner sign-off complete until the **monitoring repo** contains an imported rule set derived from `alerting-rules.yml`, **Pushgateway** is scraped with labels that match those expressions, and a **blackbox** (or equivalent synthetic) probe uses the Prometheus **`job` label `chisto_api_health_ready`** so `HealthCheckFailing` in `alerting-rules.yml` evaluates correctly. Link the monitoring PR or ticket in the sign-off log.

## External sign-off log

Track process-only criteria here; link external evidence (tickets, PDF store, monitoring repo PRs). **Do not** record Pass without dated evidence your organization accepts.

| Activity | Owner | Evidence type | Date | Outcome | Link / notes |
|----------|-------|----------------|------|---------|--------------|
| Staging soak (48h+) | Product / Eng | Ticket, soak report | — | Pending | — |
| Game day (Redis / DB / S3) | Infra + Eng | Runbook notes, ticket | — | Pending | — |
| Pen test / ASVS (external or internal report) | Security | Report ID / storage link | — | Pending | — |
| Deploy: Prometheus rules + blackbox `chisto_api_health_ready` | Infra / SRE | Monitoring repo PR, Grafana | — | Pending | — |

### Repo-owned verification (this monorepo)

These close in CI or via local command; link a **green workflow run** or PR when filling the last column.

| Activity | Owner | Evidence type | Date | Outcome | Link / notes |
|----------|-------|----------------|------|---------|--------------|
| `alerting-rules.yml` passes `promtool check rules` | Engineering | CI `validate` job step | — | Pending | [`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml) — step “Validate Prometheus alerting rules (promtool)” |
| `validate` job: Redis 7 + `REDIS_URL` (RedisReportEventBus in `test:cov`) | Engineering | CI config + green run | — | Pending | Same workflow `validate` job `services.redis` |
| k6 smoke hits **`GET /health/ready`** (readiness path = blackbox target) | Engineering | Code + optional green `API perf baseline` run | — | Pending | [`perf/smoke.js`](../perf/smoke.js) scenario `readiness`; link a run after setting `API_STAGING_BASE_URL` |

## CI jobs (reference)

| Workflow job | Purpose |
|--------------|---------|
| `secret-scan` | Gitleaks on full history |
| `validate` | Postgres 16 + **Redis 7** services, `REDIS_URL`; **promtool** on `docs/alerting-rules.yml`; install, dual audit, Prisma generate/validate/**migrate deploy**, god-services, madge, **build**, OpenAPI snapshot (loads compiled `dist/`), lint, Flutter checks, `test:cov`, `test:cov:areas`, `test:cov:leaks` (main only), admin tests |
| `e2e` | Postgres + Redis + MinIO (Docker), `prisma migrate deploy`, `test:e2e` |
| `docker-build` | `Dockerfile.prod` image |
| `API perf baseline` | Manual k6 or weekly schedule with `vars.API_STAGING_BASE_URL`; smoke includes **`/health/ready`** |

## Commands (local)

```bash
pnpm --filter @chisto/api run audit:high
AUDIT_SEVERITY=high pnpm --filter @chisto/api run audit:high
pnpm --filter @chisto/api run test:cov
pnpm --filter @chisto/api run test:cov:leaks
pnpm --filter @chisto/api run test:cov:areas
pnpm --filter @chisto/api run test:e2e
pnpm --filter @chisto/api run check:god-services
docker run --rm -v "$PWD:/work:ro" prom/prometheus:v2.55.1 promtool check rules /work/apps/api/docs/alerting-rules.yml
```

## SLO targets (draft)

See [Runbook §9 — SLOs, alerting rules, and synthetics](runbook.md).

## Revision

Update this file when audit tier, coverage floors, or sign-off requirements change.
