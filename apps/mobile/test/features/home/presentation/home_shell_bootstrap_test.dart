import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_home/src/presentation/screens/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';
import '../../auth/support/fake_auth_repository.dart';

void main() {
  setUp(() async {
    await bootstrapWidgetTests();
    AppBootstrap.instance.authState.setAuthenticated(
      userId: 'user-1',
      displayName: 'Test User',
    );
    AppBootstrap.instance.overrideAuthRepositoryForTests(
      FakeAuthRepository()..requiresTermsAcceptance = false,
    );
    AppBootstrap.instance.providerContainer.invalidate(authRepositoryProvider);
  });

  tearDown(() {
    AppBootstrap.instance.authState.setUnauthenticated();
  });

  testWidgets('renders child without explore banner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapForWidgetTest(HomeShellBootstrap(child: const Text('child'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('child'), findsOneWidget);
    expect(find.text("You're exploring from outside Macedonia"), findsNothing);
    expect(find.text('Use current location'), findsNothing);
  });
}
