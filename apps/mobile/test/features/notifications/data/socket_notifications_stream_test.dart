import 'dart:async';

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:feature_auth/src/domain/refresh_outcome.dart';
import 'package:feature_notifications/src/data/socket_notifications_stream.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _notificationEnvelope({
  required String id,
  int unread = 3,
}) {
  return <String, dynamic>{
    'unreadCount': unread,
    'notification': <String, dynamic>{
      'id': id,
      'title': 'Title',
      'body': 'Body',
      'type': 'SYSTEM',
      'isRead': false,
      'createdAt': '2026-05-01T12:00:00.000Z',
    },
  };
}

void main() {
  group('SocketNotificationsStream lifecycle', () {
    test('connect without auth is no-op', () {
      final SocketNotificationsStream stream = SocketNotificationsStream(
        baseUrl: 'http://localhost:3000',
        authState: AuthState(),
      );
      stream.connect();
      expect(stream.isConnected, isFalse);
      stream.dispose();
    });

    test('resume without auth is no-op', () {
      final SocketNotificationsStream stream = SocketNotificationsStream(
        baseUrl: 'http://127.0.0.1:9',
        authState: AuthState(),
      );
      expect(stream.isConnected, isFalse);
      expect(() => stream.resume(), returnsNormally);
      expect(stream.isConnected, isFalse);
      stream.dispose();
    });

    test('disconnect is idempotent', () {
      final AuthState auth = AuthState()
        ..setAuthenticated(
          userId: 'u1',
          displayName: 'Test',
          accessToken: 'tok',
        );
      final SocketNotificationsStream stream = SocketNotificationsStream(
        baseUrl: 'http://127.0.0.1:9',
        authState: auth,
      );
      expect(() => stream.disconnect(), returnsNormally);
      expect(stream.isConnected, isFalse);
      stream.dispose();
    });
  });

  group('SocketNotificationsStream payload parsing', () {
    late SocketNotificationsStream stream;

    setUp(() {
      stream = SocketNotificationsStream(
        baseUrl: 'http://localhost:3000',
        authState: AuthState(),
      );
    });

    tearDown(() => stream.dispose());

    test('notification.new emits unread count and parsed item', () async {
      final List<int> unread = <int>[];
      final List<UserNotification> items = <UserNotification>[];
      final StreamSubscription<int> unreadSub = stream.unreadCounts.listen(
        unread.add,
      );
      final StreamSubscription<UserNotification> newSub = stream
          .newNotifications
          .listen(items.add);

      stream.dispatchNotificationNewForTest(_notificationEnvelope(id: 'n1'));

      await Future<void>.delayed(Duration.zero);
      expect(unread, <int>[3]);
      expect(items.single.id, 'n1');

      await unreadSub.cancel();
      await newSub.cancel();
    });

    test('notification.updated emits unread and updated item', () async {
      final List<UserNotification> updated = <UserNotification>[];
      final StreamSubscription<UserNotification> sub = stream
          .updatedNotifications
          .listen(updated.add);

      stream.dispatchNotificationUpdatedForTest(
        _notificationEnvelope(id: 'n2', unread: 1),
      );

      await Future<void>.delayed(Duration.zero);
      expect(updated.single.id, 'n2');
      await sub.cancel();
    });

    test('unread-only payloads accept list wrapper', () async {
      final List<int> unread = <int>[];
      final StreamSubscription<int> sub = stream.unreadCounts.listen(
        unread.add,
      );

      stream.dispatchUnreadPayloadForTest(<dynamic>[
        <String, dynamic>{'unreadCount': 9},
      ]);

      await Future<void>.delayed(Duration.zero);
      expect(unread, <int>[9]);
      await sub.cancel();
    });

    test('malformed payloads are ignored without throwing', () {
      expect(
        () => stream.dispatchNotificationNewForTest('not-a-map'),
        returnsNormally,
      );
      expect(() => stream.dispatchUnreadPayloadForTest(null), returnsNormally);
    });
  });

  group('SocketNotificationsStream AUTH_FAILED', () {
    test('serverRejected invokes onAuthRejected', () async {
      var rejected = 0;
      final AuthState auth = AuthState()
        ..setAuthenticated(
          userId: 'u1',
          displayName: 'Test',
          accessToken: 'tok',
        );
      final SocketNotificationsStream stream = SocketNotificationsStream(
        baseUrl: 'http://localhost:3000',
        authState: auth,
        sessionRefresh: () async => RefreshOutcome.serverRejected,
        onAuthRejected: () => rejected += 1,
      );

      await stream.handleAuthFailedForTest();

      expect(rejected, 1);
      expect(stream.isConnected, isFalse);
      stream.dispose();
    });

    test('auth failed without refresh hook disconnects', () async {
      final AuthState auth = AuthState()
        ..setAuthenticated(
          userId: 'u1',
          displayName: 'Test',
          accessToken: 'tok',
        );
      final SocketNotificationsStream stream = SocketNotificationsStream(
        baseUrl: 'http://localhost:3000',
        authState: auth,
      );

      await stream.handleAuthFailedForTest();

      expect(stream.isConnected, isFalse);
      stream.dispose();
    });

    test('transient disconnects without onAuthRejected', () async {
      var rejected = 0;
      final AuthState auth = AuthState()
        ..setAuthenticated(
          userId: 'u1',
          displayName: 'Test',
          accessToken: 'tok',
        );
      final SocketNotificationsStream stream = SocketNotificationsStream(
        baseUrl: 'http://localhost:3000',
        authState: auth,
        sessionRefresh: () async => RefreshOutcome.transient,
        onAuthRejected: () => rejected += 1,
      );

      await stream.handleAuthFailedForTest();

      expect(rejected, 0);
      expect(stream.isConnected, isFalse);
      stream.dispose();
    });
  });
}
