import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'shared/widget_test_bootstrap.dart';

import 'package:chisto_mobile/main.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('boot flow reaches onboarding and sign in', (WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ServiceLocator.instance.providerContainer,
        child: const ChistoApp(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
