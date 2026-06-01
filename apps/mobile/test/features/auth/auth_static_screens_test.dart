import 'package:feature_auth/src/application/initial_route_controller.dart';
import 'package:feature_auth/src/application/splash_session_controller.dart';
import 'package:feature_auth/src/presentation/constants/splash_constants.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_email_sent_screen.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_new_screen.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_success_screen.dart';
import 'package:feature_auth/src/presentation/screens/initial_route_screen.dart';
import 'package:feature_auth/src/presentation/screens/location_screen.dart';
import 'package:feature_auth/src/presentation/screens/onboarding_screen.dart';
import 'package:feature_auth/src/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/pump_auth_app.dart';
import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('splash shows logo animation host', (WidgetTester tester) async {
    SplashSessionController.pauseAfterRestore = true;
    SplashScreen.disableTimersForTests = true;
    addTearDown(() {
      SplashSessionController.pauseAfterRestore = false;
      SplashScreen.disableTimersForTests = false;
    });
    await pumpAuthWidget(tester, home: const SplashScreen());
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('initial route shows loading indicator', (
    WidgetTester tester,
  ) async {
    InitialRouteController.pauseNavigation = true;
    addTearDown(() => InitialRouteController.pauseNavigation = false);
    await pumpAuthWidget(tester, home: const InitialRouteScreen());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(SplashConstants.initialRouteMinDisplayTime);
    await tester.pump(SplashConstants.initialRouteSessionTimeout);
    await tester.pump();
  });

  testWidgets('onboarding shows continue CTA', (WidgetTester tester) async {
    await pumpAuthWidget(tester, home: const OnboardingScreen());
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('forgot password email sent screen renders', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(tester, home: const ForgotPasswordEmailSentScreen());
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordEmailSentScreen), findsOneWidget);
  });

  testWidgets('forgot password success screen renders', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(tester, home: const ForgotPasswordSuccessScreen());
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordSuccessScreen), findsOneWidget);
  });

  testWidgets('forgot password new password form renders', (
    WidgetTester tester,
  ) async {
    await pumpAuthWidget(
      tester,
      home: const ForgotPasswordNewScreen(
        phoneNumberE164: '+38970123456',
        code: '123456',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('New password'), findsOneWidget);
  });

  testWidgets('location screen shows confirm CTA', (WidgetTester tester) async {
    await pumpAuthWidget(tester, home: const LocationScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 950));
    expect(find.byType(LocationScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });
}
