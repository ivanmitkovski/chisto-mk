# Chisto.mk

Civic environmental platform for pollution reporting, site lifecycle management, cleanup events, and data transparency.

## Stack

- **Backend**: NestJS, TypeScript, Prisma, PostgreSQL
- **Admin**: Next.js 15 (port 3001)
- **Landing**: Next.js 15 (port 3002)
- **Mobile**: Flutter

## Quick start

### Prerequisites

- Node.js 20+
- pnpm 9+
- Docker (for local Postgres)
- Flutter 3.x (for mobile app)

### Setup

```bash
# Install dependencies (requires pnpm: npm i -g pnpm or corepack enable)
pnpm install

# Start Postgres
docker compose up -d postgres

# Copy env and run migrations
cp .env.example .env
pnpm db:push

# Start dev servers
pnpm dev
```

- API: http://localhost:3000
- API docs: http://localhost:3000/api/docs
- Admin: http://localhost:3001
- Landing: http://localhost:3002

### Scripts

| Command | Description |
|---------|-------------|
| `pnpm dev` | Run API + Admin + Landing in parallel |
| `pnpm dev:api` | Run API only |
| `pnpm dev:admin` | Run Admin only |
| `pnpm dev:landing` | Run Landing only |
| `pnpm dev:mobile` | Run Flutter app (requires device/emulator) |
| `pnpm build` | Build all Node apps |
| `pnpm build:mobile` | Build Flutter APK |
| `pnpm db:migrate` | Run Prisma migrations |
| `pnpm db:migrate:deploy` | Apply migrations in staging/production |
| `pnpm db:migrate:status` | Check migration status |
| `pnpm db:studio` | Open Prisma Studio |
| `pnpm ci:check` | Run CI-equivalent local checks |

## Environment strategy

- Local template: `.env.local.example`
- Staging template: `.env.staging.example`
- Production template: `.env.production.example`

Use `cp .env.local.example .env` for local development.
Never commit real secrets.

## Database policy

- Local: `pnpm db:push` is allowed for fast iteration.
- Staging/Production: use `pnpm db:migrate:deploy` only.

## Git hooks (Husky)

- `pre-commit`:
  - blocks accidental `.env` commits
  - validates Prisma schema (`pnpm --filter @chisto/api exec prisma validate`)
- `pre-push`:
  - runs `pnpm ci:check`

## Project structure

```
chisto-mk/
├── apps/
│   ├── api/      # NestJS backend
│   ├── admin/    # Next.js admin panel
│   ├── landing/  # Next.js marketing site
│   └── mobile/   # Flutter app
├── docker-compose.yml
└── package.json
```

See `docs/platform-baseline-ci-env.md` for CI and environment guardrails.

## License

Proprietary — Chisto.mk
