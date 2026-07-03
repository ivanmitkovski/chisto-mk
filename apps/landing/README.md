# Chisto.mk Landing

Next.js 15 marketing site: [chisto.mk](https://chisto.mk).

## Development

```bash
pnpm dev:landing
```

| URL | Description |
|-----|-------------|
| http://localhost:3002 | Local site |
| http://localhost:3002/mk | Macedonian (default locale prefix) |
| http://localhost:3002/en | English |
| http://localhost:3002/sq | Albanian |

## Configuration

Copy `apps/landing/.env.example`. Key public URLs:

- `NEXT_PUBLIC_APP_STORE_URL` — live MK App Store listing
- `NEXT_PUBLIC_GOOGLE_PLAY_URL` — live Google Play listing (`mk.chisto.app`)
- Other `NEXT_PUBLIC_*`: social links, legal overrides
- Defaults in [`src/lib/legal/legal-public-config.ts`](src/lib/legal/legal-public-config.ts)

## Content

- Legal: `content/legal/`
- Help centre: `content/help/`
- News: fetched from API + [`@chisto/news-content`](../../packages/news-content)

## Universal links

Serves `/.well-known/apple-app-site-association` and `assetlinks.json` for mobile deep links. Verified in CI: `mobile-deep-links-verify.yml`.

## Brand

| Asset | Path |
|-------|------|
| Mark (green + black) | `public/brand/chisto-mark.svg` |
| Mark (all green) | `public/brand/chisto-mark-green.svg` |
| Theme color | `#2FD788` |

Press assets: `/press` on production.

## Scripts

| Command | Description |
|---------|-------------|
| `pnpm test` | Vitest |
| `pnpm test:e2e` | Playwright |
| `pnpm launch:check` | Pre-launch content validation |

## Related

- [Platform docs](../../docs/README.md)
- [Mobile store release](../mobile/docs/store-release.md)
