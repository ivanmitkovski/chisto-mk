import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chisto_mobile/features/home/data/map_realtime/map_site_event.dart';
import 'package:chisto_mobile/features/home/data/map_realtime/map_sync_coordinator.dart';
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
  })
  onGetSitesForMap;
  final Future<PollutionSite?> Function(String id) onGetSiteById;

  int getSitesForMapCalls = 0;
  int getSiteByIdCalls = 0;

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
  }) async {
    getSitesForMapCalls += 1;
    return onGetSitesForMap(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      limit: limit,
      minLatitude: minLatitude,
      maxLatitude: maxLatitude,
      minLongitude: minLongitude,
      maxLongitude: maxLongitude,
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
      ),
    );
    coordinator.requestSync(immediate: true);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(repository.getSitesForMapCalls, 1);
    expect(coordinator.snapshot.sites, hasLength(1));
    expect(
      coordinator.snapshot.inlineNotice,
      contains('Offline. Showing your last saved map snapshot'),
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
}
