import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:feature_home/src/data/api_feed_sites_repository.dart';
import 'package:feature_home/src/data/sites_local_cache.dart';
import 'package:feature_home/src/domain/repositories/sites_repository_types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: AppConfig.dev,
        accessToken: () => null,
        onUnauthorized: (_) {},
      );

  int getCalls = 0;
  String? lastPath;
  Map<String, String>? lastHeaders;
  AppError? nextError;
  final Map<String, ApiResponse> _responses = <String, ApiResponse>{};

  static Map<String, dynamic> emptyMapJson() => <String, dynamic>{
    'data': <dynamic>[],
    'meta': <String, dynamic>{
      'signedMediaExpiresAt': '2026-01-01T00:00:00.000Z',
      'serverTime': '2026-01-01T00:00:00.000Z',
      'queryMode': 'radius',
      'dataVersion': 'v1',
    },
  };

  void stubGet(
    String path,
    Map<String, dynamic> json, {
    int statusCode = 200,
    Map<String, String> headers = const <String, String>{},
  }) {
    _responses[path] = ApiResponse(
      statusCode: statusCode,
      json: json,
      headers: headers,
    );
  }

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    getCalls += 1;
    lastPath = path;
    lastHeaders = headers;
    if (nextError != null) {
      throw nextError!;
    }
    final ApiResponse? response = _responses[path];
    if (response != null) {
      return response;
    }
    return ApiResponse(
      statusCode: 200,
      json: emptyMapJson(),
      headers: const <String, String>{},
    );
  }
}

Map<String, dynamic> _siteListItemJson({required String id}) {
  return <String, dynamic>{
    'id': id,
    'description': 'Site $id',
    'status': 'REPORTED',
    'latitude': 41.99,
    'longitude': 21.43,
    'pollutionType': 'Illegal landfill',
    'distanceKm': 1.0,
    'upvotesCount': 0,
  };
}

Map<String, dynamic> _sitesListJson(List<Map<String, dynamic>> items) {
  return <String, dynamic>{
    'data': items,
    'meta': <String, dynamic>{
      'total': items.length,
      'page': 1,
      'limit': 20,
      'signedMediaExpiresAt': '2026-01-01T00:00:00.000Z',
    },
  };
}

class _MapEtagFakeClient extends _FakeApiClient {
  int mapCalls = 0;

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, String>? headers,
    RequestCancellationToken? cancellation,
  }) async {
    if (path.startsWith('/sites/map?')) {
      mapCalls += 1;
      lastPath = path;
      lastHeaders = headers;
      if (headers?['If-None-Match'] != null) {
        return ApiResponse(
          statusCode: 304,
          json: _FakeApiClient.emptyMapJson(),
          headers: const <String, String>{'etag': '"v1"'},
        );
      }
      return ApiResponse(
        statusCode: 200,
        json: _sitesListJson(<Map<String, dynamic>>[
          _siteListItemJson(id: 'map-1'),
        ]),
        headers: const <String, String>{'etag': '"v1"'},
      );
    }
    return super.get(path, headers: headers, cancellation: cancellation);
  }
}

class _StubSitesLocalCache extends SitesLocalCache {
  _StubSitesLocalCache({this.snapshot, this.feedPage});

  final ({Map<String, dynamic> payload, DateTime cachedAt})? snapshot;
  final ({Map<String, dynamic> payload, DateTime cachedAt, int storedPage})?
  feedPage;

  @override
  Future<({Map<String, dynamic> payload, DateTime cachedAt})?> loadMapSnapshot({
    required String authSegment,
  }) async {
    return snapshot;
  }

  @override
  Future<({Map<String, dynamic> payload, DateTime cachedAt, int storedPage})?>
  loadFeedPage({
    required String requestKey,
    required String scopeKey,
    required int page,
  }) async {
    return feedPage;
  }

  @override
  Future<void> persistMapSnapshot(
    Map<String, dynamic> payload, {
    required String authSegment,
  }) async {}

