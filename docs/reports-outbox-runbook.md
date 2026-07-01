# Reports outbox: background submit runbook

Device QA and triage for offline report submission and Workmanager background drain on iOS and Android.

## Overview

When a user files a report without reliable connectivity, drafts sit in a local **outbox**. Submission resumes via:

1. **In-process drain**: while the app is foregrounded
2. **Native Workmanager task**: `chisto.reportOutbox.drain` after backgrounding

Implementation: `apps/mobile/packages/feature_reports/.../platform_background_submit_scheduler.dart` and `apps/mobile/lib/core/background/chisto_workmanager_dispatcher.dart`.

## Platform requirements

### Android

- `workmanager` `0.9.0+3` (see `pubspec.lock`)
- Network constraint: `NetworkType.connected`
- Task name: `ReportOutboxBackgroundDrain.taskName`

### iOS

Must stay aligned across:

- `UIBackgroundModes`: `fetch`, `processing`
- `BGTaskSchedulerPermittedIdentifiers`: `chisto.reportOutbox.drain`, `offline-regions-refresh`
- `AppDelegate` Workmanager registration
- [`PlatformBackgroundSubmitScheduler`](../apps/mobile/packages/feature_reports/lib/src/data/outbox/background/platform_background_submit_scheduler.dart)

Apple enforces strict background quotas. Expect best-effort delivery, not guaranteed immediate upload.

## Device QA checklist

1. Enable airplane mode; create a report with photo + location; confirm draft saved in outbox UI.
2. Disable airplane mode; foreground app. Report should submit within seconds.
3. Repeat step 1; background the app (home button); wait 1–5 minutes; reopen. Report should show submitted or retrying.
4. Force-quit and relaunch. Outbox should resume without duplicate public reports (idempotency on API).
5. iOS: verify no crash on background enqueue; check Xcode console for Workmanager registration errors.

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Gradle `workmanager-0.5.x` errors | Run `flutter pub get && flutter clean` from `apps/mobile` |
| iOS task never runs | `Info.plist` identifiers vs dispatcher task name |
| Duplicate submissions | API idempotency keys / client outbox state |
| Sentry noise | Filter tags `report_outbox`. See `chisto_sentry.dart` |

## Integration test

[`report_submit_flow_test.dart`](../apps/mobile/integration_test/report_submit_flow_test.dart) covers happy-path submit; extend for offline scenarios when adding regression coverage.

## Related

- [apps/mobile/README.md](../apps/mobile/README.md)
- [store-release.md](../apps/mobile/docs/store-release.md)
