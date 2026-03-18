import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServiceLocator', () {
    late ServiceLocator locator;

    setUp(() {
      locator = ServiceLocator.instance;
      locator.reset();
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('starts as not initialized', () {
      expect(locator.isInitialized, isFalse);
    });

    test('initialize sets isInitialized to true', () async {
      await locator.initialize();
      expect(locator.isInitialized, isTrue);
    });

    test('double initialization is idempotent', () async {
      await locator.initialize();
      final authState = locator.authState;

      await locator.initialize();
      expect(locator.authState, same(authState));
    });

    test('after init, repositories are available', () async {
      await locator.initialize();
      expect(locator.authRepository, isNotNull);
      expect(locator.eventsRepository, isNotNull);
      expect(locator.checkInRepository, isNotNull);
    });

    test('after init, authState starts unauthenticated (no hardcoded user)', () async {
      await locator.initialize();
      expect(locator.authState.isAuthenticated, isFalse);
    });

    test('reset sets isInitialized to false', () async {
      await locator.initialize();
      expect(locator.isInitialized, isTrue);

      locator.reset();
      expect(locator.isInitialized, isFalse);
    });
  });
}
