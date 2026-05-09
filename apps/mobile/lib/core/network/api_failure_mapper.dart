import 'dart:io' show HttpDate;

import 'package:chisto_mobile/core/errors/app_error.dart';

/// Maps failed HTTP responses to [AppError] without side effects (no token clearing).
/// The HTTP client applies session invalidation for selected 401 codes after mapping.
AppError appErrorFromFailedResponse({
  required int statusCode,
  Map<String, dynamic>? json,
  String? bodyStr,
  String? retryAfterHeader,
}) {
  final DateTime? serverTimestamp = _parseApiTimestamp(json?['timestamp']);
  final String code = json?['code'] is String
      ? json!['code'] as String
      : _codeForStatus(statusCode);
  final String message = json?['message'] is String
      ? json!['message'] as String
      : (bodyStr ?? 'Request failed');
  final dynamic details = json?['details'];
  final int? jsonRetryAfter = json?['retryAfterSeconds'] is int
      ? json!['retryAfterSeconds'] as int
      : null;
  final int? headerRetryAfter = _parseRetryAfterSeconds(retryAfterHeader);

  if (statusCode == 429) {
    final Map<String, dynamic> merged = <String, dynamic>{};
    if (details is Map) {
      merged.addAll(Map<String, dynamic>.from(details));
    }
    final int? retryAfter = jsonRetryAfter ?? headerRetryAfter;
    if (retryAfter != null) {
      merged['retryAfterSeconds'] = retryAfter;
    }
    return AppError(
      code: 'TOO_MANY_REQUESTS',
      message: message,
      retryable: true,
      details: merged.isEmpty ? null : merged,
      serverTimestamp: serverTimestamp,
    );
  }

  if (statusCode == 401) {
    return AppError(
      code: code,
      message: message,
      serverTimestamp: serverTimestamp,
    );
  }
  if (statusCode == 403) {
    return AppError(
      code: code,
      message: message,
      retryable: false,
      serverTimestamp: serverTimestamp,
    );
  }
  if (statusCode == 404) {
    return AppError.notFound(
      message: message,
      serverTimestamp: serverTimestamp,
    );
  }
  if (statusCode == 422 ||
      (statusCode == 400 && code == 'VALIDATION_ERROR')) {
    return AppError.validation(
      message: message,
      details: details,
      serverTimestamp: serverTimestamp,
    );
  }
  if (statusCode >= 500) {
    return AppError.server(
      message: message,
      serverTimestamp: serverTimestamp,
    );
  }
  if (statusCode == 408 || statusCode == 504) {
    return AppError.timeout(
      message: message,
      serverTimestamp: serverTimestamp,
    );
  }
  return AppError(
    code: code,
    message: message,
    retryable: statusCode >= 500 || statusCode == 408 || statusCode == 504,
    details: details,
    serverTimestamp: serverTimestamp,
  );
}

DateTime? _parseApiTimestamp(Object? raw) {
  if (raw is String && raw.isNotEmpty) {
    return DateTime.tryParse(raw);
  }
  return null;
}

int? _parseRetryAfterSeconds(String? header) {
  if (header == null || header.isEmpty) return null;
  final int? asInt = int.tryParse(header.trim());
  if (asInt != null && asInt >= 0) return asInt;
  try {
    final DateTime httpDate = HttpDate.parse(header.trim());
    final int sec = httpDate.difference(DateTime.now()).inSeconds;
    return sec > 0 ? sec : null;
  } catch (_) {
    return null;
  }
}

String _codeForStatus(int status) {
  switch (status) {
    case 400:
      return 'BAD_REQUEST';
    case 401:
      return 'UNAUTHORIZED';
    case 403:
      return 'FORBIDDEN';
    case 404:
      return 'NOT_FOUND';
    case 409:
      return 'CONFLICT';
    case 429:
      return 'TOO_MANY_REQUESTS';
    default:
      return 'HTTP_ERROR';
  }
}
