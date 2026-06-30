import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/repositories/sites_repository.dart';
import 'package:feature_home/src/presentation/providers/map_derived_providers.dart';
import 'package:feature_home/src/presentation/providers/map_search_controller.dart';
import 'package:feature_home/src/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/stub_sites_repository.dart';
import '../support/test_pollution_site.dart';

ProviderContainer _searchContainer({
  required SitesRepository repository,
  List<PollutionSite> localPool = const <PollutionSite>[],
}) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      sitesRepositoryProvider.overrideWithValue(repository),
      mapSearchLocalPoolProvider.overrideWith((Ref ref) => localPool),
    ],
  );
  final ProviderSubscription<MapSearchState> subscription = container.listen(
    mapSearchControllerProvider,
    (_, __) {},
  );
  addTearDown(() {
    subscription.close();
    container.dispose();
  });
  return container;
}

void main() {
  test('ranks prefix match before contains match', () async {
    final ProviderContainer container = _searchContainer(
      repository: StubSitesRepository(),
      localPool: <PollutionSite>[
        buildTestPollutionSite(id: 'waste-alpha'),
        buildTestPollutionSite(id: 'alpha-site'),
      ],
    );

    final MapSearchController notifier = container.read(
      mapSearchControllerProvider.notifier,
    );
    notifier.updateQuery('Alpha');
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(
      container.read(mapSearchControllerProvider).localResults.first.id,
      'alpha-site',
    );
  });

  test('stays in searching state until remote finishes', () async {
    var remoteCalls = 0;
    final ProviderContainer delayedContainer = ProviderContainer(
      overrides: <Override>[
        sitesRepositoryProvider.overrideWithValue(
          _DelayedSitesRepository(
            onSearch: (SiteMapSearchRequest _, {cancellation}) async {
              remoteCalls += 1;
              await Future<void>.delayed(const Duration(milliseconds: 120));
              return SiteMapSearchResponse(
                items: <PollutionSite>[buildTestPollutionSite(id: 'bitola')],
              );
            },
          ),
        ),
        mapSearchLocalPoolProvider.overrideWith(
          (Ref ref) => const <PollutionSite>[],
        ),
      ],
    );
    final ProviderSubscription<MapSearchState> delayedSub = delayedContainer
        .listen(mapSearchControllerProvider, (_, __) {});
    addTearDown(() {
      delayedSub.close();
      delayedContainer.dispose();
    });

    final MapSearchController notifier = delayedContainer.read(
      mapSearchControllerProvider.notifier,
    );

    notifier.updateQuery('Bitola');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(remoteCalls, 0);
    expect(
      delayedContainer.read(mapSearchControllerProvider).isSearching,
      isTrue,
    );
    expect(
      delayedContainer.read(mapSearchControllerProvider).shouldShowNoResults,
      isFalse,
    );

    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(remoteCalls, 1);
    final MapSearchState state = delayedContainer.read(
      mapSearchControllerProvider,
    );
    expect(state.isSearching, isFalse);
    expect(state.remotePhase, MapSearchRemotePhase.ready);
    expect(state.totalMatchCount, 1);
  });

  test('single-character query is too short for remote search', () async {
    final ProviderContainer container = _searchContainer(
      repository: _FailingSitesRepository(),
    );

    container.read(mapSearchControllerProvider.notifier).updateQuery('b');
    await Future<void>.delayed(const Duration(milliseconds: 260));

    final MapSearchState state = container.read(mapSearchControllerProvider);
    expect(state.isQueryTooShortForRemote, isTrue);
    expect(state.remotePhase, MapSearchRemotePhase.idle);
    expect(state.shouldShowNoResults, isFalse);
  });

  test('shows no results only after remote search completes empty', () async {
    final ProviderContainer container = _searchContainer(
      repository: StubSitesRepository(),
      localPool: const <PollutionSite>[],
    );

    container.read(mapSearchControllerProvider.notifier).updateQuery('bi');
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final MapSearchState state = container.read(mapSearchControllerProvider);
    expect(state.shouldShowNoResults, isTrue);
    expect(state.remotePhase, MapSearchRemotePhase.ready);
  });

  test('setCamera does not trigger remote search', () async {
    var remoteCalls = 0;
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sitesRepositoryProvider.overrideWithValue(
          _DelayedSitesRepository(
            onSearch: (SiteMapSearchRequest _, {cancellation}) async {
              remoteCalls += 1;
              return const SiteMapSearchResponse(items: <PollutionSite>[]);
            },
          ),
        ),
        mapSearchLocalPoolProvider.overrideWith(
          (Ref ref) => const <PollutionSite>[],
        ),
      ],
    );
    final ProviderSubscription<MapSearchState> sub = container.listen(
      mapSearchControllerProvider,
      (_, __) {},
    );
    addTearDown(() {
      sub.close();
      container.dispose();
    });

    final MapSearchController notifier = container.read(
      mapSearchControllerProvider.notifier,
    );

    notifier.updateQuery('bi');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(remoteCalls, 1);

    notifier.setCamera(42, 21);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(remoteCalls, 1);
  });

  test('folded local search matches Cyrillic title', () async {
    final ProviderContainer container = _searchContainer(
      repository: StubSitesRepository(),
      localPool: <PollutionSite>[
        buildTestPollutionSite(id: 'mk').copyWithTitle('Битола'),
      ],
    );

    container.read(mapSearchControllerProvider.notifier).updateQuery('Bitola');
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(
      container.read(mapSearchControllerProvider).localResults,
      hasLength(1),
    );
  });
}

class _DelayedSitesRepository implements SitesRepository {
  _DelayedSitesRepository({required this.onSearch});

  final Future<SiteMapSearchResponse> Function(
    SiteMapSearchRequest request, {
    RequestCancellationToken? cancellation,
  })
  onSearch;

  @override
  Future<SiteMapSearchResponse> searchSitesForMap(
    SiteMapSearchRequest request, {
    RequestCancellationToken? cancellation,
  }) => onSearch(request, cancellation: cancellation);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingSitesRepository implements SitesRepository {
  @override
  Future<SiteMapSearchResponse> searchSitesForMap(
    SiteMapSearchRequest request, {
    RequestCancellationToken? cancellation,
  }) async {
    fail('remote search should not run for one character');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

extension on PollutionSite {
  PollutionSite copyWithTitle(String title) {
    return PollutionSite(
      id: id,
      title: title,
      description: description,
      statusLabel: statusLabel,
      statusCode: statusCode,
      statusColor: statusColor,
      distanceKm: distanceKm,
      score: score,
      participantCount: participantCount,
      pollutionType: pollutionType,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
