# Chisto.mk API

NestJS backend for reports, sites, events, auth, moderation, and notifications.

## Development

```bash
# From repo root
pnpm dev:api

# Or from this directory
pnpm dev
```

| URL | Description |
|-----|-------------|
| http://localhost:3000 | API base |
| http://localhost:3000/api/docs | Swagger OpenAPI UI |
| http://localhost:3000/health/ready | Readiness (DB, Redis, S3) |

Requires Postgres (`docker compose up -d postgres` from root) and `.env` with `DATABASE_URL`, `JWT_SECRET`.

## Scripts

| Command | Description |
|---------|-------------|
| `pnpm test` | Unit tests (Jest) |
| `pnpm test:e2e` | E2E suite (Postgres required) |
| `pnpm snapshot:openapi:check` | Verify OpenAPI snapshot matches code |
| `pnpm build` | Production build |

## Documentation

- Runbooks: [docs/runbooks/](docs/runbooks/)
  - [DB restore](docs/runbooks/db-restore.md)
  - [Redis realtime](docs/runbooks/redis-realtime.md)
  - [Auth session deploy](docs/runbooks/auth-session-deploy.md)
- [Email copy style guide](docs/email-copy-style-guide.md)
- Platform: [docs/architecture.md](../../docs/architecture.md)

## Production

`https://api.chisto.mk`. Deployed via [GitHub Actions](../../infra/terraform/GITHUB_ACTIONS.md).
