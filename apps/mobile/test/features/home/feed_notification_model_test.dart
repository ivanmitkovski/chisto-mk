import 'package:chisto_mobile/features/home/domain/models/feed_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedNotificationType', () {
    test('has expected enum values', () {
      expect(FeedNotificationType.values.length, 3);
      expect(FeedNotificationType.values, contains(FeedNotificationType.update));
      expect(FeedNotificationType.values, contains(FeedNotificationType.action));
      expect(FeedNotificationType.values, contains(FeedNotificationType.system));
    });

    test('enum names match', () {
      expect(FeedNotificationType.update.name, 'update');
      expect(FeedNotificationType.action.name, 'action');
      expect(FeedNotificationType.system.name, 'system');
    });
  });

  group('FeedNotification', () {
    final DateTime createdAt = DateTime(2025, 6, 15, 10, 30);

    test('constructs with required fields', () {
      final FeedNotification notification = FeedNotification(
        id: 'n1',
        title: 'Update',
        message: 'Your report was reviewed',
        createdAt: createdAt,
        type: FeedNotificationType.update,
      );

      expect(notification.id, 'n1');
      expect(notification.title, 'Update');
      expect(notification.message, 'Your report was reviewed');
      expect(notification.createdAt, createdAt);
      expect(notification.type, FeedNotificationType.update);
      expect(notification.isRead, false);
      expect(notification.targetSiteId, isNull);
      expect(notification.targetTabIndex, isNull);
    });

    test('constructs with optional fields', () {
      final FeedNotification notification = FeedNotification(
        id: 'n2',
        title: 'Action',
        message: 'Action required',
        createdAt: createdAt,
        type: FeedNotificationType.action,
        isRead: true,
        targetSiteId: 'site-1',
        targetTabIndex: 2,
      );

      expect(notification.isRead, true);
      expect(notification.targetSiteId, 'site-1');
      expect(notification.targetTabIndex, 2);
    });

    test('copyWith produces new instance with updated fields', () {
      final FeedNotification original = FeedNotification(
        id: 'n1',
        title: 'Original',
        message: 'Original message',
        createdAt: createdAt,
        type: FeedNotificationType.update,
        isRead: false,
      );

      final FeedNotification updated = original.copyWith(
        title: 'Updated',
        isRead: true,
        type: FeedNotificationType.system,
      );

      expect(updated.id, 'n1');
      expect(updated.title, 'Updated');
      expect(updated.message, 'Original message');
      expect(updated.isRead, true);
      expect(updated.type, FeedNotificationType.system);
    });

    test('copyWith preserves unchanged fields', () {
      final FeedNotification original = FeedNotification(
        id: 'n1',
        title: 'Title',
        message: 'Message',
        createdAt: createdAt,
        type: FeedNotificationType.action,
        targetSiteId: 'site-1',
      );

      final FeedNotification updated = original.copyWith(isRead: true);

      expect(updated.targetSiteId, 'site-1');
      expect(updated.targetTabIndex, isNull);
    });
  });
}
