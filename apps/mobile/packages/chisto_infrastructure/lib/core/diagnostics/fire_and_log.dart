import 'dart:async';

import 'package:chisto_infrastructure/core/logging/app_log.dart';

/// Runs [future] without awaiting; logs failures instead of swallowing them.
void fireAndLog(
  Future<void> future, {
  required String op,
  String category = 'fire_and_log',
}) {
  unawaited(
    future.catchError((Object error, StackTrace stackTrace) {
      AppLog.warn(
        '$op failed',
        error: error,
        stackTrace: stackTrace,
        category: category,
      );
    }),
  );
}
