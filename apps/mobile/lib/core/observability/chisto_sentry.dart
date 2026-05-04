import 'package:sentry_flutter/sentry_flutter.dart';

/// Breadcrumb helper for the reports vertical — **no PII** (no coordinates, addresses, bodies).
void chistoReportsBreadcrumb(
  String category,
  String message, {
  Map<String, Object?> data = const <String, Object?>{},
}) {
  try {
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: category,
        message: message,
        level: SentryLevel.info,
        data: data,
      ),
    );
  } catch (_) {
    // Sentry may be uninitialized in local/dev runs.
  }
}

/// Basename only — avoids leaking full device paths in Sentry breadcrumbs.
String chistoRedactPhotoPathForBreadcrumb(String? path) {
  if (path == null || path.isEmpty) {
    return '';
  }
  final String normalized = path.replaceAll(r'\', '/');
  final int slash = normalized.lastIndexOf('/');
  return slash < 0 ? normalized : normalized.substring(slash + 1);
}

/// Structured outbox pipeline breadcrumb (no coordinates, bodies, or raw paths).
void chistoOutboxBreadcrumb({
  required String phase,
  int attempt = 0,
  int durationMs = 0,
  bool retryable = true,
  String? code,
}) {
  chistoReportsBreadcrumb(
    'report_outbox',
    phase,
    data: <String, Object?>{
      'attempt': attempt,
      'durationMs': durationMs,
      'retryable': retryable,
      if (code != null && code.isNotEmpty) 'code': code,
    },
  );
}
