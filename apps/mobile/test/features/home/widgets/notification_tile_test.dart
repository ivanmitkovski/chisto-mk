import 'package:chisto_mobile/features/home/domain/models/feed_notification.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/notifications/notification_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders unread notification with affordances', (
    WidgetTester tester,
  ) async {
    final FeedNotification item = FeedNotification(
      id: 'n1',
      title: 'New site update',
      message: 'Someone commented on a site you follow.',
      createdAt: DateTime(2026, 3, 27, 10, 0),
      type: FeedNotificationType.action,
      isRead: false,
      targetSiteId: 'site-1',
      targetTabIndex: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationTile(item: item, onTap: () {}),
        ),
      ),
    );

    expect(find.text('New site update'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    expect(find.text('Action'), findsOneWidget);
    expect(find.text('Opens pollution site'), findsOneWidget);
  });
}
