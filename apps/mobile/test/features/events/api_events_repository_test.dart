import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:feature_events/src/data/api_events_repository.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/models/eco_event_search_params.dart';
import 'package:feature_events/src/domain/models/event_participant_row.dart';
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
  int postCalls = 0;
  final Map<String, ApiResponse> _responses = <String, ApiResponse>{};
  final Map<String, ApiResponse> _postResponses = <String, ApiResponse>{};
  AppError? nextGetError;

  void stubGet(String path, Map<String, dynamic> json) {
    _responses[path] = ApiResponse(statusCode: 200, json: json);
  }

  void stubGetNull(String path) {
    _responses[path] = const ApiResponse(statusCode: 200, json: null);
  }

  void stubPost(String path, Map<String, dynamic> json) {
    _postResponses[path] = ApiResponse(statusCode: 200, json: json);
  }

  @override
  Future<ApiResponse> get(
    String path, {
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    getCalls += 1;
    if (nextGetError != null) {
      throw nextGetError!;
    }
    final ApiResponse? response = _responses[path];
    if (response == null) {
      throw const AppError(code: 'NOT_FOUND', message: 'missing stub');
    }
    return response;
  }

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) async {
    postCalls += 1;
    final ApiResponse? response = _postResponses[path];
    if (response == null) {
      throw const AppError(code: 'NOT_FOUND', message: 'missing stub');
    }
    return response;
  }
}

