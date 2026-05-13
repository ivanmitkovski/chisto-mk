# ADR 001 — Reports vertical boundaries

## Status

Accepted — documents the reporting “wizard + outbox” layering as implemented in the mobile app.

## Context

The reporting flow combines **SQLite outbox**, **multipart uploads**, and a **multi-stage wizard**. We need clear rules for where `ServiceLocator`, `ReportOutboxCoordinator`, and UI widgets meet without leaking data-layer DTOs into presentation.

## Decision

1. **Domain models** (`features/reports/domain/models/`) hold cross-layer value types shared by data and UI — e.g. `ReportUploadPrepProgress` for JPEG prep progress, `ReportWizardRestoreSnapshot` for draft restore. Presentation must not import `features/reports/data/outbox/report_outbox_entry.dart` (or other outbox row DTOs); coordinator-facing submit flows go through **`ReportWizardSubmitPort`** (`features/reports/application/report_wizard_submit_port.dart`) so widgets/controllers do not depend on `ReportOutboxCoordinator` types.
2. **Coordinator** (`ReportOutboxCoordinator`) owns pipeline orchestration, Sentry scope tags for the active row, and `BackgroundSubmitScheduler` injection. `ServiceLocator` wires `PlatformBackgroundSubmitScheduler` on Android/iOS so Workmanager can schedule `ReportOutboxBackgroundDrain` without touching the UI isolate.
3. **Screens** (`new_report_screen.dart`) may use `ServiceLocator` for composition only; heavy logic stays in `NewReportController` / repositories. Constructor injection is preferred for tests; `ServiceLocator` is the production graph.
4. **Headless drain** (`ReportOutboxBackgroundDrain`) opens its own `SqfliteReportOutboxRepository` + `ApiClient` — no `ServiceLocator` in the Workmanager callback isolate.

## Allowed imports (summary)

| Layer | May import from |
|-------|-----------------|
| `presentation/` | `domain/*`, `application/*` (ports/facades), shared UI, `core/*` as today. **Not** `data/outbox/report_outbox_entry.dart`, **not** `data/outbox/report_outbox_coordinator.dart`. |
| `application/` | `domain/*`, `data/outbox/*` (impl wires coordinator — keep this folder small). |
| `data/outbox/` | `domain/*`, `data/*`, `core/*`. |
| Tests under `test/features/reports/presentation/` | Same rules as presentation; use fakes of `ReportWizardSubmitPort` / `ReportsApiRepository` where possible. |

## Consequences

- Adding new UI fields flows: domain sanitizer → coordinator enqueue validation → API mapper.
- Changing outbox schema touches SQLite migrations + coordinator + repository, not wizard widgets directly.
