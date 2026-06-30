import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:flutter/foundation.dart';

/// Lightweight coach funnel logging (debug only; no PII).
enum CoachTourAnalyticsEvent {
  started,
  stepShown,
  advanced,
  completed,
  skipped,
  dismissedForDeepLink,
}

abstract final class CoachTourAnalytics {
  CoachTourAnalytics._();

  static void log(CoachTourAnalyticsEvent event, {int? stepIndex}) {
    if (!kDebugMode) {
      return;
    }
    final String suffix = stepIndex != null ? ' step=$stepIndex' : '';
    AppLog.verbose('[CoachTour] ${event.name}$suffix');
  }
}
