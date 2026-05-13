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

/// Sentry scope tags for the reports vertical (safe: state names and row ids only).
///
/// See `docs/reports-outbox-runbook.md` for naming and triage.
abstract final class ReportSentryTagKeys {
  static const String outboxState = 'report.outbox.state';
  static const String pipelinePhase = 'report.pipeline.phase';
  static const String correlationOutboxId = 'report.correlation.outbox_id';
}

void chistoReportSentryClearOutboxEntryScope() {
  try {
    Sentry.configureScope((Scope scope) {
      scope.removeTag(ReportSentryTagKeys.outboxState);
      scope.removeTag(ReportSentryTagKeys.correlationOutboxId);
    });
  } catch (_) {}
}

void chistoReportSentryClearReportPipelineScope() {
  try {
    Sentry.configureScope((Scope scope) {
      scope.removeTag(ReportSentryTagKeys.outboxState);
      scope.removeTag(ReportSentryTagKeys.correlationOutboxId);
      scope.removeTag(ReportSentryTagKeys.pipelinePhase);
    });
  } catch (_) {}
}

void chistoReportSentrySyncOutboxScope({
  String? outboxState,
  String? outboxId,
  String? pipelinePhase,
}) {
  try {
    Sentry.configureScope((Scope scope) {
      if (outboxState != null && outboxState.isNotEmpty) {
        scope.setTag(ReportSentryTagKeys.outboxState, outboxState);
      } else {
        scope.removeTag(ReportSentryTagKeys.outboxState);
      }
      if (outboxId != null && outboxId.isNotEmpty) {
        scope.setTag(ReportSentryTagKeys.correlationOutboxId, outboxId);
      } else {
        scope.removeTag(ReportSentryTagKeys.correlationOutboxId);
      }
      if (pipelinePhase != null && pipelinePhase.isNotEmpty) {
        scope.setTag(ReportSentryTagKeys.pipelinePhase, pipelinePhase);
      } else {
        scope.removeTag(ReportSentryTagKeys.pipelinePhase);
      }
    });
  } catch (_) {}
}
