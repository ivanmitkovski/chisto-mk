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

  testWidgets('NotificationTile golden unread comment', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 140));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final UserNotification item = UserNotification(
      id: 'n-golden',
      title: 'New comment on your report',
      body: 'Someone replied on the site you follow.',
      createdAt: DateTime(2026, 5, 19, 10, 30),
      type: UserNotificationType.comment,
      isRead: false,
      data: <String, dynamic>{'siteId': 'site-1'},
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 140),
            devicePixelRatio: 1,
            textScaler: TextScaler.linear(1),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: NotificationTile(item: item, onTap: _noop),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(NotificationTile),
      matchesGoldenFile('__goldens__/notification_tile_unread_en.png'),
    );
  });
}

void _noop() {}
