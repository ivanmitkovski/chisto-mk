import 'package:chisto_infrastructure/core/providers/refresh_signals_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_notifications/src/data/notification_inbox_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    setRootProviderContainer(ProviderContainer());
  });

  test(
    'notificationPushImpliesInboxUpdate is true when notificationId present',
    () {
      expect(
        notificationPushImpliesInboxUpdate(<String, dynamic>{
          'notificationId': 'n1',
        }),
        isTrue,
      );
    },
  );

  test('notificationPushImpliesInboxUpdate is true when type present', () {
    expect(
      notificationPushImpliesInboxUpdate(<String, dynamic>{'type': 'COMMENT'}),
      isTrue,
    );
  });

  test('notificationPushImpliesInboxUpdate is false for empty data', () {
    expect(notificationPushImpliesInboxUpdate(<String, dynamic>{}), isFalse);
  });

  test('bumpNotificationsInboxRefreshTick increments notifier', () {
    final int before = readRoot(notificationsInboxRefreshTickProvider);
    bumpNotificationsInboxRefreshTick(<String, dynamic>{
      'notificationId': 'abc',
    });
    expect(readRoot(notificationsInboxRefreshTickProvider), before + 1);
  });

  test('bumpNotificationsInboxRefreshTick increments for any data payload', () {
    final int before = readRoot(notificationsInboxRefreshTickProvider);
    bumpNotificationsInboxRefreshTick(<String, dynamic>{'foo': 'bar'});
    expect(readRoot(notificationsInboxRefreshTickProvider), before + 1);
  });

  test('bumpNotificationsInboxRefreshTick without data always increments', () {
    final int before = readRoot(notificationsInboxRefreshTickProvider);
    bumpNotificationsInboxRefreshTick();
    expect(readRoot(notificationsInboxRefreshTickProvider), before + 1);
  });

  test('applyPushUnreadCountIfPresent publishes unread from payload', () {
    applyPushUnreadCountIfPresent(<String, dynamic>{'unreadCount': '4'});
    expect(readNotificationsUnreadCount(), 4);
  });

  test('bumpNotificationsInboxRefreshTick applies unreadCount from data', () {
    setNotificationsUnreadCount(0);
    bumpNotificationsInboxRefreshTick(<String, dynamic>{'unreadCount': 2});
    expect(readNotificationsUnreadCount(), 2);
  });

  test('publishNotificationsUnreadCount updates global notifier', () {
    publishNotificationsUnreadCount(3);
    expect(readNotificationsUnreadCount(), 3);
    publishNotificationsUnreadCount(0);
    expect(readNotificationsUnreadCount(), 0);
  });
}