  @override
  Future<void> persistFeedSnapshot({
    required String scopeKey,
    required String requestKey,
    required Map<String, dynamic> payload,
    required DateTime now,
    required int page,
    required String? cursor,
    required String? nextCursor,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('adds includeArchived=true query param for map fetches', () async {
    final stub = _FakeApiClient();
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

  test(
    'uses cached map snapshot only for connectivity/server failures',
    () async {
      final stub = _FakeApiClient()
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
    },
  );

  test('does not use cached map snapshot for validation errors', () async {
    final stub = _FakeApiClient()
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
    final repository = ApiFeedSitesRepository(client: stub, localCache: cache);
    await expectLater(
      repository.getSitesForMap(latitude: 41.99, longitude: 21.43),
      throwsA(
        isA<AppError>().having((e) => e.code, 'code', 'VALIDATION_ERROR'),
      ),
    );
  });

  test(
    'getSavedSites returns empty list when endpoint is not available',
    () async {
      final stub = _FakeApiClient()
        ..nextError = AppError.validation(message: 'Request validation failed');
      final repository = ApiFeedSitesRepository(
        client: stub,
        localCache: _StubSitesLocalCache(),
      );
      final result = await repository.getSavedSites(page: 1, limit: 24);
      expect(result.sites, isEmpty);
      expect(result.total, 0);
      expect(stub.lastPath, contains('/sites/saved'));
    },
  );

  test('getSavedSites rethrows unauthorized errors', () async {
    final stub = _FakeApiClient()..nextError = AppError.unauthorized();
    final repository = ApiFeedSitesRepository(
      client: stub,
      localCache: _StubSitesLocalCache(),
    );
    await expectLater(
      repository.getSavedSites(),
      throwsA(
        isA<AppError>().having((AppError e) => e.code, 'code', 'UNAUTHORIZED'),
      ),
    );
  });

  test('getSavedSites uses disk fallback on network failure', () async {
    final stub = _FakeApiClient()
      ..nextError = AppError.network(message: 'offline');
    final cache = _StubSitesLocalCache(
      feedPage: (
        payload: <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'saved_cached',
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
        storedPage: 1,
      ),
    );
    final repository = ApiFeedSitesRepository(client: stub, localCache: cache);
    final result = await repository.getSavedSites(page: 1, limit: 24);
    expect(result.isStaleFallback, isTrue);
    expect(result.sites, isNotEmpty);
    expect(result.sites.first.id, 'saved_cached');
  });

  test('getSites returns memory cache within TTL without second GET', () async {
    final stub = _FakeApiClient();
    const String path =
        '/sites?page=1&limit=20&radiusKm=10.0&sort=hybrid&mode=for_you&scope=local&explain=false';
    stub.stubGet(
      path,
      _sitesListJson(<Map<String, dynamic>>[_siteListItemJson(id: 'feed-1')]),
    );
    final repository = ApiFeedSitesRepository(
      client: stub,
      localCache: _StubSitesLocalCache(),
    );

    final SitesListResult first = await repository.getSites();
    expect(first.sites.single.id, 'feed-1');
    expect(first.servedFromCache, isFalse);

    final int callsAfterFirst = stub.getCalls;
    final SitesListResult second = await repository.getSites();
    expect(second.servedFromCache, isTrue);
    expect(second.sites.single.id, 'feed-1');
    expect(stub.getCalls, callsAfterFirst);
  });

  test('getSites appends scope to query string', () async {
    final stub = _FakeApiClient();
    const String path =
        '/sites?page=1&limit=20&radiusKm=150.0&sort=hybrid&mode=for_you&scope=discovery&explain=false';
    stub.stubGet(
      path,
      _sitesListJson(<Map<String, dynamic>>[_siteListItemJson(id: 'disc-1')]),
    );
    final repository = ApiFeedSitesRepository(
      client: stub,
      localCache: _StubSitesLocalCache(),
    );

    final SitesListResult result = await repository.getSites(
      radiusKm: 150,
      scope: 'discovery',
    );

    expect(result.sites.single.id, 'disc-1');
    expect(stub.getCalls, 1);
  });

  test('getSites uses disk fallback on network error', () async {
    final stub = _FakeApiClient()
      ..nextError = AppError.network(message: 'offline');
    final cache = _StubSitesLocalCache(
      feedPage: (
        payload: _sitesListJson(<Map<String, dynamic>>[
          _siteListItemJson(id: 'disk-feed'),
        ]),
        cachedAt: DateTime.now(),
        storedPage: 1,
      ),
    );
    final repository = ApiFeedSitesRepository(client: stub, localCache: cache);

    final SitesListResult result = await repository.getSites();

    expect(result.isStaleFallback, isTrue);
    expect(result.sites.single.id, 'disk-feed');
  });

  test('getSites reads x-feed-variant response header', () async {
    final stub = _FakeApiClient();
    stub.stubGet(
      '/sites?page=1&limit=20&radiusKm=10.0&sort=hybrid&mode=for_you&scope=local&explain=false',
      _sitesListJson(<Map<String, dynamic>>[_siteListItemJson(id: 'v')]),
      headers: <String, String>{'x-feed-variant': 'v2'},
    );
    final repository = ApiFeedSitesRepository(
      client: stub,
      localCache: _StubSitesLocalCache(),
    );

    final SitesListResult result = await repository.getSites();

    expect(result.feedVariant, 'v2');
  });

  test('getSiteById returns null for NOT_FOUND', () async {
    final stub = _FakeApiClient()
      ..nextError = const AppError(code: 'NOT_FOUND', message: 'missing');
    final repository = ApiFeedSitesRepository(
      client: stub,
      localCache: _StubSitesLocalCache(),
    );

    expect(await repository.getSiteById('missing'), isNull);
  });

  test('getSiteById deduplicates concurrent fetches', () async {
    final stub = _FakeApiClient();
    stub.stubGet('/sites/site-dedupe', <String, dynamic>{
      'id': 'site-dedupe',
      'description': 'Deduped',
      'status': 'REPORTED',
      'latitude': 41.99,
      'longitude': 21.43,
      'reports': <dynamic>[],
    });
    final repository = ApiFeedSitesRepository(
      client: stub,
      localCache: _StubSitesLocalCache(),
    );

    final List<Future<Object?>> futures = <Future<Object?>>[
      repository.getSiteById('site-dedupe'),
      repository.getSiteById('site-dedupe'),
    ];
    final List<Object?> results = await Future.wait(futures);

    expect(results.first, isNotNull);
    expect(stub.getCalls, 1);
  });

  test('rememberLocalUpvote merges into subsequent feed fetch', () async {
    final auth = AuthState();
    auth.setAuthenticated(userId: 'u1', displayName: 'User');
    final stub = _FakeApiClient();
    stub.stubGet(
      '/sites?page=1&limit=20&radiusKm=10.0&sort=hybrid&mode=for_you&scope=local&explain=false',
      _sitesListJson(<Map<String, dynamic>>[
        <String, dynamic>{
          ..._siteListItemJson(id: 'up-1'),
          'isUpvotedByMe': false,
        },
      ]),
    );
    final repository = ApiFeedSitesRepository(
      client: stub,
      authState: auth,
      localCache: _StubSitesLocalCache(),
    );

    await repository.rememberLocalUpvote('up-1');
    final SitesListResult result = await repository.getSites();

    expect(result.sites.single.isUpvotedByMe, isTrue);
  });

  test(
    'getSitesForMap uses 304 etag payload after memory cache expires',
    () async {
      final _MapEtagFakeClient stub = _MapEtagFakeClient();
      final repository = ApiFeedSitesRepository(
        client: stub,
        localCache: _StubSitesLocalCache(),
      );

      final first = await repository.getSitesForMap(
        latitude: 41.99,
        longitude: 21.43,
      );
      expect(first.sites.single.id, 'map-1');
      expect(stub.mapCalls, 1);

      await Future<void>.delayed(const Duration(seconds: 16));

      final second = await repository.getSitesForMap(
        latitude: 41.99,
        longitude: 21.43,
      );

      expect(second.sites.single.id, 'map-1');
      expect(stub.mapCalls, 2);
      expect(stub.lastHeaders?['If-None-Match'], '"v1"');
    },
  );

  test('clearAllCaches clears map etag cache forcing full refetch', () async {
    final _MapEtagFakeClient stub = _MapEtagFakeClient();
    final repository = ApiFeedSitesRepository(
      client: stub,
      localCache: _StubSitesLocalCache(),
    );

    await repository.getSitesForMap(latitude: 41.99, longitude: 21.43);
    await repository.clearAllCaches();
    final second = await repository.getSitesForMap(
      latitude: 41.99,
      longitude: 21.43,
    );

    expect(second.sites.single.id, 'map-1');
    expect(stub.mapCalls, 2);
    expect(stub.lastHeaders?['If-None-Match'], isNull);
  });

  test(
    'getSitesForMap memory cache is scoped per authenticated user',
    () async {
      final stub = _FakeApiClient();
      final auth = AuthState();
      auth.setAuthenticated(userId: 'user-a', displayName: 'User A');
      final repository = ApiFeedSitesRepository(
        client: stub,
        authState: auth,
        localCache: _StubSitesLocalCache(),
      );

      await repository.getSitesForMap(latitude: 41.99, longitude: 21.43);
      expect(stub.getCalls, 1);

      final MapSitesResult cached = await repository.getSitesForMap(
        latitude: 41.99,
        longitude: 21.43,
      );
      expect(cached.servedFromCache, isTrue);
      expect(stub.getCalls, 1);

      auth.setAuthenticated(userId: 'user-b', displayName: 'User B');
      final MapSitesResult afterUserSwitch = await repository.getSitesForMap(
        latitude: 41.99,
        longitude: 21.43,
      );
      expect(afterUserSwitch.servedFromCache, isFalse);
      expect(stub.getCalls, 2);
    },
  );

  test('getSavedSites marks isSavedByMe when API omits the flag', () async {
    final stub = _FakeApiClient();
    stub.stubGet(
      '/sites/saved?page=1&limit=24',
      _sitesListJson(<Map<String, dynamic>>[_siteListItemJson(id: 'saved-1')]),
    );
    final repository = ApiFeedSitesRepository(
      client: stub,
      localCache: _StubSitesLocalCache(),
    );

    final SitesListResult result = await repository.getSavedSites();

    expect(result.sites, hasLength(1));
    expect(result.sites.single.id, 'saved-1');
    expect(result.sites.single.isSavedByMe, isTrue);
  });

  test('getSavedSites returns empty for NOT_FOUND', () async {
    final stub = _FakeApiClient()
      ..nextError = const AppError(code: 'NOT_FOUND', message: 'n/a');
    final repository = ApiFeedSitesRepository(
      client: stub,
      localCache: _StubSitesLocalCache(),
    );

    final SitesListResult result = await repository.getSavedSites();

    expect(result.sites, isEmpty);
  });

  test('clearAllCaches clears memory feed cache', () async {
    final stub = _FakeApiClient();
    const String path =
        '/sites?page=1&limit=20&radiusKm=10.0&sort=hybrid&mode=for_you&scope=local&explain=false';
    stub.stubGet(
      path,
      _sitesListJson(<Map<String, dynamic>>[_siteListItemJson(id: 'c1')]),
    );
    final repository = ApiFeedSitesRepository(
      client: stub,
      localCache: _StubSitesLocalCache(),
    );

    await repository.getSites();
    await repository.clearAllCaches();
    stub.stubGet(
      path,
      _sitesListJson(<Map<String, dynamic>>[_siteListItemJson(id: 'c2')]),
    );
    final SitesListResult afterClear = await repository.getSites();

    expect(afterClear.sites.single.id, 'c2');
    expect(afterClear.servedFromCache, isFalse);
  });
}
