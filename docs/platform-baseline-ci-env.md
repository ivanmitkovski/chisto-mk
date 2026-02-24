# Platform Baseline: CI, Environments, and DB Policy

This document defines the minimum platform guardrails for Chisto.mk at the current stage.

## Environments

- `local`: developer machine, local Postgres, iterative development.
- `staging`: shared pre-production validation environment.
- `production`: live environment.

Use templates:

- `.env.local.example`
- `.env.staging.example`
- `.env.production.example`

Do not commit real credentials to git.

## CI Rules

Pull requests and pushes to `main` must pass:

1. Dependency install with lockfile: `pnpm install --frozen-lockfile`
2. Prisma schema validation: `pnpm --filter @chisto/api exec prisma validate`
3. Monorepo build: `pnpm build`

CI failure blocks merge.

## Local Git Hooks

Husky is enabled to catch issues before CI:

- `pre-commit`:
  - blocks staged `.env` files
  - runs Prisma schema validation
- `pre-push`:
  - runs `pnpm ci:check`

## Database Policy

- Local development:
  - `pnpm db:push` is allowed for fast iteration.
  - `pnpm db:migrate` for creating migration files.
- Staging/Production:
  - Never use `db push`.
  - Use only `pnpm db:migrate:deploy`.
  - Check state with `pnpm db:migrate:status`.

## Branch / PR Discipline

- Work in feature/chore branches.
- Keep PRs small and scoped to one slice.
- Merge only after CI pass and manual functional validation.
