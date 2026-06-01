import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_status_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/home/support/test_pollution_site.dart';

void main() {
  testWidgets('SiteHistoryStatusHeader shows status pill, stats, and meta', (
    WidgetTester tester,
  ) async {
    final DateTime recent = DateTime(2026, 5, 20, 14);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SiteHistoryStatusHeader(
            site: buildTestPollutionSite(
              id: 's1',
              statusCode: 'VERIFIED',
              statusLabel: 'Verified',
            ),
            summary: SiteHistorySummary(
              totalEntries: 5,
              reportCount: 2,
              cleanupCount: 1,
              currentStatus: 'VERIFIED',
              firstActivityAt: DateTime(2026, 1, 10),
              lastActivityAt: recent,
            ),
            entryCount: 3,
            mostRecentEntryAt: recent,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current status'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('2 reports'), findsOneWidget);
    expect(find.text('1 cleanup'), findsOneWidget);
    expect(find.text('5 entries'), findsOneWidget);
    expect(find.textContaining('Active since'), findsOneWidget);
    expect(find.textContaining('Updated'), findsOneWidget);
  });

  testWidgets('SiteHistoryStatusHeader falls back when summary is null', (
    WidgetTester tester,
  ) async {
    final DateTime recent = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SiteHistoryStatusHeader(
            site: buildTestPollutionSite(
              id: 's1',
              statusCode: 'VERIFIED',
              statusLabel: 'Verified',
            ),
            entryCount: 3,
            mostRecentEntryAt: recent,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 reports'), findsOneWidget);
    expect(find.text('0 cleanups'), findsOneWidget);
    expect(find.text('3 entries'), findsOneWidget);
    expect(find.textContaining('Updated'), findsOneWidget);
  });
}
