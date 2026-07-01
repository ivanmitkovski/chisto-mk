# Runbook: Auth session deploy (JWT rotation)

JWT access/refresh token configuration and zero-downtime secret rotation for multi-task ECS deployments.

## Environment variables

From root `.env.example`:

```bash
JWT_SECRET="current-signing-secret-min-32-chars"
JWT_SECRET_PREVIOUS="prior-secret-during-rotation"
# JWT_KID=default
# JWT_KID_PREVIOUS=previous
JWT_ACCESS_EXPIRES_IN=900
JWT_REFRESH_EXPIRES_DAYS=90
JWT_REFRESH_STANDARD_DAYS=7
REFRESH_TOKEN_ROTATION_GRACE_SECONDS=120
```

During rotation, set `JWT_SECRET_PREVIOUS` to the **old** secret so in-flight access tokens keep validating until they expire.

## Rotation procedure

1. Generate a new `JWT_SECRET` (≥ 32 random bytes).
2. Set `JWT_SECRET_PREVIOUS` to the current production secret.
3. Set `JWT_SECRET` to the new value (optionally bump `JWT_KID` / `JWT_KID_PREVIOUS`).
4. Update Secrets Manager bundle `chisto/production/api` and redeploy ECS (`api-deploy.yml` or force new deployment).
5. Wait at least `JWT_ACCESS_EXPIRES_IN` seconds (plus buffer) for old access tokens to age out.
6. Remove `JWT_SECRET_PREVIOUS` and `JWT_KID_PREVIOUS` in a follow-up deploy.

## Multi-task note

Refresh token rotation uses a **shared Redis replay cache** (`AuthRefreshReplayCacheService`). Without Redis, concurrent refresh requests across tasks can invalidate sessions.

See [redis-realtime.md](./redis-realtime.md) before scaling past one API task.

## Verify

- Admin and mobile login still work after deploy
- `/auth/refresh` succeeds under load (no spike in `INVALID_REFRESH_TOKEN`)
- `/health/ready` unchanged

## Related

- [db-restore.md](./db-restore.md): incident recovery if secrets bundle is corrupted
