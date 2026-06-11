# chisto_mobile

Chisto.mk Flutter app.

## Toolchain

Pinned in repo root [`.tool-versions`](../../.tool-versions): **Flutter 3.44.0**, **Dart 3.12.0**.

```sh
flutter pub get
flutter analyze lib
flutter test test/
dart run tool/check_haptics_usage.dart
```

Release version: `pubspec.yaml` (`1.0.0+4`). Store-submission mechanics (certificates, provisioning, screenshots, metadata) are documented in the launch-readiness submission guide (`docs/launch-readiness/phase-13-submission-guide.md`, produced in Phase 13).

```sh
# Staging beta IPA / AAB (requires signing secrets — see checklist)
./scripts/build-beta.sh both
```

## Local development privacy (draft)

When you run the app against a local or staging API, your device still sends the same categories of data the production build would (for example, account identifiers when signed in, photos and location when you file a report, and telemetry needed for maps and events). Treat any non-production backend like real user data: use test accounts, avoid personal photos in shared builds, and do not log or share API responses that could contain someone else’s submissions.

## Workmanager (`0.9.x`) and Android builds

The app pins **`workmanager` `0.9.0+3`** in `pubspec.lock`. If Gradle errors mention **`workmanager-0.5.x`** (Kotlin `Registrar`, `shim`, etc.), your tree is out of sync with the lockfile.

From **`apps/mobile`** run:

```sh
flutter pub get
flutter clean
flutter build apk --debug
```

Do **not** add `dependency_overrides` for Workmanager unless a transitive conflict is proven; document any override in the PR.

Background tasks use a **single** Dart callback, [`chistoWorkmanagerCallbackDispatcher`](lib/core/background/chisto_workmanager_dispatcher.dart): offline map refresh and **report outbox drain** are routed by task name. **iOS**: `UIBackgroundModes` (`fetch`, `processing`), `BGTaskSchedulerPermittedIdentifiers` (`chisto.reportOutbox.drain`, `offline-regions-refresh`), and `AppDelegate` Workmanager registration must stay aligned with [`PlatformBackgroundSubmitScheduler`](lib/features/reports/data/outbox/background/platform_background_submit_scheduler.dart). Apple quotas still apply — see [`docs/reports-outbox-runbook.md`](../../docs/reports-outbox-runbook.md) (repo root) for device QA steps.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
