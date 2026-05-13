import 'package:intl/intl.dart' hide TextDirection;

import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/l10n/duplicate_event_conflict.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Maps stable [AppError.code] values to localized copy. Falls back to
/// [AppError.message] for validation and unknown server codes.
String localizedAppErrorMessage(AppLocalizations l10n, AppError error) {
  switch (error.code) {
    case 'NETWORK_ERROR':
      return l10n.errorUserNetwork;
    case 'TIMEOUT':
      return l10n.errorUserTimeout;
    case 'UNAUTHORIZED':
      return l10n.errorUserUnauthorized;
    case 'SESSION_REVOKED':
      return l10n.errorUserSessionRevoked;
    case 'FORBIDDEN':
      return l10n.errorUserForbidden;
    case 'NOT_FOUND':
      return l10n.errorUserNotFound;
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
    case 'SERVER_ERROR':
      return l10n.errorUserServer;
    case 'TOO_MANY_REQUESTS':
      return l10n.errorUserTooManyRequests;
    case 'EVENT_NOT_EDITABLE':
      return l10n.eventsEventNotEditable;
    case 'DUPLICATE_EVENT':
      final DuplicateEventConflictUi? dup =
          duplicateEventConflictUiFromAppError(error);
      if (dup != null) {
        final String when = DateFormat.yMMMd(
          l10n.localeName,
        ).add_jm().format(dup.scheduledAt.toLocal());
        return l10n.eventsDuplicateEventBlocked(dup.title, when);
      }
      if (error.message.trim().isNotEmpty) {
        return error.message;
      }
      return l10n.errorUserUnknown;
    case 'VALIDATION_ERROR':
    case 'BAD_REQUEST':
    case 'CONFLICT':
    case 'HTTP_ERROR':
      if (error.message.trim().isNotEmpty) {
        return error.message;
      }
      return l10n.errorUserUnknown;
    case 'UNKNOWN':
      return l10n.errorUserUnknown;
    case 'ORGANIZER_QUIZ_SESSION_EXPIRED':
      return l10n.errorOrganizerQuizSessionExpired;
    case 'ORGANIZER_QUIZ_SESSION_INVALID':
      return l10n.errorOrganizerQuizSessionInvalid;
    case 'ORGANIZER_QUIZ_ANSWERS_MISMATCH':
      return l10n.errorOrganizerQuizAnswersMismatch;
    case 'ORGANIZER_QUIZ_INVALID':
      return l10n.errorOrganizerQuizInvalid;
    case 'ORGANIZER_CERTIFICATION_ALREADY_CERTIFIED':
      return l10n.errorOrganizerCertificationAlreadyDone;
    case 'EVENTS_IMPACT_RECEIPT_NOT_AVAILABLE':
      return l10n.errorEventsImpactReceiptNotAvailable;
    default:
      if (error.message.trim().isNotEmpty) {
        return error.message;
      }
      return l10n.errorUserUnknown;
  }
}
