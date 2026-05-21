import 'dart:async';

import 'package:chisto_mobile/core/logging/app_log.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Installs framework error hooks. When [useSentry] is true, forwards to Sentry after logging.
void installGlobalErrorHandlers({required bool useSentry}) {
  final FlutterExceptionHandler? previousFlutter = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLog.error(
      'FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
    if (useSentry) {
      Sentry.captureException(
        details.exception,
        stackTrace: details.stack,
      );
    }
    previousFlutter?.call(details);
  };

  final bool Function(Object, StackTrace)? previousPlatform =
      PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppLog.error(
      'Uncaught async error',
      error: error,
      stackTrace: stack,
    );
    if (useSentry) {
      unawaited(Sentry.captureException(error, stackTrace: stack));
    }
    return previousPlatform?.call(error, stack) ?? false;
  };
}
