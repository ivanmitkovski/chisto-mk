import 'package:flutter/foundation.dart';
import 'package:chisto_mobile/core/logging/app_log.dart';

/// Debug-only, non-PII breadcrumbs for chat flows. Enable with
/// `--dart-define=CHAT_DIAG=true`.
void chatDiagLog(String message, [Map<String, Object?>? fields]) {
  if (!kDebugMode) {
    return;
  }
  const bool enabled = bool.fromEnvironment('CHAT_DIAG', defaultValue: false);
  if (!enabled) {
    return;
  }
  final String extra = fields == null || fields.isEmpty
      ? ''
      : ' ${fields.entries.map((MapEntry<String, Object?> e) => '${e.key}=${e.value}').join(' ')}';
  AppLog.verbose('[chat_diag] $message$extra');
}
