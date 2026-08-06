# GitHub Actions workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| [ci.yml](ci.yml) | PR; push to `main`, `develop` | Secret scan, build, API tests, contract checks |
| [api-deploy.yml](api-deploy.yml) | Push to `main`/`develop`/`infra-migration`; `workflow_dispatch` | Build the production API image, push it to GHCR, smoke-test the pulled artifact |
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

Deploy configuration: none currently. `api-deploy.yml` builds and smoke-tests the API image; the AWS deploy jobs were removed with the Terraform stack. See [infra/README.md](../../infra/README.md).
