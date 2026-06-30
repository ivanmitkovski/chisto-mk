import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/site_history_entry.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_empty_state.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_skeleton.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_status_header.dart';
import 'package:feature_home/src/presentation/widgets/site_detail/history/site_history_timeline_tile.dart';
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
            devicePixelRatio: 1,
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
            site: buildTestPollutionSite(id: 'golden', statusCode: 'VERIFIED'),
            summary: SiteHistorySummary(
              totalEntries: 2,
              reportCount: 1,
              cleanupCount: 1,
              currentStatus: 'VERIFIED',
              firstActivityAt: now.subtract(const Duration(days: 30)),
              lastActivityAt: now,
            ),
            entryCount: 2,
            mostRecentEntryAt: now,
          ),
          const SizedBox(height: AppSpacing.lg),
          SiteHistoryTimelineTile(
            entry: SiteHistoryEntry(
              id: 'g1',
              kind: SiteHistoryEntryKind.siteCreated,
              occurredAt: now.subtract(const Duration(days: 2)),
            ),
            showLineAbove: false,
            showLineBelow: true,
          ),
          SiteHistoryTimelineTile(
            entry: SiteHistoryEntry(
              id: 'g2',
              kind: SiteHistoryEntryKind.cleanupEventScheduled,
              occurredAt: now.subtract(const Duration(days: 2)),
              cleanupEventId: 'evt-1',
            ),
            showLineAbove: true,
            showLineBelow: false,
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
    await pumpGolden(
      tester,
      const SizedBox(height: 520, child: SiteHistorySkeleton()),
      size: const Size(390, 520),
    );
    await expectLater(
      find.byType(SiteHistorySkeleton),
      matchesGoldenFile('__goldens__/site_history_skeleton_en.png'),
    );
  });
}
