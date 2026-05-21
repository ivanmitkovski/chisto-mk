import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/site_history_entry.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_empty_state.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_grouped_panel.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_list_tile.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_skeleton.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_status_header.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../features/home/support/test_pollution_site.dart';
import '../../../shared/widget_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  Future<void> pumpGolden(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 520),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            devicePixelRatio: 1.0,
            textScaler: TextScaler.noScaling,
            disableAnimations: true,
          ),
          child: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('SiteHistoryEmptyState golden', (WidgetTester tester) async {
    await pumpGolden(
      tester,
      const SiteHistoryEmptyState(),
      size: const Size(390, 360),
    );
    await expectLater(
      find.byType(SiteHistoryEmptyState),
      matchesGoldenFile('__goldens__/site_history_empty_en.png'),
    );
  });

  testWidgets('SiteHistory loaded preview golden', (WidgetTester tester) async {
    final DateTime now = DateTime(2026, 5, 20, 14);
    await pumpGolden(
      tester,
      ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          SiteHistoryStatusHeader(
            site: buildTestPollutionSite(
              id: 'golden',
              statusCode: 'VERIFIED',
            ),
            entryCount: 2,
            mostRecentEntryAt: now,
          ),
          const SizedBox(height: AppSpacing.lg),
          SiteHistoryGroupedPanel(
            child: Column(
              children: <Widget>[
                SiteHistoryListTile(
                  entry: SiteHistoryEntry(
                    id: 'g1',
                    kind: SiteHistoryEntryKind.siteCreated,
                    occurredAt: now.subtract(const Duration(days: 2)),
                  ),
                  showDividerBelow: true,
                ),
                SiteHistoryListTile(
                  entry: SiteHistoryEntry(
                    id: 'g2',
                    kind: SiteHistoryEntryKind.cleanupEventScheduled,
                    occurredAt: now.subtract(const Duration(days: 2)),
                    cleanupEventId: 'evt-1',
                  ),
                  showDividerBelow: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    await expectLater(
      find.byType(ListView),
      matchesGoldenFile('__goldens__/site_history_loaded_en.png'),
    );
  });

  testWidgets('SiteHistorySkeleton golden', (WidgetTester tester) async {
    await pumpGolden(tester, const SiteHistorySkeleton());
    await expectLater(
      find.byType(SiteHistorySkeleton),
      matchesGoldenFile('__goldens__/site_history_skeleton_en.png'),
    );
  });
}
