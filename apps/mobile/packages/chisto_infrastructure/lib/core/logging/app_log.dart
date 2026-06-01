import 'dart:async';
import 'dart:developer' as developer;

import 'package:chisto_infrastructure/core/observability/chisto_sentry.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Lightweight app logging. Wave 18: [warn]/[error] also emit Sentry breadcrumbs.
class AppLog {
  AppLog._();

  static void verbose(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'chisto', level: 500);
    }
  }

  static void warn(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String category = 'app',
  }) {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'chisto',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
    chistoBreadcrumb(category: category, message: message, level: 'warning');
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String category = 'app',
  }) {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'chisto',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
    }
    chistoBreadcrumb(category: category, message: message, level: 'error');
    if (kReleaseMode && error != null) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
    }
  }
}
