# API security pre-flight — OWASP ASVS Level 2 (lightweight)

Internal checklist before a major release or external pen test. Scope: **NestJS `apps/api`** (citizen + admin HTTP, WebSockets, uploads). Align external vendor scope with the same chapters. Status: **Implemented** | **Partial** | **N/A** | **External** (infra / mobile / admin UI).

| ASVS area | Control | Evidence / notes | Status |
|-----------|---------|------------------|--------|
| **V2 Authentication** | Password hashing at rest | bcrypt on credentials; admin flows per auth modules | Implemented |
| **V2 Authentication** | JWT access + refresh; short-lived access | Passport JWT; refresh rotation in session service | Partial |
| **V2 Authentication** | MFA where enabled | `auth-mfa` module; verify flows before release | Partial |
| **V2 Authentication** | Credential stuffing / brute-force throttling | `@nestjs/throttler` on auth routes; e2e `throttling.e2e-spec.ts` | Implemented |
| **V3 Session management** | Server-side session invalidation for `sid` claims | `authenticateSocketUser` + JwtStrategy session checks | Implemented |
| **V3 Session management** | Logout / refresh replay safety | `auth-session` e2e + service specs | Partial |
| **V4 Access control** | RBAC on admin routes | `RolesGuard`, `ADMIN_PANEL_ROLES` | Implemented |
| **V4 Access control** | Resource ownership (reports, events, sites) | Service-layer checks; never trust IDs alone | Implemented |
| **V5 Validation** | Global whitelist + structured validation errors | `ValidationPipe` in `configure-http-app.ts` | Implemented |
| **V5 Validation** | Geo / bounds for coordinates | DTOs + domain validators on map/report flows | Implemented |
| **V8 Data protection** | TLS in production | Terminated at load balancer / ingress | External |
| **V8 Data protection** | S3 private objects + presigned URLs | `S3StorageClient`, upload pipes | Partial |
| **V8 Data protection** | No secrets in logs; structured logging | Pino + request logging interceptor | Partial |
| **V8 Data protection** | Secret scanning in CI | Gitleaks job in `.github/workflows/ci.yml` | Implemented |
| **V9 Communication** | Security headers | Helmet in `main.ts` (CSP defaults, COEP off for compat) | Implemented |
| **V9 Communication** | CORS allowlist | `CORS_ORIGINS` / credentials flag | Implemented |
| **V9 Communication** | WebSocket CORS allowlist | `CHAT_WS_CORS_ORIGINS` → `parse-ws-cors-allowlist` | Implemented |
| **V9 Communication** | Trust proxy for correct client IP | `expressApp.set('trust proxy', true)` | Implemented |
| **V13 API** | Rate limits on sensitive routes | Throttler + per-route `@Throttle` | Implemented |
| **V13 API** | Body size limits | `express.json` / `urlencoded` 1mb in `main.ts` | Implemented |
| **V13 API** | Contract drift guard | OpenAPI snapshot CI (`snapshot:openapi:check`) | Implemented |
| **V13 API** | Dependency audit | `audit:high` critical + high in CI; `audit-waivers.json` | Implemented |

## How to use

1. Walk the table before tagging a release candidate; set any **Partial** to **Implemented** with a PR link or test name.
2. For external pen tests, attach vendor report ID or storage link in [`production-readiness-scorecard.md`](production-readiness-scorecard.md) sign-off log.
3. Track MFA / refresh / upload hardening in the issue tracker — do not waive without product + security sign-off.

## Revision

Update when auth surfaces, upload paths, or compliance scope change.
