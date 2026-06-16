import 'dart:typed_data';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/network/request_cancellation.dart';
import 'package:feature_events/src/data/chat/api_event_chat_repository.dart';
import 'package:feature_events/src/data/chat/event_chat_fetch_result.dart';
import 'package:feature_events/src/data/chat/event_chat_message.dart';
import 'package:feature_events/src/data/chat/event_chat_participants.dart';
import 'package:feature_events/src/data/chat/event_chat_read_cursor.dart';
import 'package:feature_events/src/data/chat/event_chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient()
    : super(
        config: AppConfig.dev,
        accessToken: () => null,
        onUnauthorized: (_) {},
      );

  final Map<String, ApiResponse> _getResponses = <String, ApiResponse>{};
  final Map<String, ApiResponse> _postResponses = <String, ApiResponse>{};
  final Map<String, ApiResponse> _patchResponses = <String, ApiResponse>{};
  final Map<String, ApiResponse> _putResponses = <String, ApiResponse>{};
  final Map<String, ApiResponse> _multipartResponses = <String, ApiResponse>{};
  AppError? nextGetError;
  AppError? nextPostError;

  void stubGet(String path, Map<String, dynamic> json, {int statusCode = 200}) {
    _getResponses[path] = ApiResponse(statusCode: statusCode, json: json);
  }

  void stubGetNull(String path) {
    _getResponses[path] = const ApiResponse(statusCode: 200, json: null);
  }

  void stubPost(String path, Map<String, dynamic> json) {
    _postResponses[path] = ApiResponse(statusCode: 200, json: json);
  }

  void stubPatch(String path, Map<String, dynamic> json) {
    _patchResponses[path] = ApiResponse(statusCode: 200, json: json);
  }

  void stubPut(String path) {
    _putResponses[path] = const ApiResponse(statusCode: 200, json: null);
  }

  void stubMultipart(String path, Map<String, dynamic> json) {
    _multipartResponses[path] = ApiResponse(statusCode: 200, json: json);
  }

  @override
  Future<ApiResponse> get(
    String path, {
    RequestCancellationToken? cancellation,
    Map<String, String>? headers,
  }) async {
    if (nextGetError != null) {
      throw nextGetError!;
    }
    final ApiResponse? response = _getResponses[path];
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
    if (nextPostError != null) {
      throw nextPostError!;
    }
    final ApiResponse? response = _postResponses[path];
    if (response == null) {
      throw const AppError(code: 'NOT_FOUND', message: 'missing stub');
    }
    return response;
  }

  @override
  Future<ApiResponse> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final ApiResponse? response = _patchResponses[path];
    if (response == null) {
      throw const AppError(code: 'NOT_FOUND', message: 'missing stub');
    }
    return response;
  }

  @override
  Future<ApiResponse> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final ApiResponse? response = _putResponses[path];
    if (response == null) {
      throw const AppError(code: 'NOT_FOUND', message: 'missing stub');
    }
    return response;
  }

  @override
  Future<ApiResponse> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    return const ApiResponse(statusCode: 204, json: null);
  }

  @override
  Future<ApiResponse> multipartPost(
    String path, {
    required List<MultipartFileData> files,
    Map<String, String>? fields,
    void Function(int sent, int total)? onSendProgress,
    bool Function()? isCancelled,
    Duration? timeout,
  }) async {
    final ApiResponse? response = _multipartResponses[path];
    if (response == null) {
      throw const AppError(code: 'NOT_FOUND', message: 'missing stub');
    }
    return response;
  }
}

Map<String, dynamic> _chatMessageJson({
  required String id,
  String eventId = 'evt-1',
  String body = 'Hello',
}) {
  return <String, dynamic>{
    'id': id,
    'eventId': eventId,
    'createdAt': '2026-01-01T00:00:00.000Z',
    'body': body,
    'isDeleted': false,
    'author': <String, dynamic>{'id': 'author-1', 'displayName': 'Pat'},
  };
}

ApiEventChatRepository _repo(_FakeApiClient client, {AuthState? auth}) {
  final AuthState authState = auth ?? AuthState();
  authState.setAuthenticated(userId: 'viewer-1', displayName: 'Viewer');
  return ApiEventChatRepository(
    client: client,
    config: AppConfig.dev,
    authState: authState,
  );
}

