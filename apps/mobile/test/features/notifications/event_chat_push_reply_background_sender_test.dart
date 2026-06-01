import 'dart:convert';

import 'package:feature_notifications/src/data/event_chat_push_reply_background_sender.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('trySend returns false when access token missing', () async {
    final bool sent = await EventChatPushReplyBackgroundSender.trySend(
      eventId: 'evt-1',
      body: 'hello',
    );

    expect(sent, isFalse);
  });

  test('trySend posts chat message and patches read on success', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'chisto_access_token': 'test-token',
    });

    final List<String> methods = <String>[];
    final List<String> paths = <String>[];

    final bool sent = await http.runWithClient(
      () {
        return EventChatPushReplyBackgroundSender.trySend(
          eventId: 'evt-42',
          body: '  inline reply  ',
        );
      },
      () => MockClient((http.Request request) async {
        methods.add(request.method);
        paths.add(request.url.path);
        expect(request.headers['Authorization'], 'Bearer test-token');

        if (request.method == 'POST' &&
            request.url.path == '/events/evt-42/chat') {
          final Map<String, dynamic> body =
              jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['body'], '  inline reply  ');
          expect(body['clientMessageId'], isNotEmpty);
          return http.Response(
            jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{'id': 'msg-sent-1'},
            }),
            201,
          );
        }
        if (request.method == 'PATCH' &&
            request.url.path == '/events/evt-42/chat/read') {
          final Map<String, dynamic> body =
              jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['lastReadMessageId'], 'msg-sent-1');
          return http.Response('', 204);
        }
        return http.Response('not found', 404);
      }),
    );

    expect(sent, isTrue);
    expect(methods, <String>['POST', 'PATCH']);
    expect(paths, <String>['/events/evt-42/chat', '/events/evt-42/chat/read']);
  });

  test('trySend returns false on non-2xx chat response', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'chisto_access_token': 'test-token',
    });

    final bool sent = await http.runWithClient(
      () {
        return EventChatPushReplyBackgroundSender.trySend(
          eventId: 'evt-99',
          body: 'fail',
        );
      },
      () => MockClient((http.Request request) async {
        return http.Response('bad request', 400);
      }),
    );

    expect(sent, isFalse);
  });

  test(
    'trySend succeeds without read patch when response has no message id',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'chisto_access_token': 'test-token',
      });

      final bool sent = await http.runWithClient(
        () {
          return EventChatPushReplyBackgroundSender.trySend(
            eventId: 'evt-7',
            body: 'ok',
          );
        },
        () => MockClient((http.Request request) async {
          if (request.method == 'POST') {
            return http.Response(jsonEncode(<String, dynamic>{}), 200);
          }
          fail('read patch should not run without message id');
        }),
      );

      expect(sent, isTrue);
    },
  );

  test('trySend parses top-level id when data wrapper missing', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'chisto_access_token': 'test-token',
    });

    int patchCalls = 0;

    final bool sent = await http.runWithClient(
      () {
        return EventChatPushReplyBackgroundSender.trySend(
          eventId: 'evt-8',
          body: 'legacy',
        );
      },
      () => MockClient((http.Request request) async {
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode(<String, dynamic>{'id': 'legacy-msg-id'}),
            200,
          );
        }
        if (request.method == 'PATCH') {
          patchCalls++;
          return http.Response('', 204);
        }
        return http.Response('', 404);
      }),
    );

    expect(sent, isTrue);
    expect(patchCalls, 1);
  });
}
