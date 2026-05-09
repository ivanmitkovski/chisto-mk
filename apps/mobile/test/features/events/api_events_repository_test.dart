import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/network/request_cancellation.dart';
import 'package:chisto_mobile/features/events/data/api_events_repository.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_search_params.dart';
import 'package:chisto_mobile/features/events/domain/models/event_participant_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
      : super(
          config: AppConfig.dev,
          accessToken: () => null,
          onUnauthorized: () {},
        );

  int getCalls = 0;
  final Map<String, ApiResponse> _responses = <String, ApiResponse>{};

  void stubGet(String path, Map<String, dynamic> json) {
    _responses[path] = ApiResponse(
      statusCode: 200,
      json: json,
    );
  }

  @override
  Future<ApiResponse> get(
    String path, {
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    getCalls += 1;
    final ApiResponse? response = _responses[path];
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
    client.stubGet('/events/evt-1', _eventJson(id: 'evt-1', title: 'Event One'));
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

  test('fetchParticipants GETs participants endpoint and parses page', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet(
      '/events/evt-1/participants?limit=50',
      <String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'userId': 'u1',
            'displayName': 'Test User',
            'joinedAt': '2026-01-02T12:00:00.000Z',
            'avatarUrl': 'https://cdn.example/a.webp',
          },
        ],
        'meta': <String, dynamic>{
          'hasMore': false,
          'nextCursor': null,
        },
      },
    );
    final ApiEventsRepository repo = ApiEventsRepository(client: client);

    final EventParticipantsPage page = await repo.fetchParticipants('evt-1');

    expect(page.items, hasLength(1));
    expect(page.items.single.userId, 'u1');
    expect(page.items.single.avatarUrl, 'https://cdn.example/a.webp');
    expect(page.hasMore, isFalse);
    expect(client.getCalls, 1);
  });

  test('refreshEvents encodes multiple categories as comma-separated sorted keys', () async {
    final _FakeApiClient client = _FakeApiClient();
    final String expectedPath =
        '/events?limit=50&category=${Uri.encodeQueryComponent('riverAndLake,treeAndGreen')}';
    client.stubGet(
      expectedPath,
      <String, dynamic>{
        'data': <dynamic>[],
        'meta': <String, dynamic>{
          'hasMore': false,
          'nextCursor': null,
        },
      },
    );
    final ApiEventsRepository repo = ApiEventsRepository(client: client);
    await repo.refreshEvents(
      params: EcoEventSearchParams(
        categories: <EcoEventCategory>{
          EcoEventCategory.treeAndGreen,
          EcoEventCategory.riverAndLake,
        },
      ),
    );
    expect(client.getCalls, 1);
  });

  test('refreshEvents includes user location hint when available', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet(
      '/events?limit=50&lat=41.997300&lng=21.428000',
      <String, dynamic>{
        'data': <dynamic>[],
        'meta': <String, dynamic>{
          'hasMore': false,
          'nextCursor': null,
        },
      },
    );
    final ApiEventsRepository repo = ApiEventsRepository(client: client);
    repo.setUserLocationHint(latitude: 41.9973, longitude: 21.4280);
    await repo.refreshEvents();
    expect(client.getCalls, 1);
  });

  test('bootstrap loads global list without lifecycle filter', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet(
      '/events?limit=50',
      <String, dynamic>{
        'data': <dynamic>[_eventJson(id: 'evt-list', title: 'Listed')],
        'meta': <String, dynamic>{
          'hasMore': false,
          'nextCursor': null,
        },
      },
    );
    final ApiEventsRepository repo = ApiEventsRepository(client: client);
    repo.loadInitialIfNeeded();
    await repo.ready;
    expect(repo.events, hasLength(1));
    expect(repo.findById('evt-list')?.title, 'Listed');
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

    await expectLater(
      repo.loadMore(),
      throwsA(isA<AppError>()),
    );

    expect(repo.events, hasLength(1));
    expect(repo.lastGlobalListLoadFailed, isTrue);
    expect(repo.isShowingStaleCachedEvents, isTrue);
  });
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
          'meta': <String, dynamic>{
            'hasMore': true,
            'nextCursor': 'c2',
          },
        },
      );
    }
    return super.get(path, cancellation: cancellation, headers: headers);
  }
}