void main() {
  group('fetchMessages', () {
    test('parses list with cursor and marks own messages', () async {
      final _FakeApiClient client = _FakeApiClient();
      client.stubGet('/events/evt-1/chat?limit=50', <String, dynamic>{
        'data': <dynamic>[
          _chatMessageJson(id: 'm1'),
          <String, dynamic>{
            'id': 'm2',
            'eventId': 'evt-1',
            'createdAt': '2026-01-02T00:00:00.000Z',
            'body': 'Mine',
            'isDeleted': false,
            'author': <String, dynamic>{
              'id': 'viewer-1',
              'displayName': 'Viewer',
            },
          },
        ],
        'meta': <String, dynamic>{'hasMore': true, 'nextCursor': 'c2'},
      });
      final ApiEventChatRepository repo = _repo(client);

      final EventChatFetchResult result = await repo.fetchMessages('evt-1');

      expect(result.messages, hasLength(2));
      expect(result.messages.first.isOwnMessage, isFalse);
      expect(result.messages.last.isOwnMessage, isTrue);
      expect(result.hasMore, isTrue);
      expect(result.nextCursor, 'c2');
    });

    test('encodes cursor in query', () async {
      final _FakeApiClient client = _FakeApiClient();
      client.stubGet(
        '/events/evt-1/chat?limit=20&cursor=abc%2F2',
        <String, dynamic>{
          'data': <dynamic>[],
          'meta': <String, dynamic>{'hasMore': false},
        },
      );
      final ApiEventChatRepository repo = _repo(client);

      await repo.fetchMessages('evt-1', cursor: 'abc/2', limit: 20);
    });

    test('throws validation when json is null', () async {
      final _FakeApiClient client = _FakeApiClient();
      client.stubGetNull('/events/evt-1/chat?limit=50');
      final ApiEventChatRepository repo = _repo(client);

      await expectLater(
        repo.fetchMessages('evt-1'),
        throwsA(
          isA<AppError>().having(
            (AppError e) => e.code,
            'code',
            'VALIDATION_ERROR',
          ),
        ),
      );
    });

    test('throws validation when data is not a list', () async {
      final _FakeApiClient client = _FakeApiClient();
      client.stubGet('/events/evt-1/chat?limit=50', <String, dynamic>{
        'data': <String, dynamic>{},
      });
      final ApiEventChatRepository repo = _repo(client);

      await expectLater(
        repo.fetchMessages('evt-1'),
        throwsA(
          isA<AppError>().having(
            (AppError e) => e.code,
            'code',
            'VALIDATION_ERROR',
          ),
        ),
      );
    });
  });

  group('searchMessages', () {
    test('parses search hits and encodes query', () async {
      final _FakeApiClient client = _FakeApiClient();
      client.stubGet(
        '/events/evt-1/chat/search?limit=20&q=river',
        <String, dynamic>{
          'data': <dynamic>[_chatMessageJson(id: 'hit-1')],
          'meta': <String, dynamic>{'hasMore': false},
        },
      );
      final ApiEventChatRepository repo = _repo(client);

      final EventChatFetchResult result = await repo.searchMessages(
        'evt-1',
        'river',
      );

      expect(result.messages.single.id, 'hit-1');
    });

    test('throws when search response json is null', () async {
      final _FakeApiClient client = _FakeApiClient();
      client.stubGetNull('/events/evt-1/chat/search?limit=20&q=hi');
      final ApiEventChatRepository repo = _repo(client);

      await expectLater(
        repo.searchMessages('evt-1', 'hi'),
        throwsA(
          isA<AppError>().having(
            (AppError e) => e.code,
            'code',
            'VALIDATION_ERROR',
          ),
        ),
      );
    });
  });

  test('fetchPinnedMessages returns parsed messages', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet('/events/evt-1/chat/pinned', <String, dynamic>{
      'data': <dynamic>[_chatMessageJson(id: 'pin-1')],
    });
    final ApiEventChatRepository repo = _repo(client);

    final List<EventChatMessage> pinned = await repo.fetchPinnedMessages(
      'evt-1',
    );

    expect(pinned.single.id, 'pin-1');
  });

  test('sendMessage posts payload and parses response', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubPost('/events/evt-1/chat', <String, dynamic>{
      'data': <String, dynamic>{
        ..._chatMessageJson(id: 'sent-1', body: 'Posted'),
        'author': <String, dynamic>{'id': 'viewer-1', 'displayName': 'Viewer'},
      },
    });
    final ApiEventChatRepository repo = _repo(client);

    final EventChatMessage sent = await repo.sendMessage(
      'evt-1',
      'Posted',
      clientMessageId: 'client-1',
      replyToId: 'm0',
      locationLat: 41,
      locationLng: 21,
      locationLabel: 'Skopje',
    );

    expect(sent.id, 'sent-1');
    expect(sent.isOwnMessage, isTrue);
  });

  test('editMessage patches body and parses response', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubPatch('/events/evt-1/chat/m1', <String, dynamic>{
      'data': _chatMessageJson(id: 'm1', body: 'Edited'),
    });
    final ApiEventChatRepository repo = _repo(client);

    final EventChatMessage edited = await repo.editMessage(
      'evt-1',
      'm1',
      'Edited',
    );

    expect(edited.body, 'Edited');
  });

  test('setPin posts pinned flag', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubPost('/events/evt-1/chat/m1/pin', <String, dynamic>{
      'data': _chatMessageJson(id: 'm1'),
    });
    final ApiEventChatRepository repo = _repo(client);

    final EventChatMessage pinned = await repo.setPin(
      'evt-1',
      'm1',
      pinned: true,
    );

    expect(pinned.id, 'm1');
  });

  test('deleteMessage completes without error', () async {
    final ApiEventChatRepository repo = _repo(_FakeApiClient());
    await expectLater(repo.deleteMessage('evt-1', 'm1'), completes);
  });

  test('markRead returns parsed result', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubPatch('/events/evt-1/chat/read', <String, dynamic>{
      'meta': <String, dynamic>{'unreadCount': 2},
    });
    final ApiEventChatRepository repo = _repo(client);

    final result = await repo.markRead('evt-1', 'm9');

    expect(result?.unreadCount, 2);
  });

  test('fetchUnreadCount coerces num count', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet('/events/evt-1/chat/unread-count', <String, dynamic>{
      'data': <String, dynamic>{'count': 3.0},
    });
    final ApiEventChatRepository repo = _repo(client);

    expect(await repo.fetchUnreadCount('evt-1'), 3);
  });

  test('fetchUnreadCount returns zero for missing count', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet('/events/evt-1/chat/unread-count', <String, dynamic>{
      'data': <String, dynamic>{},
    });
    final ApiEventChatRepository repo = _repo(client);

    expect(await repo.fetchUnreadCount('evt-1'), 0);
  });

  test('fetchMuteStatus and setMuteStatus', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet('/events/evt-1/chat/mute', <String, dynamic>{
      'data': <String, dynamic>{'muted': true},
    });
    client.stubPut('/events/evt-1/chat/mute');
    final ApiEventChatRepository repo = _repo(client);

    expect(await repo.fetchMuteStatus('evt-1'), isTrue);
    await expectLater(repo.setMuteStatus('evt-1', false), completes);
  });

  test('fetchParticipants parses count and previews', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet('/events/evt-1/chat/participants', <String, dynamic>{
      'data': <String, dynamic>{
        'count': 2,
        'participants': <dynamic>[
          <String, dynamic>{
            'id': 'u1',
            'displayName': 'One',
            'avatarUrl': 'https://cdn/a.webp',
          },
          <String, dynamic>{'id': 'bad'},
        ],
      },
    });
    final ApiEventChatRepository repo = _repo(client);

    final EventChatParticipantsResult result = await repo.fetchParticipants(
      'evt-1',
    );

    expect(result.count, 2);
    expect(result.participants, hasLength(1));
    expect(result.participants.single.displayName, 'One');
  });

  test('fetchReadCursors skips invalid rows', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubGet('/events/evt-1/chat/read-cursors', <String, dynamic>{
      'data': <String, dynamic>{
        'cursors': <dynamic>[
          <String, dynamic>{
            'userId': 'u1',
            'displayName': 'One',
            'lastReadMessageId': 'm1',
          },
          <String, dynamic>{'userId': 'x'},
        ],
      },
    });
    final ApiEventChatRepository repo = _repo(client);

    final List<EventChatReadCursor> cursors = await repo.fetchReadCursors(
      'evt-1',
    );

    expect(cursors, hasLength(1));
    expect(cursors.single.userId, 'u1');
  });

  test('uploadAttachments parses attachment list', () async {
    final _FakeApiClient client = _FakeApiClient();
    client.stubMultipart('/events/evt-1/chat/upload', <String, dynamic>{
      'data': <dynamic>[
        <String, dynamic>{
          'url': 'https://cdn/f.webp',
          'mimeType': 'image/webp',
          'fileName': 'f.webp',
          'sizeBytes': 100,
        },
      ],
    });
    final ApiEventChatRepository repo = _repo(client);

    final List<EventChatAttachment> attachments = await repo.uploadAttachments(
      'evt-1',
      <UploadableFile>[
        UploadableFile(
          bytes: Uint8List.fromList(<int>[1, 2]),
          fileName: 'f.webp',
          mimeType: 'image/webp',
        ),
      ],
    );

    expect(attachments.single.url, 'https://cdn/f.webp');
  });

  test('setTyping swallows REST errors', () async {
    final _FakeApiClient client = _FakeApiClient()
      ..nextPostError = AppError.network();
    final ApiEventChatRepository repo = _repo(client);

    await expectLater(repo.setTyping('evt-1', typing: true), completes);
  });
}
