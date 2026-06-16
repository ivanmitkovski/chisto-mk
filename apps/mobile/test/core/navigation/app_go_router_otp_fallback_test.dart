import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/navigation/app_go_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:feature_auth/src/presentation/screens/otp_screen.dart';
import 'package:feature_auth/src/presentation/screens/sign_in_screen.dart';
import 'package:feature_auth/src/presentation/screens/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../shared/pump_auth_app.dart';
import '../../shared/widget_test_bootstrap.dart';

Future<void> _pumpLegacyOtpRoute(
  WidgetTester tester, {
  Object? arguments,
}) async {
  final MaterialPageRoute<void> route =
      AppRouter.onGenerateRoute(
            RouteSettings(name: AppRoutes.otp, arguments: arguments),
          )!
          as MaterialPageRoute<void>;
  await pumpAuthWidget(tester, home: Builder(builder: route.builder));
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() {
    AppBootstrap.instance.authState.setUnauthenticated();
  });

  testWidgets('GoRouter otp route with missing extra falls back to sign in', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpAppRouter(
      tester,
      initialLocation: AppRoutes.signIn,
    );

    router.go(AppRoutes.otp);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.otp);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(SignUpScreen), findsNothing);
    expect(find.byType(OtpScreen), findsNothing);
  });

  testWidgets('GoRouter otp route with invalid extra falls back to sign in', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpAppRouter(
      tester,
      initialLocation: AppRoutes.signIn,
    );

    router.go(AppRoutes.otp, extra: 42);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.otp);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(SignUpScreen), findsNothing);
    expect(find.byType(OtpScreen), findsNothing);
  });

  testWidgets(
    'legacy AppRouter otp route with missing args falls back to sign in',
    (WidgetTester tester) async {
      await _pumpLegacyOtpRoute(tester);
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(SignUpScreen), findsNothing);
      expect(find.byType(OtpScreen), findsNothing);
    },
  );

  testWidgets(
    'legacy AppRouter otp route with invalid args falls back to sign in',
    (WidgetTester tester) async {
      await _pumpLegacyOtpRoute(tester, arguments: 42);
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(SignUpScreen), findsNothing);
      expect(find.byType(OtpScreen), findsNothing);
    },
  );
}
