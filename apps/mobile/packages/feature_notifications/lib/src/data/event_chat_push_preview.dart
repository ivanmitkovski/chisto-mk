import 'package:chisto_infrastructure/l10n/app_localizations.dart';

/// Resolves visible EVENT_CHAT push body from FCM data (with type fallbacks).
abstract final class EventChatPushPreview {
  static String resolveMessageBody(
    Map<String, dynamic> data, {
    AppLocalizations? strings,
  }) {
    final String? preview = (data['messagePreview'] as String?)?.trim();
    if (preview != null && preview.isNotEmpty) {
      return preview;
    }

    final String? rawBody = (data['body'] as String?)?.trim();
    if (rawBody != null && rawBody.isNotEmpty) {
      final String? afterSender = _stripSenderPrefix(rawBody);
      if (afterSender != null && afterSender.isNotEmpty) {
        return afterSender;
      }
    }

    final String? messageType = data['messageType'] as String?;
    return localizedForMessageType(messageType, strings);
  }

  /// Full notification line (`Sender: preview`) for local banners.
  static String resolveNotificationBody(
    Map<String, dynamic> data, {
    AppLocalizations? strings,
  }) {
    final String preview = resolveMessageBody(data, strings: strings);
    final String? sender = (data['senderName'] as String?)?.trim();
    if (sender != null && sender.isNotEmpty) {
      return '$sender: $preview';
    }
    return preview;
  }

  static String? _stripSenderPrefix(String rawBody) {
    final int colon = rawBody.indexOf(':');
    if (colon < 0) {
      return rawBody;
    }
    return rawBody.substring(colon + 1).trim();
  }

  static String localizedForMessageType(
    String? messageType,
    AppLocalizations? strings,
  ) {
    switch (messageType) {
      case 'AUDIO':
        return strings?.eventChatPushPreviewVoice ?? 'Voice message';
      case 'IMAGE':
        return strings?.eventChatPushPreviewPhoto ?? 'Photo';
      case 'VIDEO':
        return strings?.eventChatPushPreviewVideo ?? 'Video';
      case 'FILE':
        return strings?.eventChatPushPreviewFile ?? 'File';
      case 'LOCATION':
        return strings?.eventChatPushPreviewLocation ?? 'Shared location';
      case 'SYSTEM':
        return strings?.eventChatPushPreviewSystem ?? 'Event update';
      case 'TEXT':
      default:
        return strings?.eventChatPushPreviewMessage ?? 'Message';
    }
  }
}
