import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_empty_state.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_footer.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_sections.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_status_header.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_timeline_rows.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_timeline_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/home/support/test_pollution_site.dart';
import '../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('SiteHistoryEmptyState shows title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SiteHistoryEmptyState()),
      ),
    );
    await tester.pump();
    expect(find.text('No history yet'), findsOneWidget);
  });

  testWidgets(
    'SiteHistory loaded layout shows header, timeline sections, and end footer',
    (WidgetTester tester) async {
      final DateTime now = DateTime(2026, 5, 20, 14);
      final List<SiteHistoryEntry> items = <SiteHistoryEntry>[
        SiteHistoryEntry(
          id: '1',
          kind: SiteHistoryEntryKind.siteCreated,
          occurredAt: now,
        ),
        SiteHistoryEntry(
          id: '2',
          kind: SiteHistoryEntryKind.reportSubmitted,
          occurredAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (BuildContext context) {
              final List<SiteHistoryTimelineRow> rows =
                  buildSiteHistoryTimelineRows(
                    items: items,
                    now: now,
                    sectionLabelFor: (SiteHistorySection section) =>
                        siteHistorySectionLabel(context, section),
                  );
              return Scaffold(
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    SiteHistoryStatusHeader(
                      site: buildTestPollutionSite(
                        id: 'site-1',
                        statusCode: 'VERIFIED',
                      ),
                      entryCount: items.length,
                      mostRecentEntryAt: now,
                    ),
                    for (final SiteHistoryTimelineRow row in rows)
                      switch (row.kind) {
                        SiteHistoryTimelineRowKind.sectionHeader =>
                          SiteHistoryTimelineSectionHeader(
                            label: row.label!,
                            showLineAbove: row.showLineAbove,
                            showLineBelow: row.showLineBelow,
                          ),
                        SiteHistoryTimelineRowKind.entry =>
                          SiteHistoryTimelineTile(
                            entry: row.entry!,
                            showLineAbove: row.showLineAbove,
                            showLineBelow: row.showLineBelow,
                          ),
                      },
                    const SiteHistoryFooter(
                      mode: SiteHistoryFooterMode.endOfList,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Current status'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Site created'), findsOneWidget);
      expect(find.text('End of history'), findsOneWidget);
      expect(find.byType(SiteHistoryTimelineTile), findsNWidgets(2));
    },
  );
}
