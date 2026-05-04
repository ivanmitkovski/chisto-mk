import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/report_capacity_ui_state.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reports capacity visibility widgets show mapped copy', (
    WidgetTester tester,
  ) async {
    final AppLocalizationsEn l10n = AppLocalizationsEn();
    final ui = mapReportCapacityToUiState(
      const ReportCapacity(
        creditsAvailable: 0,
        emergencyAvailable: true,
        emergencyWindowDays: 7,
        retryAfterSeconds: null,
        nextEmergencyReportAvailableAt: null,
        unlockHint: 'Join eco actions to unlock new credits.',
      ),
      l10n: l10n,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              ReportStatePill(
                label: ui.pillLabel,
                icon: ui.pillIcon,
                tone: ui.pillTone,
              ),
              ReportInfoBanner(
                title: ui.bannerTitle,
                message: ui.bannerMessage,
                icon: ui.bannerIcon,
                tone: ui.bannerTone,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text(l10n.reportCapacityPillEmergency), findsNWidgets(2));
    expect(find.textContaining('up to 10'), findsOneWidget);
  });

  test('new report review message uses shared mapper', () {
    final AppLocalizationsEn l10n = AppLocalizationsEn();
    final ui = mapReportCapacityToUiState(
      const ReportCapacity(
        creditsAvailable: 2,
        emergencyAvailable: true,
        emergencyWindowDays: 7,
        retryAfterSeconds: null,
        nextEmergencyReportAvailableAt: null,
        unlockHint: 'Join eco actions to unlock new credits.',
      ),
      l10n: l10n,
    );

    expect(ui.reviewMessage, contains('1 credit'));
  });
}
