import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/network/request_cancellation.dart';
import 'package:chisto_mobile/features/home/data/api_feed_sites_repository.dart';
import 'package:chisto_mobile/features/home/data/sites_local_cache.dart';

class _StubApiClient extends ApiClient {
  _StubApiClient()
      : super(
          config: AppConfig.local,
          accessToken: () => null,
          onUnauthorized: () {},
        );

  String? lastPath;
  AppError? nextError;

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    lastPath = path;
    if (nextError != null) {
      throw nextError!;
    }
    return const ApiResponse(
      statusCode: 200,
      json: <String, dynamic>{
        'data': <dynamic>[],
        'meta': <String, dynamic>{
          'signedMediaExpiresAt': '2026-01-01T00:00:00.000Z',
          'serverTime': '2026-01-01T00:00:00.000Z',
          'queryMode': 'radius',
          'dataVersion': 'v1',
        },
      },
      headers: <String, String>{},
    );
  }
}

class _StubSitesLocalCache extends SitesLocalCache {
  _StubSitesLocalCache({this.snapshot});

  final ({Map<String, dynamic> payload, DateTime cachedAt})? snapshot;

  @override
  Future<({Map<String, dynamic> payload, DateTime cachedAt})?> loadMapSnapshot() async {
    return snapshot;
  }

  @override
  Future<void> persistMapSnapshot(Map<String, dynamic> payload) async {}
}

void main() {
  test('adds includeArchived=true query param for map fetches', () async {
    final stub = _StubApiClient();
    final repository = ApiFeedSitesRepository(
      client: stub,
      localCache: _StubSitesLocalCache(),
    );
    await repository.getSitesForMap(
      latitude: 41.99,
      longitude: 21.43,
      includeArchived: true,
    );
    expect(stub.lastPath, contains('includeArchived=true'));
  });

  test('uses cached map snapshot only for connectivity/server failures', () async {
    final stub = _StubApiClient()
      ..nextError = AppError.network(message: 'offline');
    final cache = _StubSitesLocalCache(
      snapshot: (
        payload: <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'site_cached',
              'latitude': 41.99,
              'longitude': 21.43,
              'status': 'REPORTED',
            },
          ],
          'meta': <String, dynamic>{
            'signedMediaExpiresAt': '2026-01-01T00:00:00.000Z',
          },
        },
        cachedAt: DateTime.now(),
      ),
    );
    final repository = ApiFeedSitesRepository(
      client: stub,
      localCache: cache,
    );
    final result = await repository.getSitesForMap(
      latitude: 41.99,
      longitude: 21.43,
    );
    expect(result.isStaleFallback, isTrue);
    expect(result.sites, isNotEmpty);
  });

  test('does not use cached map snapshot for validation errors', () async {
    final stub = _StubApiClient()
      ..nextError = AppError.validation(message: 'viewport invalid');
    final cache = _StubSitesLocalCache(
      snapshot: (
        payload: <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'site_cached',
              'latitude': 41.99,
              'longitude': 21.43,
              'status': 'REPORTED',
            },
          ],
          'meta': <String, dynamic>{
            'signedMediaExpiresAt': '2026-01-01T00:00:00.000Z',
          },
        },
        cachedAt: DateTime.now(),
      ),
    );
    final repository = ApiFeedSitesRepository(
      client: stub,
      localCache: cache,
    );
    await expectLater(
      repository.getSitesForMap(latitude: 41.99, longitude: 21.43),
      throwsA(isA<AppError>().having((e) => e.code, 'code', 'VALIDATION_ERROR')),
    );
  });
}
