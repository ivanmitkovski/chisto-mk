import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppError', () {
    group('factory constructors', () {
      test('network creates correct code and message', () {
        final err = AppError.network();
        expect(err.code, equals('NETWORK_ERROR'));
        expect(
          err.message,
          equals('Unable to reach the server. Check your connection.'),
        );
      });

      test('timeout creates correct code and message', () {
        final err = AppError.timeout();
        expect(err.code, equals('TIMEOUT'));
        expect(
          err.message,
          equals('The request took too long. Please try again.'),
        );
      });

      test('unauthorized creates correct code and message', () {
        final err = AppError.unauthorized();
        expect(err.code, equals('UNAUTHORIZED'));
        expect(
          err.message,
          equals('Your session has expired. Please sign in again.'),
        );
      });

      test('forbidden creates correct code and message', () {
        final err = AppError.forbidden();
        expect(err.code, equals('FORBIDDEN'));
        expect(
          err.message,
          equals('You do not have permission to perform this action.'),
        );
      });

      test('notFound creates correct code and message', () {
        final err = AppError.notFound();
        expect(err.code, equals('NOT_FOUND'));
        expect(
          err.message,
          equals('The requested resource was not found.'),
        );
      });

      test('server creates correct code and message', () {
        final err = AppError.server();
        expect(err.code, equals('SERVER_ERROR'));
        expect(
          err.message,
          equals('Something went wrong on our end. Please try again.'),
        );
      });

      test('validation creates correct code and message', () {
        final err = AppError.validation(message: 'Invalid input');
        expect(err.code, equals('VALIDATION_ERROR'));
        expect(err.message, equals('Invalid input'));
      });

      test('unknown creates correct code and message', () {
        final err = AppError.unknown();
        expect(err.code, equals('UNKNOWN'));
        expect(err.message, equals('An unexpected error occurred.'));
      });
    });

    test('network errors are retryable', () {
      expect(AppError.network().retryable, isTrue);
      expect(AppError.timeout().retryable, isTrue);
      expect(AppError.server().retryable, isTrue);
    });

    test('unauthorized errors are not retryable', () {
      expect(AppError.unauthorized().retryable, isFalse);
      expect(AppError.forbidden().retryable, isFalse);
      expect(AppError.notFound().retryable, isFalse);
      expect(AppError.validation(message: 'x').retryable, isFalse);
      expect(AppError.unknown().retryable, isFalse);
    });

    test('toString formats correctly', () {
      final err = AppError.network();
      expect(err.toString(), equals('AppError(NETWORK_ERROR: Unable to reach the server. Check your connection.)'));
    });
  });
}
