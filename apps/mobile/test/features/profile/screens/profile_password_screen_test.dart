import 'package:chisto_mobile/features/profile/presentation/screens/profile_password_screen.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('ProfilePasswordScreen shows fields and visibility semantics',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: ProfilePasswordScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current password'), findsOneWidget);
    expect(find.text('New password'), findsOneWidget);
    expect(find.text('Confirm new password'), findsOneWidget);

    expect(find.bySemanticsLabel('Show or hide password'), findsNWidgets(3));
  });
}
