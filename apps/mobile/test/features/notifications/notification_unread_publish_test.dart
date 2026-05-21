import 'package:chisto_mobile/core/providers/refresh_signals_providers.dart';
import 'package:chisto_mobile/core/providers/root_container.dart';
import 'package:chisto_mobile/features/notifications/data/notification_unread_publish.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    clearSuppressUnreadBadgeIncreasesForTest();
    setRootProviderContainer(ProviderContainer());
    setNotificationsUnreadCount(2);
  });

  test('publishNotificationsUnreadCountRespectingSuppress blocks increases', () {
    beginSuppressUnreadBadgeIncreases();
    publishNotificationsUnreadCountRespectingSuppress(5);
    expect(readNotificationsUnreadCount(), 2);
    publishNotificationsUnreadCountRespectingSuppress(0);
    expect(readNotificationsUnreadCount(), 0);
  });

  test('shouldApplyServerUnreadCount allows sync outside suppress window', () {
    setNotificationsUnreadCount(0);
    expect(shouldApplyServerUnreadCount(3), isTrue);
    expect(shouldApplyServerUnreadCount(0), isTrue);
  });

  test('shouldApplyServerUnreadCount blocks increase while suppressing', () {
    setNotificationsUnreadCount(0);
    beginSuppressUnreadBadgeIncreases();
    expect(shouldApplyServerUnreadCount(3), isFalse);
    expect(shouldApplyServerUnreadCount(0), isTrue);
  });

  test('shouldApplyServerUnreadCount allows increase when requested', () {
    setNotificationsUnreadCount(0);
    beginSuppressUnreadBadgeIncreases();
    expect(shouldApplyServerUnreadCount(5, allowIncrease: true), isTrue);
  });
}
