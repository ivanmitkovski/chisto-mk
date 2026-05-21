# Chisto API

NestJS backend for Chisto.mk.

## Prisma client

The generated client lives in `src/generated/prisma/` and is **committed** so `nest build` works without a prior generate step.

After schema changes:

```bash
pnpm --filter @chisto/api exec prisma generate
pnpm --filter @chisto/api exec prisma migrate dev
```

CI and Docker always run `prisma generate` before build.

## Toolchain

- **Node** ≥ 20.19 (see `package.json` engines).
- **Prisma** 7.x (patch upgrades only within major 7).

## Ops

- Prometheus alerting rules: `docs/alerting-rules.yml` (validated in CI).
- Post-deploy smoke: `pnpm --filter @chisto/api run verify:v1` (set `API_BASE`, optional `AUTH_TOKEN`).
