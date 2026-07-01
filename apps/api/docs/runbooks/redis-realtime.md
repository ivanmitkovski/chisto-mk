# Redis for Socket.IO realtime (multi-task ECS)

## Why

When the API runs **more than one ECS task** behind an ALB (including during rolling deploys), shared Redis is required for:

1. **Socket.IO** multi-replica fan-out (below)
2. **Auth refresh replay cache** (`AuthRefreshReplayCacheService`) — concurrent `/auth/refresh` rotation grace is shared across tasks. Without Redis, a refresh that lands on a different task than the rotator returns `INVALID_REFRESH_TOKEN` and can log users out.

Socket.IO specifically needs a shared adapter so:

- Engine.IO **polling** sessions survive cross-task routing
- **Owner report events** (`/reports-owner`) and **event chat** fan-out reach clients on any task

Without `REDIS_URL`:

- `/health/ready` reports `"redis": "skipped"`
- Socket.IO uses the in-process adapter (single-node only)
- `RedisReportEventBus` falls back to in-memory (events lost across tasks)
- Refresh token replay cache is **in-memory per task** — unsafe at `desiredCount` ≥ 2

See also [auth-session-deploy.md](./auth-session-deploy.md) for JWT secret rotation.

The mobile app mitigates brief outages with WebSocket-first transport, debounced banners, and ALB target-group stickiness — but **Redis is required before scaling `desiredCount` ≥ 2**.

## awsDev audit (2026-06-11)

Initial check: `GET …/health/ready` returned `"redis":"skipped"` — `REDIS_URL` was missing on `chisto-api-task`.

**Remediation (2026-06-11):** ElastiCache cluster `chisto-dev-redis` + `REDIS_URL` on task definition revision `:17`. Re-verify:

```bash
curl -s "http://chisto-dev-alb-1776277878.eu-central-1.elb.amazonaws.com/health/ready"
# {"status":"ok","redis":"ok","s3":"ok"}
```

Repeatable setup: [`infra/scripts/configure-awsdev-redis.sh`](../../../../infra/scripts/configure-awsdev-redis.sh).

## Provision ElastiCache (AWS console or CLI)

1. Create an **ElastiCache Redis 7** replication group in the **same VPC** as the ECS service.
2. Place it in **private subnets** reachable from the API task security group.
3. Security group: allow **TCP 6379** from the `chisto-api` ECS task SG.
4. Enable encryption in transit if using `rediss://` (supported by `RedisIoAdapter`).
5. Note the **primary endpoint** (e.g. `chisto-dev-redis.xxxxx.ng.0001.euc1.cache.amazonaws.com:6379`).

## Configure ECS

Add to the `chisto-api` task definition environment (or Secrets Manager → env):

```bash
REDIS_URL=redis://chisto-dev-redis.xxxxx.ng.0001.euc1.cache.amazonaws.com:6379
# or rediss://… when TLS is enabled
```

Redeploy:

```bash
aws ecs update-service --cluster chisto-dev --service chisto-api \
  --force-new-deployment --region eu-central-1
```

## Verify

1. Bootstrap log: `Socket.IO Redis adapter enabled (multi-replica WebSocket fan-out)`
2. `GET /health/ready` → `"redis": "ok"`
3. Scale dev to 2 tasks; mobile reports/chat stay **live** without reconnect banners during steady state
4. Owner `report_event` and chat messages reach clients regardless of which task handles REST

## ALB stickiness (complement)

Enable **target-group stickiness** (`lb_cookie`, 86400s) on the API target group so polling handshakes stay pinned during single-task rollovers:

```bash
aws elbv2 modify-target-group-attributes \
  --target-group-arn arn:aws:elasticloadbalancing:REGION:ACCOUNT:targetgroup/chisto-dev-tg/… \
  --attributes \
    Key=stickiness.enabled,Value=true \
    Key=stickiness.type,Value=lb_cookie \
    Key=stickiness.lb_cookie.duration_seconds,Value=86400 \
  --region eu-central-1
```

**Dev (`chisto-dev-tg`)**: enabled 2026-06-08.

**Prod**: apply the same when the production target group is created.

## Rollback

Unset `REDIS_URL` and redeploy. Adapter falls back to single-node; safe only at `desiredCount: 1`.
