import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:feature_auth/src/presentation/screens/sign_in_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  setUp(() {
    AppBootstrap.instance.authState.setUnauthenticated();
  });

  testWidgets('redirects unauthenticated user on protected route to sign-in', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpAppRouter(
      tester,
      initialLocation: '/events',
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.signIn);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('allows unauthenticated user on sign-in route', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpAppRouter(
      tester,
      initialLocation: AppRoutes.signIn,
    );

    await tester.pump();

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.signIn);
    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
