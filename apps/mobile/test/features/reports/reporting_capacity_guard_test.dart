import 'dart:async';

import 'package:chisto_mobile/features/reports/domain/models/report_capacity.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/new_report/reporting_capacity_guard.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows reporting cooldown dialog copy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    final BuildContext context = tester.element(find.byType(SizedBox));
    unawaited(
      showReportingCooldownDialog(
        context,
        const ReportCapacity(
          creditsAvailable: 0,
          emergencyAvailable: false,
          emergencyWindowDays: 7,
          retryAfterSeconds: 3600,
          nextEmergencyReportAvailableAt: null,
          unlockHint: 'Join and verify attendance, or create an eco action.',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Reporting cooldown'), findsOneWidget);
    expect(find.textContaining('used all 10 report credits'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
  });
}
