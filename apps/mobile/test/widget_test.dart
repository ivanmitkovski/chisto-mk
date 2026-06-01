import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:feature_auth/src/presentation/screens/onboarding_screen.dart';
import 'package:feature_auth/src/presentation/screens/sign_in_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('boot flow reaches onboarding and sign in', (
    WidgetTester tester,
  ) async {
    await pumpAppRouter(tester, initialLocation: AppRoutes.onboarding);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Get started'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
