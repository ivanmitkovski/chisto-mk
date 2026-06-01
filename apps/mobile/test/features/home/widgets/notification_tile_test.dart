import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/presentation/widgets/notifications/notification_tile.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  Widget wrapTile(NotificationTile tile) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: tile),
    );
  }

  testWidgets('renders unread notification with type-specific visual', (
    WidgetTester tester,
  ) async {
    final UserNotification item = UserNotification(
      id: 'n1',
      title: 'New site update',
      body: 'Someone commented on a site you follow.',
      createdAt: DateTime(2026, 3, 27, 10, 0),
      type: UserNotificationType.comment,
      isRead: false,
      data: <String, dynamic>{'siteId': 'site-1', 'targetTab': '0'},
    );

    await tester.pumpWidget(
      wrapTile(NotificationTile(item: item, onTap: () {})),
    );

    expect(find.text('New site update'), findsOneWidget);
    expect(find.text('Comments'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
  });

  testWidgets('read notification has no unread dot', (
    WidgetTester tester,
  ) async {
    final UserNotification item = UserNotification(
      id: 'n2',
      title: 'Report approved',
      body: 'Your report has been approved.',
      createdAt: DateTime(2026, 3, 26, 8, 0),
      type: UserNotificationType.reportStatus,
      isRead: true,
    );

    await tester.pumpWidget(
      wrapTile(NotificationTile(item: item, onTap: () {})),
    );

    expect(find.text('Report status'), findsOneWidget);
    expect(find.byIcon(Icons.assignment_rounded), findsOneWidget);
  });

  testWidgets('renders all notification types without error', (
    WidgetTester tester,
  ) async {
    for (final UserNotificationType type in UserNotificationType.values) {
      final UserNotification item = UserNotification(
        id: 'n-${type.name}',
        title: 'Test ${type.name}',
        body: 'Body for ${type.name}',
        createdAt: DateTime(2026, 5, 11),
        type: type,
        isRead: false,
      );

      await tester.pumpWidget(
        wrapTile(NotificationTile(item: item, onTap: () {})),
      );

      expect(find.text('Test ${type.name}'), findsOneWidget);
    }
  });
}
