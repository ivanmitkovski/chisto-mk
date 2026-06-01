import 'package:feature_notifications/src/data/notification_inbox_refresh.dart';
import 'package:feature_notifications/src/domain/repositories/notifications_repository.dart';

/// Owns global unread-badge refresh when the notifications inbox is not visible.
///
/// While [isInboxVisible] is true, [NotificationsScreen] reloads the list and
/// publishes unread from list `meta.unreadCount`; this coordinator must not
/// call [NotificationsRepository.getUnreadCount] in parallel (avoids bell/inbox drift).
class NotificationsInboxCoordinator {
  NotificationsInboxCoordinator({required NotificationsRepository repository})
    : _repository = repository;

  final NotificationsRepository _repository;

  int _inboxVisibleCount = 0;

  bool get isInboxVisible => _inboxVisibleCount > 0;

  void onInboxOpened() {
    _inboxVisibleCount++;
  }

  void onInboxClosed() {
    if (_inboxVisibleCount > 0) {
      _inboxVisibleCount--;
    }
  }

  /// Fetches unread count from the API and updates the feed bell.
  Future<int> fetchUnreadCount() async {
    return _repository.getUnreadCount();
  }

  /// Updates the global bell from [GET /notifications/unread-count].
  Future<void> refreshUnreadBadge() async {
    if (isInboxVisible) return;
    try {
      final int count = await _repository.getUnreadCount();
      if (isInboxVisible) return;
      publishNotificationsUnreadCount(count);
    } catch (_) {
      // Badge refresh is best-effort.
    }
  }

  /// Called when [notificationsInboxRefreshTick] increments (push, resume, tap).
  void onInboxRefreshTick() {
    if (isInboxVisible) return;
    // ignore: discarded_futures, fire-and-forget badge refresh
    refreshUnreadBadge();
  }
}
