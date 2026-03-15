import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthState', () {
    late AuthState authState;

    setUp(() {
      authState = AuthState();
    });

    test('initial status is unknown', () {
      expect(authState.status, equals(AuthStatus.unknown));
      expect(authState.userId, isNull);
      expect(authState.displayName, isNull);
      expect(authState.accessToken, isNull);
      expect(authState.isAuthenticated, isFalse);
    });

    test('setAuthenticated updates status, userId, displayName', () {
      authState.setAuthenticated(
        userId: 'user-123',
        displayName: 'John Doe',
        accessToken: 'token-abc',
      );

      expect(authState.status, equals(AuthStatus.authenticated));
      expect(authState.userId, equals('user-123'));
      expect(authState.displayName, equals('John Doe'));
      expect(authState.accessToken, equals('token-abc'));
      expect(authState.isAuthenticated, isTrue);
    });

    test('setAuthenticated works without accessToken', () {
      authState.setAuthenticated(
        userId: 'user-456',
        displayName: 'Jane',
      );

      expect(authState.status, equals(AuthStatus.authenticated));
      expect(authState.userId, equals('user-456'));
      expect(authState.displayName, equals('Jane'));
      expect(authState.accessToken, isNull);
    });

    test('setUnauthenticated clears all fields', () {
      authState.setAuthenticated(
        userId: 'user-123',
        displayName: 'John',
      );
      authState.setUnauthenticated();

      expect(authState.status, equals(AuthStatus.unauthenticated));
      expect(authState.userId, isNull);
      expect(authState.displayName, isNull);
      expect(authState.accessToken, isNull);
      expect(authState.isAuthenticated, isFalse);
    });

    test('updateDisplayName changes name', () {
      authState.setAuthenticated(
        userId: 'user-123',
        displayName: 'John',
      );
      authState.updateDisplayName('John Smith');

      expect(authState.displayName, equals('John Smith'));
    });

    test('notifies listeners on setAuthenticated', () {
      var notified = false;
      authState.addListener(() => notified = true);

      authState.setAuthenticated(
        userId: 'user-1',
        displayName: 'Test',
      );

      expect(notified, isTrue);
    });

    test('notifies listeners on setUnauthenticated', () {
      authState.setAuthenticated(userId: 'u', displayName: 'X');
      var notified = false;
      authState.addListener(() => notified = true);

      authState.setUnauthenticated();

      expect(notified, isTrue);
    });

    test('notifies listeners on updateDisplayName', () {
      authState.setAuthenticated(userId: 'u', displayName: 'X');
      var notified = false;
      authState.addListener(() => notified = true);

      authState.updateDisplayName('Y');

      expect(notified, isTrue);
    });
  });
}
