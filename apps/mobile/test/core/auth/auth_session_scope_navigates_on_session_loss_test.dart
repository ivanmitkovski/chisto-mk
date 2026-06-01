import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:feature_auth/src/presentation/screens/sign_in_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() {
    AppBootstrap.instance.suppressSessionExpiredMessage = false;
    AppBootstrap.instance.authState.setUnauthenticated();
  });

  testWidgets(
    'onAuthUnauthorized navigates to sign-in when session already cleared on app content',
    (WidgetTester tester) async {
      AppBootstrap.instance.authState.setAuthenticated(
        userId: 'u-nav-test',
        displayName: 'Tester',
      );

      await pumpAuthSessionScopeRouter(tester, initialLocation: '/feed');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SignInScreen), findsNothing);

      AppBootstrap.instance.authState.setUnauthenticated();
      AppBootstrap.instance.onAuthUnauthorized?.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SignInScreen), findsOneWidget);
    },
  );
}
