import 'package:sentry_flutter/sentry_flutter.dart';

/// Strips tokens, credentials, and query secrets before events leave the device.
SentryEvent? chistoSentryBeforeSend(SentryEvent event, Hint hint) {
  final SentryRequest? request = event.request;
  SentryRequest? scrubbedRequest = request;
  if (request != null) {
    final Map<String, String> headers = Map<String, String>.from(
      request.headers,
    );
    for (final String key in headers.keys.toList()) {
      if (key.toLowerCase() == 'authorization') {
        headers[key] = '[Filtered]';
      }
    }
    scrubbedRequest = SentryRequest(
      url: _scrubUrlQuery(request.url),
      method: request.method,
      headers: headers,
      data: request.data != null ? '[Filtered]' : null,
      cookies: request.cookies != null ? '[Filtered]' : null,
    );
    return SentryEvent(
      throwable: event.throwable,
      level: event.level,
      message: event.message,
      timestamp: event.timestamp,
      release: event.release,
      environment: event.environment,
      request: scrubbedRequest,
      tags: event.tags,
      user: event.user,
      contexts: event.contexts,
      breadcrumbs: event.breadcrumbs,
      fingerprint: event.fingerprint,
    );
  }
  return event;
}

String? _scrubUrlQuery(String? url) {
  if (url == null || url.isEmpty || !url.contains('?')) {
    return url;
  }
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) {
    return url;
  }
  const Set<String> sensitive = <String>{
    'token',
    'access_token',
    'refresh_token',
    'password',
    'otp',
    'code',
  };
  final Map<String, String> q = Map<String, String>.from(uri.queryParameters);
  for (final String key in q.keys.toList()) {
    if (sensitive.contains(key.toLowerCase())) {
      q[key] = '[Filtered]';
    }
  }
  return uri.replace(queryParameters: q).toString();
}

/// Tags Sentry events with the signed-in user id so we can group reports per
/// session without leaking PII (no email, name, or phone). Called once after
/// successful sign-in / token restore.
Future<void> chistoSentrySetUser(String userId) async {
  try {
    await Sentry.configureScope((Scope scope) async {
      await scope.setUser(SentryUser(id: userId));
    });
  } on Object {
    // Sentry may be uninitialized in local/dev runs.
  }
}

/// Clears the user tag on logout / account switch so subsequent crashes are
/// not attributed to the previous account.
Future<void> chistoSentryClearUser() async {
  try {
    await Sentry.configureScope((Scope scope) async {
      await scope.setUser(null);
    });
  } on Object {
    // Sentry may be uninitialized in local/dev runs.
  }
}

/// Generic Sentry breadcrumb (Wave 18). Avoid PII in [message].
void chistoBreadcrumb({
  required String category,
  required String message,
  String level = 'info',
}) {
  try {
    final SentryLevel sentryLevel = switch (level) {
      'warning' => SentryLevel.warning,
      'error' => SentryLevel.error,
      _ => SentryLevel.info,
    };
    Sentry.addBreadcrumb(
      Breadcrumb(category: category, message: message, level: sentryLevel),
    );
  } on Object {
    // Sentry may be uninitialized in local/dev runs.
  }
}

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
