import 'dart:async';

import 'package:chisto_mobile/core/logging/app_log.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Fire-and-forget with centralized error logging (debug + Sentry when configured).
void fireAndLog(
  Future<void> future, {
  required String operation,
  bool captureToSentry = true,
}) {
  unawaited(
    future.catchError((Object error, StackTrace stack) {
      AppLog.warn(
        '$operation failed',
        error: error,
        stackTrace: stack,
      );
      if (captureToSentry && !kDebugMode) {
        unawaited(Sentry.captureException(error, stackTrace: stack));
      }
    }),
  );
}
