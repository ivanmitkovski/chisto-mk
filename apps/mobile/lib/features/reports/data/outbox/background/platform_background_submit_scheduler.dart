import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

import 'package:chisto_mobile/core/logging/app_log.dart';
import 'package:chisto_mobile/features/reports/data/outbox/background/background_submit_scheduler.dart';
import 'package:chisto_mobile/features/reports/data/outbox/background/report_outbox_background_drain.dart';

/// Runs the in-process [drain] immediately, and **additionally** schedules a
/// native one-off task so uploads can resume after the app is suspended.
///
/// On **iOS**, BG processing uses `UIBackgroundModes` + `BGTaskSchedulerPermittedIdentifiers`
/// in `Info.plist` and `WorkmanagerPlugin` registration in `AppDelegate.swift`.
/// The in-process microtask path still drains while the app is foregrounded.
/// See `docs/reports-outbox-runbook.md` and `apps/mobile/README.md`.
///
/// The Workmanager callback runs [ReportOutboxBackgroundDrain.run] — not the
/// closure passed here — so there must be only one app outbox coordinator
/// policy (same as today).
class PlatformBackgroundSubmitScheduler implements BackgroundSubmitScheduler {
  @override
  void scheduleDrain(Future<void> Function() drain) {
    InProcessBackgroundSubmitScheduler().scheduleDrain(drain);
    if (kIsWeb) {
      return;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        unawaited(_enqueueNativeDrain());
        return;
      default:
        return;
    }
  }

  static DateTime? _lastNativeEnqueueAt;
  static const Duration _coalesce = Duration(seconds: 2);

  static Future<void> _enqueueNativeDrain() async {
    final DateTime now = DateTime.now();
    if (_lastNativeEnqueueAt != null &&
        now.difference(_lastNativeEnqueueAt!) < _coalesce) {
      return;
    }
    _lastNativeEnqueueAt = now;
    try {
      await Workmanager().registerOneOffTask(
        ReportOutboxBackgroundDrain.uniqueTaskName,
        ReportOutboxBackgroundDrain.taskName,
        initialDelay: Duration.zero,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
    } on MissingPluginException catch (e) {
      AppLog.verbose(
        '[Workmanager] report outbox drain skipped (no plugin): $e',
      );
    } on UnimplementedError catch (e) {
      AppLog.verbose(
        '[Workmanager] report outbox drain skipped (no native impl): $e',
      );
    } on Exception catch (e, st) {
      AppLog.warn(
        '[Workmanager] report outbox drain enqueue failed: $e',
        error: e,
        stackTrace: st,
      );
    }
  }
}
