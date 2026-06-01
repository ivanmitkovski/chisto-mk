import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/providers/events_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_events/src/presentation/screens/event_chat_screen.dart';
import 'package:feature_events/src/presentation/screens/event_detail_screen.dart';
import 'package:feature_notifications/src/application/notifications_providers.dart';
import 'package:feature_notifications/src/data/notification_open_router.dart';
import 'package:feature_notifications/src/domain/repositories/notifications_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widget_test_bootstrap.dart';
import '../../support/events/in_memory_events_store.dart';

/// Seeded in [buildMockEcoEventsSeed] (valid UUID shape for payload guards).
const String _eventId = '550e8400-e29b-41d4-a716-446655440000';

class _FakeNotificationsRepository implements NotificationsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

String _currentPath(GoRouter router) =>
    router.routeInformationProvider.value.uri.path;

void main() {
  late InMemoryEventsStore eventsStore;

  setUpAll(() async {
    await bootstrapWidgetTests();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  setUp(() {
    eventsStore = InMemoryEventsStore.instance;
    setEventsRepositoryTestOverride(eventsStore);
    eventsStore.resetToSeed();
    eventsStore.loadInitialIfNeeded();
    eventsStore.seedAliasEventId(_eventId);
    setRootProviderContainer(
      ProviderContainer(
        parent: AppBootstrap.instance.providerContainer,
        overrides: <Override>[
          notificationsRepositoryProvider.overrideWithValue(
            _FakeNotificationsRepository(),
          ),
        ],
      ),
    );
  });

  tearDown(() {
    setEventsRepositoryTestOverride(null);
  });

  Future<GoRouter> pumpHost(
    WidgetTester tester,
    void Function(BuildContext context) onReady,
  ) async {
    final GoRouter router = await pumpAppRouter(
      tester,
      initialLocation: '/feed',
    );
    final BuildContext context = tester.element(find.byType(MaterialApp));
    onReady(context);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    return router;
  }

  testWidgets('siteId opens map focus', (WidgetTester tester) async {
    final GoRouter router = await pumpHost(tester, (BuildContext context) {
      NotificationOpenRouter.handleOpenFromData(context, <String, dynamic>{
        'siteId': 'site-abc',
      });
    });
    await tester.pump();
    expect(_currentPath(router), '/map');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('REPORT_STATUS with siteId opens map focus', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpHost(tester, (BuildContext context) {
      NotificationOpenRouter.handleOpenFromData(context, <String, dynamic>{
        'type': 'REPORT_STATUS',
        'siteId': 'site-abc',
      });
    });
    await tester.pump();
    expect(_currentPath(router), '/map');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('REPORT_STATUS without siteId opens home tab', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpHost(tester, (BuildContext context) {
      NotificationOpenRouter.handleOpenFromData(context, <String, dynamic>{
        'type': 'REPORT_STATUS',
      });
    });
    await tester.pump();
    expect(_currentPath(router), '/feed');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('CLEANUP_EVENT with valid eventId opens detail', (
    WidgetTester tester,
  ) async {
    await pumpHost(tester, (BuildContext context) {
      NotificationOpenRouter.handleOpenFromData(context, <String, dynamic>{
        'type': 'CLEANUP_EVENT',
        'eventId': _eventId,
      });
    });
    expect(find.byType(EventDetailScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('EVENT_CHAT with valid eventId opens chat', (
    WidgetTester tester,
  ) async {
    await pumpHost(tester, (BuildContext context) {
      NotificationOpenRouter.handleOpenFromData(context, <String, dynamic>{
        'type': 'EVENT_CHAT',
        'eventId': _eventId,
        'threadTitle': 'Park cleanup',
      });
    });
    expect(find.byType(EventChatScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('unknown type opens home default', (WidgetTester tester) async {
    final GoRouter router = await pumpHost(tester, (BuildContext context) {
      NotificationOpenRouter.handleOpenFromData(context, <String, dynamic>{
        'type': 'ACHIEVEMENT',
      });
    });
    await tester.pump();
    expect(_currentPath(router), '/feed');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
