import 'package:chisto_mobile/features/profile/presentation/widgets/profile_screen_skeleton.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/testing/widget_test_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('ProfileScreenSkeleton exposes loading semantics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(
          body: ProfileScreenSkeleton(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ProfileScreenSkeleton), findsOneWidget);
    expect(find.bySemanticsLabel('Loading profile'), findsOneWidget);
  });
}
