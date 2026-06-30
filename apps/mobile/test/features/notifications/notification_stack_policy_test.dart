import 'dart:io';

import 'package:feature_notifications/src/data/notification_navigation_origin.dart';
import 'package:feature_notifications/src/data/notification_navigation_target.dart';
import 'package:feature_notifications/src/data/notification_stack_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notificationUsesExternalGoNavigation', () {
    test('inbox never uses external go navigation', () {
      const List<NotificationNavigationTarget> targets =
          <NotificationNavigationTarget>[
            NotificationOpenHomeMapFocus(siteId: 'site_1'),
            NotificationOpenHomeTab(tabIndex: 1),
            NotificationOpenFeatureGuide(),
            NotificationOpenReportDetail(reportId: 'report_1'),
            NotificationOpenSiteDetail(siteId: 'site_1'),
            NotificationOpenEventDetail(eventId: 'event_1'),
            NotificationOpenEventChat(eventId: 'event_1'),
            NotificationOpenProfileAchievements(),
          ];

      for (final NotificationNavigationTarget target in targets) {
        expect(
          notificationUsesExternalGoNavigation(
            origin: NotificationNavigationOrigin.inbox,
            target: target,
          ),
          isFalse,
          reason: 'inbox must preserve stack for $target',
        );
      }
    });

    test('external uses go only for tab-only targets', () {
      expect(
        notificationUsesExternalGoNavigation(
          origin: NotificationNavigationOrigin.external,
          target: const NotificationOpenHomeMapFocus(siteId: 'site_1'),
        ),
        isTrue,
      );
      expect(
        notificationUsesExternalGoNavigation(
          origin: NotificationNavigationOrigin.external,
          target: const NotificationOpenHomeTab(tabIndex: 2),
        ),
        isTrue,
      );
      expect(
        notificationUsesExternalGoNavigation(
          origin: NotificationNavigationOrigin.external,
          target: const NotificationOpenFeatureGuide(),
        ),
        isTrue,
      );
      expect(
        notificationUsesExternalGoNavigation(
          origin: NotificationNavigationOrigin.external,
          target: const NotificationOpenReportDetail(reportId: 'report_1'),
        ),
        isFalse,
      );
      expect(
        notificationUsesExternalGoNavigation(
          origin: NotificationNavigationOrigin.external,
          target: const NotificationOpenEventDetail(eventId: 'event_1'),
        ),
        isFalse,
      );
    });
  });

  group('notificationUsesRootEntityPush', () {
    test('entity targets use root push', () {
      expect(
        notificationUsesRootEntityPush(
          const NotificationOpenReportDetail(reportId: 'r1'),
        ),
        isTrue,
      );
      expect(
        notificationUsesRootEntityPush(
          const NotificationOpenSiteDetail(siteId: 's1'),
        ),
        isTrue,
      );
      expect(
        notificationUsesRootEntityPush(
          const NotificationOpenEventDetail(eventId: 'e1'),
        ),
        isTrue,
      );
      expect(
        notificationUsesRootEntityPush(
          const NotificationOpenEventChat(eventId: 'e1'),
        ),
        isTrue,
      );
      expect(
        notificationUsesRootEntityPush(
          const NotificationOpenProfileAchievements(),
        ),
        isTrue,
      );
    });

    test('tab-only targets do not use root entity push', () {
      expect(
        notificationUsesRootEntityPush(
          const NotificationOpenHomeMapFocus(siteId: 's1'),
        ),
        isFalse,
      );
      expect(
        notificationUsesRootEntityPush(const NotificationOpenFeatureGuide()),
        isFalse,
      );
    });
  });

  group('NotificationNavigationExecutor stack contract', () {
    test('does not pop navigator before opening destinations', () {
      final File executor = File(
        'packages/feature_notifications/lib/src/data/notification_navigation_executor.dart',
      );
      expect(executor.existsSync(), isTrue);
      final String source = executor.readAsStringSync();
      expect(source.contains('Navigator.of(resolved).pop'), isFalse);
      expect(source.contains('Navigator.pop('), isFalse);
      expect(source.contains('.pop();'), isFalse);
    });
  });
}
