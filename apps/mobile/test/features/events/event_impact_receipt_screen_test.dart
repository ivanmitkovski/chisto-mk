import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/events/presentation/screens/event_impact_receipt_screen.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_back_button.dart';
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
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const EventImpactReceiptScreen(eventId: 'evt-test-impact'),
      ),
    );
    await tester.pump();

    final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, AppColors.appBackground);
    expect(appBar.surfaceTintColor, AppColors.transparent);
    expect(find.byType(AppBackButton), findsOneWidget);
  });
}
