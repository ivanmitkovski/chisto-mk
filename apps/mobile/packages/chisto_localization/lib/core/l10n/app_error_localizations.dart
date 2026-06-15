import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_localization/core/l10n/duplicate_event_conflict.dart';
import 'package:chisto_localization/l10n/app_localizations.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Maps stable [AppError.code] values to localized copy.
///
/// Never returns raw [AppError.message] — unknown codes fall back to a
/// localized generic by error class.
String localizedAppErrorMessage(AppLocalizations l10n, AppError error) {
  final String? specific = _messageForKnownCode(l10n, error);
  if (specific != null) {
    return specific;
  }
  return _genericFallbackForError(l10n, error);
}

/// Optional secondary line (e.g. retry hint) for error surfaces.
String? localizedAppErrorDetailMessage(AppLocalizations l10n, AppError error) {
  final int? retry = _retryAfterSeconds(error);
  if (retry != null && retry > 0) {
    return l10n.errorUserRetryAfterSeconds(retry);
  }
  if (error.code == 'MAP_RATE_LIMITED' || error.code == 'MAP_RATE_LIMIT_BACKEND') {
    return l10n.mapErrorAutoRetryFootnote;
  }
  return null;
}

int? _retryAfterSeconds(AppError error) {
  final dynamic details = error.details;
  if (details is Map) {
    final dynamic raw = details['retryAfterSeconds'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
  }
  return null;
}

String _genericFallbackForError(AppLocalizations l10n, AppError error) {
  switch (error.code) {
    case 'NETWORK_ERROR':
      return l10n.errorUserNetwork;
    case 'TIMEOUT':
      return l10n.errorUserTimeout;
    case 'UNAUTHORIZED':
    case 'INVALID_TOKEN':
    case 'INVALID_TOKEN_USER':
    case 'INVALID_REFRESH_TOKEN':
    case 'SESSION_REQUIRED':
    case 'INVALID_AUTH_HEADER':
      return l10n.errorUserUnauthorized;
    case 'SESSION_REVOKED':
      return l10n.errorUserSessionRevoked;
    case 'FORBIDDEN':
    case 'NOT_EVENT_ORGANIZER':
    case 'EVENT_CHAT_FORBIDDEN':
    case 'CHECK_IN_FORBIDDEN':
    case 'ROUTE_SEGMENT_FORBIDDEN':
      return l10n.errorUserForbidden;
    case 'NOT_FOUND':
    case 'DATABASE_RECORD_NOT_FOUND':
    case 'REPORT_NOT_FOUND':
    case 'NOTIFICATION_NOT_FOUND':
    case 'CLEANUP_EVENT_NOT_FOUND':
      return l10n.errorUserNotFound;
    case 'SITE_NOT_FOUND':
      return l10n.feedSiteNotFoundMessage;
    case 'EVENT_NOT_FOUND':
      return l10n.eventsEventNotFoundBody;
    case 'SERVER_ERROR':
    case 'INTERNAL_ERROR':
    case 'DATABASE_TIMEOUT':
    case 'DATABASE_UNAVAILABLE':
    case 'DATABASE_DISCONNECTED':
      return l10n.errorUserServer;
    case 'TOO_MANY_REQUESTS':
    case 'TOO_MANY_ATTEMPTS':
    case 'MAP_RATE_LIMITED':
    case 'MAP_RATE_LIMIT_BACKEND':
    case 'EVENT_CHAT_WS_RATE_LIMIT':
    case 'OTP_SEND_RATE_LIMIT':
      return l10n.errorUserTooManyRequests;
    case 'VALIDATION_ERROR':
    case 'BAD_REQUEST':
    case 'REFERENCE_CONSTRAINT':
      return l10n.errorUserValidation;
    case 'CONFLICT':
    case 'DUPLICATE_SUBMIT_INFLIGHT':
    case 'IDEMPOTENCY_IN_FLIGHT':
      return l10n.errorUserConflict;
    case 'CANCELLED':
      return l10n.errorUserCancelled;
    case 'PAYLOAD_TOO_LARGE':
    case 'TOO_MANY_FILES':
      return l10n.errorUserPayloadTooLarge;
    case 'HTTP_ERROR':
      return l10n.errorUserUnknown;
    case 'UNKNOWN':
      return l10n.errorUserUnknown;
    default:
      if (error.code.startsWith('CHECK_IN_')) {
        return _checkInFallback(l10n, error.code);
      }
      if (error.code.startsWith('EVENT_CHAT_') ||
          error.code.startsWith('CHAT_UPLOAD_')) {
        return l10n.eventChatLoadError;
      }
      if (error.code.startsWith('MAP_')) {
        return l10n.mapSyncConnectionUnstable;
      }
      if (error.code.startsWith('ORGANIZER_QUIZ_')) {
        return l10n.errorOrganizerQuizInvalid;
      }
      return l10n.errorUserUnknown;
  }
}

String? _messageForKnownCode(AppLocalizations l10n, AppError error) {
  switch (error.code) {
    // Auth (shared with messageForAuthError)
    case 'INVALID_CREDENTIALS':
      return l10n.authErrorInvalidCredentials;
    case 'ACCOUNT_SUSPENDED':
    case 'ACCOUNT_NOT_ACTIVE':
      return l10n.authErrorAccountSuspended;
    case 'PHONE_NOT_VERIFIED':
      return l10n.authErrorPhoneNotVerified;
    case 'PHONE_NOT_REGISTERED':
      return l10n.authErrorPhoneNotRegistered;
    case 'PASSWORD_RESET_TOKEN_INVALID':
    case 'PASSWORD_RESET_EMAIL_TOKEN_INVALID':
    case 'PASSWORD_RESET_EMAIL_EXPIRED':
      return l10n.authErrorPasswordResetTokenInvalid;
    case 'EMAIL_ALREADY_REGISTERED':
    case 'EMAIL_IN_USE':
      return l10n.authErrorEmailRegistered;
    case 'PHONE_ALREADY_REGISTERED':
    case 'PHONE_IN_USE':
      return l10n.authErrorPhoneRegistered;
    case 'REGISTRATION_CONFLICT':
      return l10n.authErrorRegistrationConflict;
    case 'OTP_NOT_FOUND':
      return l10n.authErrorOtpNotFound;
    case 'OTP_EXPIRED':
      return l10n.authErrorOtpExpired;
    case 'OTP_INVALID':
    case 'INVALID_CODE':
      return l10n.authErrorOtpInvalid;
    case 'OTP_MAX_ATTEMPTS':
      return l10n.authErrorOtpMaxAttempts;
    case 'OTP_SEND_COOLDOWN':
      return l10n.errorOtpSendCooldown;
    case 'OTP_SEND_FAILED':
      return l10n.errorOtpSendFailed;
    case 'CURRENT_PASSWORD_INVALID':
      return l10n.authErrorCurrentPasswordInvalid;
    case 'USER_NOT_FOUND':
      return l10n.authErrorUserNotFound;
    case 'TERMS_VERSION_MISMATCH':
      return l10n.errorTermsVersionMismatch;
    case 'DEVICE_TOKEN_IN_USE':
      return l10n.errorDeviceTokenInUse;

    // Events — schedule / join
    case 'EVENT_START_TOO_EARLY':
      return l10n.eventsStartEventTooEarly;
    case 'EVENT_END_AT_TOO_FAR':
      return l10n.errorEventEndAtTooFar;
    case 'EVENTS_END_DIFFERENT_SKOPJE_CALENDAR_DAY':
      return l10n.errorEventsEndDifferentSkopjeCalendarDay;
    case 'EVENTS_END_AFTER_SKOPJE_LOCAL_DAY':
      return l10n.errorEventsEndAfterSkopjeLocalDay;
    case 'EVENT_JOIN_NOT_YET_OPEN':
      return l10n.eventsJoinNotYetOpen;
    case 'EVENT_JOIN_WINDOW_CLOSED':
      return l10n.eventsJoinWindowClosed;
    case 'EVENT_NOT_EDITABLE':
      return l10n.eventsEventNotEditable;
    case 'EVENT_FULL':
      return l10n.eventsEventFull;
    case 'ALREADY_JOINED':
      return l10n.errorAlreadyJoined;
    case 'ORGANIZER_CANNOT_JOIN':
      return l10n.errorOrganizerCannotJoin;
    case 'NOT_A_PARTICIPANT':
      return l10n.errorNotAParticipant;
    case 'REMINDER_REQUIRES_JOIN':
      return l10n.eventsJoinFirstForReminders;
    case 'EVENT_NOT_JOINABLE':
    case 'EVENT_NOT_APPROVED':
      return l10n.qrScannerErrorCheckInUnavailable;
    case 'DUPLICATE_EVENT':
      final DuplicateEventConflictUi? dup =
          duplicateEventConflictUiFromAppError(error);
      if (dup != null) {
        final String when = DateFormat.yMMMd(
          l10n.localeName,
        ).add_jm().format(dup.scheduledAt.toLocal());
        return l10n.eventsDuplicateEventBlocked(dup.title, when);
      }
      return l10n.errorUserConflict;

    // Quiz / certification
    case 'ORGANIZER_QUIZ_SESSION_EXPIRED':
      return l10n.errorOrganizerQuizSessionExpired;
    case 'ORGANIZER_QUIZ_SESSION_INVALID':
      return l10n.errorOrganizerQuizSessionInvalid;
    case 'ORGANIZER_QUIZ_ANSWERS_MISMATCH':
      return l10n.errorOrganizerQuizAnswersMismatch;
    case 'ORGANIZER_QUIZ_INVALID':
    case 'ORGANIZER_QUIZ_FAILED':
      return l10n.errorOrganizerQuizInvalid;
    case 'ORGANIZER_CERTIFICATION_ALREADY_CERTIFIED':
      return l10n.errorOrganizerCertificationAlreadyDone;
    case 'EVENTS_ORGANIZER_NOT_CERTIFIED':
      return l10n.errorEventsOrganizerNotCertified;
    case 'EVENTS_IMPACT_RECEIPT_NOT_AVAILABLE':
      return l10n.errorEventsImpactReceiptNotAvailable;

    // Reports
    case 'REPORTING_COOLDOWN':
      return l10n.reportListOutboxCooldownBanner;
    case 'SUBMIT_FAILED_RETRYABLE':
      return l10n.errorUserNetwork;

    // Site resolutions (cleanup evidence)
    case 'SITE_RESOLUTION_NOT_ALLOWED':
      return l10n.submitResolutionNotAvailableSnack;
    case 'SITE_RESOLUTION_PENDING_EXISTS':
      return l10n.submitResolutionAlreadyUnderReviewSnack;
    case 'RESOLUTION_UPLOAD_STORAGE_ERROR':
      return l10n.submitResolutionFailedSnack;

    // Chat
    case 'EVENT_CHAT_NOT_PARTICIPANT':
      return l10n.errorEventChatNotParticipant;
    case 'EVENT_CHAT_BODY_INVALID':
      return l10n.eventChatSendFailed;
    case 'EVENT_CHAT_MESSAGE_NOT_FOUND':
    case 'EVENT_CHAT_REPLY_NOT_FOUND':
    case 'EVENT_CHAT_EDIT_DELETED':
    case 'EVENT_CHAT_PIN_DELETED':
      return l10n.errorEventChatMessageUnavailable;
    case 'CHAT_UPLOAD_TOO_MANY':
      return l10n.errorChatUploadTooMany;
    case 'CHAT_UPLOAD_MIME':
    case 'CHAT_UPLOAD_SIZE':
      return l10n.errorChatUploadInvalid;
    case 'S3_NOT_CONFIGURED':
    case 'S3_CIRCUIT_OPEN':
      return l10n.errorUserServer;

    // Avatar / uploads
    case 'AVATAR_FILE_REQUIRED':
      return l10n.errorAvatarFileRequired;
    case 'FILE_TOO_LARGE':
    case 'IMAGE_TOO_LARGE':
      return l10n.errorUserPayloadTooLarge;
    case 'INVALID_FILE_TYPE':
    case 'MIME_TYPE_MISMATCH':
      return l10n.errorInvalidFileType;

    // Feed / map
    case 'FEED_RANKER_UNAVAILABLE':
    case 'FEED_FEATURES_UNAVAILABLE':
      return l10n.feedRefreshStaleSnack;
    case 'INVALID_MAP_VIEWPORT':
    case 'MAP_VIEWPORT_TOO_WIDE':
    case 'MAP_VIEWPORT_OUT_OF_BOUNDS':
    case 'MAP_CENTER_OUT_OF_BOUNDS':
      return l10n.mapSyncConnectionUnstable;

    // Comments / sites
    case 'COMMENT_EMPTY':
      return l10n.errorUserValidation;
    case 'COMMENT_NOT_FOUND':
      return l10n.errorUserNotFound;

    default:
      return null;
  }
}

String _checkInFallback(AppLocalizations l10n, String code) {
  switch (code) {
    case 'CHECK_IN_INVALID_QR':
      return l10n.qrScannerErrorInvalidQr;
    case 'CHECK_IN_WRONG_EVENT':
      return l10n.qrScannerErrorWrongEvent;
    case 'CHECK_IN_SESSION_CLOSED':
      return l10n.qrScannerErrorSessionClosed;
    case 'CHECK_IN_QR_EXPIRED':
    case 'CHECK_IN_REQUEST_EXPIRED':
      return l10n.qrScannerErrorSessionExpired;
    case 'CHECK_IN_REPLAY':
      return l10n.qrScannerErrorReplayDetected;
    case 'CHECK_IN_ALREADY_CHECKED_IN':
    case 'CHECK_IN_ALREADY_RECORDED':
      return l10n.qrScannerErrorAlreadyCheckedIn;
    case 'CHECK_IN_REQUIRES_JOIN':
      return l10n.qrScannerErrorRequiresJoin;
    case 'ORGANIZER_CANNOT_CHECK_IN':
      return l10n.eventsOrganizerFeedbackCheckInUnavailable;
    default:
      return l10n.qrScannerErrorCheckInUnavailable;
  }
}
