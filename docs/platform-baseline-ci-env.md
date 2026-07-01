# Platform baseline: CI and environment

Guardrails for local development, CI, and deployed environments.

## Environment templates

| File | Purpose |
|------|---------|
| `.env.local.example` | **Recommended** local template. Copy to `.env` |
| `.env.example` | Minimal API-focused template |
| `.env.staging.example` | Staging variable reference |
| `.env.production.example` | Production variable reference |

Per-app overrides: `apps/api/.env.example`, `apps/admin/.env.example`, `apps/landing/.env.example`, `apps/mobile/.env.release.example`.

Never commit `.env` files with real secrets. Pre-commit hook blocks accidental `.env` commits.

## Database policy

| Environment | Command |
|-------------|---------|
| Local | `pnpm db:push` allowed for fast iteration |
| Staging / Production | `pnpm db:migrate:deploy` only |

Check status: `pnpm db:migrate:status`.

## CI workflow (`.github/workflows/ci.yml`)

Runs on pull requests and pushes to `main` / `develop`.

| Job | What it checks |
|-----|----------------|
| Secret scan | Gitleaks |
| Build and validate | Prisma generate/validate, API audits, full `pnpm build`, API unit tests, admin/landing tests, contract verification |

CI services (validate job):

- PostgreSQL 16 + PostGIS (`chisto_ci`)
- Redis 7
- `DATABASE_URL`, `JWT_SECRET`, `REDIS_URL` injected for tests

Local parity: `pnpm ci:check` (Prisma generate + validate + build).

## Git hooks (Husky)

| Hook | Behavior |
|------|----------|
| `pre-commit` | Block `.env` commits; `prisma validate` |
| `pre-push` | Block push if local API/admin/landing dev servers are listening; run `pnpm ci:check` |

## Mobile CI

Path-filtered workflows: `mobile-pr.yml`, `mobile-e2e.yml`, `flutter-goldens.yml`. Entry point in app: `melos run ci` from `apps/mobile`.

## Deploy gating (API)

- `main` → production ECS deploy via `api-deploy.yml`
- `develop` → build only unless `API_STAGING_DEPLOY=true`

Details: [infra/terraform/GITHUB_ACTIONS.md](../infra/terraform/GITHUB_ACTIONS.md).

## Node toolchain

- Node `>=20.19.0` (root `package.json` engines)
- pnpm `10.27.0` (`packageManager` field; use `corepack enable`)

## Related

- [architecture.md](architecture.md)
- [CONTRIBUTING.md](../CONTRIBUTING.md)
