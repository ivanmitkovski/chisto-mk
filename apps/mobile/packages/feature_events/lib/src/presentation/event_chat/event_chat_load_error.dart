import 'package:chisto_infrastructure/core/errors/app_error.dart';

bool isEventNoLongerAvailable(AppError error) {
  switch (error.code) {
    case 'EVENT_NOT_FOUND':
    case 'NOT_FOUND':
    case 'CLEANUP_EVENT_NOT_FOUND':
      return true;
    default:
      return false;
  }
}

bool isEventChatAccessDenied(AppError error) {
  switch (error.code) {
    case 'EVENT_CHAT_NOT_PARTICIPANT':
    case 'EVENT_CHAT_FORBIDDEN':
    case 'FORBIDDEN':
      return true;
    default:
      return false;
  }
}

bool isTerminalEventChatLoadFailure(AppError error) {
  return !error.retryable ||
      isEventNoLongerAvailable(error) ||
      isEventChatAccessDenied(error);
}
