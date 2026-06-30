import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_back_button.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/presentation/screens/event_impact_receipt_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('uses neutral AppBar and AppBackButton while loading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: EventImpactReceiptScreen(eventId: 'evt-test-impact'),
      ),
    );
    await tester.pump();

    final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, AppColors.appBackground);
    expect(appBar.surfaceTintColor, AppColors.transparent);
    expect(find.byType(AppBackButton), findsOneWidget);
  });
}
