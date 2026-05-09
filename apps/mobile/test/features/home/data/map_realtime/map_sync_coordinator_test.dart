import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chisto_mobile/core/connectivity/connectivity_checker.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_site_event.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_sync_coordinator.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_sync_inline_notice.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/domain/repositories/sites_repository.dart';

class _TestSitesRepository implements SitesRepository {
  _TestSitesRepository({
    required this.onGetSitesForMap,
    required this.onGetSiteById,
  });

  final Future<MapSitesResult> Function({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required int limit,
    double? minLatitude,
    double? maxLatitude,
    double? minLongitude,
    double? maxLongitude,
    double? zoom,
    String? status,
    bool includeArchived,
  })
  onGetSitesForMap;
  final Future<PollutionSite?> Function(String id) onGetSiteById;

  int getSitesForMapCalls = 0;
  int getSiteByIdCalls = 0;

  bool lastPrefetchCall = false;

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
    lastPrefetchCall = prefetch;
    return onGetSitesForMap(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      limit: limit,
      minLatitude: minLatitude,
      maxLatitude: maxLatitude,
      minLongitude: minLongitude,
      maxLongitude: maxLongitude,
      zoom: zoom,
      status: status,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<PollutionSite?> getSiteById(String id) async {
    getSiteByIdCalls += 1;
    return onGetSiteById(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PollutionSite _buildSite(String id) {
  return PollutionSite(
    id: id,
    title: 'Site $id',
    description: 'Description',
    statusLabel: 'High',
    statusColor: Colors.red,
    distanceKm: 1.2,
    score: 10,
    participantCount: 0,
    mediaUrls: const <String>['assets/images/content/placeholder.png'],
    latitude: 41.61,
    longitude: 21.75,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MapViewportQuery.containsViewport requires matching bounds and params', () {
    const MapViewportQuery outer = MapViewportQuery(
      latitude: 41.5,
      longitude: 21.5,
      radiusKm: 40,
      limit: 250,
      zoom: 11,
      minLatitude: 41.0,
      maxLatitude: 42.0,
      minLongitude: 21.0,
      maxLongitude: 22.0,
    );
    const MapViewportQuery innerInside = MapViewportQuery(
      latitude: 41.55,
      longitude: 21.55,
      radiusKm: 40,
      limit: 250,
      zoom: 11,
      minLatitude: 41.2,
      maxLatitude: 41.8,
      minLongitude: 21.2,
      maxLongitude: 21.8,
    );
    const MapViewportQuery innerOutside = MapViewportQuery(
      latitude: 41.55,
      longitude: 21.55,
      radiusKm: 40,
      limit: 250,
      zoom: 11,
      minLatitude: 40.5,
      maxLatitude: 41.5,
      minLongitude: 21.2,
      maxLongitude: 21.8,
    );
    expect(outer.containsViewport(innerInside), isTrue);
    expect(outer.containsViewport(innerOutside), isFalse);
  });

  test('MapViewportQuery.shiftedBy offsets center and bounds', () {
    const MapViewportQuery q = MapViewportQuery(
      latitude: 41.5,
      longitude: 21.5,
      radiusKm: 40,
      limit: 250,
      zoom: 11,
      minLatitude: 41.0,
      maxLatitude: 42.0,
      minLongitude: 21.0,
      maxLongitude: 22.0,
    );
    final MapViewportQuery s = q.shiftedBy(
      deltaLatDegrees: 0.1,
      deltaLngDegrees: -0.05,
    );
    expect(s.latitude, closeTo(41.6, 1e-9));
    expect(s.longitude, closeTo(21.45, 1e-9));
    expect(s.minLatitude, closeTo(41.1, 1e-9));
    expect(s.maxLatitude, closeTo(42.1, 1e-9));
  });

  test('predictive prefetch calls repository with prefetch after fast pan', () async {
    final _TestSitesRepository repository = _TestSitesRepository(
      onGetSitesForMap:
          ({
            required double latitude,
            required double longitude,
            required double radiusKm,
            required int limit,
            double? minLatitude,
            double? maxLatitude,
            double? minLongitude,
            double? maxLongitude,
            double? zoom,
            String? status,
            bool includeArchived = false,
          }) async {
            return MapSitesResult(sites: <PollutionSite>[_buildSite('a')]);
          },
      onGetSiteById: (_) async => null,
    );
    final MapSyncCoordinator c = MapSyncCoordinator(sitesRepository: repository);
    c.setActive(true);
    c.updateViewport(
      const MapViewportQuery(
        latitude: 41.5,
        longitude: 21.5,
        radiusKm: 40,
        limit: 250,
        zoom: 10,
        minLatitude: 41.0,
        maxLatitude: 42.0,
        minLongitude: 21.0,
        maxLongitude: 22.0,
      ),
    );
    c.schedulePredictivePrefetchFromPan(
      centerLat: 41.5,
      centerLng: 21.5,
      zoom: 10,
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    c.schedulePredictivePrefetchFromPan(
      centerLat: 41.65,
      centerLng: 21.65,
      zoom: 10,
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(repository.getSitesForMapCalls, greaterThan(0));
    expect(repository.lastPrefetchCall, isTrue);
    c.dispose();
  });

  test('skips debounced full sync when viewport stays inside last envelope', () async {
    final PollutionSite site = _buildSite('s1');
    final _TestSitesRepository repository = _TestSitesRepository(
      onGetSitesForMap:
          ({
            required double latitude,
            required double longitude,
            required double radiusKm,
            required int limit,
            double? minLatitude,
            double? maxLatitude,
            double? minLongitude,
            double? maxLongitude,
            double? zoom,
            String? status,
            bool includeArchived = false,
          }) async {
            return MapSitesResult(sites: <PollutionSite>[site]);
          },
      onGetSiteById: (_) async => site,
    );
    final MapSyncCoordinator coordinator = MapSyncCoordinator(
      sitesRepository: repository,
    );
    const MapViewportQuery outer = MapViewportQuery(
      latitude: 41.5,
      longitude: 21.5,
      radiusKm: 40,
      limit: 250,
      zoom: 11,
      minLatitude: 41.0,
      maxLatitude: 42.0,
      minLongitude: 21.0,
      maxLongitude: 22.0,
    );
    coordinator.updateViewport(outer);
    coordinator.requestSync(immediate: true);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(repository.getSitesForMapCalls, 1);

    const MapViewportQuery inner = MapViewportQuery(
      latitude: 41.55,
      longitude: 21.55,
      radiusKm: 40,
      limit: 250,
      zoom: 11,
      minLatitude: 41.2,
      maxLatitude: 41.8,
      minLongitude: 21.2,
      maxLongitude: 21.8,
    );
    coordinator.updateViewport(inner);
    coordinator.requestSync(immediate: false);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(repository.getSitesForMapCalls, 1);

    coordinator.dispose();
  });

  test('loads cached fallback notice for saved map results', () async {
    final PollutionSite site = _buildSite('site-1');
    final _TestSitesRepository repository = _TestSitesRepository(
      onGetSitesForMap:
          ({
            required double latitude,
            required double longitude,
            required double radiusKm,
            required int limit,
            double? minLatitude,
            double? maxLatitude,
            double? minLongitude,
            double? maxLongitude,
            double? zoom,
            String? status,
            bool includeArchived = false,
          }) async {
            return MapSitesResult(
              sites: <PollutionSite>[site],
              servedFromCache: true,
              isStaleFallback: true,
              cachedAt: DateTime.now().subtract(const Duration(minutes: 5)),
            );
          },
      onGetSiteById: (_) async => site,
    );
    final MapSyncCoordinator coordinator = MapSyncCoordinator(
      sitesRepository: repository,
    );

    coordinator.updateViewport(
      const MapViewportQuery(
        latitude: 41.6,
        longitude: 21.7,
        radiusKm: 20,
        limit: 120,
        zoom: 11,
      ),
    );
    coordinator.requestSync(immediate: true);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(repository.getSitesForMapCalls, 1);
    expect(coordinator.snapshot.sites, hasLength(1));
    expect(coordinator.snapshot.inlineNotice, isNotNull);
    expect(
      coordinator.snapshot.inlineNotice!.kind,
      MapSyncInlineNoticeKind.offlineCached,
    );

    coordinator.dispose();
  });

  testWidgets('refetches map when signedMediaExpiresAt is already past', (
    WidgetTester tester,
  ) async {
    final PollutionSite site = _buildSite('site-exp');
    final _TestSitesRepository repository = _TestSitesRepository(
      onGetSitesForMap:
          ({
            required double latitude,
            required double longitude,
            required double radiusKm,
            required int limit,
            double? minLatitude,
            double? maxLatitude,
            double? minLongitude,
            double? maxLongitude,
            double? zoom,
            String? status,
            bool includeArchived = false,
          }) async {
            return MapSitesResult(
              sites: <PollutionSite>[site],
              signedMediaExpiresAt: DateTime.now().subtract(
                const Duration(minutes: 1),
              ),
            );
          },
      onGetSiteById: (_) async => null,
    );
    final MapSyncCoordinator coordinator = MapSyncCoordinator(
      sitesRepository: repository,
    );
    coordinator.updateViewport(
      const MapViewportQuery(
        latitude: 41.6,
        longitude: 21.7,
        radiusKm: 20,
        limit: 120,
        zoom: 11,
      ),
    );
    coordinator.requestSync(immediate: true);
    // First sync completes; expired signed URLs schedule a microtask refresh that
    // typically runs in the same test frame as a single pump().
    await tester.pump();
    expect(repository.getSitesForMapCalls, 2);

    coordinator.dispose();
  });

  test('dedupes duplicate realtime events and merges the site once', () async {
    final PollutionSite site = _buildSite('site-live');
    final _TestSitesRepository repository = _TestSitesRepository(
      onGetSitesForMap:
          ({
            required double latitude,
            required double longitude,
            required double radiusKm,
            required int limit,
            double? minLatitude,
            double? maxLatitude,
            double? minLongitude,
            double? maxLongitude,
            double? zoom,
            String? status,
            bool includeArchived = false,
          }) async {
            return MapSitesResult(sites: <PollutionSite>[site]);
          },
      onGetSiteById: (_) async => site,
    );
    final MapSyncCoordinator coordinator = MapSyncCoordinator(
      sitesRepository: repository,
    );
    const MapViewportQuery query = MapViewportQuery(
      latitude: 41.6,
      longitude: 21.7,
      radiusKm: 20,
      limit: 120,
      zoom: 11,
    );
    coordinator.updateViewport(query);

    final MapSiteEvent event = MapSiteEvent(
      eventId: 'evt-1',
      type: 'site_created',
      siteId: 'site-live',
      occurredAtMs: 1,
      updatedAt: DateTime.utc(2026, 3, 27, 10),
      mutationKind: 'created',
      status: 'REPORTED',
      latitude: 41.61,
      longitude: 21.75,
    );
    coordinator.ingestEvent(event);
    coordinator.ingestEvent(event);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(repository.getSiteByIdCalls, 1);
    expect(repository.getSitesForMapCalls, 1);
    expect(
      coordinator.snapshot.sites.map((PollutionSite item) => item.id),
      contains('site-live'),
    );

    coordinator.dispose();
  });

  test('keeps existing markers without connectivity banner for validation map errors', () async {
    final PollutionSite site = _buildSite('site-existing');
    int calls = 0;
    final _TestSitesRepository repository = _TestSitesRepository(
      onGetSitesForMap:
          ({
            required double latitude,
            required double longitude,
            required double radiusKm,
            required int limit,
            double? minLatitude,
            double? maxLatitude,
            double? minLongitude,
            double? maxLongitude,
            double? zoom,
            String? status,
            bool includeArchived = false,
          }) async {
            calls += 1;
            if (calls == 1) {
              return MapSitesResult(sites: <PollutionSite>[site]);
            }
            throw AppError.validation(message: 'Invalid viewport');
          },
      onGetSiteById: (_) async => site,
    );
    final MapSyncCoordinator coordinator = MapSyncCoordinator(
      sitesRepository: repository,
    );

    coordinator.updateViewport(
      const MapViewportQuery(
        latitude: 41.6,
        longitude: 21.7,
        radiusKm: 20,
        limit: 120,
        zoom: 11,
      ),
    );
    coordinator.requestSync(immediate: true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(coordinator.snapshot.sites, hasLength(1));

    coordinator.requestSync(immediate: true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(coordinator.snapshot.sites, hasLength(1));
    expect(coordinator.snapshot.inlineNotice, isNull);

    coordinator.dispose();
  });

  test('429 applies cooldown so immediate follow-up syncs do not stack fetches', () async {
    final PollutionSite site = _buildSite('rl-1');
    int calls = 0;
    final _TestSitesRepository repository = _TestSitesRepository(
      onGetSitesForMap:
          ({
            required double latitude,
            required double longitude,
            required double radiusKm,
            required int limit,
            double? minLatitude,
            double? maxLatitude,
            double? minLongitude,
            double? maxLongitude,
            double? zoom,
            String? status,
            bool includeArchived = false,
          }) async {
        calls += 1;
        if (calls == 1) {
          throw AppError.tooManyRequests(
            message: 'slow down',
            retryAfterSeconds: 1,
          );
        }
        return MapSitesResult(sites: <PollutionSite>[site]);
      },
      onGetSiteById: (_) async => site,
    );
    final MapSyncCoordinator coordinator = MapSyncCoordinator(
      sitesRepository: repository,
      connectivityChecker: const FixedConnectivityChecker(offline: false),
    );
    coordinator.updateViewport(
      const MapViewportQuery(
        latitude: 41.6,
        longitude: 21.7,
        radiusKm: 20,
        limit: 120,
        zoom: 11,
      ),
    );
    coordinator.requestSync(immediate: true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(calls, 1);
    expect(coordinator.snapshot.loadError, isNull);
    expect(
      coordinator.snapshot.inlineNotice?.kind,
      MapSyncInlineNoticeKind.liveUpdatesDelayed,
    );

    coordinator.requestSync(immediate: true);
    coordinator.requestSync(immediate: true);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(calls, 1);

    // Rate-limit backoff + debounced follow-up need wall-clock slack under parallel CI load.
    await Future<void>.delayed(const Duration(seconds: 6));
    expect(calls, 2);
    expect(coordinator.snapshot.loadError, isNull);
    expect(coordinator.snapshot.sites, hasLength(1));

    coordinator.dispose();
  });

  test('429 with existing sites shows live updates delayed banner', () async {
    final PollutionSite site = _buildSite('rl-2');
    int calls = 0;
    final _TestSitesRepository repository = _TestSitesRepository(
      onGetSitesForMap:
          ({
            required double latitude,
            required double longitude,
            required double radiusKm,
            required int limit,
            double? minLatitude,
            double? maxLatitude,
            double? minLongitude,
            double? maxLongitude,
            double? zoom,
            String? status,
            bool includeArchived = false,
          }) async {
        calls += 1;
        if (calls == 1) {
          return MapSitesResult(sites: <PollutionSite>[site]);
        }
        throw AppError.tooManyRequests(
          message: 'slow down',
          retryAfterSeconds: 30,
        );
      },
      onGetSiteById: (_) async => site,
    );
    final MapSyncCoordinator coordinator = MapSyncCoordinator(
      sitesRepository: repository,
      connectivityChecker: const FixedConnectivityChecker(offline: false),
    );
    coordinator.updateViewport(
      const MapViewportQuery(
        latitude: 41.6,
        longitude: 21.7,
        radiusKm: 20,
        limit: 120,
        zoom: 11,
      ),
    );
    coordinator.requestSync(immediate: true);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 1);

    coordinator.requestSync(immediate: true);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(calls, 2);
    expect(coordinator.snapshot.sites, hasLength(1));
    expect(
      coordinator.snapshot.inlineNotice?.kind,
      MapSyncInlineNoticeKind.liveUpdatesDelayed,
    );

    coordinator.dispose();
  });
}