Map<String, dynamic> _eventJson({required String id, required String title}) {
  return <String, dynamic>{
    'id': id,
    'title': title,
    'description': 'D',
    'category': 'riverAndLake',
    'siteId': 'site-1',
    'siteName': 'Site',
    'siteImageUrl': '',
    'organizerId': 'org-1',
    'organizerName': 'Org',
    'scheduledAt': '2026-08-15T09:30:00.000Z',
    'endAt': '2026-08-15T11:45:00.000Z',
    'status': 'upcoming',
    'participantCount': 3,
    'createdAt': '2026-01-01T00:00:00.000Z',
    'gear': <String>['trashBags'],
    'isCheckInOpen': false,
    'checkedInCount': 0,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('prefetchEvent skips network for cached event by default', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet(
      '/events/evt-1',
      _eventJson(id: 'evt-1', title: 'Event One'),
    );
    final ApiEventsRepository repo = ApiEventsRepository(client: client);

    await repo.prefetchEvent('evt-1');
    final int afterFirst = client.getCalls;

    await repo.prefetchEvent('evt-1');
    expect(client.getCalls, afterFirst);
  });

  test('prefetchEvent force refreshes cached event', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet('/events/evt-1', _eventJson(id: 'evt-1', title: 'Old'));
    final ApiEventsRepository repo = ApiEventsRepository(client: client);

    await repo.prefetchEvent('evt-1');
    expect(repo.findById('evt-1')?.title, 'Old');

    client.stubGet('/events/evt-1', _eventJson(id: 'evt-1', title: 'New'));
    await repo.prefetchEvent('evt-1', force: true);

    expect(repo.findById('evt-1')?.title, 'New');
  });

  test(
    'fetchParticipants GETs participants endpoint and parses page',
    () async {
      final _FakeApiClient client = _FakeApiClient();
      client.stubGet('/events/evt-1/participants?limit=50', <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'userId': 'u1',
            'displayName': 'Test User',
            'joinedAt': '2026-01-02T12:00:00.000Z',
            'avatarUrl': 'https://cdn.example/a.webp',
          },
        ],
        'meta': <String, dynamic>{'hasMore': false, 'nextCursor': null},
      });
      final ApiEventsRepository repo = ApiEventsRepository(client: client);

      final EventParticipantsPage page = await repo.fetchParticipants('evt-1');

      expect(page.items, hasLength(1));
      expect(page.items.single.userId, 'u1');
      expect(page.items.single.avatarUrl, 'https://cdn.example/a.webp');
      expect(page.hasMore, isFalse);
      expect(client.getCalls, 1);
    },
  );

  test(
    'refreshEvents encodes multiple categories as comma-separated sorted keys',
    () async {
      final _FakeApiClient client = _FakeApiClient();
      final String expectedPath =
          '/events?limit=50&category=${Uri.encodeQueryComponent('riverAndLake,treeAndGreen')}';
      client.stubGet(expectedPath, <String, dynamic>{
        'data': <dynamic>[],
        'meta': <String, dynamic>{'hasMore': false, 'nextCursor': null},
      });
      final ApiEventsRepository repo = ApiEventsRepository(client: client);
      await repo.refreshEvents(
        params: const EcoEventSearchParams(
          categories: <EcoEventCategory>{
            EcoEventCategory.treeAndGreen,
            EcoEventCategory.riverAndLake,
          },
        ),
      );
      expect(client.getCalls, 1);
    },
  );

  test('refreshEvents includes user location hint when available', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet(
      '/events?limit=50&nearLat=41.997300&nearLng=21.428000',
      <String, dynamic>{
        'data': <dynamic>[],
        'meta': <String, dynamic>{'hasMore': false, 'nextCursor': null},
      },
    );
    final ApiEventsRepository repo = ApiEventsRepository(client: client);
    repo.setUserLocationHint(latitude: 41.9973, longitude: 21.4280);
    await repo.refreshEvents();
    expect(client.getCalls, 1);
  });

  test('bootstrap loads global list without lifecycle filter', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet('/events?limit=50', <String, dynamic>{
      'data': <dynamic>[_eventJson(id: 'evt-list', title: 'Listed')],
      'meta': <String, dynamic>{'hasMore': false, 'nextCursor': null},
    });
    final ApiEventsRepository repo = ApiEventsRepository(client: client);
    repo.loadInitialIfNeeded();
    await repo.ready;
    expect(repo.events, hasLength(1));
    expect(repo.findById('evt-list')?.title, 'Listed');
    expect(repo.lastGlobalListLoadFailed, isFalse);
  });

  test(
    'setUserLocationHint after bootstrap refreshes list when first fetch lacked location',
    () async {
      final _FakeApiClient client = _FakeApiClient();
      client.stubGet('/events?limit=50', <String, dynamic>{
        'data': <dynamic>[_eventJson(id: 'evt-list', title: 'Listed')],
        'meta': <String, dynamic>{'hasMore': false, 'nextCursor': null},
      });
      client.stubGet(
        '/events?limit=50&nearLat=41.997300&nearLng=21.428000',
        <String, dynamic>{
          'data': <dynamic>[
            _eventJson(id: 'evt-list', title: 'Listed with distance'),
          ],
          'meta': <String, dynamic>{'hasMore': false, 'nextCursor': null},
        },
      );
      final ApiEventsRepository repo = ApiEventsRepository(client: client);
      repo.loadInitialIfNeeded();
      await repo.ready;
      expect(client.getCalls, 1);

      repo.setUserLocationHint(latitude: 41.9973, longitude: 21.4280);
      await pumpEventQueue();

      expect(client.getCalls, 2);
      expect(repo.findById('evt-list')?.title, 'Listed with distance');
    },
  );

  test('prefetchEvent removes event on NOT_FOUND', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet('/events/evt-1', _eventJson(id: 'evt-1', title: 'Gone'));
    final ApiEventsRepository repo = ApiEventsRepository(client: client);
    await repo.prefetchEvent('evt-1');
    expect(repo.findById('evt-1')?.title, 'Gone');

    client.nextGetError = const AppError(code: 'NOT_FOUND', message: 'gone');
    final bool ok = await repo.prefetchEvent('evt-1', force: true);

    expect(ok, isFalse);
    expect(repo.findById('evt-1'), isNull);
  });

  test('prefetchEvent returns false when detail json is null', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGetNull('/events/evt-2');
    final ApiEventsRepository repo = ApiEventsRepository(client: client);

    expect(await repo.prefetchEvent('evt-2'), isFalse);
  });

  test('refreshEvents with ranked query uses POST /events/search', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubPost('/events/search', <String, dynamic>{
      'data': <dynamic>[_eventJson(id: 'rank-1', title: 'Ranked')],
      'meta': <String, dynamic>{'hasMore': false, 'nextCursor': null},
      'suggestions': <String>['river'],
    });
    final ApiEventsRepository repo = ApiEventsRepository(client: client);

    await repo.refreshEvents(
      params: const EcoEventSearchParams(query: 'river'),
    );

    expect(client.postCalls, 1);
    expect(repo.events.single.title, 'Ranked');
    expect(repo.lastRankedSearchSuggestions, <String>['river']);
  });

  test('refreshEvents coalesces overlapping calls', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet('/events?limit=50', <String, dynamic>{
      'data': <dynamic>[],
      'meta': <String, dynamic>{'hasMore': false, 'nextCursor': null},
    });
    final ApiEventsRepository repo = ApiEventsRepository(client: client);

    await Future.wait(<Future<void>>[
      repo.refreshEvents(),
      repo.refreshEvents(),
    ]);

    expect(client.getCalls, 1);
  });

  test(
    'fetchEventsSnapshot returns parsed list without mutating store',
    () async {
      final _FakeApiClient client = _FakeApiClient();
      client.stubGet('/events?limit=50&q=cleanup', <String, dynamic>{
        'data': <dynamic>[_eventJson(id: 'snap-1', title: 'Snap')],
        'meta': <String, dynamic>{'hasMore': false, 'nextCursor': null},
      });
      final ApiEventsRepository repo = ApiEventsRepository(client: client);

      final List<EcoEvent> snapshot = await repo.fetchEventsSnapshot(
        const EcoEventSearchParams(query: 'cleanup'),
      );

      expect(snapshot.single.id, 'snap-1');
      expect(repo.events, isEmpty);
    },
  );

  test('prefetchEventsForSite merges site events into list', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet('/events?siteId=site-9&limit=50', <String, dynamic>{
      'data': <dynamic>[_eventJson(id: 'site-evt', title: 'At site')],
      'meta': <String, dynamic>{'hasMore': false},
    });
    final ApiEventsRepository repo = ApiEventsRepository(client: client);

    await repo.prefetchEventsForSite('site-9');

    expect(repo.findById('site-evt')?.title, 'At site');
  });

  test('fetchParticipants encodes cursor', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet(
      '/events/evt-1/participants?limit=50&cursor=pc1',
      <String, dynamic>{
        'data': <dynamic>[],
        'meta': <String, dynamic>{'hasMore': true, 'nextCursor': 'pc2'},
      },
    );
    final ApiEventsRepository repo = ApiEventsRepository(client: client);

    final EventParticipantsPage page = await repo.fetchParticipants(
      'evt-1',
      cursor: 'pc1',
    );

    expect(page.hasMore, isTrue);
    expect(client.getCalls, 1);
  });

  test('local check-in helpers no-op when event missing or unchanged', () {
    final ApiEventsRepository repo = ApiEventsRepository(
      client: _FakeApiClient(),
    );

    expect(repo.setCheckInOpen(eventId: 'missing', isOpen: true), isFalse);
    expect(
      repo.rotateCheckInSession(eventId: 'missing', sessionId: 's1'),
      isFalse,
    );
    expect(
      repo.setCheckedInCount(eventId: 'missing', checkedInCount: 1),
      isFalse,
    );
    expect(
      repo.setAttendeeCheckInStatus(
        eventId: 'missing',
        status: AttendeeCheckInStatus.checkedIn,
      ),
      isFalse,
    );
  });

  test('loadMore session-invalid failure does not mark stale cache', () async {
    final _SessionRevokedPagingClient client = _SessionRevokedPagingClient();
    final ApiEventsRepository repo = ApiEventsRepository(client: client);
    repo.loadInitialIfNeeded();
    await repo.ready;

    expect(repo.events, hasLength(1));
    expect(repo.isShowingStaleCachedEvents, isFalse);

    await expectLater(
      repo.loadMore(),
      throwsA(
        isA<AppError>().having(
          (AppError e) => e.code,
          'code',
          'SESSION_REVOKED',
        ),
      ),
    );

    expect(repo.isShowingStaleCachedEvents, isFalse);
    expect(repo.lastGlobalListLoadFailed, isFalse);
  });

  test('loadMore failure marks stale when list is non-empty', () async {
    final _PagingFakeApiClient client = _PagingFakeApiClient();
    final ApiEventsRepository repo = ApiEventsRepository(client: client);
    repo.loadInitialIfNeeded();
    await repo.ready;

    expect(repo.events, hasLength(1));
    expect(repo.hasMoreEvents, isTrue);
    expect(repo.isShowingStaleCachedEvents, isFalse);

    await expectLater(repo.loadMore(), throwsA(isA<AppError>()));

    expect(repo.events, hasLength(1));
    expect(repo.lastGlobalListLoadFailed, isTrue);
    expect(repo.isShowingStaleCachedEvents, isTrue);
  });
}

class _SessionRevokedPagingClient extends _PagingFakeApiClient {
  @override
  Future<ApiResponse> get(
    String path, {
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    if (path.contains('cursor=c2')) {
      throw const AppError(code: 'SESSION_REVOKED', message: 'revoked');
    }
    return super.get(path, cancellation: cancellation, headers: headers);
  }
}

/// First `/events?limit=50` page has more; second page request throws.
class _PagingFakeApiClient extends _FakeApiClient {
  @override
  Future<ApiResponse> get(
    String path, {
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    getCalls += 1;
    if (path.contains('cursor=c2')) {
      throw const AppError(code: 'SERVER', message: 'page failed');
    }
    if (path.startsWith('/events?limit=50')) {
      return ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'data': <dynamic>[_eventJson(id: 'evt-1', title: 'One')],
          'meta': <String, dynamic>{'hasMore': true, 'nextCursor': 'c2'},
        },
      );
    }
    return super.get(path, cancellation: cancellation, headers: headers);
  }
}
