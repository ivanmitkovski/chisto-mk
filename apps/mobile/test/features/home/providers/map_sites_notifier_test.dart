import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/providers/notifications_providers.dart';
import 'package:feature_home/src/application/home_providers.dart';
import 'package:feature_home/src/data/map_realtime/map_realtime_service.dart';
import 'package:feature_home/src/data/map_realtime/map_sync_coordinator.dart';
import 'package:feature_home/src/data/map_realtime/map_sync_inline_notice.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/domain/repositories/sites_repository.dart';
import 'package:feature_home/src/presentation/providers/map_sites_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/test_pollution_site.dart';

class _EmptySitesRepository implements SitesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TrackingSitesRepository implements SitesRepository {
  int getSitesForMapCalls = 0;

  @override
  Future<MapSitesResult> getSitesForMap({
    required double latitude,
    required double longitude,
    double radiusKm = 80,
    int limit = 200,
    double? minLatitude,
    double? maxLatitude,
    double? minLongitude,
    double? maxLongitude,
    String mapDetail = SitesRepository.mapDetailLite,
    double? zoom,
    String? status,
    bool includeArchived = false,
    bool prefetch = false,
  }) async {
    getSitesForMapCalls += 1;
    return MapSitesResult(
      sites: <PollutionSite>[buildTestPollutionSite(id: 'site-1')],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MapViewportQuery _testViewportQuery() {
  return const MapViewportQuery(
    latitude: 41.61,
    longitude: 21.75,
    radiusKm: 50,
    limit: 250,
    zoom: 12,
  );
}

void main() {
  late MapRealtimeService mapRealtime;

  setUp(() {
    final AuthState auth = AuthState()
      ..setAuthenticated(
        userId: 'u1',
        displayName: 'Tester',
        accessToken: 'token',
      );
    mapRealtime = MapRealtimeService(
      config: AppConfig.local,
      authState: auth,
      httpClient: MockClient((http.Request request) async {
        return http.Response('', 404);
      }),
    );
  });

  tearDown(() {
    mapRealtime.dispose();
  });

  test(
    'brief reconnect blip does not surface connection unstable banner',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sitesRepositoryProvider.overrideWithValue(_EmptySitesRepository()),
          mapRealtimeServiceProvider.overrideWithValue(mapRealtime),
        ],
      );
      addTearDown(container.dispose);
      container.listen(mapSitesNotifierProvider, (_, __) {});

      final MapSitesNotifier notifier = container.read(
        mapSitesNotifierProvider.notifier,
      );
      notifier.connectionUnstableBannerGrace = const Duration(milliseconds: 50);
      notifier.upsertSiteFromFocus(buildTestPollutionSite(id: 'site-1'));

      notifier.debugApplySseStateForTest(
        MapRealtimeConnectionState.reconnecting,
      );
      expect(container.read(mapSitesNotifierProvider).syncNotice, isNull);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      notifier.debugApplySseStateForTest(MapRealtimeConnectionState.live);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(container.read(mapSitesNotifierProvider).syncNotice, isNull);
    },
  );

  test(
    'sustained reconnecting surfaces connection unstable banner when data stale',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sitesRepositoryProvider.overrideWithValue(_EmptySitesRepository()),
          mapRealtimeServiceProvider.overrideWithValue(mapRealtime),
        ],
      );
      addTearDown(container.dispose);
      container.listen(mapSitesNotifierProvider, (_, __) {});

      final MapSitesNotifier notifier = container.read(
        mapSitesNotifierProvider.notifier,
      );
      notifier.connectionUnstableBannerGrace = const Duration(milliseconds: 50);
      notifier.upsertSiteFromFocus(buildTestPollutionSite(id: 'site-1'));

      notifier.debugApplySseStateForTest(
        MapRealtimeConnectionState.reconnecting,
      );
      expect(container.read(mapSitesNotifierProvider).syncNotice, isNull);

      await Future<void>.delayed(const Duration(milliseconds: 60));

      final MapSyncInlineNotice? notice = container
          .read(mapSitesNotifierProvider)
          .syncNotice;
      expect(notice, isNotNull);
      expect(notice!.kind, MapSyncInlineNoticeKind.connectionUnstable);
    },
  );

  test('sustained reconnecting hides banner when map data is fresh', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sitesRepositoryProvider.overrideWithValue(_EmptySitesRepository()),
        mapRealtimeServiceProvider.overrideWithValue(mapRealtime),
      ],
    );
    addTearDown(container.dispose);
    container.listen(mapSitesNotifierProvider, (_, __) {});

    final MapSitesNotifier notifier = container.read(
      mapSitesNotifierProvider.notifier,
    );
    notifier.connectionUnstableBannerGrace = const Duration(milliseconds: 50);
    notifier.upsertSiteFromFocus(buildTestPollutionSite(id: 'site-1'));
    notifier.debugSetLastSuccessfulSyncAtForTest(DateTime.now());

    notifier.debugApplySseStateForTest(MapRealtimeConnectionState.reconnecting);
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(container.read(mapSitesNotifierProvider).syncNotice, isNull);
  });

  test(
    'SSE reconnecting to live with stale data requests map reconcile sync',
    () async {
      final _TrackingSitesRepository repo = _TrackingSitesRepository();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sitesRepositoryProvider.overrideWithValue(repo),
          mapRealtimeServiceProvider.overrideWithValue(mapRealtime),
        ],
      );
      addTearDown(container.dispose);
      container.listen(mapSitesNotifierProvider, (_, __) {});

      final MapSitesNotifier notifier = container.read(
        mapSitesNotifierProvider.notifier,
      );
      notifier.setActive(true);
      notifier.updateViewport(_testViewportQuery());
      notifier.upsertSiteFromFocus(buildTestPollutionSite(id: 'site-1'));
      notifier.debugSetLastSuccessfulSyncAtForTest(
        DateTime.now().subtract(const Duration(minutes: 10)),
      );

      final int callsBefore = repo.getSitesForMapCalls;

      notifier.debugApplySseStateForTest(
        MapRealtimeConnectionState.reconnecting,
      );
      notifier.debugApplySseStateForTest(MapRealtimeConnectionState.live);

      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(repo.getSitesForMapCalls, greaterThan(callsBefore));
    },
  );

  test(
    'SSE reconnecting to live with fresh data does not request reconcile sync',
    () async {
      final _TrackingSitesRepository repo = _TrackingSitesRepository();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sitesRepositoryProvider.overrideWithValue(repo),
          mapRealtimeServiceProvider.overrideWithValue(mapRealtime),
        ],
      );
      addTearDown(container.dispose);
      container.listen(mapSitesNotifierProvider, (_, __) {});

      final MapSitesNotifier notifier = container.read(
        mapSitesNotifierProvider.notifier,
      );
      notifier.setActive(true);
      notifier.updateViewport(_testViewportQuery());
      notifier.upsertSiteFromFocus(buildTestPollutionSite(id: 'site-1'));
      notifier.debugSetLastSuccessfulSyncAtForTest(DateTime.now());

      final int callsBefore = repo.getSitesForMapCalls;

      notifier.debugApplySseStateForTest(
        MapRealtimeConnectionState.reconnecting,
      );
      notifier.debugApplySseStateForTest(MapRealtimeConnectionState.live);

      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(repo.getSitesForMapCalls, callsBefore);
    },
  );
}
