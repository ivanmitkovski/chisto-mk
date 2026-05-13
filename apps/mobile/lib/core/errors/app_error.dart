class AppError implements Exception {
  const AppError({
    required this.code,
    required this.message,
    this.retryable = false,
    this.details,
    this.cause,
    this.serverTimestamp,
  });

  final String code;
  final String message;
  final bool retryable;
  final dynamic details;
  final Object? cause;

  /// When the API includes `timestamp` on error JSON, parsed for support correlation.
  final DateTime? serverTimestamp;

  /// Session or access token is no longer accepted; user should sign in again.
  ///
  /// Aligns with [ApiClient] 401 handling and [AppErrorView] sign-out affordance.
  bool get indicatesInvalidOrEndedSession {
    switch (code) {
      case 'UNAUTHORIZED':
      case 'INVALID_TOKEN_USER':
      case 'ACCOUNT_NOT_ACTIVE':
      case 'SESSION_REVOKED':
        return true;
      default:
        return false;
    }
  }

  factory AppError.network({String? message, Object? cause}) => AppError(
        code: 'NETWORK_ERROR',
        message: message ?? 'Unable to reach the server. Check your connection.',
        retryable: true,
        cause: cause,
      );

  factory AppError.timeout({String? message, DateTime? serverTimestamp}) =>
      AppError(
        code: 'TIMEOUT',
        message: message ?? 'The request took too long. Please try again.',
        retryable: true,
        serverTimestamp: serverTimestamp,
      );

  factory AppError.unauthorized({String? message}) => AppError(
        code: 'UNAUTHORIZED',
        message: message ?? 'Your session has expired. Please sign in again.',
        retryable: false,
      );

  factory AppError.forbidden({String? message}) => AppError(
        code: 'FORBIDDEN',
        message: message ?? 'You do not have permission to perform this action.',
        retryable: false,
      );

  factory AppError.notFound({String? message, DateTime? serverTimestamp}) =>
      AppError(
        code: 'NOT_FOUND',
        message: message ?? 'The requested resource was not found.',
        retryable: false,
        serverTimestamp: serverTimestamp,
      );

  factory AppError.server({
    String? message,
    Object? cause,
    DateTime? serverTimestamp,
  }) =>
      AppError(
        code: 'SERVER_ERROR',
        message: message ?? 'Something went wrong on our end. Please try again.',
        retryable: true,
        cause: cause,
        serverTimestamp: serverTimestamp,
      );

  factory AppError.validation({
    required String message,
    dynamic details,
    DateTime? serverTimestamp,
  }) =>
      AppError(
        code: 'VALIDATION_ERROR',
        message: message,
        retryable: false,
        details: details,
        serverTimestamp: serverTimestamp,
      );

  factory AppError.cancelled({String? message}) => AppError(
        code: 'CANCELLED',
        message: message ?? 'Cancelled.',
        retryable: false,
      );

  /// Rate limit / throttling (HTTP 429 or API `TOO_MANY_REQUESTS`).
  factory AppError.tooManyRequests({
    String? message,
    int? retryAfterSeconds,
    DateTime? serverTimestamp,
  }) =>
      AppError(
        code: 'TOO_MANY_REQUESTS',
        message:
            message ?? 'Too many requests. Please wait and try again.',
        retryable: true,
        details: retryAfterSeconds != null
            ? <String, dynamic>{'retryAfterSeconds': retryAfterSeconds}
            : null,
        serverTimestamp: serverTimestamp,
      );

  factory AppError.unknown({Object? cause}) => AppError(
        code: 'UNKNOWN',
        message: 'An unexpected error occurred.',
        retryable: false,
        cause: cause,
      );

  @override
  String toString() => 'AppError($code: $message)';
}
