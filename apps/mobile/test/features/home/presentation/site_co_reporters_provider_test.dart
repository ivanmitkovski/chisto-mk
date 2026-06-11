import 'package:feature_home/src/domain/repositories/sites_repository.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:feature_home/src/presentation/providers/site_co_reporters_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CoReportersFakeRepo implements SitesRepository {
  int pageCalls = 0;

  @override
  Future<SiteCoReportersResult> getSiteCoReporters(
    String id, {
    int page = 1,
    int limit = 50,
  }) async {
    pageCalls += 1;
    if (page == 1) {
      return SiteCoReportersResult(
        items: <SiteCoReporterItem>[
          SiteCoReporterItem(
            id: 'row-1',
            firstName: 'Ana',
            lastName: 'One',
            displayName: 'Ana One',
            reportedAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
            isOriginalReporter: true,
          ),
        ],
        page: 1,
        limit: limit,
        total: 2,
        hasMore: true,
      );
    }
    return SiteCoReportersResult(
      items: <SiteCoReporterItem>[
        SiteCoReporterItem(
          id: 'row-1',
          firstName: 'Ana',
          lastName: 'One',
          displayName: 'Ana One',
          reportedAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
          isOriginalReporter: true,
        ),
        SiteCoReporterItem(
          id: 'row-2',
          firstName: 'Ben',
          lastName: 'Two',
          displayName: 'Ben Two',
          reportedAt: DateTime.parse('2026-02-01T00:00:00.000Z'),
          isOriginalReporter: false,
        ),
      ],
      page: 2,
      limit: limit,
      total: 2,
      hasMore: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('siteCoReportersNotifierProvider loads and dedupes by id', () async {
    final _CoReportersFakeRepo repo = _CoReportersFakeRepo();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sitesRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(siteCoReportersNotifierProvider('site-1').notifier)
        .loadInitial();
    await container
        .read(siteCoReportersNotifierProvider('site-1').notifier)
        .loadMore();

    final SiteCoReportersState state = container.read(
      siteCoReportersNotifierProvider('site-1'),
    );
    expect(state.items, hasLength(2));
    expect(state.items.map((SiteCoReporterItem i) => i.id), <String>['row-1', 'row-2']);
    expect(state.hasMore, isFalse);
    expect(repo.pageCalls, greaterThanOrEqualTo(2));
  });
}
