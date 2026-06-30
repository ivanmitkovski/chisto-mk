import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/navigation/unknown_route_screen.dart';
import 'package:feature_auth/src/presentation/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('unknown route builds UnknownRouteScreen not SignInScreen', (
    WidgetTester tester,
  ) async {
    await pumpAppRouter(tester, initialLocation: '/route-that-does-not-exist');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(UnknownRouteScreen), findsOneWidget);
    expect(find.text('Page not found'), findsOneWidget);
  });

  testWidgets('sign-in route builds SignInScreen', (WidgetTester tester) async {
    await pumpAppRouter(
      tester,
      locale: const Locale('en'),
      initialLocation: AppRoutes.signIn,
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
