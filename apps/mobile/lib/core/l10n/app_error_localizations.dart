import 'package:chisto_mobile/core/errors/app_error.dart';
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
    case 'FORBIDDEN':
      return l10n.errorUserForbidden;
    case 'NOT_FOUND':
      return l10n.errorUserNotFound;
    case 'EVENT_START_TOO_EARLY':
      return l10n.eventsStartEventTooEarly;
    case 'SERVER_ERROR':
      return l10n.errorUserServer;
    case 'TOO_MANY_REQUESTS':
      return l10n.errorUserTooManyRequests;
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
    default:
      if (error.message.trim().isNotEmpty) {
        return error.message;
      }
      return l10n.errorUserUnknown;
  }
}
