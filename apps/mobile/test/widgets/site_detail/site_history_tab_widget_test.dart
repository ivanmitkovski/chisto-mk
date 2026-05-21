import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/features/home/data/site_history_repository.dart';
import 'package:chisto_mobile/features/home/domain/models/site_history_entry.dart';
import 'package:chisto_mobile/features/home/presentation/providers/site_history_providers.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_empty_state.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/site_detail/history/site_history_tab.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/home/support/test_pollution_site.dart';
import '../../shared/widget_test_bootstrap.dart';

class _FakeApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSiteHistoryRepository extends SiteHistoryRepository {
  _FakeSiteHistoryRepository(this._page) : super(_FakeApiClient());

  final SiteHistoryPage _page;

  @override
  Future<SiteHistoryPage> fetchHistory(
    String siteId, {
    int limit = 30,
    String? beforeId,
  }) async {
    return _page;
  }
}

void main() {
  setUpAll(() async {
    await bootstrapWidgetTests();
  });

  testWidgets('SiteHistoryEmptyState shows title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SiteHistoryEmptyState()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No history yet'), findsOneWidget);
  });

  testWidgets('SiteHistoryTab shows header, sections, and end footer', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.now();
    final SiteHistoryPage page = SiteHistoryPage(
      items: <SiteHistoryEntry>[
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
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          siteHistoryRepositoryProvider.overrideWith(
            (Ref ref) => _FakeSiteHistoryRepository(page),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: SizedBox(
              height: 800,
              width: 400,
              child: SiteHistoryTab(
              site: buildTestPollutionSite(
                id: 'site-1',
                statusCode: 'VERIFIED',
              ),
            ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Current status'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Site created'), findsOneWidget);
    expect(find.text('End of history'), findsOneWidget);
  });
}
