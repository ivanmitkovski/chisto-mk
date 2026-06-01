import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:feature_profile/src/presentation/screens/profile_screen.dart';
import 'package:feature_profile/src/presentation/widgets/profile_screen_skeleton.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  tearDown(() {
    AppBootstrap.instance.authState.setUnauthenticated();
  });

  testWidgets('ProfileScreen mounts under app provider scope', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrapForWidgetTest(const ProfileScreen()));
    await tester.pump();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('unauthenticated profile shows sign-in CTA not skeleton', (
    WidgetTester tester,
  ) async {
    AppBootstrap.instance.authState.setUnauthenticated();

    await tester.pumpWidget(wrapForWidgetTest(const ProfileScreen()));
    await tester.pump();
    await tester.pump();

    expect(find.byType(ProfileScreenSkeleton), findsNothing);
    expect(find.text('Sign in to view your profile'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
