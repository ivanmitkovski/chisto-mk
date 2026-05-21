import 'dart:convert';

import 'package:chisto_mobile/features/notifications/data/event_chat_push_preview.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shared FCM title/body/channel resolution for foreground and background isolates.
class PushNotificationPayload {
  const PushNotificationPayload._();

  static ({String? title, String? body}) resolveTitleBody(
    RemoteMessage message, {
    AppLocalizations? strings,
  }) {
    final Map<String, dynamic> data = message.data;
    final String? type = data['type'] as String?;
    String? title = message.notification?.title;
    String? body = message.notification?.body;
    if (title == null || title.isEmpty) {
      title = data['title'] as String?;
    }
    if (type == 'EVENT_CHAT') {
      final String resolved =
          EventChatPushPreview.resolveNotificationBody(data, strings: strings);
      final String trimmed = body?.trim() ?? '';
      if (trimmed.isEmpty) {
        body = resolved;
      } else {
        final int colon = trimmed.indexOf(':');
        if (colon >= 0 && trimmed.substring(colon + 1).trim().isEmpty) {
          body = resolved;
        }
      }
    } else if (body == null || body.isEmpty) {
      body = data['body'] as String?;
    }
    return (title: title, body: body);
  }

  /// Silent / data-only pushes that must not show an in-app banner.
  static bool isSilentDataPayload(Map<String, dynamic> data) {
    final String? kind = data['kind'] as String?;
    return kind == 'badge_sync';
  }

  /// Whether to show a heads-up banner while the app is foregrounded.
  static bool shouldPresentForegroundBanner(RemoteMessage message) {
    if (isSilentDataPayload(message.data)) {
      return false;
    }
    final ({String? title, String? body}) resolved = resolveTitleBody(message);
    final String? title = resolved.title?.trim();
    final String? body = resolved.body?.trim();
    return title != null &&
        title.isNotEmpty &&
        body != null &&
        body.isNotEmpty;
  }

  static int? parseMessageCount(Map<String, dynamic> data) {
    final Object? raw = data['messageCount'];
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  /// Unique Android tag / notification id so each message is its own shade entry.
  static String? eventChatNotificationTag(Map<String, dynamic> data) {
    final String? messageId = data['messageId'] as String?;
    if (messageId != null && messageId.isNotEmpty) {
      return 'event_chat_msg_$messageId';
    }
    final String? notificationId = data['notificationId'] as String?;
    if (notificationId != null && notificationId.isNotEmpty) {
      return 'event_chat_notif_$notificationId';
    }
    return null;
  }

  /// Per-event Android notification group / iOS thread id (stack by conversation).
  static String? eventChatOsGroupId(Map<String, dynamic> data) {
    final String? eventId = data['eventId'] as String?;
    if (eventId != null && eventId.isNotEmpty) {
      return 'event_chat_$eventId';
    }
    final String? threadKey = data['threadKey'] as String?;
    if (threadKey != null && threadKey.startsWith('event-chat:')) {
      return 'event_chat_${threadKey.substring('event-chat:'.length)}';
    }
    return null;
  }

  static int? parseUnreadCountFromData(Map<String, dynamic> data) {
    final Object? raw = data['unreadCount'];
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }

  static String? encodePayload(Map<String, dynamic> data) {
    if (data.isEmpty) return null;
    try {
      return jsonEncode(data);
    } on Object {
      return null;
    }
  }

  static Map<String, dynamic>? decodePayload(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on Object {
      return null;
    }
    return null;
  }

  static AndroidChannelInfo resolveAndroidChannel(String? type) {
    switch (type) {
      case 'EVENT_CHAT':
        return const AndroidChannelInfo(
          'chisto_event_chat',
          'Event Chat',
          'Messages on cleanup events you joined',
          Importance.high,
        );
      case 'REPORT_STATUS':
      case 'NEARBY_REPORT':
        return const AndroidChannelInfo(
          'chisto_reports',
          'Report Updates',
          'Report status changes and nearby pollution reports',
          Importance.high,
        );
      case 'CLEANUP_EVENT':
        return const AndroidChannelInfo(
          'chisto_events',
          'Cleanup Events',
          'Cleanup event reminders and updates',
          Importance.high,
        );
      case 'UPVOTE':
      case 'COMMENT':
        return const AndroidChannelInfo(
          'chisto_social',
          'Social Activity',
          'Upvotes, comments, and community interactions',
          Importance.defaultImportance,
        );
      case 'SYSTEM':
      case 'ACHIEVEMENT':
      case 'WELCOME':
        return const AndroidChannelInfo(
          'chisto_system',
          'System',
          'System announcements and achievements',
          Importance.defaultImportance,
        );
      default:
        return const AndroidChannelInfo(
          'chisto_default',
          'Chisto Notifications',
          'Default notification channel for Chisto.mk',
          Importance.high,
        );
    }
  }
}

class AndroidChannelInfo {
  const AndroidChannelInfo(
    this.id,
    this.name,
    this.description,
    this.importance,
  );

  final String id;
  final String name;
  final String description;
  final Importance importance;
}
