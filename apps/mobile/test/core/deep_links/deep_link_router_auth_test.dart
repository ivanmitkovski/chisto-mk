import 'package:chisto_mobile/core/deep_links/deep_link_router.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkRouter', () {
    setUp(DeepLinkRouter.resetDedupeForTest);

    testWidgets('routes unauthenticated event-detail to sign-in', (
      WidgetTester tester,
    ) async {
      final List<String> pushed = <String>[];
      await tester.pumpWidget(_App(observer: _RouteCapture(pushed)));
      final NavigatorState nav = tester.state(find.byType(Navigator));
      final bool handled = DeepLinkRouter.handleUri(
        nav,
        Uri.parse('https://chisto.mk/app/events/detail/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
        isAuthenticated: false,
      );
      expect(handled, isTrue);
      expect(pushed, contains(AppRoutes.signIn));
    });

    testWidgets('routes unauthenticated new-report to sign-in', (
      WidgetTester tester,
    ) async {
      final List<String> pushed = <String>[];
      await tester.pumpWidget(_App(observer: _RouteCapture(pushed)));
      final NavigatorState nav = tester.state(find.byType(Navigator));
      DeepLinkRouter.handleUri(
        nav,
        Uri.parse('chisto://app/reports/new'),
        isAuthenticated: false,
      );
      expect(pushed, contains(AppRoutes.signIn));
    });

    testWidgets('deduplicates identical URIs within the dedupe window', (
      WidgetTester tester,
    ) async {
      final List<String> pushed = <String>[];
      await tester.pumpWidget(_App(observer: _RouteCapture(pushed)));
      final NavigatorState nav = tester.state(find.byType(Navigator));
      final Uri uri = Uri.parse('chisto://app/reports/new');
      DeepLinkRouter.handleUri(nav, uri, isAuthenticated: true);
      DeepLinkRouter.handleUri(nav, uri, isAuthenticated: true);
      DeepLinkRouter.handleUri(nav, uri, isAuthenticated: true);
      final int hits = pushed.where((String r) => r == AppRoutes.newReport).length;
      expect(hits, 1);
    });
  });
}

class _App extends StatelessWidget {
  const _App({required this.observer});
  final NavigatorObserver observer;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: <NavigatorObserver>[observer],
      home: const Scaffold(body: SizedBox.shrink()),
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute<dynamic>(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(child: Text('route:${settings.name}')),
          ),
        );
      },
    );
  }
}

class _RouteCapture extends NavigatorObserver {
  _RouteCapture(this.pushed);
  final List<String> pushed;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String? name = route.settings.name;
    if (name != null) pushed.add(name);
    super.didPush(route, previousRoute);
  }
}
