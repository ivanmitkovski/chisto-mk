import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/events/presentation/screens/event_impact_receipt_screen.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ServiceLocator.instance.reset();
    await ServiceLocator.instance.initialize();
  });

  tearDown(() {
    ServiceLocator.instance.reset();
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
