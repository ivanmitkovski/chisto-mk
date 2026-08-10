# GitHub Actions workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| [ci.yml](ci.yml) | PR; push to `main`, `develop` | Secret scan, build, API tests, contract checks |
| [api-deploy.yml](api-deploy.yml) | Push to `main`/`develop`/`infra-migration`; `workflow_dispatch` | Build the production API image, push it to GHCR, smoke-test the pulled artifact — then deploy to the VPS (`infra-migration` and manual dispatch only) |
| [api-typecheck.yml](api-typecheck.yml) | PR (API paths) | Standalone API TypeScript check |
| [api-security.yml](api-security.yml) | PR (API paths) | API security scans |
| [api-migration-lint.yml](api-migration-lint.yml) | PR (migrations) | Prisma migration lint |
| [api-perf-baseline.yml](api-perf-baseline.yml) | Schedule; manual | k6 smoke vs baseline thresholds |
| [mobile-pr.yml](mobile-pr.yml) | PR (mobile paths) | Flutter analyze, guards, tests |
| [mobile-e2e.yml](mobile-e2e.yml) | PR; manual | Integration smoke |
| [mobile-release.yml](mobile-release.yml) | Manual | Store release build |
| [mobile-deep-links-verify.yml](mobile-deep-links-verify.yml) | Schedule; manual | Verify chisto.mk universal links |
| [flutter-goldens.yml](flutter-goldens.yml) | Manual | Update Flutter golden files |

Dependabot: [../dependabot.yml](../dependabot.yml) (npm, GitHub Actions, Docker).

Deploy configuration: the `deploy` job in `api-deploy.yml` ssh's a digest-pinned image ref to the VPS, where a forced command runs `infra/deploy/chisto-deploy.sh` and nothing else. Setup and secrets: [infra/deploy/README.md](../../infra/deploy/README.md). The AWS ECS deploy jobs were removed with the Terraform stack.

Required repository secrets for that job: `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`, `VPS_KNOWN_HOSTS`.
