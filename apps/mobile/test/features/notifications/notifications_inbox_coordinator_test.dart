import 'package:chisto_infrastructure/core/providers/refresh_signals_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_notifications/src/data/notification_inbox_refresh.dart';
import 'package:feature_notifications/src/data/notifications_inbox_coordinator.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:feature_notifications/src/domain/repositories/notifications_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingNotificationsRepository implements NotificationsRepository {
  _RecordingNotificationsRepository({this.unreadCount = 0});

  int unreadCount;
  int getUnreadCountCalls = 0;

  @override
  Future<int> getUnreadCount() async {
    getUnreadCountCalls++;
    return unreadCount;
  }

  @override
  Future<NotificationsListResult> getNotifications({
    int page = 1,
    int limit = 20,
    bool onlyUnread = false,
  }) => throw UnimplementedError();

  @override
  Future<void> markAsRead(String notificationId) => throw UnimplementedError();

  @override
  Future<void> markAllAsRead() => throw UnimplementedError();

  @override
  Future<List<NotificationPreference>> getPreferences() =>
      throw UnimplementedError();

  @override
  Future<NotificationPreference> setPreference({
    required UserNotificationType type,
    required bool muted,
    DateTime? mutedUntil,
  }) => throw UnimplementedError();

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? appVersion,
    String? locale,
  }) => throw UnimplementedError();

  @override
  Future<void> unregisterDeviceToken(String token) =>
      throw UnimplementedError();

  @override
  Future<void> markAsUnread(String notificationId) =>
      throw UnimplementedError();

  @override
  Future<void> archiveNotification(String notificationId) =>
      throw UnimplementedError();

  @override
  Future<void> archiveAllRead() => throw UnimplementedError();

  @override
  Future<void> recordOpened(String notificationId) =>
      throw UnimplementedError();
}

class _DelayedNotificationsRepository
    extends _RecordingNotificationsRepository {
  _DelayedNotificationsRepository({required this.delay, super.unreadCount});

  final Duration delay;

  @override
  Future<int> getUnreadCount() async {
    getUnreadCountCalls++;
    await Future<void>.delayed(delay);
    return unreadCount;
  }
}

void main() {
  late _RecordingNotificationsRepository repository;
  late NotificationsInboxCoordinator coordinator;

  setUp(() {
    setRootProviderContainer(ProviderContainer());
    repository = _RecordingNotificationsRepository(unreadCount: 2);
    coordinator = NotificationsInboxCoordinator(repository: repository);
    setNotificationsUnreadCount(0);
  });

  test('isInboxVisible tracks open/close refcount', () {
    expect(coordinator.isInboxVisible, isFalse);
    coordinator.onInboxOpened();
    expect(coordinator.isInboxVisible, isTrue);
    coordinator.onInboxOpened();
    coordinator.onInboxClosed();
    expect(coordinator.isInboxVisible, isTrue);
    coordinator.onInboxClosed();
    expect(coordinator.isInboxVisible, isFalse);
    coordinator.onInboxClosed();
    expect(coordinator.isInboxVisible, isFalse);
  });

  test('refreshUnreadBadge fetches and publishes when inbox hidden', () async {
    await coordinator.refreshUnreadBadge();
    expect(repository.getUnreadCountCalls, 1);
    expect(readNotificationsUnreadCount(), 2);
  });

  test('refreshUnreadBadge skips API when inbox visible', () async {
    coordinator.onInboxOpened();
    await coordinator.refreshUnreadBadge();
    expect(repository.getUnreadCountCalls, 0);
    expect(readNotificationsUnreadCount(), 0);
  });

  test('onInboxRefreshTick delegates to refreshUnreadBadge', () async {
    coordinator.onInboxRefreshTick();
    await Future<void>.delayed(Duration.zero);
    expect(repository.getUnreadCountCalls, 1);
    expect(readNotificationsUnreadCount(), 2);
  });

  test('onInboxRefreshTick does not fetch when inbox visible', () async {
    coordinator.onInboxOpened();
    coordinator.onInboxRefreshTick();
    await Future<void>.delayed(Duration.zero);
    expect(repository.getUnreadCountCalls, 0);
  });

  test('fetchUnreadCount returns repository value', () async {
    expect(await coordinator.fetchUnreadCount(), 2);
  });

  test('publishNotificationsUnreadCount is idempotent for same value', () {
    publishNotificationsUnreadCount(3);
    publishNotificationsUnreadCount(3);
    expect(readNotificationsUnreadCount(), 3);
  });

  test(
    'refreshUnreadBadge discards stale count if inbox opened while awaiting',
    () async {
      final _DelayedNotificationsRepository delayedRepo =
          _DelayedNotificationsRepository(
            delay: const Duration(milliseconds: 50),
            unreadCount: 5,
          );
      final NotificationsInboxCoordinator delayedCoordinator =
          NotificationsInboxCoordinator(repository: delayedRepo);
      publishNotificationsUnreadCount(0);

      final Future<void> refresh = delayedCoordinator.refreshUnreadBadge();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      delayedCoordinator.onInboxOpened();
      await refresh;

      expect(delayedRepo.getUnreadCountCalls, 1);
      expect(readNotificationsUnreadCount(), 0);
    },
  );
}
