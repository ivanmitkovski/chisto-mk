# Documentation

Central index for Chisto.mk platform documentation. Canonical source lives in this repository (wiki disabled).

## Getting started

- [README](../README.md): install, dev servers, scripts
- [CONTRIBUTING](../CONTRIBUTING.md): internal branch workflow and PR checklist
- [SECURITY](../SECURITY.md): vulnerability reporting

## Platform

- [Architecture](architecture.md): system boundaries and shared packages
- [CI & environment guardrails](platform-baseline-ci-env.md): env templates, Husky, CI parity
- [Reports outbox runbook](reports-outbox-runbook.md): mobile background upload QA

## Applications

| App | README | Deep docs |
|-----|--------|-----------|
| API | [apps/api/README.md](../apps/api/README.md) | [runbooks](../apps/api/docs/runbooks/), [email style guide](../apps/api/docs/email-copy-style-guide.md) |
| Admin | [apps/admin/README.md](../apps/admin/README.md) | Playwright smoke/a11y in package scripts |
| Landing | [apps/landing/README.md](../apps/landing/README.md) | Legal/help content under `apps/landing/content/` |
| Mobile | [apps/mobile/README.md](../apps/mobile/README.md) | [store release](../apps/mobile/docs/store-release.md), [deep links](../apps/mobile/docs/deep-link-inventory.md), [notifications](../apps/mobile/docs/notification-routing-architecture.md) |

## Infrastructure & deploy

- [infra/README.md](../infra/README.md): Terraform layout
- [GitHub Actions production deploy](../infra/terraform/GITHUB_ACTIONS.md)
- [AWS production readiness](launch-readiness/phase-04-aws-production-readiness.md): DR targets

## Observability

- [Grafana map dashboard](grafana/map-dashboard.json)

## Brand assets

Official mark: [`apps/landing/public/brand/chisto-mark.svg`](../apps/landing/public/brand/chisto-mark.svg) (green `#2FD788`, accent black). Press kit: [chisto.mk/press](https://chisto.mk/en/press).

Regenerate GitHub social preview from brand SVG:

```bash
node scripts/render-social-preview.mjs
```

After updating [`.github/social-preview.png`](../.github/social-preview.png), upload it in the GitHub repository under **Settings → General → Social preview** (GitHub does not pick it up from the repo automatically).
