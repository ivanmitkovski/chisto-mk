import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:flutter/material.dart';
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

    test('loads app locale from SharedPreferences on initialize', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_locale_code': 'mk',
      });
      await locator.initialize();
      expect(locator.appLocaleOverride.value, const Locale('mk'));
    });

    test('setAppLocale persists and updates notifier', () async {
      await locator.initialize();
      await locator.setAppLocale(const Locale('sq'));
      expect(locator.appLocaleOverride.value, const Locale('sq'));
      expect(locator.preferences.getString('app_locale_code'), 'sq');

      await locator.setAppLocale(null);
      expect(locator.appLocaleOverride.value, isNull);
      expect(locator.preferences.containsKey('app_locale_code'), isFalse);
    });
  });
}
