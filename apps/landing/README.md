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

## Web Analytics

Consent-gated via the cookie banner (`ConditionalVercelAnalytics`). Requires:

1. Web Analytics enabled on the Vercel project (`vercel project web-analytics chisto-mk-landing`)
2. A production redeploy **after** enablement so `/_vercel/insights/script.js` is served as JS

Soft probe (warn only): set `NEXT_PUBLIC_SITE_URL` and run `pnpm launch:check`.  
Strict probe (fails on missing JS): `VERIFY_ANALYTICS_URL=https://www.chisto.mk pnpm launch:check`

## Scripts

| Command | Description |
|---------|-------------|
| `pnpm test` | Vitest |
| `pnpm test:e2e` | Playwright |
| `pnpm launch:check` | Pre-launch content validation |

## Related

- [Platform docs](../../docs/README.md)
- [Mobile store release](../mobile/docs/store-release.md)
