import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
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
    'armSuppressSessionExpiredWindow suppresses snack on onAuthUnauthorized',
    (WidgetTester tester) async {
      AppBootstrap.instance.armSuppressSessionExpiredWindow();

      await pumpAuthSessionScopeRouter(
        tester,
        initialLocation: AppRoutes.signIn,
      );
      await tester.pump();

      AppBootstrap.instance.onAuthUnauthorized?.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('Your session expired. Please sign in again.'),
        findsNothing,
      );
    },
  );
}
