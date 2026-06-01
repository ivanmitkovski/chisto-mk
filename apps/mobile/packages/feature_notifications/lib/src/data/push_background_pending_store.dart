import 'package:feature_notifications/src/data/push_notification_payload.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kPushPendingUnreadCountKey = 'push_pending_unread_count_v1';
const String kPushPendingInboxBumpKey = 'push_pending_inbox_bump_v1';
const String kPushPendingTapPayloadKey = 'push_pending_tap_payload_v1';
const String kPushLastReceivedAtKey = 'push_last_received_at_v1';

/// Result of draining background push state on resume / cold start.
class PendingPushDrainResult {
  const PendingPushDrainResult({
    this.unreadCount,
    this.inboxBump = false,
    this.tapPayload,
  });

  final int? unreadCount;
  final bool inboxBump;
  final Map<String, dynamic>? tapPayload;

  bool get hasWork =>
      unreadCount != null ||
      inboxBump ||
      (tapPayload != null && tapPayload!.isNotEmpty);
}

/// Persists minimal push state from the FCM background isolate (no AppBootstrap).
class PushBackgroundPendingStore {
  PushBackgroundPendingStore._();

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<void> recordBackgroundMessage(RemoteMessage message) async {
    final SharedPreferences prefs = await _prefs();
    final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);

    await prefs.setBool(kPushPendingInboxBumpKey, true);
    await prefs.setInt(
      kPushLastReceivedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    final int? unread = PushNotificationPayload.parseUnreadCountFromData(data);
    if (unread != null) {
      await prefs.setInt(kPushPendingUnreadCountKey, unread);
    }

    final String? notificationId = data['notificationId'] as String?;
    if (notificationId != null && notificationId.isNotEmpty) {
      final String? encoded = PushNotificationPayload.encodePayload(data);
      if (encoded != null) {
        await prefs.setString(kPushPendingTapPayloadKey, encoded);
      }
    }
  }

  static Future<void> stashLaunchTapPayload(Map<String, dynamic> data) async {
    if (data.isEmpty) return;
    final String? encoded = PushNotificationPayload.encodePayload(data);
    if (encoded == null) return;
    final SharedPreferences prefs = await _prefs();
    await prefs.setString(kPushPendingTapPayloadKey, encoded);
  }

  static Future<PendingPushDrainResult> drainPending() async {
    final SharedPreferences prefs = await _prefs();

    final int unread = prefs.getInt(kPushPendingUnreadCountKey) ?? -1;
    final bool inboxBump = prefs.getBool(kPushPendingInboxBumpKey) ?? false;
    final String? tapRaw = prefs.getString(kPushPendingTapPayloadKey);

    await prefs.remove(kPushPendingUnreadCountKey);
    await prefs.remove(kPushPendingInboxBumpKey);
    await prefs.remove(kPushPendingTapPayloadKey);

    return PendingPushDrainResult(
      unreadCount: unread >= 0 ? unread : null,
      inboxBump: inboxBump,
      tapPayload: PushNotificationPayload.decodePayload(tapRaw),
    );
  }

  /// Wipes every pending background push hint. Used on logout / account
  /// switch so a notification queued for user A can't tap-route user B.
  static Future<void> clearAll() async {
    final SharedPreferences prefs = await _prefs();
    await prefs.remove(kPushPendingUnreadCountKey);
    await prefs.remove(kPushPendingInboxBumpKey);
    await prefs.remove(kPushPendingTapPayloadKey);
    await prefs.remove(kPushLastReceivedAtKey);
  }

  @visibleForTesting
  static Future<void> clearForTest() => clearAll();
}
