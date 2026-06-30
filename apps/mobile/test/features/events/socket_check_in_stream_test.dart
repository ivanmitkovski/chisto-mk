import 'dart:async';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:feature_events/src/data/socket_check_in_stream.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SocketCheckInStream lifecycle', () {
    test('starts disconnected and dispose is idempotent', () {
      final AuthState auth = AuthState();
      final SocketCheckInStream stream = SocketCheckInStream(
        baseUrl: 'http://localhost:3000',
        authState: auth,
      );
      expect(stream.connectionStatus, CheckInWsConnectionStatus.disconnected);
      stream.dispose();
      expect(stream.dispose, returnsNormally);
    });

    test('connect without token does not crash', () {
      final AuthState auth = AuthState();
      final SocketCheckInStream stream = SocketCheckInStream(
        baseUrl: 'http://localhost:3000/',
        authState: auth,
      );
      stream.connect('evt-1');
      expect(stream.connectionStatus, CheckInWsConnectionStatus.disconnected);
      stream.dispose();
    });

    test('stream replays last connection status to new listeners', () async {
      final AuthState auth = AuthState()
        ..setAuthenticated(
          userId: 'u1',
          displayName: 'Test',
          accessToken: 'tok',
        );
      final SocketCheckInStream stream = SocketCheckInStream(
        baseUrl: 'http://127.0.0.1:9',
        authState: auth,
      );
      stream.setCurrentEventIdForTest('evt-1');

      final List<CheckInStreamEvent> events = <CheckInStreamEvent>[];
      final StreamSubscription<CheckInStreamEvent> sub = stream.stream.listen(
        events.add,
      );
      await Future<void>.delayed(Duration.zero);
      expect(events, isNotEmpty);
      expect(events.last, isA<CheckInConnectionChanged>());
      await sub.cancel();
      stream.dispose();
    });

    test('auth token cleared disconnects', () {
      final AuthState auth = AuthState()
        ..setAuthenticated(
          userId: 'u1',
          displayName: 'Test',
          accessToken: 'tok',
        );
      final SocketCheckInStream stream = SocketCheckInStream(
        baseUrl: 'http://127.0.0.1:9',
        authState: auth,
      );
      stream.setCurrentEventIdForTest('evt-1');

      auth.setUnauthenticated();

      expect(stream.connectionStatus, CheckInWsConnectionStatus.disconnected);
      stream.dispose();
    });
  });

  group('SocketCheckInStream payload parsing', () {
    late SocketCheckInStream stream;

    setUp(() {
      final AuthState auth = AuthState()
        ..setAuthenticated(
          userId: 'u1',
          displayName: 'Test',
          accessToken: 'tok',
        );
      stream = SocketCheckInStream(
        baseUrl: 'http://localhost:3000',
        authState: auth,
      );
      stream.setCurrentEventIdForTest('evt-1');
    });

    tearDown(() => stream.dispose());

    test('checkin:request parses full payload including avatar', () async {
      final List<CheckInStreamEvent> events = <CheckInStreamEvent>[];
      final StreamSubscription<CheckInStreamEvent> sub = stream.stream.listen(
        events.add,
      );

      stream.injectSocketEventForTest('checkin:request', <String, dynamic>{
        'pendingId': 'p1',
        'eventId': 'evt-1',
        'userId': 'u2',
        'firstName': 'Ana',
        'lastName': 'K',
        'expiresAt': '2026-06-15T12:00:00.000Z',
        'avatarUrl': ' https://cdn.example/a.webp ',
      });

      await Future<void>.delayed(Duration.zero);
      expect(events.whereType<CheckInRequestEvent>(), hasLength(1));
      final CheckInRequestEvent req = events
          .whereType<CheckInRequestEvent>()
          .single;
      expect(req.pendingId, 'p1');
      expect(req.avatarUrl, 'https://cdn.example/a.webp');
      await sub.cancel();
    });

    test('checkin:request drops wrong eventId when room is set', () async {
      final List<CheckInStreamEvent> events = <CheckInStreamEvent>[];
      final StreamSubscription<CheckInStreamEvent> sub = stream.stream.listen(
        events.add,
      );

      stream.injectSocketEventForTest('checkin:request', <String, dynamic>{
        'pendingId': 'p1',
        'eventId': 'other-event',
        'userId': 'u2',
        'firstName': 'Ana',
        'lastName': 'K',
        'expiresAt': '2026-06-15T12:00:00.000Z',
      });

      await Future<void>.delayed(Duration.zero);
      expect(events.whereType<CheckInRequestEvent>(), isEmpty);
      await sub.cancel();
    });

    test('checkin:request ignores incomplete payloads', () async {
      final List<CheckInStreamEvent> events = <CheckInStreamEvent>[];
      final StreamSubscription<CheckInStreamEvent> sub = stream.stream.listen(
        events.add,
      );

      stream.injectSocketEventForTest('checkin:request', <String, dynamic>{
        'pendingId': 'p1',
        'eventId': 'evt-1',
      });
      stream.injectSocketEventForTest('checkin:request', <dynamic>[
        <String, dynamic>{'bad': true},
      ]);

      await Future<void>.delayed(Duration.zero);
      expect(events.whereType<CheckInRequestEvent>(), isEmpty);
      await sub.cancel();
    });

    test('checkin:confirmed parses points and displayName', () async {
      final List<CheckInStreamEvent> events = <CheckInStreamEvent>[];
      final StreamSubscription<CheckInStreamEvent> sub = stream.stream.listen(
        events.add,
      );

      stream.injectSocketEventForTest('checkin:confirmed', <String, dynamic>{
        'pendingId': 'p1',
        'eventId': 'evt-1',
        'userId': 'u2',
        'checkedInAt': '2026-06-15T12:01:00.000Z',
        'pointsAwarded': 15,
        'displayName': 'Ana K',
      });

      await Future<void>.delayed(Duration.zero);
      final CheckInConfirmedEvent ev = events
          .whereType<CheckInConfirmedEvent>()
          .single;
      expect(ev.pointsAwarded, 15);
      expect(ev.displayName, 'Ana K');
      await sub.cancel();
    });

    test('checkin:rejected emits rejection event', () async {
      final List<CheckInStreamEvent> events = <CheckInStreamEvent>[];
      final StreamSubscription<CheckInStreamEvent> sub = stream.stream.listen(
        events.add,
      );

      stream.injectSocketEventForTest('checkin:rejected', <String, dynamic>{
        'pendingId': 'p9',
        'eventId': 'evt-1',
        'userId': 'u3',
      });

      await Future<void>.delayed(Duration.zero);
      expect(events.whereType<CheckInRejectedEvent>().single.pendingId, 'p9');
      await sub.cancel();
    });

    test('AUTH_FAILED error sets disconnected', () async {
      final List<CheckInStreamEvent> events = <CheckInStreamEvent>[];
      final StreamSubscription<CheckInStreamEvent> sub = stream.stream.listen(
        events.add,
      );

      stream.injectSocketEventForTest('error', <String, String>{
        'code': 'AUTH_FAILED',
      });

      await Future<void>.delayed(Duration.zero);
      expect(stream.connectionStatus, CheckInWsConnectionStatus.disconnected);
      expect(
        events.whereType<CheckInConnectionChanged>().last.status,
        CheckInWsConnectionStatus.disconnected,
      );
      await sub.cancel();
    });
  });
}
