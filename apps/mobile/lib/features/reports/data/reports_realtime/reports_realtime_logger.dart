import 'dart:developer' as developer;

/// No PII: connection lifecycle and sizes only.
void reportsRealtimeLog(
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  developer.log(
    message,
    name: 'ReportsRealtime',
    error: error,
    stackTrace: stackTrace,
  );
}
