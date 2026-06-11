import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/primary_button.dart';
import 'package:feature_profile/src/presentation/screens/profile_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('ProfilePasswordScreen shows fields and visibility semantics', (
    WidgetTester tester,
  ) async {
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

  // Regression: the "Update password" CTA must be a short bottom bar, not a
  // full-screen green pill hiding the form (shared PrimaryButton fill bug).
  testWidgets('Update password CTA does not fill the screen on iPhone size', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1320, 2868); // iPhone 16 Pro Max px
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(440, 956),
            devicePixelRatio: 3.0,
            padding: EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: EdgeInsets.only(top: 59, bottom: 34),
            textScaler: TextScaler.linear(1.3),
          ),
          child: ProfilePasswordScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current password'), findsOneWidget);

    final Size screen = tester.getSize(find.byType(ProfilePasswordScreen));
    final Size cta = tester.getSize(
      find.widgetWithText(PrimaryButton, 'Update password'),
    );
    expect(
      cta.height < screen.height / 3,
      isTrue,
      reason: 'Update password CTA should be a bottom bar, not fill the screen '
          '(cta=${cta.height}, screen=${screen.height})',
    );
  });
}
