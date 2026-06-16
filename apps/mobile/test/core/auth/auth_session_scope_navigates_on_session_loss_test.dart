import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('AuthSessionScope registers onAuthUnauthorized callback', (
    WidgetTester tester,
  ) async {
    await pumpAuthSessionScopeRouter(tester, initialLocation: AppRoutes.signIn);
    expect(AppBootstrap.instance.onAuthUnauthorized, isNotNull);
  });
}
