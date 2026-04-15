import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_capacity_summary_card.dart';
import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('healthy profile credits: number pill only, no capacity banner', (
    WidgetTester tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (BuildContext context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: ReportCapacitySummaryCard(
                capacity: ReportCapacity(
                  creditsAvailable: 10,
                  emergencyAvailable: true,
                  emergencyWindowDays: 7,
                  retryAfterSeconds: null,
                  nextEmergencyReportAvailableAt: null,
                  unlockHint: 'hint',
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(find.text(l10n.profileReportCreditsTitle), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text(l10n.reportCapacityBannerHealthyBody(10)), findsNothing);
  });

  testWidgets('shows report credits card cooldown details', (
    WidgetTester tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (BuildContext context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: ReportCapacitySummaryCard(
                capacity: ReportCapacity(
                  creditsAvailable: 0,
                  emergencyAvailable: false,
                  emergencyWindowDays: 7,
                  retryAfterSeconds: 120,
                  nextEmergencyReportAvailableAt: null,
                  unlockHint: 'Join eco actions to unlock new credits.',
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(find.text(l10n.profileReportCreditsTitle), findsOneWidget);
    expect(find.text(l10n.reportCapacityPillCooldown), findsOneWidget);
    expect(find.textContaining('120s remaining'), findsOneWidget);
  });
}
