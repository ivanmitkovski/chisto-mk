import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_status_header.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/home/support/test_pollution_site.dart';

void main() {
  testWidgets('SiteHistoryStatusHeader shows status, updated, entry count', (
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

    expect(find.text('Current status'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.textContaining('Updated'), findsOneWidget);
    expect(find.text('3 entries'), findsOneWidget);
  });
}
