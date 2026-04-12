import 'package:flutter/foundation.dart';

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
  debugPrint('[chat_diag] $message$extra');
}
