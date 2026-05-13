# Reports API — client schema alignment and trust

## Client schema (mobile)

| Field | Client rule | Server must |
|-------|-------------|-------------|
| Title / description | `ReportInputSanitizer` + `ReportFieldLimits` | Reject overlong / control-heavy payloads; return typed validation errors. |
| Category / severity | Picker enums only | Reject unknown enum strings. |
| Photos | JPEG/PNG/Webp via compression path + magic-byte check on server | Reject wrong MIME / oversized bodies. |
| Location | `ReportGeoFence` + picker confirmation | Validate country/region rules; never trust client fence alone for compliance. |
| Idempotency | `ReportIdempotencyKey` per enqueue | Dedupe POST `/reports` by key. |

OpenAPI / backend DTO is authoritative; mismatches should surface as **`AppError.validation`** with stable `code` (covered by coordinator error handler tests where applicable).

## Short threat model

**Client cannot be trusted for:** identity (tokens), entitlement, rate limits, media content policy, or geographic eligibility beyond UX hints.

**Client may trust:** local file paths **only** as “user picked this file”; paths are normalized and scanned for readability before upload. Malicious files should fail server verification.

**Abuse cases:** oversized payloads (mitigated by limits + server max body), replay submits (idempotency + in-flight guard), path traversal in legacy imports (photo store path rules + basename redaction in logs).

**Telemetry:** Sentry tags and breadcrumbs intentionally exclude PII (see `chisto_sentry.dart`).
