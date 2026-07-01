# Contributing (internal team)

Chisto.mk is proprietary software maintained by the Ekohab team. This guide covers how we work inside the repository, not public open-source contribution.

For questions: [info@ekohab.mk](mailto:info@ekohab.mk).

## Branches

| Branch | Purpose |
|--------|---------|
| `develop` | Integration branch; open PRs here |
| `main` | Production releases; promoted from `develop` via release PR |

Feature and fix branches: `feat/…`, `fix/…`, `chore/…` off `develop`.

## Pull request checklist

- [ ] Branch is up to date with `develop`
- [ ] `pnpm ci:check` passes locally (also enforced by pre-push hook)
- [ ] `pnpm check:doc-links` for documentation changes
- [ ] Prisma: `db:push` only for local dev; staging/production use `db:migrate:deploy`
- [ ] No secrets in commits (`.env` files are blocked by pre-commit)
- [ ] UI changes include screenshots in the PR
- [ ] Infra or migration changes called out explicitly in the PR description
- [ ] Mobile: `melos run ci` when touching Flutter packages

## Local workflow

```bash
pnpm install
docker compose up -d postgres
cp .env.local.example .env   # or cp .env.example .env
pnpm db:push
pnpm dev
```

See [README.md](README.md) and [docs/README.md](docs/README.md) for full setup.

## Git hooks (Husky)

- **pre-commit**: blocks `.env` commits; validates Prisma schema
- **pre-push**: blocks push while local dev servers are listening; runs `pnpm ci:check`

## Repository settings (maintainers)

- Require CI status checks on `main` and `develop`
- Enable **Automatically delete head branches** after merge
- Wiki disabled; documentation lives in `docs/`

## Security

Report vulnerabilities to [info@ekohab.mk](mailto:info@ekohab.mk). See [SECURITY.md](SECURITY.md).
