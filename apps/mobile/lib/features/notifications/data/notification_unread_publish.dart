import 'package:chisto_mobile/core/providers/refresh_signals_providers.dart';
import 'package:chisto_mobile/features/notifications/data/notification_inbox_refresh.dart';
import 'package:flutter/foundation.dart';

DateTime? _suppressUnreadIncreasesUntil;

/// After mark-all-read, ignore stale API/meta counts that would bump the badge.
void beginSuppressUnreadBadgeIncreases({
  Duration duration = const Duration(seconds: 3),
}) {
  _suppressUnreadIncreasesUntil = DateTime.now().add(duration);
}

@visibleForTesting
void clearSuppressUnreadBadgeIncreasesForTest() {
  _suppressUnreadIncreasesUntil = null;
}

bool get isSuppressingUnreadBadgeIncreases {
  final DateTime? until = _suppressUnreadIncreasesUntil;
  if (until == null) return false;
  if (DateTime.now().isAfter(until)) {
    _suppressUnreadIncreasesUntil = null;
    return false;
  }
  return true;
}

/// Publishes unread count to feed bell and app icon unless suppressed after mark-all.
void publishNotificationsUnreadCountRespectingSuppress(int count) {
  if (isSuppressingUnreadBadgeIncreases &&
      count > readNotificationsUnreadCount()) {
    return;
  }
  publishNotificationsUnreadCount(count);
}

/// Server refresh after mark-read should not resurrect a higher badge.
///
/// Outside the post-mark-all suppress window, always trust the server count so
/// the feed bell can catch up with the inbox.
bool shouldApplyServerUnreadCount(int latest, {bool allowIncrease = false}) {
  if (allowIncrease) return true;
  if (!isSuppressingUnreadBadgeIncreases) return true;
  final int current = readNotificationsUnreadCount();
  return latest <= current;
}
