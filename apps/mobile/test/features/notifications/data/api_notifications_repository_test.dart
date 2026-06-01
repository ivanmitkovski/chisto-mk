import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:feature_notifications/src/data/api_notifications_repository.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: AppConfig.dev,
        accessToken: () => null,
        onUnauthorized: () {},
      );

  final List<String> getPaths = <String>[];
  final List<String> patchPaths = <String>[];
  final List<String> postPaths = <String>[];
  final List<Object?> patchBodies = <Object?>[];
  final List<Object?> postBodies = <Object?>[];
  final Map<String, ApiResponse> _responses = <String, ApiResponse>{};

  void stub(String methodPath, ApiResponse response) {
    _responses[methodPath] = response;
  }

  ApiResponse _lookup(String verbPath) {
    final ApiResponse? response = _responses[verbPath];
    if (response == null) {
      throw StateError('missing stub for $verbPath');
    }
    return response;
  }

  @override
  Future<ApiResponse> get(
    String path, {
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    getPaths.add(path);
    return _lookup('GET $path');
  }

  @override
  Future<ApiResponse> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) async {
    patchPaths.add(path);
    patchBodies.add(body);
    return _lookup('PATCH $path');
  }

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    RequestCancellationToken? cancellation,
  }) async {
    postPaths.add(path);
    postBodies.add(body);
    return _lookup('POST $path');
  }
}

Map<String, dynamic> _notificationJson({required String id}) {
  return <String, dynamic>{
    'id': id,
    'title': 'Title $id',
    'body': 'Body $id',
    'type': 'SYSTEM',
    'isRead': false,
    'createdAt': '2026-05-01T12:00:00.000Z',
  };
}

void main() {
  late _FakeApiClient client;
  late ApiNotificationsRepository repo;

  setUp(() {
    client = _FakeApiClient();
    repo = ApiNotificationsRepository(client: client);
  });

  test('getNotifications parses list and meta defaults', () async {
    client.stub(
      'GET /notifications?page=1&limit=20',
      ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'data': <dynamic>[_notificationJson(id: 'n1')],
          'meta': <String, dynamic>{
            'total': 5,
            'unreadCount': 2,
            'page': 1,
            'limit': 20,
          },
        },
      ),
    );

    final result = await repo.getNotifications();

    expect(result.notifications, hasLength(1));
    expect(result.total, 5);
    expect(result.unreadCount, 2);
  });

  test('getNotifications onlyUnread adds query flag', () async {
    client.stub(
      'GET /notifications?page=2&limit=10&onlyUnread=true',
      ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'data': <dynamic>[],
          'meta': <String, dynamic>{},
        },
      ),
    );

    await repo.getNotifications(page: 2, limit: 10, onlyUnread: true);

    expect(client.getPaths.single, contains('onlyUnread=true'));
  });

  test('getUnreadCount reads unreadCount field', () async {
    client.stub(
      'GET /notifications/unread-count',
      ApiResponse(statusCode: 200, json: <String, dynamic>{'unreadCount': 7}),
    );

    expect(await repo.getUnreadCount(), 7);
  });

  test('markAsRead PATCHes read endpoint', () async {
    client.stub(
      'PATCH /notifications/n1/read',
      const ApiResponse(statusCode: 200, json: null),
    );

    await repo.markAsRead('n1');
    expect(client.patchPaths.single, '/notifications/n1/read');
  });

  test('markAllAsRead PATCHes read-all', () async {
    client.stub(
      'PATCH /notifications/read-all',
      const ApiResponse(statusCode: 200, json: null),
    );

    await repo.markAllAsRead();
    expect(client.patchPaths.single, '/notifications/read-all');
  });

  test('recordOpened POSTs opened endpoint', () async {
    client.stub(
      'POST /notifications/n1/opened',
      const ApiResponse(statusCode: 200, json: null),
    );

    await repo.recordOpened('n1');
    expect(client.postPaths.single, '/notifications/n1/opened');
  });

  test('getPreferences maps preference rows', () async {
    client.stub(
      'GET /notifications/preferences',
      ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{
          'data': <dynamic>[
            <String, dynamic>{
              'type': 'EVENT_CHAT',
              'muted': true,
              'mutedUntil': '2026-12-01T00:00:00.000Z',
            },
          ],
        },
      ),
    );

    final List<NotificationPreference> prefs = await repo.getPreferences();

    expect(prefs.single.type, UserNotificationType.eventChat);
    expect(prefs.single.muted, isTrue);
    expect(prefs.single.mutedUntil, isNotNull);
  });

  test('setPreference PATCHes type-specific path', () async {
    client.stub(
      'PATCH /notifications/preferences/EVENT_CHAT',
      ApiResponse(
        statusCode: 200,
        json: <String, dynamic>{'type': 'EVENT_CHAT', 'muted': false},
      ),
    );

    final NotificationPreference pref = await repo.setPreference(
      type: UserNotificationType.eventChat,
      muted: false,
    );

    expect(pref.muted, isFalse);
    expect(client.patchPaths.single, '/notifications/preferences/EVENT_CHAT');
  });

  test('registerDeviceToken POSTs device payload', () async {
    client.stub(
      'POST /notifications/devices',
      const ApiResponse(statusCode: 200, json: null),
    );

    await repo.registerDeviceToken(
      token: 'fcm-token',
      platform: 'ios',
      appVersion: '1.2.3',
      locale: 'mk',
    );

    expect(client.postPaths.single, '/notifications/devices');
    expect(client.postBodies.single, isA<Map<String, dynamic>>());
    final Map<String, dynamic> body =
        client.postBodies.single! as Map<String, dynamic>;
    expect(body['token'], 'fcm-token');
    expect(body['locale'], 'mk');
  });

  test('unregisterDeviceToken POSTs unregister body', () async {
    client.stub(
      'POST /notifications/devices/unregister',
      const ApiResponse(statusCode: 200, json: null),
    );

    await repo.unregisterDeviceToken('old-token');

    expect(
      (client.postBodies.single! as Map<String, dynamic>)['token'],
      'old-token',
    );
  });

  test('markAsUnread and archiveNotification PATCH correct paths', () async {
    client.stub(
      'PATCH /notifications/n9/unread',
      const ApiResponse(statusCode: 200, json: null),
    );
    client.stub(
      'PATCH /notifications/n9/archive',
      const ApiResponse(statusCode: 200, json: null),
    );

    await repo.markAsUnread('n9');
    await repo.archiveNotification('n9');

    expect(client.patchPaths, <String>[
      '/notifications/n9/unread',
      '/notifications/n9/archive',
    ]);
  });

  test('archiveAllRead PATCHes archive-all-read', () async {
    client.stub(
      'PATCH /notifications/archive-all-read',
      const ApiResponse(statusCode: 200, json: null),
    );

    await repo.archiveAllRead();
    expect(client.patchPaths.single, '/notifications/archive-all-read');
  });
}
