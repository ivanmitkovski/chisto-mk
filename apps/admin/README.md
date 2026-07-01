# Chisto.mk Admin

Next.js 15 operations and moderation dashboard for the Chisto.mk team.

## Development

```bash
# From repo root (starts API separately or point at remote API)
pnpm dev:admin
```

| URL | Description |
|-----|-------------|
| http://localhost:3001 | Admin UI |
| `/login` | Staff authentication |

Set `NEXT_PUBLIC_API_BASE_URL` / `SERVER_API_BASE_URL` in `.env` (see `apps/admin/.env.example`). Default local API: `http://localhost:3000`.

## Auth

Session-based staff login via API (`/auth/admin/login`). Support: [support@chisto.mk](mailto:support@chisto.mk).

## Testing

| Command | Description |
|---------|-------------|
| `pnpm test` | Vitest unit tests |
| `pnpm test:smoke` | Playwright smoke |
| `pnpm test:a11y` | Playwright accessibility |
| `pnpm test:structure` | Architecture/i18n guard scripts |

CI stack script: `scripts/run-playwright-ci-stack.sh`.

## Production

`https://admin.chisto.mk`

## Related

- [API README](../api/README.md)
- [Platform architecture](../../docs/architecture.md)
