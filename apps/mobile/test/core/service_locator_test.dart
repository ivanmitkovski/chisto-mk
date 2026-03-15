import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceLocator', () {
    late ServiceLocator locator;

    setUp(() {
      locator = ServiceLocator.instance;
    });

    test('initialize sets isInitialized to true', () {
      if (!locator.isInitialized) {
        locator.initialize(config: AppConfig.dev);
      }
      expect(locator.isInitialized, isTrue);
    });

    test('double initialization is idempotent', () {
      if (!locator.isInitialized) {
        locator.initialize(config: AppConfig.dev);
      }
      final authState = locator.authState;

      locator.initialize(config: AppConfig.dev);

      expect(locator.isInitialized, isTrue);
      expect(locator.authState, same(authState));
      expect(locator.authState.displayName, equals('You'));
    });

    test('after init, eventsRepository and checkInRepository are non-null', () {
      if (!locator.isInitialized) {
        locator.initialize(config: AppConfig.dev);
      }
      expect(locator.eventsRepository, isNotNull);
      expect(locator.checkInRepository, isNotNull);
    });

    test('after init, authState is authenticated with default user', () {
      if (!locator.isInitialized) {
        locator.initialize(config: AppConfig.dev);
      }
      expect(locator.authState.isAuthenticated, isTrue);
      expect(locator.authState.userId, equals('current_user'));
      expect(locator.authState.displayName, equals('You'));
    });

    test('reset sets isInitialized to false', () {
      if (!locator.isInitialized) {
        locator.initialize(config: AppConfig.dev);
      }
      expect(locator.isInitialized, isTrue);

      locator.reset();
      expect(locator.isInitialized, isFalse);
    });
  });
}
