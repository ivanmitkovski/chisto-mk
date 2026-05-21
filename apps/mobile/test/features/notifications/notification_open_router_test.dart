import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/providers/home_providers.dart';
import 'package:chisto_mobile/core/providers/root_container.dart';
import 'package:chisto_mobile/features/events/data/events_repository_registry.dart';
import 'package:chisto_mobile/features/notifications/data/notification_open_router.dart';
import 'package:chisto_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/events/in_memory_events_store.dart';

/// Seeded in [buildMockEcoEventsSeed] (valid UUID shape for payload guards).
const String _eventId = '550e8400-e29b-41d4-a716-446655440000';

class _FakeNotificationsRepository implements NotificationsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _RouteRecordingObserver extends NavigatorObserver {
  final List<String?> routes = <String?>[];

  void _record(Route<dynamic>? route) {
    routes.add(route?.settings.name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _record(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _record(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

Widget _host({
  required _RouteRecordingObserver observer,
  required void Function(BuildContext context) onReady,
}) {
  return MaterialApp(
    navigatorObservers: <NavigatorObserver>[observer],
    routes: <String, WidgetBuilder>{
      AppRoutes.home: (_) => const SizedBox(key: Key('home')),
      AppRoutes.homeEvents: (_) => const SizedBox(key: Key('home_events')),
      AppRoutes.homeMapFocus: (_) => const SizedBox(key: Key('map_focus')),
      AppRoutes.eventsDetail: (_) => const SizedBox(key: Key('event_detail')),
      AppRoutes.eventChat: (_) => const SizedBox(key: Key('event_chat')),
    },
    home: Builder(
      builder: (BuildContext context) {
        onReady(context);
        return const SizedBox(key: Key('host'));
      },
    ),
  );
}

void main() {
  late InMemoryEventsStore eventsStore;

  setUpAll(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  setUp(() {
    eventsStore = InMemoryEventsStore.instance;
    EventsRepositoryRegistry.setTestOverride(eventsStore);
    eventsStore.resetToSeed();
    eventsStore.loadInitialIfNeeded();
    eventsStore.seedAliasEventId(_eventId);
    setRootProviderContainer(
      ProviderContainer(
        overrides: <Override>[
          notificationsRepositoryProvider.overrideWithValue(_FakeNotificationsRepository()),
        ],
      ),
    );
  });

  tearDown(() {
    EventsRepositoryRegistry.setTestOverride(null);
  });

  testWidgets('siteId opens map focus', (WidgetTester tester) async {
    final _RouteRecordingObserver observer = _RouteRecordingObserver();
    await tester.pumpWidget(
      _host(
        observer: observer,
        onReady: (BuildContext context) {
          NotificationOpenRouter.handleOpenFromData(
            context,
            <String, dynamic>{'siteId': 'site-abc'},
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(observer.routes, contains(AppRoutes.homeMapFocus));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('REPORT_STATUS opens home tab', (WidgetTester tester) async {
    final _RouteRecordingObserver observer = _RouteRecordingObserver();
    await tester.pumpWidget(
      _host(
        observer: observer,
        onReady: (BuildContext context) {
          NotificationOpenRouter.handleOpenFromData(
            context,
            <String, dynamic>{'type': 'REPORT_STATUS'},
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(observer.routes, contains(AppRoutes.home));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('CLEANUP_EVENT with valid eventId opens detail', (WidgetTester tester) async {
    final _RouteRecordingObserver observer = _RouteRecordingObserver();
    await tester.pumpWidget(
      _host(
        observer: observer,
        onReady: (BuildContext context) {
          NotificationOpenRouter.handleOpenFromData(
            context,
            <String, dynamic>{
              'type': 'CLEANUP_EVENT',
              'eventId': _eventId,
            },
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(observer.routes, contains(AppRoutes.eventsDetail));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('EVENT_CHAT with valid eventId opens chat', (WidgetTester tester) async {
    final _RouteRecordingObserver observer = _RouteRecordingObserver();
    await tester.pumpWidget(
      _host(
        observer: observer,
        onReady: (BuildContext context) {
          NotificationOpenRouter.handleOpenFromData(
            context,
            <String, dynamic>{
              'type': 'EVENT_CHAT',
              'eventId': _eventId,
              'threadTitle': 'Park cleanup',
            },
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(observer.routes, contains(AppRoutes.eventChat));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('unknown type opens home default', (WidgetTester tester) async {
    final _RouteRecordingObserver observer = _RouteRecordingObserver();
    await tester.pumpWidget(
      _host(
        observer: observer,
        onReady: (BuildContext context) {
          NotificationOpenRouter.handleOpenFromData(
            context,
            <String, dynamic>{'type': 'ACHIEVEMENT'},
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(observer.routes, contains(AppRoutes.home));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
